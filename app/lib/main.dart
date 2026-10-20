import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    // Tắt tự thử lại của Riverpod 3: màn hiện lỗi/mất mạng kèm nút "Thử lại".
    retry: (_, _) => null,
    overrides: [prefsProvider.overrideWithValue(prefs)],
    child: const DropItApp(),
  ));
}

class DropItApp extends ConsumerWidget {
  const DropItApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        title: 'DropIt!',
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(),
        routerConfig: ref.watch(routerProvider),
      );
}
