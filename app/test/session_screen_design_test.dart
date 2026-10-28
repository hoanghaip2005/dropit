import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dropit/core/models.dart';
import 'package:dropit/core/providers.dart';
import 'package:dropit/core/theme/theme.dart';
import 'package:dropit/features/session/session_controller.dart';
import 'package:dropit/features/session/session_screen.dart';

class ScreenController extends SessionController {
  ScreenController(this.initial) : super('s');
  final SessionView initial;
  int leaveCalls = 0;
  final dismissed = <String>[];
  @override
  SessionView build() => initial;
  @override
  Future<void> leave() async {
    leaveCalls++;
    state = state.copyWith(leaving: true);
  }

  @override
  void dismissBanner(String id) {
    dismissed.add(id);
    state = state.copyWith(
      banners: state.banners.where((b) => b.eventId != id).toList(),
    );
  }

  void change(SessionView next) => state = next;
}

SessionSummary metadata() => SessionSummary.fromJson({
  'session_id': 's',
  'group_id': 'g',
  'group_name': 'Nhóm thiết kế sản phẩm và trải nghiệm người dùng tên rất dài',
  'started_at': DateTime.now()
      .toUtc()
      .add(const Duration(minutes: 3))
      .toIso8601String(),
  'duration_min': 50,
});

Widget direct(Widget child, {double scale = 1}) => MaterialApp(
  theme: buildLightTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    backgroundColor: DT.lockdownBg,
    body: SafeArea(child: child),
  ),
);

Widget screen(ScreenController controller, {bool failMetadata = false}) =>
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        sessionControllerProvider('s').overrideWith(() => controller),
        sessionInfoProvider('s').overrideWith((ref) async {
          if (failMetadata) throw Exception('raw internal error');
          return metadata();
        }),
      ],
      child: MaterialApp(
        theme: buildLightTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: const SessionScreen(sessionId: 's'),
      ),
    );

