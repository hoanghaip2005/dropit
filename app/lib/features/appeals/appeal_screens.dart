import 'dart:async';
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
  bool _prefilled = false;
  String? _err;
  Explanation? _sent;
  String _baseline = '';
  bool _allowPop = false;
  bool _permissionDenied = false;
  Timer? _deadlineTimer;
  DateTime? _armedDeadline;

  @override
  void dispose() {
    _deadlineTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_busy) return;
    if (_c.text != _baseline) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Bỏ thay đổi chưa lưu?'),
          content: const Text('Nội dung đang viết sẽ không được lưu.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Tiếp tục viết'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Bỏ thay đổi'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).maybePop();
      } else {
        context.go('/history/${widget.sessionId}');
      }
    });
  }

  void _armDeadline(DateTime? deadline) {
    if (_armedDeadline == deadline) return;
    _deadlineTimer?.cancel();
    _armedDeadline = deadline;
    if (deadline != null && deadline.isAfter(DateTime.now().toUtc())) {
      _deadlineTimer = Timer(deadline.difference(DateTime.now().toUtc()), () {
        if (mounted) setState(() {});
      });
    }
  }

  bool _editable(MySessionResult result, Explanation? full) {
    if (_permissionDenied || result.finalState != 'EXITED') return false;
    final now = DateTime.now().toUtc();
    if (full != null) {
      return full.canEdit &&
          (full.editDeadline == null || now.isBefore(full.editDeadline!));
    }
    return result.canExplain &&
        (result.explanationSubmitDeadline == null ||
            now.isBefore(result.explanationSubmitDeadline!));
  }

  Future<void> _retry() async {
    ref.invalidate(resultProvider(widget.sessionId));
    ref.invalidate(myExplanationProvider(widget.sessionId));
  }

  Future<void> _submit() async {
    if (_busy) return;
    final result = ref.read(resultProvider(widget.sessionId));
    final mine = ref.read(myExplanationProvider(widget.sessionId));
    if (!result.hasValue ||
        result.isLoading ||
        result.hasError ||
        !mine.hasValue ||
        mine.isLoading ||
        mine.hasError ||
        !_editable(result.requireValue, mine.requireValue)) {
      return;
    }
    final text = _c.text.trim();
    if (text.isEmpty || text.runes.length > explanationMaxChars) return;
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      final saved = await ref
          .read(apiProvider)
          .submitExplanation(
            widget.sessionId,
            text,
            version: mine.requireValue?.version,
          );
      if (!mounted) return;
      setState(() {
        _sent = saved;
        _prefilled = true;
        _baseline = text;
        _c.text = text;
      });
      ref.invalidate(resultProvider(widget.sessionId));
      ref.invalidate(historyProvider);
      ref.invalidate(historyPeriodProvider);
      ref.invalidate(historyRewardTodayProvider);
      ref.invalidate(myExplanationProvider(widget.sessionId));
      showSnack(context, 'Đã lưu giải trình.');
    } catch (error) {
      if (!mounted) return;
      final a = ApiError.from(error);
      if (a.code == 'EXPLANATION_WINDOW_CLOSED' ||
          a.code == 'NOT_EXITED_IN_SESSION' ||
          a.code == 'FORBIDDEN_GROUP') {
        _permissionDenied = true;
        ref.invalidate(resultProvider(widget.sessionId));
        ref.invalidate(myExplanationProvider(widget.sessionId));
      }
      setState(
        () => _err = switch (a.code) {
          'EXPLANATION_WINDOW_CLOSED' => 'Đã hết hạn gửi hoặc sửa giải trình.',
          'NOT_EXITED_IN_SESSION' ||
          'FORBIDDEN_GROUP' => 'Bạn không có quyền giải trình cho phiên này.',
          'VALIDATION_FAILED' => 'Nội dung tối đa 500 ký tự.',
          'VERSION_CONFLICT' =>
            'Giải trình đã thay đổi ở nơi khác. Tải lại trước khi lưu; bản đang viết vẫn được giữ.',
          _ =>
            a.offline
                ? 'Chưa gửi được. Nội dung vẫn được giữ trên màn hình.'
                : a.message,
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(resultProvider(widget.sessionId));
    final mine = ref.watch(myExplanationProvider(widget.sessionId));
    final ready =
        result.hasValue &&
        !result.isLoading &&
        !result.hasError &&
        mine.hasValue &&
        !mine.isLoading &&
        !mine.hasError;
    final full = ready ? mine.requireValue : null;
    if (ready && !_prefilled) {
      _prefilled = true;
      if (full != null) {
        _c.text = full.body;
        _baseline = full.body;
        _sent = full;
      }
    }
    if (ready) {
      _armDeadline(
        full?.editDeadline ??
            (full == null
                ? result.requireValue.explanationSubmitDeadline
                : null),
      );
    }
    final canEdit = ready && _editable(result.requireValue, full);
    final t = context.text;
    final theme = Theme.of(context).copyWith(
      textTheme: t.apply(
        bodyColor: OwnerStyle.ink,
        displayColor: OwnerStyle.ink,
      ),
    );
    return PopScope(
      canPop: _allowPop || (!_busy && _c.text == _baseline),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Theme(
        data: theme,
        child: AppScaffold(
          backgroundColor: OwnerStyle.canvas,
          header: AppHeader.back(
            title: 'Giải trình',
            leading: HeaderLeading.close,
            onLeading: _close,
          ),
          footer: canEdit
              ? ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _c,
                  builder: (_, value, _) => PrimaryButton(
                    key: const Key('explanationSubmit'),
                    label: full == null && _sent == null
                        ? 'Gửi giải trình'
                        : 'Lưu thay đổi',
                    loading: _busy,
                    onPressed:
                        _busy ||
                            value.text.trim().isEmpty ||
                            value.text.trim().runes.length > explanationMaxChars
                        ? null
                        : _submit,
                  ),
                )
              : null,
          children: [
            if (!ready && (result.hasError || mine.hasError))
              SizedBox(
                height: 400,
                child: ErrorState(
                  error: result.error ?? mine.error!,
                  onRetry: _retry,
                  title: 'Chưa tải được thông tin giải trình.',
                ),
              )
            else if (!ready)
              const SizedBox(height: 320, child: SkeletonList())
            else ...[
              _ExplanationSessionCard(result.requireValue),
              const AppCard(
                color: Colors.white,
                children: [
                  Text('Chỉ bạn và chủ nhóm xem được nội dung.'),
                  Text('Giải trình không đổi kết quả, Coins hoặc chuỗi.'),
                ],
              ),
              if (full == null &&
                  result.requireValue.explanationSubmitDeadline != null)
                Text(
                  'Hạn gửi: ${hhmm(result.requireValue.explanationSubmitDeadline)} ${ddmm(result.requireValue.explanationSubmitDeadline)}',
                  style: t.bodySmall!.copyWith(color: OwnerStyle.muted),
                ),
              if (!canEdit)
                AppBanner(
                  key: const Key('explanationReadOnly'),
                  tone: BannerTone.info,
                  text: full != null
                      ? 'Giải trình chỉ đọc. Đã hết hạn sửa hoặc không còn quyền sửa.'
                      : 'Hiện không thể gửi giải trình cho phiên này.',
                ),
              AppCard(
                color: Colors.white,
                children: [
                  const FieldLabel('Nội dung giải trình'),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _c,
                    builder: (_, value, _) {
                      final count = value.text.trim().runes.length;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            key: const Key('explanationField'),
                            controller: _c,
                            readOnly: !canEdit || _busy,
                            minLines: 5,
                            maxLines: 12,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Mô tả ngắn lý do bạn rời phiên…',
                              filled: true,
                              fillColor: OwnerStyle.inset,
                              errorText: count > explanationMaxChars
                                  ? 'Tối đa 500 ký tự'
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DT.radiusCard,
                                ),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          Text(
                            '$count / 500',
                            key: const Key('explanationCounter'),
                            textAlign: TextAlign.right,
                            style: t.bodySmall,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              if (_sent != null || full != null) ...[
                AppCard(
                  key: const Key('explanationSent'),
                  color: Colors.white,
                  children: [
                    Text('Đã gửi giải trình', style: t.titleMedium),
                    if (full != null && _c.text != full.body) ...[
                      const Text('Nội dung đang lưu trên máy chủ:'),
                      Text(full.body),
                    ],
                    if ((full ?? _sent)!.submittedAt != null)
                      Text(
                        'Gửi lúc ${hhmm((full ?? _sent)!.submittedAt)} ${ddmm((full ?? _sent)!.submittedAt)}',
                        style: t.bodySmall,
                      ),
                    if ((full ?? _sent)!.editedAt != null)
                      Text(
                        'Đã sửa lúc ${hhmm((full ?? _sent)!.editedAt)} ${ddmm((full ?? _sent)!.editedAt)}',
                        style: t.bodySmall,
                      ),
                    if ((full ?? _sent)!.addedAfterReport)
                      const Text('Đã thêm sau khi tạo báo cáo.'),
                    if (full?.editDeadline != null && canEdit)
                      Text(
                        'Hạn sửa: ${hhmm(full!.editDeadline)} ${ddmm(full.editDeadline)}',
                        style: t.bodySmall,
                      ),
                  ],
                ),
              ],
              if (full != null && full.history.isNotEmpty)
                AppCard(
                  key: const Key('explanationHistory'),
                  color: Colors.white,
                  children: [
                    Text(
                      'Lịch sử chỉnh sửa (${full.history.length})',
                      style: t.titleMedium,
                    ),
                    for (final revision in full.history) ...[
                      Text('${revision['body']}'),
                      Text(
                        'Viết lúc ${hhmm(DateTime.tryParse('${revision['written_at']}'))} ${ddmm(DateTime.tryParse('${revision['written_at']}'))} · thay lúc ${hhmm(DateTime.tryParse('${revision['replaced_at']}'))} ${ddmm(DateTime.tryParse('${revision['replaced_at']}'))}',
                        style: t.bodySmall!.copyWith(color: OwnerStyle.muted),
                      ),
                    ],
                  ],
                ),
              if (_err != null) ...[
                AppBanner(tone: BannerTone.danger, text: _err!),
                TextButton(
                  onPressed: _busy ? null : _retry,
                  child: const Text('Tải lại quyền và trạng thái'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ExplanationSessionCard extends StatelessWidget {
  const _ExplanationSessionCard(this.result);
  final MySessionResult result;
  @override
  Widget build(BuildContext context) {
    final mode = switch (result.sessionMode) {
      'SQUAD' => 'Squad',
      'SOLO' => 'Cá nhân',
      _ => 'Chưa rõ chế độ',
    };
    final seconds = result.focusSeconds < 0 ? 0 : result.focusSeconds;
    return AppCard(
      color: Colors.white,
      children: [
        Text(
          result.groupName ?? 'Phiên tập trung',
          style: context.text.titleMedium,
        ),
        Text(
          '$mode · ${ddmm(result.startedAt)}',
          style: context.text.bodySmall,
        ),
        Text(
          'Tập trung ${seconds ~/ 60} phút ${seconds % 60} giây',
          style: context.text.bodyMedium,
        ),
        Text(
          result.exitedAt == null
              ? 'Chưa có thời điểm rời phiên'
              : 'Rời lúc ${hhmm(result.exitedAt)} ${ddmm(result.exitedAt)}',
          style: context.text.bodySmall,
        ),
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
      ref.invalidate(historyPeriodProvider);
      ref.invalidate(historyRewardTodayProvider);
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
