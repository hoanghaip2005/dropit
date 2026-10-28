import 'dart:js_interop';

import 'session_storage.dart';

@JS('window.sessionStorage')
external _Storage get _storage;

extension type _Storage._(JSObject _) implements JSObject {
  external JSString? getItem(JSString key);
  external void setItem(JSString key, JSString value);
  external void removeItem(JSString key);
}

SessionStorage createSessionStorage() => _TabStorage();

class _TabStorage implements SessionStorage {
  static const _key = 'dropit.refresh-session.v1';
  @override
  String? read() {
    try {
      return _storage.getItem(_key.toJS)?.toDart;
    } catch (_) {
      return null;
    }
  }

  @override
  void write(String value) {
    try {
      _storage.setItem(_key.toJS, value.toJS);
    } catch (_) {
      /* Storage may be blocked. */
    }
  }

  @override
  void clear() {
    try {
      _storage.removeItem(_key.toJS);
    } catch (_) {
      /* Storage may be blocked. */
    }
  }
}
