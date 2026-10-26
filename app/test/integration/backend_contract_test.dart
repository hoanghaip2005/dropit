// Test tích hợp nhỏ với backend local (http://localhost:3000).
// Tự bỏ qua nếu /health không trả lời. Chạy: flutter test test/integration
import 'package:dio/dio.dart';
import '../support/dev_auth.dart';
import 'package:dropit/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = 'http://localhost:3000';
  final dio = Dio(BaseOptions(baseUrl: base, connectTimeout: const Duration(seconds: 2)));
  var up = false;

  setUpAll(() async {
    try {
      up = (await dio.get('/health')).statusCode == 200;
    } catch (_) {}
  });

  test('POST /dev/token (email seed) → access_token; GET /v1/me/groups của Lan', () async {
    if (!up) {
      markTestSkipped('Backend local không chạy');
      return;
    }
    final lan = fallbackDevUsers.first;
    final token = await DevAuthApi(dio).token(lan);
    expect(token, isNotEmpty);
    final auth = Options(headers: {'Authorization': 'Bearer $token'});
    final me = await dio.get('/v1/me', options: auth);
    expect(me.data, isA<Map>());
    final groups = await dio.get('/v1/me/groups', options: auth);
    final d = groups.data;
    final items = d is List ? d : (d as Map)['items'] as List;
    expect(items.length, greaterThanOrEqualTo(2), reason: 'Lan là chủ nhóm 2 nhóm seed');
    final parsed = items.map((e) => MyGroup.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    expect(parsed.map((g) => g.name).where((n) => n.isNotEmpty), hasLength(items.length));
  });
}
