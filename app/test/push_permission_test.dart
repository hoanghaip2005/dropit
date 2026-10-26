import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dropit/core/api.dart';
import 'package:dropit/core/auth.dart';
import 'package:dropit/core/models.dart';
import 'package:dropit/core/providers.dart';
import 'package:dropit/core/push.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/features/profile/profile_screens.dart';

class PermissionClient implements PushClient {
  PermissionClient({this.available = true});
  @override
  final bool available;
  final requests = <bool>[];
  @override
  Future<AuthorizationStatus> permission({bool request = false}) async {
    requests.add(request);
    return AuthorizationStatus.denied;
  }

  @override
  Future<String?> token() async => null;
  @override
  Stream<String> get tokenChanges => const Stream.empty();
  @override
  Stream<RemoteMessage> get messages => const Stream.empty();
  @override
  Stream<RemoteMessage> get opened => const Stream.empty();
  @override
  Future<RemoteMessage?> initial() async => null;
}

class PermissionAuth extends AuthController {
  @override
  AuthState build() =>
      const AuthState(token: 'fixture-session', deviceId: 'fixture-device');
}

class DeniedController extends PushController {
  @override
  PushState build() => const PushState(status: AuthorizationStatus.denied);
}

class PermissionApi extends DropItApi {
  PermissionApi() : super(Dio());
  @override
  Future<void> removePushDevice(String deviceId) async {}
}

Widget screen(
  PermissionClient client, {
  bool failedInbox = false,
  bool denied = false,
  double scale = 1,
}) => ProviderScope(
  retry: (_, _) => null,
  overrides: [
    pushClientProvider.overrideWithValue(client),
    authProvider.overrideWith(PermissionAuth.new),
    apiProvider.overrideWithValue(PermissionApi()),
    if (denied) pushControllerProvider.overrideWith(DeniedController.new),
    notificationsProvider.overrideWith((_) async {
      if (failedInbox) throw ApiError(message: 'Inbox fixture unavailable');
      return (unread: 0, items: <AppNotification>[]);
    }),
  ],
  child: MaterialApp(
    theme: buildLightTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: const NotificationsScreen(),
  ),
);

void main() {
  testWidgets(
    'Unavailable push never requests permission; empty inbox remains usable',
    (tester) async {
      final client = PermissionClient(available: false);
      await tester.pumpWidget(screen(client));
      await tester.pumpAndSettle();
      expect(find.byType(PushPermissionCard), findsOneWidget);
      expect(find.text('Chưa có thông báo'), findsOneWidget);
      expect(find.text('Bật thông báo'), findsNothing);
      expect(client.requests, isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
  testWidgets(
    'Inbox error does not hide optional permission card or prompt automatically',
    (tester) async {
      final client = PermissionClient();
      await tester.pumpWidget(screen(client, failedInbox: true));
      await tester.pumpAndSettle();
      expect(find.text('Thông báo trên thiết bị'), findsOneWidget);
      expect(find.text('Bật thông báo'), findsOneWidget);
      expect(client.requests, isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
  testWidgets(
    'Denied check reads status without requesting permission again',
    (tester) async {
      final client = PermissionClient();
      await tester.pumpWidget(screen(client, denied: true));
      await tester.pumpAndSettle();
      expect(find.text('Bật thông báo'), findsNothing);
      await tester.tap(find.text('Kiểm tra lại'));
      await tester.pumpAndSettle();
      expect(client.requests, [false]);
      expect(find.text('Chưa có thông báo'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
  testWidgets(
    'Permission copy and inbox fit 320 with text1.5',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        screen(PermissionClient(), denied: true, scale: 1.5),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Chưa có thông báo'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