void main() {
  test('Cancellation message preserves the server reason', () {
    expect(sessionCancellationText('NO_ATTENDEE'), contains('không có thành viên'));
    expect(sessionCancellationText('NO_ATTENDEE'), isNot(contains('Chủ nhóm')));
    expect(sessionCancellationText('OWNER_CANCEL'), 'Chủ nhóm đã hủy phiên này.');
    expect(sessionCancellationText('SERVER_OUTAGE'), contains('sự cố hệ thống'));
    expect(sessionCancellationText('REMOVED'), 'Bạn không còn ở nhóm này.');
    expect(sessionCancellationText(null), 'Phiên đã hủy.');
    expect(sessionEntryError('LATE_JOIN_CLOSED'), contains('Thời gian vào phiên đã đóng'));
    expect(sessionEntryError('SESSION_NOT_ACTIVE'), contains('kết thúc hoặc bị hủy'));
  });
  testWidgets(
    'Lobby unknown metadata has no fabricated duration, reward or participant count',
    (tester) async {
      await tester.pumpWidget(
        direct(
          LobbyView(
            view: const SessionView(phase: SessionPhase.waiting),
            info: null,
            onLeave: () {},
          ),
        ),
      );
      expect(find.text('Bắt đầu sau'), findsOneWidget);
      expect(find.text('Đang cập nhật thời lượng phiên'), findsOneWidget);
      expect(find.text('Đang cập nhật số người…'), findsOneWidget);
      expect(find.textContaining('25 phút'), findsNothing);
      expect(find.textContaining('+10'), findsNothing);
      expect(find.textContaining('+25'), findsNothing);
      expect(find.text('Đang kết nối lại…'), findsOneWidget);
    },
  );

  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets(
      'Lobby and every dark phase fit $width with large text and long names',
      (tester) async {
        tester.view.physicalSize = Size(width, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final now = DateTime.now().toUtc();
        final info = metadata();
        await tester.pumpWidget(
          direct(
            LobbyView(
              view: SessionView(
                phase: SessionPhase.waiting,
                connected: true,
                participantCount: 0,
                lobbyMembers: [
                  'Thành viên có tên dài để kiểm tra hiển thị đầy đủ tiếng Việt',
                ],
              ),
              info: info,
              onLeave: () {},
            ),
            scale: 1.5,
          ),
        );
        await tester.scrollUntilVisible(
          find.text('0 người đã vào phòng chờ'),
          200,
        );
        expect(find.text('0 người đã vào phòng chờ'), findsOneWidget);
        await tester.drag(find.byType(ListView).first, const Offset(0, -900));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          direct(
            CountdownView(
              view: SessionView(
                phase: SessionPhase.countdown,
                startedAt: now.add(const Duration(seconds: 4)),
              ),
              info: info,
            ),
            scale: 1.5,
          ),
        );
        expect(find.byKey(const Key('countdownDigit')), findsOneWidget);
        expect(tester.takeException(), isNull);
        for (final phase in [
          SessionPhase.focusing,
          SessionPhase.grace,
          SessionPhase.disconnected,
          SessionPhase.lost,
        ]) {
          await tester.pumpWidget(
            direct(
              LockdownView(
                view: SessionView(
                  phase: phase,
                  startedAt: now,
                  endsAt: now.add(const Duration(minutes: 50)),
                  graceDeadline: now.add(const Duration(seconds: 3)),
                  banners: [
                    ExitBanner(
                      eventId: 'private-event-id',
                      name:
                          'Thành viên tên dài thông báo rời phiên cần xuống dòng đầy đủ',
                      at: now,
                      triggeredForfeit: true,
                    ),
                  ],
                ),
                info: info,
                onLeave: () {},
                onDismissBanner: (_) {},
              ),
              scale: 1.5,
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull, reason: '$phase at $width');
          expect(find.textContaining('private-event-id'), findsNothing);
          if (phase == SessionPhase.lost) {
            expect(find.byKey(const Key('remaining')), findsNothing);
            expect(find.byKey(const Key('recordingIndicator')), findsNothing);
            expect(find.textContaining('0 Coins'), findsNothing);
          }
        }
      },
    );
  }

  testWidgets(
    'Countdown unknown clock has no recording, duration or leave action',
    (tester) async {
      await tester.pumpWidget(
        direct(
          const CountdownView(
            view: SessionView(phase: SessionPhase.countdown),
            info: null,
          ),
        ),
      );
      expect(find.text('Đang đồng bộ giờ…'), findsOneWidget);
      expect(find.byKey(const Key('leaveButton')), findsNothing);
      expect(find.byKey(const Key('recordingIndicator')), findsNothing);
    },
  );

  testWidgets(
    'Deadline displays are truthful outside old five/three second assumptions',
    (tester) async {
      final now = DateTime.now().toUtc();
      await tester.pumpWidget(
        direct(
          CountdownView(
            view: SessionView(
              phase: SessionPhase.countdown,
              startedAt: now.add(const Duration(seconds: 9)),
            ),
            info: null,
          ),
        ),
      );
      expect(find.text('9'), findsOneWidget);
      await tester.pumpWidget(
        direct(
          CountdownView(
            view: SessionView(
              phase: SessionPhase.countdown,
              startedAt: now.subtract(const Duration(seconds: 1)),
            ),
            info: null,
          ),
        ),
      );
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Đang đồng bộ bắt đầu phiên…'), findsOneWidget);
      await tester.pumpWidget(
        direct(
          GraceOverlay(
            view: SessionView(
              phase: SessionPhase.grace,
              graceDeadline: now.add(const Duration(seconds: 8)),
            ),
          ),
        ),
      );
      expect(find.text('8'), findsOneWidget);
    },
  );

  testWidgets(
    'Lobby confirmation cannot authorize active leave after phase changes',
    (tester) async {
      final controller = ScreenController(
        const SessionView(phase: SessionPhase.waiting, connected: true),
      );
      await tester.pumpWidget(screen(controller));
      await tester.pump();
      await tester.tap(find.byKey(const Key('leaveButton')));
      await tester.pumpAndSettle();
      controller.change(
        const SessionView(phase: SessionPhase.focusing, connected: true),
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('leaveConfirm')));
      await tester.tap(find.byKey(const Key('leaveConfirm')));
      await tester.pumpAndSettle();
      expect(controller.leaveCalls, 0);
      expect(
        find.text(
          'Trạng thái phiên đã thay đổi. Vui lòng xác nhận rời phiên lại.',
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Disconnect blocks underlying leave action; banner dismiss uses exact event id',
    (tester) async {
      var leaves = 0;
      await tester.pumpWidget(
        direct(
          LockdownView(
            view: const SessionView(phase: SessionPhase.disconnected),
            onLeave: () => leaves++,
            onDismissBanner: (_) {},
          ),
        ),
      );
      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('leaveButton'))),
      );
      expect(leaves, 0);
      final ids = <String>[];
      await tester.pumpWidget(
        direct(
          ExitBannerView(
            banner: ExitBanner(
              eventId: 'event-1',
              name: 'Minh',
              at: DateTime.utc(2026, 10, 23, 1),
              triggeredForfeit: false,
            ),
            more: 2,
            onDismiss: ids.add,
          ),
        ),
      );
      expect(find.text('+2 thông báo khác'), findsOneWidget);
      expect(find.textContaining('mất thưởng tập thể'), findsNothing);
      await tester.drag(
        find.byKey(const Key('exitBanner')),
        const Offset(700, 0),
      );
      await tester.pumpAndSettle();
      expect(ids, ['event-1']);
    },
  );

  for (final phase in [
    SessionPhase.waiting,
    SessionPhase.focusing,
    SessionPhase.grace,
  ]) {
    testWidgets(
      'Real screen $phase confirm cancel never leaves; confirm once; busy disables',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = ScreenController(
          SessionView(phase: phase, connected: true),
        );
        await tester.pumpWidget(screen(controller));
        await tester.pump();
        final key = phase == SessionPhase.grace
            ? 'graceEmergencyExit'
            : 'leaveButton';
        await tester.ensureVisible(find.byKey(Key(key)));
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('leaveConfirm')), findsOneWidget);
        await tester.tap(find.byKey(const Key('leaveCancel')));
        await tester.pumpAndSettle();
        expect(controller.leaveCalls, 0);
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('leaveConfirm')));
        await tester.tap(find.byKey(const Key('leaveConfirm')));
        await tester.pumpAndSettle();
        expect(controller.leaveCalls, 1);
        expect(
          find.byWidgetPredicate(
            (widget) => widget is OutlinedButton && widget.onPressed == null,
          ),
          findsWidgets,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('Actual screen maps technical error and consent navigation', (
    tester,
  ) async {
    final controller = ScreenController(
      const SessionView(
        phase: SessionPhase.error,
        errorCode: 'CONSENT_REQUIRED',
        errorMessage: 'Use session:resume socket internal',
      ),
    );
    final router = GoRouter(
      initialLocation: '/session/s',
      routes: [
        GoRoute(
          path: '/session/s',
          builder: (_, _) => const SessionScreen(sessionId: 's'),
        ),
        GoRoute(
          path: '/groups',
          builder: (_, _) => const Scaffold(body: Text('Nhóm thử nghiệm')),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Trang chủ thử nghiệm')),
        ),
        GoRoute(
          path: '/session/s/result',
          builder: (_, _) => const Scaffold(body: Text('Kết quả thử nghiệm')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider('s').overrideWith(() => controller),
          sessionInfoProvider('s').overrideWith((ref) async => metadata()),
        ],
        child: MaterialApp.router(
          theme: buildLightTheme(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('session:resume'), findsNothing);
    await tester.tap(find.text('Xem nhóm'));
    await tester.pumpAndSettle();
    expect(find.text('Nhóm thử nghiệm'), findsOneWidget);
    // Route disposal must also cancel the screen's local timers.
    await tester.pumpWidget(const SizedBox());
  });

  for (final target in ['cancelled', 'ended']) {
    testWidgets(
      'Connecting, unknown error and $target preserve state and navigation',
      (tester) async {
        final controller = ScreenController(
          const SessionView(phase: SessionPhase.connecting),
        );
        final router = GoRouter(
          initialLocation: '/session/s',
          routes: [
            GoRoute(
              path: '/session/s',
              builder: (_, _) => const SessionScreen(sessionId: 's'),
            ),
            GoRoute(
              path: '/home',
              builder: (_, _) => const Scaffold(body: Text('Home destination')),
            ),
            GoRoute(
              path: '/session/s/result',
              builder: (_, _) =>
                  const Scaffold(body: Text('Result destination')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionControllerProvider('s').overrideWith(() => controller),
              sessionInfoProvider('s').overrideWith((ref) async => metadata()),
            ],
            child: MaterialApp.router(
              theme: buildLightTheme(),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Đang vào phòng chờ…'), findsOneWidget);
        controller.change(
          const SessionView(
            phase: SessionPhase.error,
            errorCode: 'UNKNOWN',
            errorMessage: 'session:resume raw',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('session:resume'), findsNothing);
        if (target == 'cancelled') {
          controller.change(
            const SessionView(
              phase: SessionPhase.cancelled,
              cancelReason: 'SERVER_OUTAGE',
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(
              'Phiên đã hủy do sự cố hệ thống. Kết quả sẽ được chốt theo trạng thái tham gia của bạn.',
            ),
            findsOneWidget,
          );
          controller.change(
            const SessionView(
              phase: SessionPhase.cancelled,
              cancelReason: 'REMOVED',
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Bạn không còn ở nhóm này.'), findsOneWidget);
          await tester.tap(find.text('Về trang chủ'));
          await tester.pumpAndSettle();
          expect(find.text('Home destination'), findsOneWidget);
        } else {
          controller.change(const SessionView(phase: SessionPhase.ended));
          await tester.pumpAndSettle();
          expect(find.text('Result destination'), findsOneWidget);
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'Banner keeps six-second timeout and metadata failure stays honest',
    (tester) async {
      final controller = ScreenController(
        SessionView(
          phase: SessionPhase.focusing,
          banners: [
            ExitBanner(
              eventId: 'e',
              name: 'Minh',
              at: DateTime.now().toUtc(),
              triggeredForfeit: true,
            ),
          ],
        ),
      );
      await tester.pumpWidget(screen(controller, failMetadata: true));
      await tester.pump(const Duration(seconds: 5));
      expect(controller.dismissed, isEmpty);
      await tester.pump(const Duration(seconds: 1));
      expect(controller.dismissed, ['e']);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        screen(
          ScreenController(const SessionView(phase: SessionPhase.waiting)),
          failMetadata: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Chưa tải được thông tin phiên. Trạng thái kết nối được hiển thị riêng.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('raw internal error'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
