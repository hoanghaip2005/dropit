import 'session_storage.dart';

SessionStorage createSessionStorage() => _MemoryOnlyStorage();

class _MemoryOnlyStorage implements SessionStorage {
  @override
  String? read() => null;
  @override
  void write(String value) {}
  @override
  void clear() {}
}
