import 'session_storage_stub.dart'
    if (dart.library.js_interop) 'session_storage_web.dart'
    as platform;

/// A refresh credential scoped to a browser tab. Never stores passwords or access tokens.
abstract interface class SessionStorage {
  String? read();
  void write(String value);
  void clear();
}

SessionStorage createSessionStorage() => platform.createSessionStorage();
