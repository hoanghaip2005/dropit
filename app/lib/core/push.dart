import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../app/env.dart';
import 'api.dart';
import 'auth.dart';
import 'providers.dart';

final pushMessengerKey = GlobalKey<ScaffoldMessengerState>();

const pushEnabled = bool.fromEnvironment('PUSH_ENABLED');

FirebaseOptions? get pushFirebaseOptions {
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  if ([apiKey, appId, senderId, projectId].any((value) => value.isEmpty)) {
    return null;
  }
  return const FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: senderId,
    projectId: projectId,
    iosBundleId: String.fromEnvironment(
      'FIREBASE_IOS_BUNDLE_ID',
      defaultValue: 'com.bakhi.dropit.dropit',
    ),
  );
}

@pragma('vm:entry-point')
Future<void> pushBackgroundHandler(RemoteMessage message) async {
  // Notification payload is displayed by the OS. Never navigate or expose data here.
  await Firebase.initializeApp(options: pushFirebaseOptions);
}

bool get mobilePushSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

abstract class PushClient {
  bool get available;
  Future<AuthorizationStatus> permission({bool request = false});
  Future<String?> token();
  Stream<String> get tokenChanges;
  Stream<RemoteMessage> get messages;
  Stream<RemoteMessage> get opened;
  Future<RemoteMessage?> initial();
}

class FirebasePushClient implements PushClient {
  FirebasePushClient(this.available);
  @override
  final bool available;
  FirebaseMessaging get _f => FirebaseMessaging.instance;
  @override
  Future<AuthorizationStatus> permission({bool request = false}) async =>
      (request
              ? await _f.requestPermission(
                  alert: true,
                  badge: true,
                  sound: true,
                )
              : await _f.getNotificationSettings())
          .authorizationStatus;
  @override
  Future<String?> token() async {
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        await _f.getAPNSToken() == null) {
      return null;
    }
    return _f.getToken();
  }

  @override
  Stream<String> get tokenChanges => _f.onTokenRefresh;
  @override
  Stream<RemoteMessage> get messages => FirebaseMessaging.onMessage;
  @override
  Stream<RemoteMessage> get opened => FirebaseMessaging.onMessageOpenedApp;
  @override
  Future<RemoteMessage?> initial() => _f.getInitialMessage();
}

final pushClientProvider = Provider<PushClient>(
  (ref) => FirebasePushClient(false),
);

class PushState {
  const PushState({
    this.status,
    this.busy = false,
    this.registered = false,
    this.canRequest = false,
    this.error,
  });
  final AuthorizationStatus? status;
  final bool busy;
  final bool registered;
  final bool canRequest;
  final String? error;
}

bool pushAllowed(AuthorizationStatus? status) =>
    status == AuthorizationStatus.authorized ||
    status == AuthorizationStatus.provisional;

/// Never use a route supplied by an untrusted push. Open the authenticated inbox;
/// its existing server-backed entries resolve role-specific destinations.
String pushDestination(Map<String, dynamic> data) => '/notifications';

final pushControllerProvider = NotifierProvider<PushController, PushState>(
  PushController.new,
);

