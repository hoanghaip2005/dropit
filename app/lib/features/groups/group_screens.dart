import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/models_ext.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

/// V-19 Nhóm của tôi (vai trò theo từng nhóm). Mockup: `t_02_danh_sach_nhom`.
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(myGroupsProvider);
    Future<void> refresh() async {
      ref.invalidate(myGroupsProvider);
      await ref.read(myGroupsProvider.future).catchError((_) => <MyGroup>[]);
    }

    return AppScaffold(
      header: context.ownerStyle
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Align(alignment: Alignment.centerLeft, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DropIt! · Chủ nhóm', style: context.text.bodySmall!.copyWith(color: OwnerStyle.muted)),
                  const SizedBox(height: 4),
                  Text('Nhóm của tôi', style: context.text.headlineLarge!.copyWith(height: 36 / 28)),
                ],
              )),
            )
          : const AppHeader.large(caption: 'DropIt!', title: 'Nhóm của tôi'),
      body: AsyncBody<List<MyGroup>>(
        value: groups,
        onRetry: () => ref.invalidate(myGroupsProvider),
        isEmpty: (g) => g.isEmpty,
        empty: StateMessage(
          icon: Icons.groups_outlined,
          tone: StateTone.accent,
          title: 'Chưa có nhóm',
          body: 'Nhập mã mời để tham gia, hoặc tạo nhóm mới.',
          action: 'Nhập mã nhóm',
          onAction: () => context.push('/join'),
          secondaryAction: 'Tạo nhóm',
          onSecondaryAction: () => context.push('/groups/new'),
        ),
        builder: (list) {
          return PageList(
            onRefresh: refresh,
            children: [
              Row(children: [
                Expanded(child: PrimaryButton(
                  compact: true,
                  icon: Icons.add,
                  label: 'Tạo nhóm',
                  onPressed: () => context.push('/groups/new'),
                )),
                const SizedBox(width: DT.spaceSm),
                Expanded(child: SecondaryButton(
                  icon: Icons.vpn_key_outlined,
                  label: 'Nhập mã nhóm',
                  onPressed: () => context.push('/join'),
                )),
              ]),
              Padding(
                padding: const EdgeInsets.only(top: DT.spaceSm),
                child: SectionHeader(ref.watch(ownerOnlyProvider) == true ? 'Nhóm bạn quản lý' : 'Nhóm đang tham gia',
                  trailing: Text('${list.length} nhóm', style: context.text.bodySmall)),
              ),
              for (final g in list) _GroupCard(group: g),
            ],
          );
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});
  final MyGroup group;
  @override
  Widget build(BuildContext context) {
    final g = group;
    final t = context.text;
    final next = g.nextSession;
    return AppCard(
      radius: context.ownerStyle ? DT.radiusLg : DT.radiusMd,
      padding: EdgeInsets.all(context.ownerStyle ? 16 : 20),
      gap: DT.spaceMd,
      onTap: () => context.push('/groups/${g.groupId}'),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: DT.accentSoftBg, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.groups_rounded, color: DT.accent, size: 26),
            ),
            const SizedBox(width: DT.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.name, style: t.headlineSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: DT.spaceXs),
                  Text('${g.memberCount} thành viên', style: t.bodySmall!.copyWith(color: context.ownerStyle ? OwnerStyle.muted : DT.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: DT.spaceXs),
            StatusBadge(g.isOwner ? 'Chủ nhóm' : 'Thành viên', tone: g.isOwner ? BadgeTone.accent : BadgeTone.neutral),
          ],
        ),
        if (g.status != 'ACTIVE') StatusBadge(groupStatusText(g.status), tone: BadgeTone.danger),
        // BR-117: chỉ số RIÊNG nhóm này, tháng hiện tại tạm tính đến hôm qua — không cộng nhiều nhóm
        Container(
          key: Key('rate_${g.groupId}'),
          padding: const EdgeInsets.all(DT.spaceMd),
          decoration: BoxDecoration(color: context.ownerStyle ? OwnerStyle.inset : DT.background, borderRadius: BorderRadius.circular(DT.radius)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hoàn thành tháng này', style: t.titleMedium),
                const SizedBox(height: DT.spaceXs),
                Text(g.isOwner ? 'Cả nhóm · Đến hôm qua' : 'Của bạn · Đến hôm qua', style: t.bodySmall!.copyWith(color: context.ownerStyle ? OwnerStyle.muted : DT.textSecondary)),
              ])),
              const SizedBox(width: DT.spaceSm),
              Text(g.monthCompletionRate == null ? '—' : '${g.monthCompletionRate!.toStringAsFixed(1)}%',
                  style: t.headlineLarge!.copyWith(color: DT.accent, fontFeatures: DT.tabular)),
            ]),
            const SizedBox(height: DT.spaceMd),
            if (g.monthCompletionRate == null)
              Text('Chưa có dữ liệu tháng này', style: t.bodySmall!.copyWith(color: context.ownerStyle ? OwnerStyle.muted : DT.textSecondary))
            else LinearProgressIndicator(value: (g.monthCompletionRate! / 100).clamp(0.0, 1.0),
                minHeight: 6, borderRadius: BorderRadius.circular(DT.pill), backgroundColor: context.ownerStyle ? OwnerStyle.line : DT.surfaceDim),
          ]),
        ),
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: context.ownerStyle ? OwnerStyle.inset : DT.surfaceHigh, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.calendar_today_outlined, size: 19, color: DT.textSecondary),
          ),
          const SizedBox(width: DT.spaceSm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Phiên kế tiếp', style: t.bodySmall),
            const SizedBox(height: DT.spaceXs),
            Text(next == null ? 'Chưa có lịch' : '${hhmm(next.startedAt)} · ${dayLabel(next.startedAt)}', style: t.titleMedium),
            if (next != null) Text('${next.durationMin} phút tập trung', style: t.bodySmall),
          ])),
        ]),
        Divider(height: 1, color: context.ownerStyle ? OwnerStyle.line : DT.divider),
        Row(
            children: [
              if (g.isOwner) ...[
              Expanded(
                child: SecondaryButton(
                  label: 'Lên lịch',
                  onPressed: () => context.push('/groups/${g.groupId}/schedule'),
                ),
              ),
              const SizedBox(width: DT.spaceSm),
              ],
              Expanded(
                child: PrimaryButton(
                  compact: true,
                  label: 'Xem nhóm',
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: () => context.push('/groups/${g.groupId}'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// V-04 Nhập mã nhóm. Mockup: `c_03_nhap_ma_tham_gia`.
class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});
  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _c = TextEditingController();
  String? _err;
  static final _re = RegExp(r'^[A-HJ-NP-Z2-9]{8}$');

  void _go() {
    final code = _c.text.trim().toUpperCase();
    if (!_re.hasMatch(code)) {
      setState(() => _err = 'Mã gồm 8 ký tự (chữ in hoa và số, không có I, O, 0, 1).');
      return;
    }
    context.push('/consent/$code');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return AppScaffold(
      header: const AppHeader.back(title: 'Tham gia nhóm'),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(label: 'Tiếp tục', trailingIcon: Icons.arrow_forward, onPressed: _go),
          const SizedBox(height: DT.spaceSm),
          Text('Chưa có mã? Hỏi chủ nhóm của bạn.', style: t.bodySmall),
        ],
      ),
      children: [
        Text('Bước 1/2', style: t.labelLarge!.copyWith(color: DT.textSecondary)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhập mã nhóm', style: t.headlineLarge),
            Text('Nhập mã 8 ký tự do chủ nhóm gửi cho bạn.', style: t.bodyMedium!.copyWith(color: DT.textSecondary)),
          ],
        ),
        TextField(
          key: const Key('inviteCodeField'),
          controller: _c,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          maxLength: 8,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]'))],
          style: t.headlineMedium!.copyWith(letterSpacing: 8, fontFeatures: DT.tabular),
          decoration: InputDecoration(
            hintText: 'AB3CD7EF',
            hintStyle: t.headlineMedium!.copyWith(letterSpacing: 8, color: DT.outlineVariant),
            errorText: _err,
            errorMaxLines: 2,
            counterText: '',
          ),
          onSubmitted: (_) => _go(),
        ),
        const HintText('Bạn chỉ thuộc 1 nhóm tại một thời điểm. Bước sau là màn đồng ý quy tắc minh bạch.'),
      ],
    );
  }
}

