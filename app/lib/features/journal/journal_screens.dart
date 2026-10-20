import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/api.dart';
import '../../core/models_ext.dart';
import '../../core/offline.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

/// Ngày hôm nay theo giờ VN dạng yyyy-mm-dd (server chấp nhận mục mới chỉ cho hôm nay — BR-100).
String todayVnKey() {
  final n = vn(DateTime.now().toUtc());
  return '${n.year}-${two(n.month)}-${two(n.day)}';
}

const _weekdays = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];

/// "Thứ Sáu, 25/10" từ yyyy-mm-dd.
String journalDateLabel(String key) {
  final d = DateTime.tryParse(key);
  if (d == null) return key;
  return '${_weekdays[d.weekday - 1]}, ${two(d.day)}/${two(d.month)}/${d.year}';
}

const privacyLine = 'Chủ nhóm và quản trị không xem được trong app.';

/// V-33 Nhật ký: xem lại các mục (chỉ chủ sở hữu — US-07.08, US-07.10).
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final j = ref.watch(journalProvider);
    final t = context.text;
    Future<void> refresh() async {
      ref.invalidate(journalProvider);
      await ref.read(journalProvider.future).then((_) {}, onError: (_) {});
    }

    final today = todayVnKey();
    return AppScaffold(
      header: const AppHeader.back(title: 'Nhật ký'),
      body: AsyncBody<List<JournalEntry>>(
        value: j,
        onRetry: refresh,
        errorTitle: 'Chưa tải được nhật ký.',
        builder: (list) {
          final hasToday = list.any((e) => e.date == today);
          return PageList(onRefresh: refresh, children: [
            AppCard(children: [
              Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 18, color: DT.accent),
                const SizedBox(width: DT.spaceSm),
                Text(journalDateLabel(today), style: t.labelLarge!.copyWith(color: DT.accent)),
              ]),
              Text(hasToday ? 'Bạn đã viết nhật ký hôm nay' : 'Nhật ký hôm nay', style: t.headlineSmall),
              Text('Mỗi ngày 1 mục, tối đa 5.000 ký tự. Viết lại trong ngày sẽ sửa mục hôm nay.', style: t.bodySmall),
              const SizedBox(height: DT.spaceXs),
              PrimaryButton(
                key: const Key('writeToday'),
                compact: true,
                icon: hasToday ? Icons.edit_outlined : Icons.add,
                label: hasToday ? 'Sửa mục hôm nay' : 'Viết nhật ký',
                onPressed: () => context.push('/journal/$today'),
              ),
            ]),
            const HintText(privacyLine, icon: Icons.lock_outline),
            SectionHeader('Xem lại', small: true, subtitle: list.isEmpty ? null : '${list.length} mục'),
            if (list.isEmpty)
              const AppCard(children: [
                InfoRow(
                  icon: Icons.book_outlined,
                  iconColor: DT.textSecondary,
                  title: 'Chưa có mục nào',
                  subtitle: 'Nhật ký chỉ mình bạn đọc được.',
                ),
              ])
            else
              for (final e in list)
                AppCard(
                  key: Key('journal-${e.date}'),
                  onTap: () => context.push('/journal/${e.date}'),
                  children: [
                    Row(children: [
                      Expanded(child: Text(journalDateLabel(e.date), style: t.titleMedium)),
                      if (e.date == today) const StatusBadge('Hôm nay', tone: BadgeTone.accent),
                    ]),
                    Text(e.text, maxLines: 3, overflow: TextOverflow.ellipsis, style: t.bodyMedium),
                    Text('${CountedTextArea.fmt(e.text.characters.length)} ký tự · sửa lúc ${hhmm(e.updatedAt)} ${ddmm(e.updatedAt)}',
                        style: t.bodySmall),
                  ],
                ),
          ]);
        },
      ),
    );
  }
}

/// Viết / sửa / xóa một mục nhật ký. Mockup: `write_journal`.
/// Một mục mỗi ngày, ≤ 5.000 ký tự có bộ đếm; mã hóa ở server; chỉ chủ sở hữu đọc (BR-100).
class JournalEditScreen extends ConsumerStatefulWidget {
  const JournalEditScreen({super.key, required this.date});
  final String date;
  @override
  ConsumerState<JournalEditScreen> createState() => _JournalEditScreenState();
}

class _JournalEditScreenState extends ConsumerState<JournalEditScreen> {
  final _c = TextEditingController();
  bool _loaded = false;
  bool _exists = false;
  bool _busy = false;
  String? _err;

