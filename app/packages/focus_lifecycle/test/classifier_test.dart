import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_lifecycle/src/classifier.dart';

void main() {
  late List<FocusSignal> out;
  late bool fg;
  LockLeaveClassifier make() => LockLeaveClassifier(
        onSignal: out.add,
        isForeground: () => fg,
      )..start();

  setUp(() {
    out = [];
    fg = true;
  });

  List<FocusSignalType> types() => out.map((e) => e.type).toList();

  test('vào nền không có tín hiệu khóa → LEAVE sau 600 ms', () {
    fakeAsync((t) {
      final c = make();
      c.onHostLifecycle(HostLifecycle.paused);
      t.elapse(const Duration(milliseconds: 599));
      expect(out, isEmpty);
      t.elapse(const Duration(milliseconds: 2));
      expect(types(), [FocusSignalType.leftApp]);
      expect(c.state, LocalFocusState.left);
    });
  });

  test('quay lại sau LEAVE → RETURN', () {
    fakeAsync((t) {
      final c = make();
      c.onHostLifecycle(HostLifecycle.hidden);
      t.elapse(const Duration(seconds: 1));
      c.onHostLifecycle(HostLifecycle.resumed);
      expect(types(), [FocusSignalType.leftApp, FocusSignalType.returned]);
      expect(c.state, LocalFocusState.focusing);
    });
  });

  test('quay lại trong 600 ms → không gửi gì', () {
    fakeAsync((t) {
      final c = make();
      c.onHostLifecycle(HostLifecycle.paused);
      t.elapse(const Duration(milliseconds: 300));
      c.onHostLifecycle(HostLifecycle.resumed);
      t.elapse(const Duration(seconds: 2));
      expect(out, isEmpty);
    });
  });

  test('Android: process_stop không tương tác → LOCK, không LEAVE', () {
    fakeAsync((t) {
      final c = make();
      c.onHostLifecycle(HostLifecycle.paused);
      c.onNative({'event': 'process_stop', 'interactive': false, 'keyguardLocked': true});
      t.elapse(const Duration(seconds: 5));
      expect(types(), [FocusSignalType.screenLocked]);
      expect(c.screenLocked, isTrue);
    });
  });

  test('Android: screen_off đến trong lúc chờ → hủy LEAVE', () {
    fakeAsync((t) {
      final c = make();
      c.onNative({'event': 'process_stop', 'interactive': true, 'keyguardLocked': false});
      t.elapse(const Duration(milliseconds: 200));
      c.onNative({'event': 'screen_off'});
      t.elapse(const Duration(seconds: 2));
      expect(types(), [FocusSignalType.screenLocked]);
    });
  });

  test('iOS: vào nền khi protectedData không khả dụng → LOCK', () {
    fakeAsync((t) {
      final c = make();
      c.onNative({'event': 'scene_did_enter_background', 'protectedDataAvailable': false});
      t.elapse(const Duration(seconds: 2));
      expect(types(), [FocusSignalType.screenLocked]);
    });
  });

  test('iOS: inactive đơn thuần (kéo Trung tâm thông báo) không tính', () {
    fakeAsync((t) {
      final c = make();
      c.onHostLifecycle(HostLifecycle.inactive);
      t.elapse(const Duration(seconds: 5));
      c.onHostLifecycle(HostLifecycle.resumed);
      expect(out, isEmpty);
    });
  });

  test('mở khóa khi app ở tiền cảnh → UNLOCK, về FOCUSING', () {
    fakeAsync((t) {
      final c = make();
      c.onNative({'event': 'screen_off'});
      c.onHostLifecycle(HostLifecycle.resumed); // bị bỏ qua khi còn khóa
      c.onNative({'event': 'user_present'});
      t.elapse(const Duration(seconds: 2));
      expect(types(), [FocusSignalType.screenLocked, FocusSignalType.screenUnlocked]);
      expect(c.state, LocalFocusState.focusing);
    });
  });

  test('khóa → mở khóa → rời app (BR-15, ca #17) → LEAVE', () {
    fakeAsync((t) {
      final c = make();
      c.onNative({'event': 'protected_data_unavailable'});
      fg = false;
      c.onNative({'event': 'protected_data_available'});
      t.elapse(const Duration(seconds: 1));
      expect(types(), [
        FocusSignalType.screenLocked,
        FocusSignalType.screenUnlocked,
        FocusSignalType.leftApp,
      ]);
    });
  });

  test('detached → LEAVE ngay', () {
    fakeAsync((t) {
      final c = make();
      c.onHostLifecycle(HostLifecycle.detached);
      expect(types(), [FocusSignalType.leftApp]);
      expect(out.single.trigger, 'detached');
    });
  });

  test('chưa start (ngoài phiên) → không phát gì (NFR-P02)', () {
    fakeAsync((t) {
      final c = LockLeaveClassifier(onSignal: out.add);
      c.onHostLifecycle(HostLifecycle.paused);
      c.onNative({'event': 'screen_off'});
      t.elapse(const Duration(seconds: 2));
      expect(out, isEmpty);
    });
  });

  test('stop hủy LEAVE đang chờ', () {
    fakeAsync((t) {
      final c = make();
      c.onHostLifecycle(HostLifecycle.paused);
      c.stop();
      t.elapse(const Duration(seconds: 2));
      expect(out, isEmpty);
    });
  });
}
