import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dropit/core/auth.dart';
import 'package:dropit/core/api.dart';
import 'package:dropit/core/models.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/features/auth/registration_screen.dart';

class RegistrationApi extends ProductionAuthApi {
  final calls = <String>[];
  Completer<void>? pending;
  bool codeFails = false;
  @override
  bool get configured => true;
  @override
  Future<void> signUp(String email, String password, String name) async {
    calls.add('$email|$name');
    if (pending != null) await pending!.future;
  }

  @override
  Future<void> confirmSignUp(String email, String code) async {
    calls.add('confirm');
    if (codeFails) throw const AuthFailure('Mã xác minh chưa đúng.');
  }

  @override
  Future<AuthSession> signIn(String email, String password) async {
    calls.add('signIn');
    return const AuthSession(accessToken: 'fixture', label: 'Demo');
  }

  @override
  Future<void> resendSignUpCode(String email) async => calls.add('resend');
}

class RegistrationController extends AuthController {
  @override
  AuthState build() => const AuthState(deviceId: 'fixture');
  @override
  Future<void> acceptSession(AuthSession session) async {}
}

class UnavailableProfileApi extends DropItApi {
  UnavailableProfileApi() : super(Dio());
  @override
  Future<MeProfile> updateMe(String name) async =>
      throw ApiError(message: 'Offline', offline: true);
}

Widget app(RegistrationApi api, {double scale = 1}) => ProviderScope(
  overrides: [
    productionAuthApiProvider.overrideWithValue(api),
    authProvider.overrideWith(RegistrationController.new),
    apiProvider.overrideWithValue(UnavailableProfileApi()),
  ],
  child: MaterialApp(
    theme: buildLightTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: const RegistrationScreen(),
  ),
);

void main() {
  Future<void> details(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Demo Name');
    await tester.enterText(fields.at(1), 'demo@example.org');
    await tester.enterText(fields.at(2), 'ExamplePass123!');
    await tester.enterText(fields.at(3), 'ExamplePass123!');
    await tester.ensureVisible(find.text('Tạo tài khoản'));
    await tester.tap(find.text('Tạo tài khoản'));
  }

  testWidgets('Verified profile retry does not confirm a used code twice', (
    tester,
  ) async {
    final api = RegistrationApi();
    await tester.pumpWidget(app(api));
    await details(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.ensureVisible(find.text('Xác minh và tiếp tục'));
    await tester.tap(find.text('Xác minh và tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.textContaining('chưa lưu được tên hồ sơ'), findsOneWidget);
    await tester.ensureVisible(find.text('Tiếp tục'));
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(api.calls.where((call) => call == 'confirm').length, 1);
    expect(api.calls.where((call) => call == 'signIn').length, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Control characters in display name block account creation', (
    tester,
  ) async {
    final api = RegistrationApi();
    await tester.pumpWidget(app(api));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Demo\u0001Name');
    await tester.enterText(fields.at(1), 'demo@example.org');
    await tester.enterText(fields.at(2), 'ExamplePass123!');
    await tester.enterText(fields.at(3), 'ExamplePass123!');
    await tester.ensureVisible(find.text('Tạo tài khoản'));
    await tester.tap(find.text('Tạo tài khoản'));
    await tester.pumpAndSettle();
    expect(api.calls, isEmpty);
    expect(find.textContaining('không có ký tự điều khiển'), findsOneWidget);
  });

  testWidgets('Wrong verification code never signs in', (tester) async {
    final api = RegistrationApi()..codeFails = true;
    await tester.pumpWidget(app(api));
    await details(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.ensureVisible(find.text('Xác minh và tiếp tục'));
    await tester.tap(find.text('Xác minh và tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.text('Mã xác minh chưa đúng.'), findsOneWidget);
    expect(api.calls.contains('signIn'), false);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Disposed pending sign-up never updates widget', (tester) async {
    final api = RegistrationApi()..pending = Completer<void>();
    await tester.pumpWidget(app(api));
    await details(tester);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    api.pending!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Registration fits narrow screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(RegistrationApi(), scale: 1.5));
    await tester.ensureVisible(find.text('Tạo tài khoản'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Valid registration opens verification without granting role', (
    tester,
  ) async {
    final api = RegistrationApi();
    await tester.pumpWidget(app(api));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), ' Demo Name ');
    await tester.enterText(fields.at(1), ' demo@example.org ');
    await tester.enterText(fields.at(2), 'ExamplePass123!');
    await tester.enterText(fields.at(3), 'ExamplePass123!');
    await tester.ensureVisible(find.text('Tạo tài khoản'));
    await tester.tap(find.text('Tạo tài khoản'));
    await tester.pumpAndSettle();
    expect(api.calls, ['demo@example.org|Demo Name']);
    expect(find.text('Xác minh email'), findsOneWidget);
    expect(find.text('Mã xác minh'), findsOneWidget);
    expect(find.text('Gửi lại mã sau 60s'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Password mismatch blocks registration', (tester) async {
    final api = RegistrationApi();
    await tester.pumpWidget(app(api));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Demo');
    await tester.enterText(fields.at(1), 'demo@example.org');
    await tester.enterText(fields.at(2), 'ExamplePass123!');
    await tester.enterText(fields.at(3), 'DifferentPass123!');
    await tester.ensureVisible(find.text('Tạo tài khoản'));
    await tester.tap(find.text('Tạo tài khoản'));
    await tester.pumpAndSettle();
    expect(api.calls, isEmpty);
    expect(find.text('Mật khẩu nhập lại chưa khớp.'), findsOneWidget);
  });
}
