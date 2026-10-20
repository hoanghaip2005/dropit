import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/models_ext.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

/// Khối "điều cần biết" nền cam nhạt (V-15).
class _KnowCard extends StatelessWidget {
  const _KnowCard(this.lines);
  final List<String> lines;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(DT.spaceMd),
        decoration: BoxDecoration(color: DT.accentSoftBg, borderRadius: BorderRadius.circular(DT.radiusCard)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: CircleAvatar(radius: 2.5, backgroundColor: DT.accent),
                ),
                const SizedBox(width: DT.spaceSm),
                Expanded(child: Text(l, style: context.text.bodyMedium!.copyWith(color: DT.textPrimary))),
              ]),
            ),
        ]),
      );
}

Widget _sessionHead(BuildContext context, MySessionResult? r) {
  final t = context.text;
  if (r == null) return const SizedBox.shrink();
  return AppCard(children: [
    Text(r.groupName ?? 'Phiên tập trung', style: t.titleMedium),
    Text('${ddmm(r.startedAt)} · ${hhmm(r.startedAt)} · ${r.durationMin} phút', style: t.bodySmall),
    if (r.forfeitTrigger != null) Text('Phiên mất thưởng tập thể do ${r.forfeitTrigger} rời phiên.', style: t.bodySmall),
  ]);
}

/// V-15 Gửi / sửa giải trình (thành viên có EXITED). Không đổi kết quả, không hoàn Coins (BR-54).
class ExplanationScreen extends ConsumerStatefulWidget {
  const ExplanationScreen({super.key, required this.sessionId});
  final String sessionId;
  @override
  ConsumerState<ExplanationScreen> createState() => _ExplanationScreenState();
}

class _ExplanationScreenState extends ConsumerState<ExplanationScreen> {
  final _c = TextEditingController();
  bool _busy = false;
  String? _err;
  Explanation? _sent;
  bool _prefilled = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Nạp giải trình đã gửi (US-04.05) vào ô một lần.
  void _prefill(Explanation? e) {
    if (_prefilled || e == null) return;
    _prefilled = true;
    _sent = e;
    _c.text = e.body;
  }