/// V-05 Đồng ý minh bạch — mọi công tắc mặc định TẮT. Mockup: `c_04_dong_y_quy_tac`.
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key, required this.code});
  final String code;
  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  final _on = <String, bool>{};
  bool _busy = false;
  String? _err;

  // AC-01.05.5: nút "Đồng ý" chỉ bật sau khi cuộn đến cuối nội dung (giả định).
  final _scroll = ScrollController();
  bool _readToEnd = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_checkEnd);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _checkEnd() {
    if (_readToEnd || !_scroll.hasClients) return;
    final p = _scroll.position;
    if (p.pixels >= p.maxScrollExtent - 24) setState(() => _readToEnd = true);
  }

  Future<void> _accept(ConsentDocument doc) async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await ref
          .read(apiProvider)
          .acceptConsent(
            doc.groupId,
            version: doc.consentVersion,
            code: widget.code,
            items: _on.entries.where((e) => e.value).map((e) => e.key).toList(),
          );
      ref.invalidate(myGroupsProvider);
      ref.invalidate(upcomingProvider);
      if (mounted) {
        showSnack(context, 'Đã vào nhóm ${doc.groupName}.');
        context.go('/home');
      }
    } catch (e) {
      final a = ApiError.from(e);
      setState(
        () => _err = switch (a.code) {
          'GROUP_FULL' => 'Nhóm đã đủ 10 thành viên.',
          'ALREADY_IN_GROUP' => a.message,
          'OWNER_OF_THIS_GROUP' => 'Bạn là chủ nhóm này nên không tham gia làm thành viên.',
          'CONSENT_VERSION_STALE' => 'Nội dung đồng ý vừa thay đổi. Vui lòng đọc lại.',
          _ => a.offline ? 'Không có kết nối. Chưa vào nhóm.' : a.message,
        },
      );
      if (a.code == 'CONSENT_VERSION_STALE') ref.invalidate(invitePreviewProvider(widget.code));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = ref.watch(invitePreviewProvider(widget.code));
    final t = context.text;
    return AppScaffold(
      header: const AppHeader.back(title: 'Quy tắc minh bạch'),
      body: doc.when(
        loading: () => const SkeletonList(),
        error: (e, _) {
          final a = ApiError.from(e);
          if (a.status == 404) {
            return StateMessage(
              icon: Icons.search_off,
              tone: StateTone.danger,
              title: 'Mã không đúng hoặc đã hết hiệu lực',
              body: 'Hỏi chủ nhóm mã mới.',
              action: 'Nhập lại',
              onAction: () => context.pop(),
            );
          }
          if (a.status == 429) {
            return StateMessage(icon: Icons.lock_clock, title: 'Tạm khóa nhập mã', body: a.message);
          }
          return ErrorState(error: e, onRetry: () => ref.invalidate(invitePreviewProvider(widget.code)));
        },
        data: (d) {
          final requiredOk = d.items.where((i) => i.required).every((i) => _on[i.code] == true);
          // nội dung ngắn hơn màn hình → coi như đã đọc hết
          WidgetsBinding.instance.addPostFrameCallback((_) => _checkEnd());
          return PageList(
            controller: _scroll,
            children: [
              Text('Bước 2/2 · ${d.groupName}', style: t.labelLarge!.copyWith(color: DT.textSecondary)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.groupName, style: t.headlineMedium),
                  if (d.ownerDisplayName != null)
                    Text('Chủ nhóm: ${d.ownerDisplayName} · ${d.memberCount}/10 thành viên', style: t.bodySmall),
                ],
              ),
              if (d.reportPurpose != null && d.reportPurpose!.isNotEmpty)
                AppCard(
                  children: [
                    InfoRow(
                      icon: Icons.assignment_outlined,
                      title: 'Mục đích sử dụng báo cáo',
                      subtitle: d.reportPurpose!,
                    ),
                  ],
                ),
              const AppCard(
                children: [
                  InfoRow(
                    icon: Icons.visibility_outlined,
                    iconColor: DT.success,
                    title: 'App chỉ biết bạn có rời app trong phiên không',
                    subtitle:
                        'DropIt! chỉ ghi khi phiên đang chạy: giờ vào, giờ rời app, khóa màn hình, mất kết nối. '
                        'Không đọc nội dung điện thoại, không biết bạn mở app nào, không dùng vị trí hay cảm biến.',
                  ),
                ],
              ),
              const AppCard(
                gap: DT.spaceMd,
                children: [
                  InfoRow(
                    icon: Icons.logout,
                    iconColor: DT.warning,
                    title: 'Rời app quá 3 giây = rời phiên',
                    subtitle: 'Khoan hồng 3 giây. Quá 3 giây, tên bạn được báo ngay cho cả nhóm.',
                  ),
                  InfoRow(
                    icon: Icons.group_off_outlined,
                    iconColor: DT.warning,
                    title: 'Cả phiên mất thưởng',
                    subtitle: 'Phiên vẫn chạy đến hết giờ, nhưng mọi người trong phiên mất Coins của phiên.',
                  ),
                  InfoRow(
                    icon: Icons.screen_lock_portrait_outlined,
                    iconColor: DT.success,
                    title: 'Được tắt màn hình',
                    subtitle: 'Khóa màn hình không tính là rời app.',
                  ),
                ],
              ),
              if (d.isFull) const AppBanner(tone: BannerTone.danger, text: 'Nhóm đã đủ 10 thành viên.'),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: DT.spaceSm),
                gap: 0,
                children: [
                  for (final it in d.items)
                    SwitchListTile(
                      key: Key('consent_${it.code}'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: DT.spaceMd),
                      value: _on[it.code] ?? false,
                      onChanged: (v) => setState(() => _on[it.code] = v),
                      title: Text(it.text, style: t.bodyMedium),
                      subtitle: it.required
                          ? Text('Bắt buộc', style: t.labelMedium!.copyWith(color: DT.accent))
                          : Text('Không bắt buộc', style: t.bodySmall),
                    ),
                ],
              ),
              if (_err != null) AppBanner(tone: BannerTone.danger, text: _err!),
              if (!_readToEnd)
                const HintText('Cuộn đến cuối để đọc hết nội dung trước khi đồng ý.', key: Key('consentScrollHint')),
              FilledButton(
                key: const Key('acceptConsent'),
                onPressed: requiredOk && _readToEnd && !_busy && !d.isFull ? () => _accept(d) : null,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Đồng ý và vào nhóm'),
              ),
              SecondaryButton(label: 'Không đồng ý', onPressed: () => context.go('/groups')),
            ],
          );
        },
      ),
    );
  }
}

