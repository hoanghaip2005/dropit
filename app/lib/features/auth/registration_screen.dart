import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/api.dart';
import '../../core/auth.dart';

/// Registration intent selects the next screen, never grants a server role.
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  final _code = TextEditingController();
  bool _owner = false;
  bool _verify = false;
  bool _confirmed = false;
  bool _busy = false;
  bool _obscured = true;
  int _resendSeconds = 0;
  Timer? _resendTimer;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final controller in [_name, _email, _password, _repeat, _code]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _cooldown() {
    _resendTimer?.cancel();
    _resendSeconds = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) timer.cancel();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await action();
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on ApiError catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Tài khoản đã xác minh nhưng chưa lưu được tên hồ sơ. Bấm tiếp tục để thử lại.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Chưa hoàn tất được. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _register() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    await _run(() async {
      await ref
          .read(productionAuthApiProvider)
          .signUp(_email.text.trim(), _password.text, _name.text.trim());
      if (!mounted) return;
      setState(() {
        _verify = true;
        _notice = 'Mã xác minh đã gửi tới email của bạn. Kiểm tra cả thư rác.';
        _cooldown();
      });
    });
  }

  Future<void> _confirm() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    await _run(() async {
      final api = ref.read(productionAuthApiProvider);
      if (!_confirmed) {
        await api.confirmSignUp(_email.text.trim(), _code.text.trim());
        if (!mounted) return;
        setState(() => _confirmed = true);
      }
      final session = await api.signIn(_email.text.trim(), _password.text);
      if (!mounted) return;
      await ref.read(authProvider.notifier).acceptSession(session);
      if (!mounted) return;
      await ref.read(apiProvider).updateMe(_name.text.trim());
      if (mounted) context.go(_owner ? '/groups/new' : '/join');
    });
  }

  Future<void> _resend() => _run(() async {
    await ref
        .read(productionAuthApiProvider)
        .resendSignUpCode(_email.text.trim());
    if (!mounted) return;
    setState(() {
      _notice = 'Đã gửi lại mã xác minh. Kiểm tra email và thư rác.';
      _cooldown();
    });
  });

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
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

  Widget _intent(bool owner, String title, String subtitle, IconData icon) {
    final selected = _owner == owner;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? DT.accentSoftBg : OwnerStyle.inset,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _busy ? null : () => setState(() => _owner = owner),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? OwnerStyle.primary : OwnerStyle.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.text.titleSmall!.copyWith(
                          color: OwnerStyle.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: context.text.bodySmall!.copyWith(
                          color: OwnerStyle.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? OwnerStyle.primary : OwnerStyle.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(productionAuthApiProvider).configured;
    final enabled = configured && !_busy;
    final t = context.text.apply(
      bodyColor: OwnerStyle.ink,
      displayColor: OwnerStyle.ink,
    );
    return Scaffold(
      backgroundColor: OwnerStyle.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: _busy ? null : () => context.go('/login'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Đăng nhập'),
                  ),
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/brand/logo-horizontal-light.png',
                    height: 48,
                    semanticLabel: 'DropIt!',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _verify ? 'Xác minh email' : 'Bắt đầu cùng DropIt!',
                    style: t.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _verify
                        ? 'Nhập mã gửi tới ${_email.text.trim()}.'
                        : 'Một tài khoản để tập trung cá nhân và học cùng nhóm.',
                    style: t.bodyLarge!.copyWith(color: OwnerStyle.muted),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Form(
                      key: _form,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!configured) ...[
                              const Text(
                                'Đăng ký hiện chưa sẵn sàng. Vui lòng thử lại sau.',
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (!_verify) ...[
                              TextFormField(
                                controller: _name,
                                enabled: enabled,
                                decoration: _decoration(
                                  'Tên hiển thị',
                                  Icons.person_outline,
                                ),
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.name],
                                maxLength: 30,
                                validator: (value) {
                                  final name = value?.trim() ?? '';
                                  return name.length < 2 ||
                                          name.length > 30 ||
                                          RegExp(
                                            r'[\u0000-\u001f\u007f]',
                                          ).hasMatch(name)
                                      ? 'Tên cần từ 2 đến 30 ký tự, không có ký tự điều khiển.'
                                      : null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _email,
                                enabled: enabled,
                                decoration: _decoration(
                                  'Email',
                                  Icons.mail_outline,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                autocorrect: false,
                                enableSuggestions: false,
                                textInputAction: TextInputAction.next,
                                validator: (value) =>
                                    !RegExp(
                                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                    ).hasMatch(value?.trim() ?? '')
                                    ? 'Nhập email hợp lệ.'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _password,
                                enabled: enabled,
                                obscureText: _obscured,
                                autocorrect: false,
                                enableSuggestions: false,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                textInputAction: TextInputAction.next,
                                decoration:
                                    _decoration(
                                      'Mật khẩu',
                                      Icons.lock_outline,
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        onPressed: enabled
                                            ? () => setState(
                                                () => _obscured = !_obscured,
                                              )
                                            : null,
                                        tooltip: _obscured
                                            ? 'Hiện mật khẩu'
                                            : 'Ẩn mật khẩu',
                                        icon: Icon(
                                          _obscured
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                validator: (value) {
                                  final p = value ?? '';
                                  return p.length < 12 ||
                                          p.length > 256 ||
                                          !RegExp('[a-z]').hasMatch(p) ||
                                          !RegExp('[A-Z]').hasMatch(p) ||
                                          !RegExp('[0-9]').hasMatch(p) ||
                                          !RegExp(r'[^a-zA-Z0-9\s]').hasMatch(p)
                                      ? 'Cần ít nhất 12 ký tự, gồm chữ hoa, chữ thường, số và ký tự đặc biệt.'
                                      : null;
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ít nhất 12 ký tự: chữ hoa, chữ thường, số và ký tự đặc biệt.',
                                style: t.bodySmall!.copyWith(
                                  color: OwnerStyle.muted,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _repeat,
                                enabled: enabled,
                                obscureText: _obscured,
                                autocorrect: false,
                                enableSuggestions: false,
                                decoration: _decoration(
                                  'Nhập lại mật khẩu',
                                  Icons.lock_outline,
                                ),
                                textInputAction: TextInputAction.done,
                                validator: (value) => value != _password.text
                                    ? 'Mật khẩu nhập lại chưa khớp.'
                                    : null,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Bạn muốn bắt đầu thế nào?',
                                style: t.titleMedium,
                              ),
                              const SizedBox(height: 10),
                              _intent(
                                true,
                                'Tạo nhóm học',
                                'Tạo nhóm và quản lý lịch học của nhóm.',
                                Icons.groups_outlined,
                              ),
                              const SizedBox(height: 10),
                              _intent(
                                false,
                                'Tham gia nhóm học',
                                'Nhập mã mời từ chủ nhóm.',
                                Icons.group_add_outlined,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Bạn có thể tạo hoặc tham gia nhóm sau. Quyền chủ nhóm chỉ áp dụng cho nhóm bạn tạo.',
                                style: t.bodySmall!.copyWith(
                                  color: OwnerStyle.muted,
                                ),
                              ),
                            ] else if (!_confirmed) ...[
                              TextFormField(
                                controller: _code,
                                enabled: enabled,
                                decoration: _decoration(
                                  'Mã xác minh',
                                  Icons.mark_email_read_outlined,
                                ),
                                keyboardType: TextInputType.number,
                                autofillHints: const [
                                  AutofillHints.oneTimeCode,
                                ],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _confirm(),
                                validator: (value) =>
                                    RegExp(
                                      r'^\d{6}$',
                                    ).hasMatch(value?.trim() ?? '')
                                    ? null
                                    : 'Nhập mã gồm 6 chữ số.',
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: enabled && _resendSeconds == 0
                                    ? _resend
                                    : null,
                                child: Text(
                                  _resendSeconds > 0
                                      ? 'Gửi lại mã sau ${_resendSeconds}s'
                                      : 'Gửi lại mã xác minh',
                                ),
                              ),
                            ] else ...[
                              const Icon(
                                Icons.mark_email_read_outlined,
                                size: 40,
                                color: OwnerStyle.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Email đã xác minh. Tiếp tục để hoàn tất hồ sơ.',
                                style: t.bodyMedium,
                              ),
                            ],
                            if (_notice != null) ...[
                              const SizedBox(height: 16),
                              Semantics(
                                liveRegion: true,
                                child: Text(_notice!, style: t.bodyMedium),
                              ),
                            ],
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  _error!,
                                  style: t.bodyMedium!.copyWith(
                                    color: DT.warning,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: OwnerStyle.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(56),
                                padding: const EdgeInsets.all(16),
                              ),
                              onPressed: enabled
                                  ? (_verify ? _confirm : _register)
                                  : null,
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 10,
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
                                    _busy
                                        ? 'Đang xử lý…'
                                        : _verify
                                        ? (_confirmed
                                              ? 'Tiếp tục'
                                              : 'Xác minh và tiếp tục')
                                        : 'Tạo tài khoản',
                                  ),
                                ],
                              ),
                            ),
                            if (!_verify)
                              TextButton(
                                onPressed: enabled
                                    ? () {
                                        if (!(_form.currentState?.validate() ??
                                            false)) {
                                          return;
                                        }
                                        setState(() {
                                          _verify = true;
                                          _error = null;
                                          _notice =
                                              'Nhập mã bạn đã nhận. Có thể bấm gửi lại mã nếu cần.';
                                        });
                                      }
                                    : null,
                                child: const Text(
                                  'Đã đăng ký và có mã xác minh?',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