  Future<void> _submit() async {
    if (_c.text.trim().isEmpty) {
      setState(() => _err = 'Vui lòng nhập nội dung');
      return;
    }
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      final e = await ref.read(apiProvider).submitExplanation(widget.sessionId, _c.text.trim());
      ref.invalidate(resultProvider(widget.sessionId));
      ref.invalidate(historyProvider);
      ref.invalidate(myExplanationProvider(widget.sessionId));
      setState(() => _sent = e);
      if (mounted) showSnack(context, 'Đã gửi giải trình. Chủ nhóm sẽ thấy trong app.');
    } catch (e) {
      final a = ApiError.from(e);
      setState(() => _err = switch (a.code) {
            'EXPLANATION_WINDOW_CLOSED' => 'Đã hết hạn gửi hoặc sửa giải trình cho lần rời app này.',
            'NOT_EXITED_IN_SESSION' || 'FORBIDDEN_GROUP' => 'Không thể gửi giải trình cho sự kiện này.',
            'VALIDATION_FAILED' => 'Tối đa 500 ký tự.',
            _ => a.offline ? 'Chưa gửi được. Nội dung vẫn còn trên máy.' : a.message,
          });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(resultProvider(widget.sessionId)).value;
    final mine = ref.watch(myExplanationProvider(widget.sessionId));
    if (mine.hasValue) _prefill(mine.value);
    final full = mine.value;
    final locked = full != null && !full.canEdit; // quá 24 giờ từ lần gửi đầu → chỉ xem (AC-04.05.5)
    final t = context.text;
    return AppScaffold(
      header: const AppHeader.back(title: 'Giải trình lần rời app', leading: HeaderLeading.close),
      footer: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _c,
        builder: (_, v, _) => PrimaryButton(
          key: const Key('explanationSubmit'),
          label: _sent == null ? 'Gửi' : 'Lưu thay đổi',
          loading: _busy,
          onPressed: v.text.trim().isEmpty || locked ? null : _submit,
        ),
      ),
      children: [
        _sessionHead(context, r),
        if (r?.endsAtGuess != null)
          Text('Gửi được đến ${hhmm(r!.endsAtGuess!.add(const Duration(days: 7)))} '
              '${ddmm(r.endsAtGuess!.add(const Duration(days: 7)))}', style: t.bodySmall),
        const _KnowCard([
          'Giải trình không thay đổi kết quả phiên, không hoàn Coins và không khôi phục chuỗi cho ai.',
          'Chỉ bạn và chủ nhóm thấy giải trình. Các thành viên khác không thấy.',
          'Bạn chỉ gửi được một giải trình cho mỗi lần rời app; sửa được trong 24 giờ sau khi gửi.',
          'Không xóa được sự kiện rời app. Nếu ghi nhầm, hãy giải trình hoặc khiếu nại.',
        ]),
        AppCard(children: [
          const FieldLabel('Nội dung giải trình'),
          CountedTextArea(
            controller: _c,
            max: explanationMaxChars,
            minLines: 5,
            overLimitText: 'Tối đa 500 ký tự',
            fieldKey: const Key('explanationField'),
          ),
        ]),
        if (_sent != null)
          AppBanner(
            key: const Key('explanationSent'),
            tone: BannerTone.success,
            text: [
              'Đã gửi lúc ${hhmm(_sent!.submittedAt ?? _sent!.updatedAt)} ${ddmm(_sent!.submittedAt ?? _sent!.updatedAt)}.',
              if (_sent!.editedAt != null) 'Đã sửa lúc ${hhmm(_sent!.editedAt)} ${ddmm(_sent!.editedAt)}.',
              if (locked)
                'Đã hết hạn sửa.'
              else if (full?.editDeadline != null)
                'Sửa được đến ${hhmm(full!.editDeadline)} ${ddmm(full.editDeadline)}.'
              else
                'Sửa được trong 24 giờ sau lần gửi đầu.',
            ].join(' '),
          ),
        if (full != null && full.history.isNotEmpty)
          AppCard(key: const Key('explanationHistory'), children: [
            Text('Bản trước (${full.history.length})', style: t.titleMedium),
            for (final h in full.history)
              ListRow(
                title: '“${h['body']}”',
                subtitle: 'Viết lúc ${hhmm(DateTime.tryParse('${h['written_at']}'))} '
                    '${ddmm(DateTime.tryParse('${h['written_at']}'))} · thay lúc ${hhmm(DateTime.tryParse('${h['replaced_at']}'))}',
                divider: false,
              ),
          ]),
        if (_err != null) AppBanner(tone: BannerTone.danger, text: _err!),
      ],
    );
  }
}

/// Khiếu nại ghi nhầm (US-04.07, Should) — tạo từ kết quả phiên, trong 24 giờ sau khi phiên kết thúc (BR-86).
class AppealCreateScreen extends ConsumerStatefulWidget {
  const AppealCreateScreen({super.key, required this.sessionId});
  final String sessionId;
  @override
  ConsumerState<AppealCreateScreen> createState() => _AppealCreateScreenState();
}