/// V-42 Tạo nhóm. Mockup: `t_03_tao_sua_nhom`.
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});
  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _name = TextEditingController();
  final _purpose = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _err;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      final g = await ref.read(apiProvider).createGroup(_name.text.trim(), _purpose.text.trim());
      ref.invalidate(myGroupsProvider);
      if (mounted) context.pushReplacement('/groups/${g['group_id']}/invite');
    } catch (e) {
      final a = ApiError.from(e);
      setState(() => _err = a.code == 'MAX_GROUPS_OWNED' ? 'Bạn đã đạt số nhóm tối đa được làm chủ.' : a.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    header: const AppHeader.back(title: 'Tạo nhóm', leading: HeaderLeading.close),
    footer: PrimaryButton(label: 'Tạo nhóm', loading: _busy, onPressed: _submit),
    body: Form(
      key: _form,
      child: PageList(
        children: [
          const HintText('Bạn là chủ nhóm, không tham gia phiên. Nhóm có tối đa 10 thành viên.', icon: null),
          AppCard(
            gap: DT.spaceSm,
            children: [
              const FieldLabel('Tên nhóm'),
              TextFormField(
                controller: _name,
                maxLength: 60,
                decoration: inCardInput(hint: 'VD: Nhóm Thiết kế'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên nhóm' : null,
              ),
            ],
          ),
          AppCard(
            gap: DT.spaceSm,
            children: [
              const FieldLabel('Mục đích sử dụng báo cáo'),
              TextFormField(
                controller: _purpose,
                maxLength: 500,
                maxLines: 4,
                decoration: inCardInput(helper: 'Thành viên đọc mục này ở màn đồng ý.'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập mục đích sử dụng báo cáo' : null,
              ),
            ],
          ),
          if (_err != null) AppBanner(tone: BannerTone.danger, text: _err!),
        ],
      ),
    ),
  );
}

/// V-20 Thành viên nhóm (+ khối chủ nhóm: mời, đặt lịch, phiên). Không Coins/chuỗi.
/// Mockup: `manager_dashboard` (chủ nhóm).
class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(myGroupsProvider);
    final g = groups.value?.where((x) => x.groupId == groupId).firstOrNull;
    final isOwner = g?.isOwner ?? false;
    final members = ref.watch(membersProvider(groupId));
    final frames = {for (final s in ref.watch(shopItemsProvider).value ?? const <ShopItem>[]) s.itemId: s.previewKey};
    final t = context.text;
    Future<void> refresh() async {
      ref.invalidate(membersProvider(groupId));
      ref.invalidate(schedulesProvider(groupId));
      ref.invalidate(myGroupsProvider);
      await ref.read(membersProvider(groupId).future).catchError((_) => GroupMembers.fromJson(const {}));
    }

    if (members.hasError && isGroupAccessLost(members.error!)) {
      return AppScaffold(
        header: const AppHeader.back(title: 'Nhóm'),
        body: StateMessage(
          key: const Key('groupAccessLost'),
          icon: Icons.group_off_outlined,
          title: 'Bạn không còn trong nhóm này',
          body: 'Quyền truy cập nhóm đã kết thúc. Lịch sử học cá nhân của bạn vẫn được giữ lại.',
          action: 'Về danh sách nhóm',
          onAction: () {
            ref.invalidate(myGroupsProvider);
            ref.invalidate(upcomingProvider);
            ref.invalidate(membersProvider(groupId));
            ref.invalidate(schedulesProvider(groupId));
            context.go('/groups');
          },
        ),
      );
    }
    return AppScaffold(
      header: isOwner ? const AppHeader.back(title: 'Chi tiết nhóm') : AppHeader.brand(
        caption: isOwner ? 'Chủ nhóm' : 'Thành viên',
        title: g?.name ?? 'Nhóm',
        leading: HeaderLeading.back,
      ),
      body: AsyncBody<GroupMembers>(
        value: members,
        onRetry: refresh,
        builder: (m) => PageList(
          onRefresh: refresh,
          children: [
            if (isOwner) ...[
              AppCard(
                key: const Key('ownerGroupSummary'),
                radius: DT.radiusLg,
                gap: DT.spaceMd,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 48, height: 48,
                      decoration: BoxDecoration(color: DT.accentSoftBg, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.groups_outlined, color: DT.accent, size: 26)),
                    const SizedBox(width: DT.spaceSm),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(g?.name ?? 'Nhóm', style: t.headlineMedium),
                      const SizedBox(height: DT.spaceXs),
                      Text('${m.memberCount}/10 thành viên', style: t.bodySmall!.copyWith(color: OwnerStyle.muted)),
                    ])),
                  ]),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    const StatusBadge('Chủ nhóm', tone: BadgeTone.accent),
                    StatusBadge(groupStatusText(g?.status ?? 'ACTIVE'),
                      tone: g?.status == null || g?.status == 'ACTIVE' ? BadgeTone.success : BadgeTone.danger),
                  ]),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      icon: Icons.qr_code_2,
                      label: 'Mã mời',
                      onPressed: () => context.push('/groups/$groupId/invite'),
                    ),
                  ),
                  const SizedBox(width: DT.spaceSm),
                  Expanded(
                    child: PrimaryButton(
                      compact: true,
                      icon: Icons.event,
                      label: 'Đặt lịch',
                      onPressed: () => context.push('/groups/$groupId/schedule'),
                    ),
                  ),
                ],
              ),
              _OwnerSessions(groupId: groupId),
              AppCard(
                radius: DT.radiusLg,
                onTap: () => context.push('/reports/$groupId'),
                children: const [
                  InfoRow(
                    icon: Icons.analytics_outlined,
                    title: 'Báo cáo nhóm',
                    subtitle: 'Xem kết quả theo tháng của nhóm này.',
                    trailing: Icon(Icons.chevron_right, color: DT.textSecondary),
                  ),
                ],
              ),
              if (m.belowMinimum)
                const AppBanner(tone: BannerTone.accent, text: 'Nhóm dưới 4 thành viên — nên mời thêm.'),
            ],
            AppCard(
              radius: isOwner ? DT.radiusLg : DT.radiusCard,
              gap: DT.spaceMd,
              children: [
                SectionHeader(
                  'Thành viên (${m.memberCount}/10)',
                  subtitle: isOwner ? 'Danh sách theo tên A–Z' : 'Sắp theo tên A→Z. Không hiện chuỗi, Coins hay trạng thái trực tuyến.',
                ),
                if (m.owner != null)
                  MemberTile(
                    name: m.owner!.displayName,
                    leading: memberAvatar(m.owner!, frames),
                    subtitle: 'Chủ nhóm',
                    trailing: StatusBadge('Chủ nhóm', tone: isOwner ? BadgeTone.accent : BadgeTone.dark),
                    onTap: () => context.push('/users/${m.owner!.userId}'),
                    divider: m.members.isNotEmpty,
                  ),
                if (m.members.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: DT.spaceSm),
                    child: Text('Chưa có thành viên nào.', style: t.bodyMedium!.copyWith(color: DT.textSecondary)),
                  ),
                for (var i = 0; i < m.members.length; i++)
                  MemberTile(
                    key: Key('member_${m.members[i].userId}'),
                    name: m.members[i].displayName,
                    leading: memberAvatar(m.members[i], frames),
                    divider: i < m.members.length - 1,
                    // V-32: chạm người → hồ sơ công khai (không có dữ liệu phiên)
                    onTap: () => context.push('/users/${m.members[i].userId}'),
                    trailing: isOwner
                        ? IconButton(
                            key: Key('remove_${m.members[i].userId}'),
                            tooltip: 'Xóa khỏi nhóm',
                            icon: const Icon(Icons.person_remove_outlined, color: DT.textSecondary),
                            onPressed: () => removeMemberFlow(context, ref, groupId, m.members[i], g?.name ?? 'nhóm'),
                          )
                        : null,
                  ),
              ],
            ),
            if (!isOwner)
              AppCard(
                onTap: () => context.push('/reports/$groupId'),
                children: const [
                  InfoRow(
                    icon: Icons.analytics_outlined,
                    title: 'Báo cáo của tôi',
                    subtitle: 'Dòng báo cáo tháng chủ nhóm thấy về bạn.',
                    trailing: Icon(Icons.chevron_right, color: DT.textSecondary),
                  ),
                ],
              ),
            if (!isOwner)
              SecondaryButton(
                label: 'Rút đồng ý và rời nhóm',
                destructive: true,
                onPressed: () => context.push('/leave-group/$groupId'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Avatar có khung đang trang bị (AC-07.04.1) — màu khung theo món Shop; không có/khung mặc định → viền đen.
Widget memberAvatar(PublicUser u, Map<String, String> frames, {double size = 40}) {
  final key = u.frameItemId == null ? null : frames[u.frameItemId];
  return FramedAvatar(
    name: u.displayName,
    imageUrl: u.avatarUrl == null ? null : fixHost(u.avatarUrl!),
    frameKey: key,
    frameColor: key == null || key.startsWith('default') ? null : previewColor(key),
    size: size,
  );
}

/// US-02.08 / BR-77: chủ nhóm xóa thành viên — ngoài phiên hiệu lực ngay; đang trong phiên → sau khi phiên kết thúc.
/// Only explicit membership denial means access ended; connection errors remain retryable.
bool isGroupAccessLost(Object error) {
  final a = ApiError.from(error);
  return !a.offline && a.code == 'FORBIDDEN_GROUP';
}

Future<void> removeMemberFlow(
  BuildContext context,
  WidgetRef ref,
  String groupId,
  PublicUser u,
  String groupName,
) async {
  final ok = await showConfirmDialog(
    context,
    title: 'Xóa ${u.displayName} khỏi $groupName?',
    bullets: const [
      'Người này nhận thông báo “Bạn không còn trong nhóm”.',
      'Nếu người này đang trong phiên, việc xóa có hiệu lực sau khi phiên kết thúc; kết quả phiên giữ nguyên.',
      'Số liệu đến ngày xóa vẫn nằm trong báo cáo tháng.',
    ],
    confirmLabel: 'Xóa khỏi nhóm',
    confirmKey: const Key('confirmRemove'),
  );
  if (!ok || !context.mounted) return;
  try {
    final now = await ref.read(apiProvider).removeMember(groupId, u.userId);
    ref.invalidate(membersProvider(groupId));
    ref.invalidate(myGroupsProvider);
    if (context.mounted) {
      showSnack(
        context,
        now
            ? 'Đã xóa ${u.displayName} khỏi nhóm.'
            : '${u.displayName} đang trong phiên — sẽ rời nhóm khi phiên kết thúc.',
      );
    }
  } catch (e) {
    final a = ApiError.from(e);
    final accessChanged = isGroupAccessLost(a) || a.code == 'NOT_GROUP_OWNER';
    if (accessChanged) {
      ref.invalidate(membersProvider(groupId));
      ref.invalidate(myGroupsProvider);
    }
    if (context.mounted) {
      showSnack(context, a.code == 'CANNOT_REMOVE_SELF'
          ? 'Không thể tự xóa mình. Dùng “Giải tán nhóm”.'
          : accessChanged ? 'Quyền quản lý nhóm đã thay đổi. Vui lòng tải lại nhóm.' : a.message);
    }
  }
}

class _OwnerSessions extends ConsumerWidget {
  const _OwnerSessions({required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(schedulesProvider(groupId));
    final t = context.text;
    return AppCard(
      radius: DT.radiusLg,
      gap: DT.spaceMd,
      children: [
        Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 20, color: DT.accent),
          const SizedBox(width: DT.spaceSm),
          Text('Lịch phiên', style: t.headlineSmall),
        ]),
        s.when(
          loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator()),
          error: (e, _) => Row(
            children: [
              Expanded(
                child: Text(
                  ApiError.from(e).offline ? 'Không có kết nối mạng.' : 'Chưa tải được lịch.',
                  style: t.bodyMedium!.copyWith(color: DT.textSecondary),
                ),
              ),
              LinkButton(label: 'Thử lại', onPressed: () => ref.invalidate(schedulesProvider(groupId))),
            ],
          ),
          data: (list) => list.isEmpty
              ? Text(
                  'Chưa có lịch. Bấm "Đặt lịch" để tạo phiên.',
                  style: t.bodyMedium!.copyWith(color: DT.textSecondary),
                )
              : Column(
                  children: [
                    for (var i = 0; i < list.length; i++)
                      ListRow(
                        title:
                            '${dayLabel(list[i].startedAt)} ${hhmm(list[i].startedAt)} · ${list[i].durationMin} phút',
                        subtitle: list[i].forfeited ? 'Có người thoát · cả phiên mất thưởng' : null,
                        divider: i < list.length - 1,
                        trailing: StatusBadge(sessionStatusText(list[i].status), tone: sessionStatusTone(list[i])),
                        onTap: () => context.push('/owner/sessions/${list[i].sessionId}'),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

String groupStatusText(String s) => switch (s) {
  'SCHEDULE_SUSPENDED' => 'Tạm ngưng lịch',
  'DISSOLVING' => 'Chờ giải tán',
  'DISSOLVED' => 'Đã giải tán',
  _ => 'Hoạt động',
};

String sessionStatusText(String s) => switch (s) {
  'SCHEDULED' => 'Đã lên lịch',
  'COUNTDOWN' => 'Sắp bắt đầu',
  'ACTIVE' => 'Đang diễn ra',
  'COMPLETED' => 'Đã kết thúc',
  'CANCELLED' => 'Đã hủy',
  _ => s,
};

BadgeTone sessionStatusTone(SessionSummary s) => switch (s.status) {
  'SCHEDULED' || 'COUNTDOWN' => BadgeTone.accent,
  'ACTIVE' => BadgeTone.dark,
  'COMPLETED' => s.forfeited ? BadgeTone.danger : BadgeTone.success,
  _ => BadgeTone.neutral,
};

/// V-43 Mời thành viên (mã mời).
class InviteScreen extends ConsumerWidget {
  const InviteScreen({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(inviteCodeProvider(groupId));
    final t = context.text;
    return AppScaffold(
      header: const AppHeader.back(title: 'Mời thành viên'),
      body: AsyncBody<String>(
        value: code,
        onRetry: () => ref.invalidate(inviteCodeProvider(groupId)),
        builder: (c) => PageList(
          children: [
            AppCard(
              padding: const EdgeInsets.all(DT.spaceLg),
              children: [
                Text(
                  'Mã mời của nhóm',
                  textAlign: TextAlign.center,
                  style: t.labelLarge!.copyWith(color: DT.textSecondary),
                ),
                SelectableText(
                  c,
                  key: const Key('inviteCode'),
                  textAlign: TextAlign.center,
                  style: t.headlineLarge!.copyWith(fontSize: 34, letterSpacing: 6, fontFeatures: DT.tabular),
                ),
                Text(
                  'Mã gồm 8 ký tự. Gửi cho thành viên qua kênh nội bộ.',
                  textAlign: TextAlign.center,
                  style: t.bodySmall,
                ),
              ],
            ),
            PrimaryButton(
              icon: Icons.copy,
              label: 'Chép mã',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: 'Tham gia nhóm trên DropIt! bằng mã: $c'));
                showSnack(context, 'Đã chép mã mời.');
              },
            ),
            SecondaryButton(
              icon: Icons.refresh,
              label: 'Đổi mã',
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: 'Đổi mã mời?',
                  message: 'Mã cũ hết hiệu lực ngay.',
                  confirmLabel: 'Đổi mã',
                );
                if (!ok) return;
                try {
                  await ref.read(apiProvider).rotateInviteCode(groupId);
                  ref.invalidate(inviteCodeProvider(groupId));
                } catch (e) {
                  if (context.mounted) showSnack(context, ApiError.from(e).message);
                }
              },
            ),
            const HintText('Người nhận mã đọc và đồng ý quy tắc trước khi vào nhóm. Nhóm tối đa 10 thành viên.'),
          ],
        ),
      ),
    );
  }
}

/// V-44 Đặt lịch một lần (25/50 phút). Mockup: `schedule_focus`.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key, required this.groupId});
  final String groupId;
  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int _dur = 25;
  late DateTime _date;
  late TimeOfDay _time;
  bool _busy = false;
  String? _err;

  // Lịch lặp (US-02.10b, BR-113): ngày trong tuần ISO 1 = Thứ Hai, ngày kết thúc ≤ 12 tuần.
  bool _repeat = false;
  final Set<int> _weekdays = {};
  late DateTime _endDate;
  static const _wdLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  void initState() {
    super.initState();
    final n = vn(DateTime.now().toUtc()).add(const Duration(minutes: 30));
    _date = DateTime(n.year, n.month, n.day);
    _time = TimeOfDay(hour: n.hour, minute: (n.minute ~/ 5) * 5);
    _endDate = _date.add(const Duration(days: 28));
    _weekdays.add(_date.weekday);
  }

  String _ymd(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

  /// Giờ đã chọn hiểu là giờ Việt Nam → UTC.
  DateTime get _startUtc =>
      DateTime.utc(_date.year, _date.month, _date.day, _time.hour, _time.minute).subtract(const Duration(hours: 7));

  Future<void> _submit() async {
    if (_startUtc.isBefore(DateTime.now().toUtc())) {
      setState(() => _err = 'Giờ bắt đầu phải ở tương lai.');
      return;
    }
    setState(() {
      _busy = true;
      _err = null;
    });
    if (_repeat && _weekdays.isEmpty) {
      setState(() {
        _busy = false;
        _err = 'Chọn ít nhất một ngày trong tuần.';
      });
      return;
    }
    if (_repeat && _endDate.isBefore(_date)) {
      setState(() {
        _busy = false;
        _err = 'Ngày kết thúc phải sau ngày bắt đầu.';
      });
      return;
    }
    try {
      if (_repeat) {
        await ref
            .read(apiProvider)
            .createRecurringSchedule(widget.groupId, _startUtc, _dur, (_weekdays.toList()..sort()), _ymd(_endDate));
      } else {
        await ref.read(apiProvider).createSchedule(widget.groupId, _startUtc, _dur);
      }
      ref.invalidate(schedulesProvider(widget.groupId));
      ref.invalidate(myGroupsProvider);
      if (mounted) {
        showSnack(context, 'Đã đặt lịch.');
        context.pop();
      }
    } catch (e) {
      final a = ApiError.from(e);
      setState(
        () => _err = switch (a.code) {
          'SCHEDULE_OVERLAP' => 'Trùng giờ với một phiên khác của nhóm.',
          'START_IN_PAST' => 'Giờ bắt đầu phải ở tương lai.',
          'DURATION_OUT_OF_RANGE' => 'Chỉ chọn 25 hoặc 50 phút.',
          'VALIDATION_FAILED' when _repeat => 'Lịch lặp tối đa 12 tuần. ${a.message}',
          _ => a.offline ? 'Không có kết nối. Chưa đặt lịch — thử lại.' : a.message,
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final g = ref.watch(myGroupsProvider).value?.where((x) => x.groupId == widget.groupId).firstOrNull;
    return AppScaffold(
      header: const AppHeader.back(title: 'Đặt lịch phiên', leading: HeaderLeading.close),
      footer: PrimaryButton(label: 'Lưu lịch', loading: _busy, onPressed: _submit),
      children: [
        Text('Dành cho chủ nhóm. Chủ nhóm không tham gia phiên.', style: t.bodySmall),
        AppCard(
          gap: DT.spaceMd,
          children: [
            if (g != null) InfoRow(icon: Icons.groups_outlined, title: g.name, subtitle: '${g.memberCount} thành viên'),
            InfoRow(
              icon: Icons.calendar_today_outlined,
              title: 'Ngày: ${two(_date.day)}/${two(_date.month)}/${_date.year}',
              subtitle: 'Chạm để đổi ngày',
              trailing: const Icon(Icons.edit_outlined, size: 18, color: DT.textSecondary),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (d != null) setState(() => _date = d);
              },
            ),
            InfoRow(
              icon: Icons.schedule,
              title: 'Giờ bắt đầu: ${two(_time.hour)}:${two(_time.minute)}',
              subtitle: 'Giờ Việt Nam. Thành viên nhận thông báo nhắc trước giờ phiên.',
              trailing: const Icon(Icons.edit_outlined, size: 18, color: DT.textSecondary),
              onTap: () async {
                final tm = await showTimePicker(context: context, initialTime: _time);
                if (tm != null) setState(() => _time = tm);
              },
            ),
          ],
        ),
        AppCard(
          children: [
            Text('Thời lượng', style: t.titleMedium),
            PillToggle<int>(
              big: true,
              value: _dur,
              onChanged: (v) => setState(() => _dur = v),
              options: const [
                PillOption(25, '25 phút', caption: '+10 Coins'),
                PillOption(50, '50 phút', caption: '+25 Coins'),
              ],
            ),
            Text('Coins cho mỗi thành viên khi cả phiên hoàn thành (không ai rời app).', style: t.bodySmall),
          ],
        ),
        AppCard(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lặp lại hằng tuần', style: t.titleMedium),
                      Text('Cùng giờ vào các ngày đã chọn, đến ngày kết thúc (tối đa 12 tuần).', style: t.bodySmall),
                    ],
                  ),
                ),
                Switch(key: const Key('repeatSwitch'), value: _repeat, onChanged: (v) => setState(() => _repeat = v)),
              ],
            ),
            if (_repeat) ...[
              const SizedBox(height: DT.spaceXs),
              Wrap(
                spacing: DT.spaceSm,
                runSpacing: DT.spaceSm,
                children: [
                  for (var i = 1; i <= 7; i++)
                    FilterChipPill(
                      key: Key('wd$i'),
                      label: _wdLabels[i - 1],
                      selected: _weekdays.contains(i),
                      onTap: () => setState(() => _weekdays.contains(i) ? _weekdays.remove(i) : _weekdays.add(i)),
                    ),
                ],
              ),
              InfoRow(
                icon: Icons.event_available_outlined,
                title: 'Kết thúc: ${two(_endDate.day)}/${two(_endDate.month)}/${_endDate.year}',
                subtitle: 'Chạm để đổi ngày kết thúc',
                trailing: const Icon(Icons.edit_outlined, size: 18, color: DT.textSecondary),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _endDate.isBefore(_date) ? _date : _endDate,
                    firstDate: _date,
                    lastDate: _date.add(const Duration(days: 84)),
                  );
                  if (d != null) setState(() => _endDate = d);
                },
              ),
              Text('Nếu một buổi trùng phiên khác, cả chuỗi không được tạo.', style: t.bodySmall),
            ],
          ],
        ),
        if (_err != null) AppBanner(tone: BannerTone.danger, text: _err!),
      ],
    );
  }
}