class PushController extends Notifier<PushState> {
  int _version = 0;
  Completer<void>? _settled;
  bool _dirty = false;
  bool _askedInProcess = false;
  bool get _asked {
    if (_askedInProcess) return true;
    try {
      return ref.read(prefsProvider).getBool("push_permission_asked") ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() async {
    final version = ++_version;
    _dirty = false;
    await _settled?.future;
    if (ref.mounted && version == _version) state = const PushState();
  }

  @override
  PushState build() => const PushState();
  Future<void> sync({bool request = false}) async {
    if (state.busy) {
      _dirty = true;
      return;
    }
    final client = ref.read(pushClientProvider);
    if (!client.available || !ref.read(authProvider).loggedIn) return;
    final version = ++_version;
    final settled = _settled = Completer<void>();
    state = PushState(status: state.status, busy: true);
    try {
      var permission = await client.permission();
      if (request &&
          (permission == AuthorizationStatus.notDetermined ||
              (permission == AuthorizationStatus.denied && !_asked))) {
        _askedInProcess = true;
        try {
          await ref.read(prefsProvider).setBool('push_permission_asked', true);
        } catch (_) {}
        permission = await client.permission(request: true);
      }
      if (!ref.mounted || version != _version) return;
      state = PushState(
        status: permission,
        busy: true,
        canRequest: !_asked && permission == AuthorizationStatus.denied,
      );
      final auth = ref.read(authProvider);
      if (!auth.loggedIn) return;
      if (!pushAllowed(permission)) {
        await ref.read(apiProvider).removePushDevice(auth.deviceId);
        if (ref.mounted && version == _version) {
          state = PushState(
            status: permission,
            canRequest: !_asked && permission == AuthorizationStatus.denied,
          );
        }
        return;
      }
      final token = await client.token();
      if (!ref.mounted ||
          version != _version ||
          ref.read(authProvider).token != auth.token) {
        return;
      }
      if (token == null) {
        state = PushState(
          status: permission,
          error: 'Thiết bị chưa sẵn sàng. Vui lòng thử lại.',
        );
        return;
      }
      await ref
          .read(apiProvider)
          .registerPushDevice(
            auth.deviceId,
            token,
            defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID',
          );
      if (ref.mounted && version == _version) {
        state = PushState(status: permission, registered: true);
      }
    } catch (_) {
      if (ref.mounted && version == _version) {
        state = PushState(
          status: state.status,
          canRequest: state.canRequest,
          error:
              'Chưa kết nối được dịch vụ thông báo. Bạn vẫn dùng app bình thường.',
        );
      }
    } finally {
      if (_dirty && ref.mounted && version == _version) {
        _dirty = false;
        state = PushState(status: state.status, canRequest: state.canRequest);
        await sync();
      }
      if (!settled.isCompleted) settled.complete();
      if (ref.mounted && version == _version && state.busy) {
        state = PushState(
          status: state.status,
          registered: state.registered,
          error: state.error,
        );
      }
    }
  }

  void reset() {
    ++_version;
    _dirty = false;
    state = const PushState();
  }
}

class PushBridge extends ConsumerStatefulWidget {
  const PushBridge({required this.child, required this.onOpen, super.key});
  final Widget child;
  final VoidCallback onOpen;
  @override
  ConsumerState<PushBridge> createState() => _PushBridgeState();
}

class _PushBridgeState extends ConsumerState<PushBridge>
    with WidgetsBindingObserver {
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Set<String> _seen = {};
  bool _pendingOpen = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final client = ref.read(pushClientProvider);
    if (!client.available) return;
    _subscriptions.add(
      client.tokenChanges.listen((_) => _sync(), onError: (_) {}),
    );
    _subscriptions.add(client.messages.listen(_foreground, onError: (_) {}));
    _subscriptions.add(client.opened.listen(_open, onError: (_) {}));
    client
        .initial()
        .then((message) {
          if (mounted && message != null) _open(message);
        })
        .catchError((_) {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  void _sync() {
    if (mounted) unawaited(ref.read(pushControllerProvider.notifier).sync());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync();
  }

  bool _accept(RemoteMessage message) {
    if (!mounted || !ref.read(authProvider).loggedIn) return false;
    final eventId = message.data['event_id'];
    final id = eventId is String && eventId.isNotEmpty
        ? eventId
        : message.messageId;
    if (id != null && !_seen.add(id)) return false;
    if (_seen.length > 100) _seen.remove(_seen.first);
    ref.invalidate(notificationsProvider);
    return true;
  }

  void _open(RemoteMessage message) {
    if (!ref.read(authProvider).loggedIn) {
      _pendingOpen = true;
      return;
    }
    if (!_accept(message)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(authProvider).loggedIn) widget.onOpen();
    });
  }

  void _foreground(RemoteMessage message) {
    if (!_accept(message)) return;
    pushMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: const Text('Bạn có thông báo mới trên DropIt!'),
        action: SnackBarAction(
          label: 'Xem',
          onPressed: () {
            if (mounted && ref.read(authProvider).loggedIn) widget.onOpen();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (previous?.loggedIn != next.loggedIn) {
        if (next.loggedIn) {
          _sync();
          if (_pendingOpen) {
            _pendingOpen = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && ref.read(authProvider).loggedIn) widget.onOpen();
            });
          }
        } else {
          ref.read(pushControllerProvider.notifier).reset();
          _seen.clear();
        }
      }
    });
    return widget.child;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}

class PushPermissionCard extends ConsumerWidget {
  const PushPermissionCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(pushClientProvider);
    if (!mobilePushSupported) return const SizedBox.shrink();
    final state = ref.watch(pushControllerProvider);
    final denied =
        state.status == AuthorizationStatus.denied && !state.canRequest;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông báo trên thiết bị',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            !client.available
                ? 'Push chưa được cấu hình cho bản cài đặt này.'
                : state.error ??
                      (state.registered
                          ? 'Đã đăng ký nhận thông báo. Bạn có thể tắt trong cài đặt hệ thống.'
                          : denied
                          ? 'Thông báo đang tắt. Bạn có thể bật trong Cài đặt hệ thống; hộp thông báo vẫn hoạt động.'
                          : 'Nhận nhắc phiên và cập nhật khi không mở app. Bạn có thể từ chối.'),
          ),
          if (client.available)
            TextButton(
              onPressed: state.busy
                  ? null
                  : () => ref
                        .read(pushControllerProvider.notifier)
                        .sync(request: !denied && !pushAllowed(state.status)),
              child: Text(
                state.busy
                    ? 'Đang kiểm tra…'
                    : denied || state.registered
                    ? 'Kiểm tra lại'
                    : pushAllowed(state.status)
                    ? 'Thử kết nối lại'
                    : 'Bật thông báo',
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> disconnectPush(
  AuthState auth,
  PushClient client, {
  required bool Function() stillCurrent,
}) async {
  if (!client.available || !auth.loggedIn || !stillCurrent()) return;
  try {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.restBase,
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 2),
      ),
    );
    try {
      await dio.delete(
        '/me/devices/${auth.deviceId}/push',
        options: Options(headers: {'Authorization': 'Bearer ${auth.token}'}),
      );
    } finally {
      dio.close(force: true);
    }
  } catch (_) {
    /* logout stays available offline */
  }
}
