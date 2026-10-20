import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth.dart';

/// Bản lưu cục bộ cho màn cần hiện "bản đã lưu + Chưa cập nhật" khi mất mạng
/// (AC-07.01.3 hồ sơ, AC-06.02.5 Coins, V-25 Dữ liệu của tôi) và nháp nhật ký (AC-07.07.6).
/// Khóa theo người dùng; xóa hết khi đăng xuất (quyền riêng tư — không để lại dữ liệu người trước trên máy).
class OfflineCache {
  OfflineCache(this._p, this._user);

  /// null = chưa có SharedPreferences (test widget không ghi đè) → bộ nhớ đệm rỗng, không lỗi.
  final SharedPreferences? _p;
  final String? _user;

  static const cachePrefix = 'cache:';
  static const draftPrefix = 'draft:';

  String _k(String prefix, String name) => '$prefix${_user ?? '-'}:$name';

  Future<void> put(String name, Map<String, dynamic> data) async =>
      _p?.setString(_k(cachePrefix, name), jsonEncode({'at': DateTime.now().toUtc().toIso8601String(), 'data': data}));

  ({Map<String, dynamic> data, DateTime at})? get(String name) {
    final raw = _p?.getString(_k(cachePrefix, name));
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return (data: Map<String, dynamic>.from(m['data'] as Map), at: DateTime.parse('${m['at']}').toUtc());
    } catch (_) {
      return null;
    }
  }

  // ---- nháp nhật ký (giữ đến khi lưu được lên máy chủ) ----
  String? draft(String date) => _p?.getString(_k(draftPrefix, date));
  Future<void> saveDraft(String date, String text) async => _p?.setString(_k(draftPrefix, date), text);
  Future<void> clearDraft(String date) async => _p?.remove(_k(draftPrefix, date));

  /// Gọi khi đăng xuất.
  static Future<void> clearAll(SharedPreferences p) async {
    for (final k in p.getKeys().toList()) {
      if (k.startsWith(cachePrefix) || k.startsWith(draftPrefix)) await p.remove(k);
    }
  }
}

final offlineCacheProvider = Provider<OfflineCache>((ref) {
  try {
    return OfflineCache(ref.read(prefsProvider), ref.watch(authProvider).userLabel);
  } catch (_) {
    return OfflineCache(null, null);
  }
});
