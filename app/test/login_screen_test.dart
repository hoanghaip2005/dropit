import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dropit/core/auth.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/features/auth/auth_screens.dart';

class LoginApi extends ProductionAuthApi {
  bool ready = true;
  Object? error;
  Completer<AuthSession>? pending;
  final calls = <({String email, String password})>[];
  @override
  bool get configured => ready;
  @override
  Future<AuthSession> signIn(String email, String password) async {
    calls.add((email: email, password: password));
    if (pending != null) return pending!.future;
    if (error != null) throw error!;
    return const AuthSession(accessToken: 'fixture-session', label: 'Fixture');
  }
}

class LoginController extends AuthController {
  final accepted = <AuthSession>[];
  Completer<void>? pending;
  @override
  AuthState build() => const AuthState(deviceId: 'fixture-device');
  @override
  Future<void> acceptSession(AuthSession session) async {
    accepted.add(session);
    if (pending != null) await pending!.future;
  }
}

Widget loginApp(
  LoginApi api,
  LoginController controller, {
  GoRouter? router,
  double scale = 1,
}) {
  Widget builder(BuildContext context, Widget? child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  );
  return ProviderScope(
    overrides: [
      productionAuthApiProvider.overrideWithValue(api),
      authProvider.overrideWith(() => controller),
    ],
    child: router == null
        ? MaterialApp(
            theme: buildLightTheme(),
            builder: builder,
            home: const LoginScreen(),
          )
        : MaterialApp.router(
            theme: buildLightTheme(),
            builder: builder,
            routerConfig: router,
          ),
  );
}

