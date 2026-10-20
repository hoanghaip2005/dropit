import Flutter
import UIKit

/// focus_lifecycle — kênh native iOS (tách từ spike T-01).
/// Chỉ dùng sự kiện vòng đời của CHÍNH app + protectedData (khóa màn hình).
/// Không đọc app khác, không cảm biến (BR-34, NFR-P01).
/// Giới hạn: protectedData* chỉ phát khi máy CÓ đặt mã khóa, và có thể đến trễ.
public final class FocusLifecyclePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  private var watching = false
  private var tokens: [NSObjectProtocol] = []

  public static func register(with registrar: FlutterPluginRegistrar) {
    let inst = FocusLifecyclePlugin()
    FlutterEventChannel(name: "dropit/focus_lifecycle/events", binaryMessenger: registrar.messenger())
      .setStreamHandler(inst)
    let method = FlutterMethodChannel(name: "dropit/focus_lifecycle", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(inst, channel: method)
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startWatching": start(); result(true)
    case "stopWatching": stop(); result(true)
    case "snapshot":
      result(["protectedDataAvailable": UIApplication.shared.isProtectedDataAvailable])
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func send(_ event: String) {
    guard watching else { return }
    let m: [String: Any] = [
      "event": event,
      "nativeUptimeMs": Int(ProcessInfo.processInfo.systemUptime * 1000),
      "protectedDataAvailable": UIApplication.shared.isProtectedDataAvailable,
    ]
    DispatchQueue.main.async { self.sink?(m) }
  }

  private func observe(_ name: Notification.Name, _ event: String) {
    tokens.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) {
      [weak self] _ in self?.send(event)
    })
  }

  // Chỉ lắng nghe khi phiên đang ghi (NFR-P02).
  private func start() {
    guard !watching else { return }
    watching = true
    observe(UIApplication.protectedDataWillBecomeUnavailableNotification, "protected_data_unavailable")
    observe(UIApplication.protectedDataDidBecomeAvailableNotification, "protected_data_available")
    observe(UIScene.willDeactivateNotification, "scene_will_resign_active")
    observe(UIScene.didEnterBackgroundNotification, "scene_did_enter_background")
    observe(UIScene.willEnterForegroundNotification, "scene_will_enter_foreground")
    observe(UIScene.didActivateNotification, "scene_did_become_active")
    observe(UIApplication.willTerminateNotification, "will_terminate")
    send("watching_started")
  }

  private func stop() {
    guard watching else { return }
    send("watching_stopped")
    watching = false
    tokens.forEach { NotificationCenter.default.removeObserver($0) }
    tokens.removeAll()
  }
}
