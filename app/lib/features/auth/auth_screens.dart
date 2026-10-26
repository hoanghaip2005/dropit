import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
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
    (
      Icons.groups_outlined,
      'Tập trung cùng nhóm',
      'Chủ nhóm đặt lịch phiên 25 hoặc 50 phút. Mọi người vào phòng chờ và bắt đầu cùng lúc.',
    ),
    (
      Icons.phonelink_lock_outlined,
      'Ở lại trong app',
      'Rời app quá 3 giây là thoát phiên, cả nhóm biết tên bạn và phiên mất thưởng tập thể. Khóa màn hình không tính.',
    ),
    (
      Icons.shield_outlined,
      'Riêng tư',
      'DropIt! không đọc nội dung điện thoại, không biết bạn mở app nào. Chỉ ghi lúc phiên đang chạy.',
    ),
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: DT.spaceSm),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset('assets/brand/icon.png', width: 32, height: 32),
                    ),
                    const SizedBox(width: DT.spaceSm),
                    Text('DropIt!', style: t.titleLarge),
                    const Spacer(),
                    if (!last) LinkButton(label: 'Bỏ qua', color: DT.textSecondary, onPressed: _finish),
                  ],
                ),
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (icon == Icons.groups_outlined)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(DT.radiusLg),
                                    child: Image.asset(
                                      'assets/mockup/onboarding.png',
                                      height: 260,
                                      width: 300,
                                      fit: BoxFit.contain,
                                      semanticLabel: 'Minh họa tập trung cùng nhóm',
                                    ),
                                  )
                                else
                                  _Illustration(icon: icon),
                                const SizedBox(height: DT.spaceLg),
                                Text(title, style: t.displaySmall, textAlign: TextAlign.center),
                                const SizedBox(height: DT.spaceSm),
                                Text(
                                  body,
                                  textAlign: TextAlign.center,
                                  style: t.bodyLarge!.copyWith(color: DT.textSecondary),
                                ),
                              ],
                            ),
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
            ],
          ),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(i, size: 18, color: green ? DT.success : DT.accent),
          const SizedBox(width: 6),
          Text(s, style: context.text.labelLarge!.copyWith(color: green ? DT.success : DT.textPrimary)),
        ],
      ),
    );
    return SizedBox(
      height: 280,
      width: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
        ],
      ),
    );
  }
}

/// V-02 Đăng nhập bằng tài khoản thật.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscured = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    final api = ref.read(productionAuthApiProvider);
    if (!api.configured) return;
    final controller = ref.read(authProvider.notifier);
    final email = _email.text.trim();
    final password = _password.text;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await api.signIn(email, password);
      if (!mounted) return;
      await controller.acceptSession(session);
      if (mounted) context.go('/home');
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Chưa đăng nhập được. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(productionAuthApiProvider).configured;
    final t = context.text.apply(
      bodyColor: OwnerStyle.ink,
      displayColor: OwnerStyle.ink,
    );
    InputDecoration decoration(String label, IconData icon) => InputDecoration(
      labelText: label,
      errorMaxLines: 3,
      prefixIcon: Icon(icon, color: OwnerStyle.muted),
      filled: true,
      fillColor: OwnerStyle.inset,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: OwnerStyle.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
    return Scaffold(
      backgroundColor: OwnerStyle.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 32).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/brand/logo-horizontal-light.png',
                        height: 56,
                        semanticLabel: 'DropIt!',
                      ),
                      const SizedBox(height: 32),
                      Text('Chào mừng trở lại', style: t.headlineLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Đăng nhập để vào nhóm của bạn.',
                        style: t.bodyLarge!.copyWith(color: OwnerStyle.muted),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: AutofillGroup(
                          child: Form(
                            key: _form,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (!configured) ...[
                                  Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      'Đăng nhập hiện chưa sẵn sàng. Vui lòng thử lại sau.',
                                      key: const Key('loginNotConfigured'),
                                      style: t.bodyMedium,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                TextFormField(
                                  key: const Key('loginEmail'),
                                  controller: _email,
                                  enabled: configured && !_busy,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [
                                    AutofillHints.username,
                                    AutofillHints.email,
                                  ],
                                  textInputAction: TextInputAction.next,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  decoration: decoration(
                                    'Email',
                                    Icons.mail_outline,
                                  ),
                                  validator: (value) {
                                    final email = value?.trim() ?? '';
                                    if (email.isEmpty) {
                                      return 'Nhập email của bạn.';
                                    }
                                    if (!RegExp(
                                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                    ).hasMatch(email)) {
                                      return 'Email chưa đúng định dạng.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  key: const Key('loginPassword'),
                                  controller: _password,
                                  enabled: configured && !_busy,
                                  obscureText: _obscured,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  autofillHints: const [AutofillHints.password],
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration:
                                      decoration(
                                        'Mật khẩu',
                                        Icons.lock_outline,
                                      ).copyWith(
                                        suffixIcon: IconButton(
                                          tooltip: _obscured
                                              ? 'Hiện mật khẩu'
                                              : 'Ẩn mật khẩu',
                                          constraints: const BoxConstraints(
                                            minWidth: 48,
                                            minHeight: 48,
                                          ),
                                          onPressed: configured && !_busy
                                              ? () => setState(
                                                  () => _obscured = !_obscured,
                                                )
                                              : null,
                                          icon: Icon(
                                            _obscured
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                        ),
                                      ),
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                      ? 'Nhập mật khẩu của bạn.'
                                      : null,
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 16),
                                  Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      _error!,
                                      key: const Key('loginError'),
                                      style: t.bodyMedium!.copyWith(
                                        color: DT.warning,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                FilledButton(
                                  key: const Key('loginSubmit'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: OwnerStyle.primary,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(56),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  onPressed: configured && !_busy
                                      ? _submit
                                      : null,
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      if (_busy)
                                        const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                      Text(
                                        _busy ? 'Đang đăng nhập…' : 'Đăng nhập',
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