class _AppealCreateScreenState extends ConsumerState<AppealCreateScreen> {
  final _c = TextEditingController();
  bool _system = false;
  bool _busy = false;
  String? _err;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      final a = await ref.read(apiProvider).createAppeal(widget.sessionId, _c.text.trim(), suspectSystemError: _system);
      ref.invalidate(resultProvider(widget.sessionId));
      ref.invalidate(historyProvider);
      if (mounted) {
        showSnack(
            context,
            a.status == 'ESCALATED'
                ? 'Đã gửi khiếu nại. Ca được chuyển quản trị xem xét.'
                : 'Đã gửi khiếu nại. Chủ nhóm sẽ xử lý trong 72 giờ.');
        context.pop();
      }
    } catch (e) {
      final a = ApiError.from(e);
      setState(() => _err = switch (a.code) {
            'APPEAL_EXISTS' => 'Bạn đã gửi khiếu nại cho phiên này.',
            'APPEAL_WINDOW_CLOSED' => 'Đã quá 24 giờ sau khi phiên kết thúc — không còn khiếu nại được.',
            _ => a.offline ? 'Chưa gửi được. Nội dung vẫn còn trên máy.' : a.message,
          });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(resultProvider(widget.sessionId)).value;
    return AppScaffold(
      header: const AppHeader.back(title: 'Khiếu nại ghi nhầm', leading: HeaderLeading.close),
      footer: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _c,
        builder: (_, v, _) => PrimaryButton(
          key: const Key('appealSubmit'),
          label: 'Gửi khiếu nại',
          loading: _busy,
          onPressed: v.text.trim().isEmpty ? null : _submit,
        ),
      ),
      children: [
        _sessionHead(context, r),
        const _KnowCard([
          'Dùng khi bạn tin lần rời app bị ghi nhầm (vd. lỗi máy, cuộc gọi khẩn cấp hệ thống).',
          'Chủ nhóm xem và quyết định miễn trừ hoặc bác, có ghi lý do. Nếu được miễn trừ, Coins và chuỗi của phiên được khôi phục.',
          'Mỗi phiên chỉ khiếu nại một lần, trong 24 giờ sau khi phiên kết thúc.',
        ]),
        AppCard(children: [
          const FieldLabel('Vì sao bạn cho là ghi nhầm?'),
          CountedTextArea(
            controller: _c,
            max: appealMaxChars,
            minLines: 5,
            overLimitText: 'Tối đa 1.000 ký tự',
            fieldKey: const Key('appealField'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _system,
            onChanged: (v) => setState(() => _system = v ?? false),
            title: const Text('Tôi nghi do lỗi hệ thống'),
            subtitle: const Text('Ca sẽ chuyển thẳng cho quản trị thay vì chủ nhóm.'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ]),
        if (_err != null) AppBanner(tone: BannerTone.danger, text: _err!),
      ],
    );
  }
}

/// V-47 Chủ nhóm xem giải trình của phiên — chỉ đọc; mỗi lần xem server ghi nhật ký truy cập.
/// Không Coins, chuỗi, điểm/hạng; không nút sửa/xóa/trả lời.
class OwnerExplanationsScreen extends ConsumerWidget {
  const OwnerExplanationsScreen({super.key, required this.sessionId});
  final String sessionId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ex = ref.watch(explanationsProvider(sessionId));
    final detail = ref.watch(ownerDetailProvider(sessionId)).value;
    final t = context.text;
    Future<void> refresh() async {
      ref.invalidate(explanationsProvider(sessionId));
      ref.invalidate(ownerDetailProvider(sessionId));
      await ref.read(explanationsProvider(sessionId).future).then((_) {}, onError: (_) {});
    }

    return AppScaffold(
      header: const AppHeader.brand(caption: 'Chủ nhóm', title: 'Giải trình', leading: HeaderLeading.back),
      body: AsyncBody<List<Explanation>>(
        value: ex,
        onRetry: refresh,
        errorTitle: 'Chưa tải được giải trình.',
        builder: (list) {
          final exitedNoExp = (detail?.members ?? const [])
              .where((m) => m['final_state'] == 'EXITED' && !list.any((e) => e.userId == m['user_id']))
              .toList();
          final deadline = detail?.endsAt?.add(const Duration(days: 7));
          return PageList(onRefresh: refresh, children: [
            if (detail != null)
              AppCard(children: [
                Text('Phiên ${hhmm(detail.startedAt)}–${hhmm(detail.endsAt)} · ${ddmm(detail.startedAt)}',
                    style: t.titleMedium),
                if (detail.forfeitTrigger != null)
                  Text('Phiên mất thưởng tập thể do ${detail.forfeitTrigger} rời phiên.', style: t.bodySmall),
              ]),
            for (final e in list)
              AppCard(key: Key('explanation-${e.userId}'), children: [
                Row(children: [
                  InitialAvatar(e.displayName, size: 40),
                  const SizedBox(width: DT.spaceSm),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.displayName, style: t.titleMedium),
                      Text('Rời app lúc ${hhmmss(e.exitedAt)}', style: t.bodySmall),
                    ]),
                  ),
                  if (detail?.forfeitTrigger == e.displayName)
                    const StatusBadge('Khởi phát', tone: BadgeTone.danger),
                ]),
                Text('“${e.body}”', style: t.bodyLarge),
                Text(
                    e.editedAt != null
                        ? 'Đã sửa lúc ${hhmm(e.editedAt)} ${ddmm(e.editedAt)}'
                        : 'Gửi lúc ${hhmm(e.submittedAt ?? e.updatedAt)} ${ddmm(e.submittedAt ?? e.updatedAt)}',
                    key: Key('explEdited_${e.userId}'),
                    style: t.bodySmall),
                if (e.addedAfterReport) const StatusBadge('Thêm sau khi tạo báo cáo', tone: BadgeTone.accent),
                _AppealStatusRow(detail: detail, userId: e.userId),
              ]),
            for (final m in exitedNoExp)
              AppCard(children: [
                MemberTile(
                  name: '${m['display_name']}',
                  subtitle: 'Rời app lúc ${hhmmss(DateTime.tryParse('${m['exited_at']}'))}',
                  divider: false,
                ),
                Text(
                  deadline != null && DateTime.now().toUtc().isBefore(deadline)
                      ? '${m['display_name']} chưa gửi giải trình. Hạn gửi đến ${hhmm(deadline)} ${ddmm(deadline)}.'
                      : '${m['display_name']} không gửi giải trình cho lần rời app này.',
                  style: t.bodyMedium!.copyWith(color: DT.textSecondary),
                ),
                _AppealStatusRow(detail: detail, userId: '${m['user_id']}'),
              ]),
            if (list.isEmpty && exitedNoExp.isEmpty)
              const AppCard(children: [
                InfoRow(icon: Icons.inbox_outlined, title: 'Chưa có giải trình', subtitle: 'Phiên này chưa có ai gửi giải trình.'),
              ]),
            const HintText('Giải trình không thay đổi kết quả phiên. Không chia sẻ cho thành viên khác.'),
          ]);
        },
      ),
    );
  }
}

