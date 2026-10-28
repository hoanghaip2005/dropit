import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth.dart';

/// Do not mount the router until refresh succeeds or the saved session is rejected.
class SessionGate extends ConsumerStatefulWidget {
  const SessionGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends ConsumerState<SessionGate> {
  late Future<void> _restore;

  @override
  void initState() {
    super.initState();
    _restore = ref.read(authProvider.notifier).restoreSession();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _restore,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        return widget.child;
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFF4F5F7),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!snapshot.hasError) ...[
                        const CircularProgressIndicator(color: Colors.black),
                        const SizedBox(height: 20),
                        const Text('Đang khôi phục đăng nhập…'),
                      ] else ...[
                        const Text(
                          'Chưa kết nối được dịch vụ đăng nhập',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Phiên đã lưu được giữ lại. Kiểm tra mạng rồi thử lại.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: () => setState(() {
                            _restore = ref
                                .read(authProvider.notifier)
                                .restoreSession();
                          }),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
