import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/auth.dart';
import 'core/providers.dart';
import 'core/push.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  var pushReady = false;
  if (pushEnabled && mobilePushSupported) {
    try {
      await Firebase.initializeApp(options: pushFirebaseOptions);
      FirebaseMessaging.onBackgroundMessage(pushBackgroundHandler);
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: false,
            sound: false,
          );
      pushReady = true;
    } catch (_) {
      // Missing native configuration must not prevent using the app.
    }
  }
  runApp(
    ProviderScope(
      // Tắt tự thử lại của Riverpod 3: màn hiện lỗi/mất mạng kèm nút "Thử lại".
      retry: (_, _) => null,
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        pushClientProvider.overrideWithValue(FirebasePushClient(pushReady)),
        beforeLogoutProvider.overrideWith(
          (ref) => () async {
            final auth = ref.read(authProvider);
            await ref.read(pushControllerProvider.notifier).stop();
            await disconnectPush(
              auth,
              ref.read(pushClientProvider),
              stillCurrent: () => ref.read(authProvider).token == auth.token,
            );
          },
        ),
      ],
      child: const DropItApp(),
    ),
  );
}

class DropItApp extends ConsumerWidget {
  const DropItApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'DropIt!',
    debugShowCheckedModeBanner: false,
    scaffoldMessengerKey: pushMessengerKey,
    builder: (context, child) => PushBridge(
      onOpen: () => ref.read(routerProvider).push('/notifications'),
      child: child ?? const SizedBox.shrink(),
    ),
    theme: ref.watch(ownerOnlyProvider) == true
        ? buildOwnerTheme()
        : buildLightTheme(),
    routerConfig: ref.watch(routerProvider),
  );
}
