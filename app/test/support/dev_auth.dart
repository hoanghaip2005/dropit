import 'package:dio/dio.dart';
import 'package:dropit/app/env.dart';
class DevUser {
  const DevUser(this.id, this.label, {this.email});
  final String id;
  final String label;
  final String? email;
}

/// Người dùng seed của backend (backend/db/seed.sql). Backend không có
/// `GET /dev/users` nên đây là danh sách chính; `/dev/token` nhận `email`.
const fallbackDevUsers = [
  DevUser('lan', 'Lan (chủ nhóm 2 nhóm)', email: 'lan@dropit.dev'),
  DevUser('an', 'An', email: 'an@dropit.dev'),
  DevUser('binh', 'Bình', email: 'binh@dropit.dev'),
  DevUser('chi', 'Chi', email: 'chi@dropit.dev'),
  DevUser('dung', 'Dũng', email: 'dung@dropit.dev'),
  DevUser('em', 'Em', email: 'em@dropit.dev'),
  DevUser('giang', 'Giang', email: 'giang@dropit.dev'),
  DevUser('hoa', 'Hoa', email: 'hoa@dropit.dev'),
];

class DevAuthApi {
  DevAuthApi([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: Env.baseUrl,
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 10),
            ));
  final Dio _dio;

  /// Thử `/dev/users` rồi `/v1/dev/users`; lỗi → danh sách dự phòng.
  Future<List<DevUser>> users() async {
    for (final p in ['/dev/users', '${Env.apiPrefix}/dev/users']) {
      try {
        final r = await _dio.get(p);
        final d = r.data;
        final list = d is List ? d : (d is Map ? (d['items'] ?? d['users']) : null);
        if (list is List && list.isNotEmpty) {
          return list.whereType<Map>().map((m) {
            final id = '${m['user_id'] ?? m['id'] ?? m['sub'] ?? m['email']}';
            final name = '${m['display_name'] ?? m['name'] ?? m['email'] ?? id}';
            return DevUser(id, name, email: m['email'] as String?);
          }).toList();
        }
      } catch (_) {/* thử đường tiếp */}
    }
    return fallbackDevUsers;
  }

  /// `POST /dev/token` (gửi cả `user_id` và `email` nếu có) → `access_token`|`token`.
  Future<String> token(DevUser u) async {
    DioException? last;
    for (final p in ['/dev/token', '${Env.apiPrefix}/dev/token']) {
      try {
        // Hợp đồng backend: { email, display_name? } — chỉ gửi email để giữ tên seed.
        final r = await _dio.post(p, data: {'email': u.email ?? '${u.id}@dropit.dev'});
        final d = r.data;
        final t = d is Map ? (d['access_token'] ?? d['token'] ?? d['accessToken']) : d;
        if (t is String && t.isNotEmpty) return t;
      } on DioException catch (e) {
        last = e;
        if (e.response?.statusCode != 404) rethrow;
      }
    }
    throw last ?? Exception('Không nhận được token');
  }
}

