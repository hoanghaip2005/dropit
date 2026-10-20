import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/env.dart';
import '../../app/theme.dart';
import '../../core/api.dart';
import '../../core/auth.dart';
import '../../core/widgets.dart';

/// V-01 Giới thiệu (splash + onboarding).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;

  static const _pages = [
    (Icons.groups_outlined, 'Tập trung cùng nhóm',
        'Chủ nhóm đặt lịch phiên 25 hoặc 50 phút. Mọi người vào phòng chờ và bắt đầu cùng lúc.'),
    (Icons.phonelink_lock_outlined, 'Ở lại trong app',
        'Rời app quá 3 giây là thoát phiên, cả nhóm biết tên bạn và phiên mất thưởng tập thể. Khóa màn hình không tính.'),
    (Icons.shield_outlined, 'Riêng tư',
        'DropIt! không đọc nội dung điện thoại, không biết bạn mở app nào. Chỉ ghi lúc phiên đang chạy.'),
  ];

  Future<void> _finish() async {
    await ref.read(authProvider.notifier).finishOnboarding();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pages.length - 1;
    final t = context.text;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DT.margin),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DT.spaceSm),
              child: Row(children: [
                const StatusBadge('DropIt!'),
                const Spacer(),
                if (!last) LinkButton(label: 'Bỏ qua', color: DT.textSecondary, onPressed: _finish),
              ]),
            ),
            Expanded(
              child: PageView(
                controller: _pc,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  for (final (icon, title, body) in _pages)
                    LayoutBuilder(
                      builder: (context, c) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: c.maxHeight),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            _Illustration(icon: icon),
                            const SizedBox(height: DT.spaceLg),
                            Text(title, style: t.displaySmall, textAlign: TextAlign.center),
                            const SizedBox(height: DT.spaceSm),
                            Text(body,
                                textAlign: TextAlign.center,
                                style: t.bodyLarge!.copyWith(color: DT.textSecondary)),
                          ]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: DT.spaceMd),
            PageDots(count: _pages.length, index: _page),
            const SizedBox(height: DT.spaceMd),
            PrimaryButton(
              label: last ? 'Bắt đầu' : 'Tiếp',
              trailingIcon: Icons.arrow_forward,
              onPressed: () async {
                if (!last) {
                  _pc.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                  return;
                }
                await _finish();
              },
            ),
            const SizedBox(height: DT.spaceLg),
          ]),
        ),
      ),
    );
  }
}

/// Minh họa onboarding: vòng tròn trắng nổi + 3 chip nổi (25:00, +10 Coins, Cùng nhóm) như mockup.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    Widget chip(IconData i, String s, {bool green = false}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: green ? DT.successSoftBg : DT.card,
            borderRadius: BorderRadius.circular(DT.pill),
            boxShadow: DT.cardShadow,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(i, size: 18, color: green ? DT.success : DT.accent),
            const SizedBox(width: 6),
            Text(s, style: context.text.labelLarge!.copyWith(color: green ? DT.success : DT.textPrimary)),
          ]),
        );
    return SizedBox(
      height: 280,
      width: 300,
      child: Stack(alignment: Alignment.center, children: [
        Container(
          width: 200,
          height: 200,
          decoration: const BoxDecoration(color: DT.card, shape: BoxShape.circle, boxShadow: DT.heroShadow),
          child: Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(color: DT.accentSoftBg, shape: BoxShape.circle),
              child: Icon(icon, size: 64, color: DT.accent),
            ),
          ),
        ),
        Positioned(top: 8, left: 8, child: chip(Icons.timer_outlined, '25:00')),
        Positioned(bottom: 16, left: 16, child: chip(Icons.monetization_on, '+10 Coins', green: true)),
        Positioned(top: 130, right: 0, child: chip(Icons.groups_outlined, 'Cùng nhóm')),
      ]),
    );
  }
}

final devUsersProvider = FutureProvider.autoDispose<List<DevUser>>((ref) => ref.watch(devAuthApiProvider).users());

/// V-02 Đăng nhập (bản dev: chọn người seed → POST /dev/token).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _custom = TextEditingController();
  String? _busy;
  String? _error;

  Future<void> _login(DevUser u) async {
    setState(() {
      _busy = u.id;
      _error = null;
    });
    try {
      final t = await ref.read(devAuthApiProvider).token(u);
      await ref.read(authProvider.notifier).setToken(t, u.label);
      if (mounted) context.go('/home');
    } catch (e) {
      final err = ApiError.from(e);
      setState(() => _error = err.offline
          ? 'Không kết nối được máy chủ ${Env.baseUrl}. Kiểm tra backend đã chạy chưa.'
          : 'Đăng nhập thất bại: ${err.message}');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(devUsersProvider);
    final t = context.text;
    return AppScaffold(
      header: const AppHeader.back(title: 'DropIt!'),
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Chào mừng trở lại', style: t.headlineLarge),
          Text('Đăng nhập để vào nhóm của bạn.', style: t.bodyMedium!.copyWith(color: DT.textSecondary)),
        ]),
        AppBanner(
          title: 'Bản phát triển',
          text: 'Chọn một tài khoản mẫu. Máy chủ: ${Env.baseUrl}',
          icon: Icons.developer_mode,
        ),
        if (_error != null) AppBanner(tone: BannerTone.danger, text: _error!),
        users.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          error: (e, _) => SizedBox(
              height: 320, child: ErrorState(error: e, onRetry: () => ref.invalidate(devUsersProvider))),
          data: (list) => AppCard(
            padding: const EdgeInsets.symmetric(horizontal: DT.spaceMd, vertical: DT.spaceXs),
            children: [
              for (var i = 0; i < list.length; i++)
                MemberTile(
                  name: list[i].label,
                  subtitle: list[i].email,
                  divider: i < list.length - 1,
                  onTap: _busy == null ? () => _login(list[i]) : null,
                  trailing: _busy == list[i].id
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.arrow_forward, size: 20, color: DT.textSecondary),
                ),
            ],
          ),
        ),
        PillTextField(
          controller: _custom,
          icon: Icons.mail_outline,
          hint: 'Email công việc hoặc mã người dùng',
          keyboardType: TextInputType.emailAddress,
        ),
        PrimaryButton(
          label: 'Đăng nhập',
          trailingIcon: Icons.arrow_forward,
          loading: _busy != null && !(users.value?.any((u) => u.id == _busy) ?? false),
          onPressed: _busy == null
              ? () {
                  final v = _custom.text.trim();
                  if (v.isEmpty) return;
                  _login(DevUser(v, v, email: v.contains('@') ? v : null));
                }
              : null,
        ),
      ],
    );
  }
}