/// V-46 Chi tiết phiên cho chủ nhóm — chỉ đọc, kéo để làm mới, không Coins/chuỗi,
/// không thời gian thực (BR-116, BR-123, D-28). Mockup: `t_07_xem_lai_phien`, `alert_details`.
class OwnerSessionDetailScreen extends ConsumerWidget {
  const OwnerSessionDetailScreen({super.key, required this.sessionId});
  final String sessionId;

  static String finalStateText(String s) => switch (s) {
    'COMPLETED' => 'Hoàn thành',
    'EXITED' => 'Rời phiên',
    'LOST' => 'Mất kết nối',
    'ABSENT' => 'Vắng',
    'WITHDRAWN' => 'Rút đồng ý',
    'VOID' => 'Không tính',
    _ => s,
  };

  static BadgeTone finalStateTone(String s) => switch (s) {
    'COMPLETED' => BadgeTone.success,
    'EXITED' => BadgeTone.danger,
    _ => BadgeTone.neutral,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(ownerDetailProvider(sessionId));
    final t = context.text;
    Future<void> refresh() async {
      ref.invalidate(ownerDetailProvider(sessionId));
      await ref.read(ownerDetailProvider(sessionId).future).catchError((_) => SessionOwnerView.fromJson(const {}));
    }

    return AppScaffold(
      header: const AppHeader.brand(caption: 'Chủ nhóm', title: 'Chi tiết phiên', leading: HeaderLeading.back),
      body: AsyncBody<SessionOwnerView>(
        value: v,
        onRetry: refresh,
        builder: (d) {
          final done = d.members.where((m) => m['final_state'] == 'COMPLETED').length;
          return PageList(
            onRefresh: refresh,
            children: [
              AppCard(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${hhmm(d.startedAt)}–${hhmm(d.endsAt)}', style: t.headlineSmall),
                            Text(
                              '${ddmm(d.startedAt)} · ${sessionStatusText(d.status).toLowerCase()}',
                              style: t.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (d.forfeited)
                        const StatusBadge('Có người thoát', tone: BadgeTone.danger)
                      else if (d.status == 'COMPLETED')
                        const StatusBadge('Hoàn thành', tone: BadgeTone.success),
                    ],
                  ),
                  if (d.forfeited)
                    Text(
                      d.forfeitTrigger == null
                          ? 'Phiên đã mất thưởng tập thể.'
                          : 'Phiên đã mất thưởng tập thể do ${d.forfeitTrigger} rời phiên.',
                      style: t.bodyMedium,
                    ),
                  Text('Cập nhật lúc ${hhmmss(d.fetchedAt)} · kéo xuống để làm mới', style: t.bodySmall),
                  if (d.status == 'SCHEDULED')
                    SecondaryButton(
                      key: const Key('editSession'),
                      icon: Icons.edit_calendar_outlined,
                      label: 'Sửa / hủy lịch',
                      onPressed: () => context.push('/owner/sessions/$sessionId/edit'),
                    ),
                ],
              ),
              // AC-08.10.10: phiên đã hủy → chỉ hiện mốc hủy, không danh sách
              if (d.status == 'CANCELLED')
                AppBanner(
                  key: const Key('cancelledAt'),
                  text: d.cancelledAt == null ? 'Phiên đã hủy.' : 'Phiên đã hủy lúc ${hhmm(d.cancelledAt)}.',
                )
              else ...[
                // AC-08.10.4: đang diễn ra → chỉ sự kiện rời đã xác nhận, không thời gian thực
                if (d.status == 'ACTIVE' || d.status == 'COUNTDOWN')
                  const AppBanner(key: Key('activeNote'), text: 'Phiên đang diễn ra — kết quả có sau khi kết thúc.'),
                if (d.members.isNotEmpty)
                  StatRow(
                    children: [
                      StatTile(label: 'Hoàn thành', value: '$done/${d.members.length}'),
                      StatTile(label: 'Số người rời', value: '${d.exitEvents.length}'),
                    ],
                  ),
                AppCard(
                  children: [
                    SectionHeader(
                      'Rời phiên',
                      trailing: d.exitEvents.isEmpty
                          ? null
                          : LinkButton(
                              key: const Key('viewExplanations'),
                              label: 'Xem giải trình',
                              onPressed: () => context.push('/owner/sessions/$sessionId/explanations'),
                            ),
                    ),
                    if (d.exitEvents.isEmpty)
                      Text(
                        d.status == 'COMPLETED' ? 'Không có ai rời app.' : 'Chưa có ai rời phiên.',
                        key: const Key('noExits'),
                        style: t.bodyMedium!.copyWith(color: DT.textSecondary),
                      )
                    else
                      for (var i = 0; i < d.exitEvents.length; i++)
                        ListRow(
                          leading: const Icon(Icons.logout, color: DT.warning),
                          title: '${d.exitEvents[i]['display_name']}',
                          subtitle: 'Rời lúc ${hhmmss(DateTime.tryParse('${d.exitEvents[i]['server_ts']}'))}',
                          divider: i < d.exitEvents.length - 1,
                        ),
                  ],
                ),
                AppCard(
                  children: [
                    const SectionHeader('Kết quả thành viên'),
                    if (d.members.isEmpty)
                      Text('Kết quả có sau khi phiên kết thúc.', style: t.bodyMedium!.copyWith(color: DT.textSecondary))
                    else
                      for (var i = 0; i < d.members.length; i++)
                        MemberTile(
                          name: '${d.members[i]['display_name']}',
                          subtitle: [
                            if (d.members[i]['has_explanation'] == true) 'Có giải trình',
                            if (d.members[i]['appeal_status'] != null)
                              'Khiếu nại: ${appealStatusText('${d.members[i]['appeal_status']}').toLowerCase()}',
                          ].join(' · ').ifEmptyNull,
                          onTap: d.members[i]['final_state'] == 'EXITED'
                              ? () => context.push('/owner/sessions/$sessionId/explanations')
                              : null,
                          divider: i < d.members.length - 1,
                          trailing: d.members[i]['exempted'] == true
                              // AC-08.10.11: dòng giữ nguyên, thêm nhãn "Đã miễn trừ"
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    StatusBadge(
                                      finalStateText('${d.members[i]['final_state']}'),
                                      tone: finalStateTone('${d.members[i]['final_state']}'),
                                    ),
                                    const SizedBox(width: 4),
                                    const StatusBadge('Đã miễn trừ', tone: BadgeTone.success),
                                  ],
                                )
                              : StatusBadge(
                                  finalStateText('${d.members[i]['final_state']}'),
                                  tone: finalStateTone('${d.members[i]['final_state']}'),
                                ),
                        ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

extension on String {
  String? get ifEmptyNull => isEmpty ? null : this;
}