  /// AC-07.07.6: lưu thất bại vì mất mạng → giữ nháp trên máy, "Chưa lưu lên máy chủ" + "Thử lại".
  bool _unsynced = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _init(List<JournalEntry> list) {
    if (_loaded) return;
    _loaded = true;
    final e = list.where((x) => x.date == widget.date).firstOrNull;
    if (e != null) {
      _exists = true;
      _c.text = e.text;
    }
    final draft = ref.read(offlineCacheProvider).draft(widget.date);
    if (draft != null && draft != _c.text) {
      _c.text = draft;
      _unsynced = true;
    }
  }

  Future<void> _save() async {
    final v = _c.text;
    if (_busy) return;
    if (v.trim().isEmpty) {
      setState(() => _err = 'Nhật ký trống'); // AC-07.07.2: không tạo mục
      return;
    }
    setState(() {
      _busy = true;
      _err = null;
    });
    final cache = ref.read(offlineCacheProvider);
    try {
      await ref.read(apiProvider).saveJournal(widget.date, v);
      await cache.clearDraft(widget.date);
      _unsynced = false;
      ref.invalidate(journalProvider);
      if (mounted) {
        showSnack(context, 'Đã lưu nhật ký.');
        context.pop();
      }
    } catch (e) {
      final a = ApiError.from(e);
      if (a.offline) {
        await cache.saveDraft(widget.date, v);
        setState(() => _unsynced = true);
        return;
      }
      setState(() => _err = switch (a.code) {
            'JOURNAL_TOO_LONG' => 'Tối đa 5.000 ký tự.',
            'JOURNAL_DATE_INVALID' => 'Chỉ viết mục mới cho hôm nay.',
            'VALIDATION_FAILED' when v.trim().isEmpty => 'Nhật ký trống',
            _ => a.message,
          });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Xóa mục nhật ký?',
      message: 'Mục ngày ${journalDateLabel(widget.date)} sẽ bị xóa hẳn, không khôi phục được.',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref.read(apiProvider).deleteJournal(widget.date);
      ref.invalidate(journalProvider);
      if (mounted) {
        showSnack(context, 'Đã xóa mục nhật ký.');
        context.pop();
      }
    } catch (e) {
      setState(() => _err = ApiError.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final j = ref.watch(journalProvider);
    final t = context.text;
    final isToday = widget.date == todayVnKey();
    if (j.hasValue) _init(j.value!);
    return AppScaffold(
      header: AppHeader.back(
        title: _exists ? 'Sửa nhật ký' : 'Viết nhật ký',
        leading: HeaderLeading.close,
        trailing: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _c,
          builder: (_, v, _) => TextButton(
            key: const Key('journalSave'),
            onPressed: v.text.isEmpty || _busy || (!_exists && !isToday) ? null : _save,
            child: const Text('Lưu'),
          ),
        ),
      ),
      body: AsyncBody<List<JournalEntry>>(
        value: j,
        onRetry: () => ref.invalidate(journalProvider),
        builder: (list) {
          final canWrite = _exists || isToday;
          return PageList(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isToday ? 'Nhật ký hôm nay' : 'Nhật ký', style: t.headlineMedium),
              const SizedBox(height: DT.spaceXs),
              Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: DT.textSecondary),
                const SizedBox(width: 6),
                Text(journalDateLabel(widget.date), style: t.labelLarge),
              ]),
              const SizedBox(height: DT.spaceXs),
              Text('Mỗi ngày 1 mục. Viết lại trong ngày sẽ sửa mục hôm nay.', style: t.bodySmall),
            ]),
            if (!canWrite)
              const AppBanner(tone: BannerTone.accent, text: 'Chỉ viết mục mới cho hôm nay.')
            else
              AppCard(children: [
                CountedTextArea(
                  controller: _c,
                  max: journalMaxChars,
                  minLines: 10,
                  hint: 'Hôm nay bạn tập trung thế nào?',
                  overLimitText: 'Đã đạt giới hạn 5.000 ký tự.',
                  fieldKey: const Key('journalField'),
                  counterKey: const Key('journalCounter'),
                ),
              ]),
            const HintText(privacyLine, icon: Icons.lock_outline),
            if (_unsynced)
              AppBanner(
                key: const Key('journalUnsynced'),
                tone: BannerTone.accent,
                icon: Icons.cloud_off,
                title: 'Chưa lưu lên máy chủ',
                text: 'Bản nháp vẫn giữ trên máy này.',
                action: 'Thử lại',
                onAction: _busy ? null : _save,
              ),
            if (_err != null) AppBanner(key: const Key('journalError'), tone: BannerTone.danger, text: _err!),
            if (_exists)
              SecondaryButton(
                  key: const Key('journalDelete'),
                  label: 'Xóa mục này',
                  icon: Icons.delete_outline,
                  destructive: true,
                  onPressed: _busy ? null : _delete),
          ]);
        },
      ),
    );
  }
}