class _AppealStatusRow extends StatelessWidget {
  const _AppealStatusRow({required this.detail, required this.userId});
  final SessionOwnerView? detail;
  final String userId;
  @override
  Widget build(BuildContext context) {
    final m = detail?.members.where((x) => x['user_id'] == userId).firstOrNull;
    final st = m?['appeal_status'] as String?;
    if (st == null) return const SizedBox.shrink();
    return Row(children: [
      Text('Khiếu nại: ', style: context.text.bodySmall),
      StatusBadge(appealStatusText(st),
          tone: st == 'EXEMPTED'
              ? BadgeTone.success
              : st == 'REJECTED'
                  ? BadgeTone.neutral
                  : BadgeTone.accent),
    ]);
  }
}

/// Chủ nhóm mở ca khiếu nại (GET /appeals/{id} → ĐANG XỬ LÝ) và quyết định miễn trừ / bác, bắt buộc lý do.
class OwnerAppealScreen extends ConsumerStatefulWidget {
  const OwnerAppealScreen({super.key, required this.appealId});
  final String appealId;
  @override
  ConsumerState<OwnerAppealScreen> createState() => _OwnerAppealScreenState();
}

class _OwnerAppealScreenState extends ConsumerState<OwnerAppealScreen> {
  final _reason = TextEditingController();
  bool _busy = false;
  String? _err;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _decide(Appeal a, String decision) async {
    final r = _reason.text.trim();
    if (decision != 'ESCALATE' && r.isEmpty) {
      setState(() => _err = 'Nhập lý do trước khi quyết định.');
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: switch (decision) {
        'EXEMPT' => 'Miễn trừ lần rời phiên?',
        'REJECT' => 'Bác khiếu nại?',
        _ => 'Chuyển quản trị?',
      },
      message: switch (decision) {
        'EXEMPT' => 'Nếu không còn ai rời phiên khác, cả phiên được khôi phục thưởng và chuỗi. Những người đã nhận thông báo rời phiên sẽ nhận bản đính chính.',
        'REJECT' => 'Kết quả phiên giữ nguyên. Người khiếu nại nhận lý do của bạn.',
        _ => 'Quản trị sẽ xem xét ca này thay bạn.',
      },
      confirmLabel: switch (decision) {
        'EXEMPT' => 'Miễn trừ',
        'REJECT' => 'Bác',
        _ => 'Chuyển',
      },
      destructive: decision == 'REJECT',
      confirmKey: const Key('decisionConfirm'),
    );
    if (!ok) return;
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await ref.read(apiProvider).decideAppeal(a.appealId, decision, r.isEmpty ? 'Chuyển quản trị' : r);
      ref.invalidate(appealProvider(widget.appealId));
      ref.invalidate(ownerDetailProvider(a.sessionId));
      if (mounted) showSnack(context, 'Đã ghi quyết định.');
    } catch (e) {
      final x = ApiError.from(e);
      setState(() => _err = x.code == 'APPEAL_ALREADY_DECIDED' ? 'Ca này đã có quyết định.' : x.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ap = ref.watch(appealProvider(widget.appealId));
    final t = context.text;
    return AppScaffold(
      header: const AppHeader.brand(caption: 'Chủ nhóm', title: 'Khiếu nại', leading: HeaderLeading.back),
      body: AsyncBody<Appeal>(
        value: ap,
        onRetry: () => ref.invalidate(appealProvider(widget.appealId)),
        errorTitle: 'Chưa tải được khiếu nại.',
        builder: (a) => PageList(children: [
          AppCard(children: [
            Row(children: [
              InitialAvatar(a.displayName ?? '?', size: 40),
              const SizedBox(width: DT.spaceSm),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.displayName ?? 'Thành viên', style: t.titleMedium),
                  Text('Rời app lúc ${hhmmss(a.exitedAt)} ${ddmm(a.exitedAt)}', style: t.bodySmall),
                ]),
              ),
              StatusBadge(appealStatusText(a.status),
                  key: const Key('appealStatus'),
                  tone: a.status == 'EXEMPTED'
                      ? BadgeTone.success
                      : a.open
                          ? BadgeTone.accent
                          : BadgeTone.neutral),
            ]),
            const FieldLabel('Nội dung khiếu nại'),
            Text('“${a.body}”', style: t.bodyLarge),
            if (a.suspectSystemError) const StatusBadge('Nghi lỗi hệ thống', tone: BadgeTone.neutral),
          ]),
          SecondaryButton(
            label: 'Xem chi tiết phiên',
            icon: Icons.event_note_outlined,
            onPressed: () => context.push('/owner/sessions/${a.sessionId}'),
          ),
          if (a.open) ...[
            AppCard(children: [
              const FieldLabel('Lý do quyết định (bắt buộc)'),
              CountedTextArea(controller: _reason, max: 500, minLines: 3, fieldKey: const Key('decisionReason')),
              Text('Người khiếu nại thấy lý do này. Không ghi điểm, hạng hay đánh giá cá nhân.', style: t.bodySmall),
            ]),
            if (_err != null) AppBanner(tone: BannerTone.danger, text: _err!),
            PrimaryButton(
                key: const Key('exemptButton'),
                label: 'Miễn trừ',
                icon: Icons.verified_outlined,
                loading: _busy,
                onPressed: () => _decide(a, 'EXEMPT')),
            SecondaryButton(
                key: const Key('rejectButton'),
                label: 'Bác',
                destructive: true,
                onPressed: _busy ? null : () => _decide(a, 'REJECT')),
            LinkButton(label: 'Chuyển quản trị', onPressed: _busy ? null : () => _decide(a, 'ESCALATE')),
          ] else
            AppCard(children: [
              Text('Quyết định', style: t.titleMedium),
              if (a.decisionReason != null) Text('Lý do: ${a.decisionReason}', style: t.bodyMedium),
              if (a.decidedAt != null) Text('Lúc ${hhmm(a.decidedAt)} ${ddmm(a.decidedAt)}', style: t.bodySmall),
              if (a.status == 'ESCALATED') Text('Ca đã chuyển quản trị xem xét.', style: t.bodySmall),
            ]),
        ]),
      ),
    );
  }
}