Future<void> enter(
  WidgetTester tester, {
  String email = 'test@example.org',
  String password = ' fixture password ',
}) async {
  await tester.enterText(find.byKey(const Key('loginEmail')), email);
  await tester.enterText(find.byKey(const Key('loginPassword')), password);
  await tester.ensureVisible(find.byKey(const Key('loginSubmit')));
}

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('Login form fits $width with text1.5 and keyboard inset', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, width == 320 ? 740 : 1024);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        loginApp(LoginApi(), LoginController(), scale: 1.5),
      );
      await enter(tester, email: 'invalid', password: '');
      await tester.tap(find.byKey(const Key('loginSubmit')));
      await tester.pumpAndSettle();
      expect(find.text('Email chưa đúng định dạng.'), findsOneWidget);
      expect(find.text('Nhập mật khẩu của bạn.'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('loginSubmit')));
      expect(
        tester.getSize(find.byKey(const Key('loginSubmit'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'Production UI has no seed picker, developer banner or backend address',
    (tester) async {
      await tester.pumpWidget(loginApp(LoginApi(), LoginController()));
      expect(find.text('Bản phát triển'), findsNothing);
      expect(find.textContaining('dropit.dev'), findsNothing);
      expect(find.textContaining('Máy chủ:'), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(2));
    },
  );
  testWidgets('Configuration missing disables form, never invokes auth', (
    tester,
  ) async {
    final api = LoginApi()..ready = false;
    await tester.pumpWidget(loginApp(api, LoginController()));
    expect(find.byKey(const Key('loginNotConfigured')), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byKey(const Key('loginEmail'))).enabled,
      false,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('loginSubmit')))
          .onPressed,
      isNull,
    );
    expect(api.calls, isEmpty);
  });
  testWidgets('Validation blocks empty/invalid email without calling API', (
    tester,
  ) async {
    final api = LoginApi();
    await tester.pumpWidget(loginApp(api, LoginController()));
    await tester.tap(find.byKey(const Key('loginSubmit')));
    await tester.pumpAndSettle();
    expect(find.text('Nhập email của bạn.'), findsOneWidget);
    expect(find.text('Nhập mật khẩu của bạn.'), findsOneWidget);
    await enter(tester, email: 'not-email');
    await tester.tap(find.byKey(const Key('loginSubmit')));
    await tester.pumpAndSettle();
    expect(api.calls, isEmpty);
  });
  testWidgets('Password toggle changes obscuring and accessibility label', (
    tester,
  ) async {
    await tester.pumpWidget(loginApp(LoginApi(), LoginController()));
    TextField password() => tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('loginPassword')),
        matching: find.byType(TextField),
      ),
    );
    expect(password().obscureText, true);
    await tester.tap(find.byTooltip('Hiện mật khẩu'));
    await tester.pump();
    expect(password().obscureText, false);
    expect(find.byTooltip('Ẩn mật khẩu'), findsOneWidget);
  });
  testWidgets(
    'Submit trims email only, keeps password exact, serializes API and session before navigating',
    (tester) async {
      final api = LoginApi()..pending = Completer<AuthSession>();
      final controller = LoginController()..pending = Completer<void>();
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('Home fixture')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(loginApp(api, controller, router: router));
      await enter(tester, email: ' test@example.org ');
      await tester.tap(find.byKey(const Key('loginSubmit')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('loginSubmit')));
      await tester.pump();
      expect(api.calls, hasLength(1));
      expect(api.calls.single.email, 'test@example.org');
      expect(api.calls.single.password, ' fixture password ');
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('loginEmail')))
            .enabled,
        false,
      );
      api.pending!.complete(
        const AuthSession(accessToken: 'fixture-session', label: 'Fixture'),
      );
      await tester.pump();
      expect(controller.accepted, hasLength(1));
      expect(find.text('Home fixture'), findsNothing);
      controller.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Home fixture'), findsOneWidget);
    },
  );
  testWidgets(
    'Enter submits once; known auth failures remain safe and permit retry',
    (tester) async {
      final api = LoginApi()
        ..error = const AuthFailure('Email hoặc mật khẩu chưa đúng.');
      final controller = LoginController();
      await tester.pumpWidget(loginApp(api, controller));
      await enter(tester);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(api.calls, hasLength(1));
      expect(controller.accepted, isEmpty);
      expect(find.text('Email hoặc mật khẩu chưa đúng.'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('loginSubmit')))
            .onPressed,
        isNotNull,
      );
    },
  );
  for (final message in [
    'Không kết nối được dịch vụ đăng nhập. Vui lòng thử lại.',
    'Bạn thử quá nhiều lần. Vui lòng chờ rồi thử lại.',
    'Tài khoản cần hoàn tất bước xác thực bổ sung. Vui lòng liên hệ quản trị viên.',
  ]) {
    testWidgets(
      'Service response is visible without accepting session: $message',
      (tester) async {
        final api = LoginApi()..error = AuthFailure(message);
        final controller = LoginController();
        await tester.pumpWidget(loginApp(api, controller));
        await enter(tester);
        await tester.tap(find.byKey(const Key('loginSubmit')));
        await tester.pumpAndSettle();
        expect(find.text(message), findsOneWidget);
        expect(controller.accepted, isEmpty);
      },
    );
  }
  testWidgets('Unexpected error never exposes raw data', (tester) async {
    final api = LoginApi()..error = Exception('raw confidential fixture');
    await tester.pumpWidget(loginApp(api, LoginController()));
    await enter(tester);
    await tester.tap(find.byKey(const Key('loginSubmit')));
    await tester.pumpAndSettle();
    expect(find.textContaining('raw confidential'), findsNothing);
    expect(find.text('Chưa đăng nhập được. Vui lòng thử lại.'), findsOneWidget);
  });
  testWidgets(
    'Disposed pending sign-in never accepts a session or updates UI',
    (tester) async {
      final api = LoginApi()..pending = Completer<AuthSession>();
      final controller = LoginController();
      await tester.pumpWidget(loginApp(api, controller));
      await enter(tester);
      await tester.tap(find.byKey(const Key('loginSubmit')));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      api.pending!.complete(
        const AuthSession(accessToken: 'fixture-session', label: 'Fixture'),
      );
      await tester.pumpAndSettle();
      expect(controller.accepted, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Disposed pending session persistence never navigates afterward',
    (tester) async {
      final api = LoginApi();
      final controller = LoginController()..pending = Completer<void>();
      await tester.pumpWidget(loginApp(api, controller));
      await enter(tester);
      await tester.tap(find.byKey(const Key('loginSubmit')));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      controller.pending!.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
