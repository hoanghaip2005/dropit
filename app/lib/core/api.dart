import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../app/env.dart';
import 'auth.dart';
import 'models.dart';
import 'models_ext.dart';

/// Server local trả URL tuyệt đối theo `PUBLIC_BASE_URL` (localhost) — đổi về gốc mà app
/// thật sự gọi được (emulator Android: 10.0.2.2).
String fixHost(String url) {
  final u = Uri.tryParse(url);
  final b = Uri.tryParse(Env.baseUrl);
  if (u == null || b == null || !u.hasScheme) return url;
  if (u.host == 'localhost' || u.host == '127.0.0.1') {
    return u.replace(scheme: b.scheme, host: b.host, port: b.port).toString();
  }
  return url;
}

/// Lỗi gọn cho tầng giao diện. `offline` = không tới được server (mất mạng).
class ApiError implements Exception {
  ApiError({
    required this.message,
    this.code,
    this.status,
    this.offline = false,
  });
  final String message;
  final String? code;
  final int? status;
  final bool offline;

  static ApiError from(Object e) {
    if (e is ApiError) return e;
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return ApiError(
            message: 'Không có kết nối tới máy chủ.',
            offline: true,
          );
        default:
          break;
      }
      final r = e.response;
      final d = r?.data;
      String? code;
      String? detail;
      if (d is Map) {
        code = d['code'] as String?;
        detail = (d['detail'] ?? d['title'] ?? d['message']) as String?;
      }
      return ApiError(
        message: detail ?? _fallback(r?.statusCode),
        code: code,
        status: r?.statusCode,
      );
    }
    return ApiError(message: 'Đã có lỗi. Vui lòng thử lại.');
  }

  static String _fallback(int? s) => switch (s) {
    401 => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    403 => 'Bạn không có quyền xem mục này.',
    404 => 'Không tìm thấy.',
    409 => 'Thao tác bị xung đột. Vui lòng tải lại.',
    429 => 'Bạn thao tác quá nhanh. Vui lòng chờ một lát.',
    _ => 'Máy chủ đang gặp lỗi. Vui lòng thử lại.',
  };

  @override
  String toString() => 'ApiError($status, $code, $message)';
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.restBase,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'X-App-Version': '0.1.0'},
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (o, h) {
        final t = ref.read(authProvider).token;
        if (t != null) o.headers['Authorization'] = 'Bearer $t';
        h.next(o);
      },
      onError: (e, h) {
        final currentToken = ref.read(authProvider).token;
        if (e.response?.statusCode == 401 &&
            currentToken != null &&
            e.requestOptions.headers['Authorization'] ==
                'Bearer $currentToken') {
          ref.read(authProvider.notifier).expire();
        }
        h.next(e);
      },
    ),
  );
  return dio;
});

final apiProvider = Provider<DropItApi>(
  (ref) => DropItApi(ref.watch(dioProvider)),
);

const _uuid = Uuid();

/// REST theo design/openapi.yaml. Mọi POST/DELETE có tác dụng phụ gửi
/// `Idempotency-Key` (P6).
class DropItApi {
  DropItApi(this._dio);
  Future<void> registerPushDevice(
    String deviceId,
    String token,
    String platform,
  ) => _wrap(
    () => _dio.put(
      '/me/devices/$deviceId/push',
      data: {'token': token, 'platform': platform},
    ),
  );
  Future<void> removePushDevice(String deviceId) =>
      _wrap(() => _dio.delete('/me/devices/$deviceId/push'));
  final Dio _dio;

  Options _idem() => Options(headers: {'Idempotency-Key': _uuid.v4()});

  Future<T> _wrap<T>(Future<T> Function() f) async {
    try {
      return await f();
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<MeProfile> me() =>
      _wrap(() async => MeProfile.fromJson((await _dio.get('/me')).data));

  Future<MeProfile> updateMe(String name) => _wrap(
    () async => MeProfile.fromJson(
      (await _dio.patch('/me', data: {'display_name': name})).data,
    ),
  );

  Future<List<MyGroup>> myGroups() => _wrap(
    () async => itemsOf(
      (await _dio.get('/me/groups')).data,
    ).map(MyGroup.fromJson).toList(),
  );

  Future<ConsentDocument> previewInvite(String code) => _wrap(
    () async =>
        ConsentDocument.fromJson((await _dio.get('/invites/$code')).data),
  );

  Future<void> acceptConsent(
    String groupId, {
    required int version,
    required String code,
    required List<String> items,
  }) => _wrap(
    () => _dio.post(
      '/groups/$groupId/consent',
      data: {
        'consent_version': version,
        'invite_code': code,
        'accepted_items': items,
      },
      options: _idem(),
    ),
  );

  Future<Map<String, dynamic>> createGroup(String name, String purpose) =>
      _wrap(
        () async => Map<String, dynamic>.from(
          (await _dio.post(
                '/groups',
                data: {'name': name, 'report_purpose': purpose},
                options: _idem(),
              )).data
              as Map,
        ),
      );

  Future<GroupMembers> members(String groupId) => _wrap(
    () async => GroupMembers.fromJson(
      (await _dio.get('/groups/$groupId/members')).data,
    ),
  );

  Future<String> inviteCode(String groupId) => _wrap(
    () async =>
        '${((await _dio.get('/groups/$groupId/invite-code')).data as Map)['code']}',
  );

  Future<String> rotateInviteCode(String groupId) => _wrap(
    () async =>
        '${((await _dio.post('/groups/$groupId/invite-code', options: _idem())).data as Map)['code']}',
  );

  Future<List<SessionSummary>> schedules(String groupId) => _wrap(() async {
    final from = DateTime.now()
        .toUtc()
        .subtract(const Duration(days: 7))
        .toIso8601String();
    final r = await _dio.get(
      '/groups/$groupId/schedules',
      queryParameters: {'from': from},
    );
    return itemsOf(r.data).map(SessionSummary.fromJson).toList();
  });

  Future<void> createSchedule(
    String groupId,
    DateTime startUtc,
    int durationMin,
  ) => _wrap(
    () => _dio.post(
      '/groups/$groupId/schedules',
      data: {
        'start_time': startUtc.toUtc().toIso8601String(),
        'duration_min': durationMin,
      },
      options: _idem(),
    ),
  );

  // ---------- Sửa / hủy lịch (US-02.11) ----------
  Future<SessionSummary> updateSession(
    String sessionId, {
    DateTime? startUtc,
    int? durationMin,
  }) => _wrap(
    () async => SessionSummary.fromJson(
      (await _dio.patch(
        '/sessions/$sessionId',
        data: {
          if (startUtc != null)
            'started_at': startUtc.toUtc().toIso8601String(),
          'duration_min': ?durationMin,
        },
      )).data,
    ),
  );

  Future<void> cancelSession(String sessionId) =>
      _wrap(() => _dio.delete('/sessions/$sessionId', options: _idem()));

  // ---------- Rời nhóm / xóa thành viên (US-01.07, US-02.08) ----------
  /// Rút đồng ý = rời nhóm. Trả các phiên bị chuyển WITHDRAWN (after_forfeit → vẫn ngắt chuỗi, D-23).
  Future<Map<String, dynamic>> withdrawConsent(String groupId) => _wrap(
    () async {
      final r = await _dio.delete('/groups/$groupId/consent', options: _idem());
      return r.data is Map
          ? Map<String, dynamic>.from(r.data as Map)
          : <String, dynamic>{};
    },
  );

  /// true = hiệu lực ngay (204); false = người đó đang trong phiên, hiệu lực sau khi phiên kết thúc (202, BR-77).
  Future<bool> removeMember(String groupId, String userId) => _wrap(() async {
    final r = await _dio.delete(
      '/groups/$groupId/members/$userId',
      options: _idem(),
    );
    return r.statusCode != 202;
  });

  // ---------- Hồ sơ công khai / Dữ liệu của tôi ----------
  Future<PublicProfile> publicProfile(String userId) => _wrap(
    () async => PublicProfile.fromJson(
      (await _dio.get('/users/$userId/public-profile')).data,
    ),
  );

  Future<Map<String, dynamic>> myData({String? groupId}) => _wrap(
    () async => Map<String, dynamic>.from(
      (await _dio.get('/me/data', queryParameters: {'group_id': ?groupId})).data
          as Map,
    ),
  );

  Future<MeProfile> setShowStreak(bool v) => _wrap(
    () async => MeProfile.fromJson(
      (await _dio.patch('/me', data: {'show_streak': v})).data,
    ),
  );

  Future<SessionSummary?> upcoming() => _wrap(() async {
    final d = (await _dio.get('/me/sessions/upcoming')).data;
    return d is Map
        ? SessionSummary.fromJson(Map<String, dynamic>.from(d))
        : null;
  });

  Future<SessionSummary> session(String id) => _wrap(
    () async => SessionSummary.fromJson((await _dio.get('/sessions/$id')).data),
  );

  Future<MySessionResult> result(String id) => _wrap(
    () async =>
        MySessionResult.fromJson((await _dio.get('/sessions/$id/result')).data),
  );

  Future<SessionOwnerView> ownerDetail(String id) => _wrap(
    () async => SessionOwnerView.fromJson(
      (await _dio.get('/sessions/$id/owner-detail')).data,
    ),
  );

  Future<({int balance, List<CoinEntry> items})> coins() => _wrap(() async {
    final d = (await _dio.get('/me/coins')).data as Map;
    return (
      balance: (d['balance'] as num?)?.toInt() ?? 0,
      items: itemsOf(d).map(CoinEntry.fromJson).toList(),
    );
  });

  Future<({int unread, List<AppNotification> items})> notifications() =>
      _wrap(() async {
        final d = (await _dio.get('/me/notifications')).data as Map;
        return (
          unread: (d['unread_count'] as num?)?.toInt() ?? 0,
          items: itemsOf(d).map(AppNotification.fromJson).toList(),
        );
      });

  Future<void> markRead(List<String> ids) =>
      _wrap(() => _dio.post('/me/notifications/read', data: {'ids': ids}));

  Future<void> markAllRead() => _wrap(
    () => _dio.post(
      '/me/notifications/read',
      data: {'up_to': DateTime.now().toUtc().toIso8601String()},
    ),
  );

  Future<void> createRecurringSchedule(
    String groupId,
    DateTime startUtc,
    int durationMin,
    List<int> weekdays,
    String endDate,
  ) => _wrap(
    () => _dio.post(
      '/groups/$groupId/schedules',
      data: {
        'start_time': startUtc.toUtc().toIso8601String(),
        'duration_min': durationMin,
        'recurrence': {'weekdays': weekdays, 'end_date': endDate},
      },
      options: _idem(),
    ),
  );

  // ---------- Avatar (PUT /me/avatar → upload_url; bản local: PUT thân ảnh kèm Bearer) ----------
  Future<void> uploadAvatar(List<int> bytes, String contentType) =>
      _wrap(() async {
        final r = await _dio.put(
          '/me/avatar',
          data: {'content_type': contentType, 'size_bytes': bytes.length},
        );
        final url = fixHost('${(r.data as Map)['upload_url']}');
        await _dio.put(
          url,
          data: Stream.fromIterable([bytes]),
          options: Options(
            headers: {
              Headers.contentTypeHeader: contentType,
              Headers.contentLengthHeader: bytes.length,
            },
          ),
        );
      });

  // ---------- Shop ----------
  Future<List<ShopItem>> shopItems() => _wrap(
    () async => itemsOf(
      (await _dio.get('/shop/items')).data,
    ).map(ShopItem.fromJson).toList(),
  );

  /// Mua: một khóa `Idempotency-Key` cho mỗi lần bấm xác nhận (bấm hai lần chỉ trừ một lần).
  Future<int> purchase(
    String itemId,
    int expectedPrice, {
    required String idempotencyKey,
  }) => _wrap(() async {
    final r = await _dio.post(
      '/shop/purchases',
      data: {'item_id': itemId, 'expected_price': expectedPrice},
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return ((r.data as Map)['balance'] as num?)?.toInt() ?? 0;
  });

  Future<List<OwnedItem>> inventory() => _wrap(
    () async => itemsOf(
      (await _dio.get('/me/inventory')).data,
    ).map(OwnedItem.fromJson).toList(),
  );

  /// Trang bị (id) hoặc gỡ (null → món mặc định, BR-95).
  Future<void> equip(String kind, String? itemId) => _wrap(
    () => _dio.put(
      '/me/equipment',
      data: {
        switch (kind) {
          'AVATAR_FRAME' => 'frame_item_id',
          'BACKGROUND' => 'background_item_id',
          _ => 'title_item_id',
        }: itemId,
      },
    ),
  );

  // ---------- Thành tích ----------
  Future<Achievements> achievements() => _wrap(
    () async =>
        Achievements.fromJson((await _dio.get('/me/achievements')).data),
  );

  Future<AttendanceMonth> attendance(String month) => _wrap(
    () async => AttendanceMonth.fromJson(
      (await _dio.get(
        '/me/attendance',
        queryParameters: {'month': month},
      )).data,
    ),
  );

  Future<void> setBadgeVisible(String code, bool visible) => _wrap(
    () => _dio.put('/me/badges/$code/display', data: {'visible': visible}),
  );

  // ---------- Lịch sử phiên ----------
  Future<HistoryRewardToday> historyRewardToday() => _wrap(
    () async => HistoryRewardToday.fromJson(
      Map<String, dynamic>.from(
        (await _dio.get('/me/rewards/today')).data as Map,
      ),
    ),
  );

  Future<HistoryPage> history({
    String? cursor,
    int limit = 30,
    String? from,
    String? to,
  }) => _wrap(() async {
    final d = (await _dio.get(
      '/me/sessions',
      queryParameters: {
        'limit': limit,
        'cursor': ?cursor,
        'from': ?from,
        'to': ?to,
      },
    )).data;
    return HistoryPage(
      itemsOf(d).map(MySessionResult.fromJson).toList(),
      (d as Map)['next_cursor'] as String?,
    );
  });

  // ---------- Nhật ký ----------
  Future<List<JournalEntry>> journal() => _wrap(
    () async => itemsOf(
      (await _dio.get('/me/journal', queryParameters: {'limit': 100})).data,
    ).map(JournalEntry.fromJson).toList(),
  );

  Future<JournalEntry> saveJournal(String date, String text) => _wrap(
    () async => JournalEntry.fromJson(
      (await _dio.put('/me/journal/$date', data: {'text': text})).data,
    ),
  );

  Future<void> deleteJournal(String date) =>
      _wrap(() => _dio.delete('/me/journal/$date', options: _idem()));

  // ---------- Giải trình / khiếu nại ----------
  Future<Explanation> submitExplanation(
    String sessionId,
    String body, {
    int? version,
  }) => _wrap(
    () async => Explanation.fromJson(
      (await _dio.put(
        '/sessions/$sessionId/explanation',
        data: {'body': body},
        options: version == null
            ? null
            : Options(headers: {'If-Match': '"$version"'}),
      )).data,
    ),
  );

  /// Giải trình của chính mình (kèm lịch sử bản cũ). null = chưa gửi.
  Future<Explanation?> myExplanation(String sessionId) => _wrap(() async {
    try {
      return Explanation.fromJson(
        (await _dio.get('/sessions/$sessionId/explanation')).data,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  });

  Future<List<Explanation>> explanations(String sessionId) => _wrap(
    () async => itemsOf(
      (await _dio.get('/sessions/$sessionId/explanations')).data,
    ).map(Explanation.fromJson).toList(),
  );

  Future<Appeal> createAppeal(
    String sessionId,
    String body, {
    bool suspectSystemError = false,
  }) => _wrap(
    () async => Appeal.fromJson(
      (await _dio.post(
        '/sessions/$sessionId/appeals',
        data: {'body': body, 'suspect_system_error': suspectSystemError},
        options: _idem(),
      )).data,
    ),
  );

  Future<Appeal> appeal(String appealId) => _wrap(
    () async => Appeal.fromJson((await _dio.get('/appeals/$appealId')).data),
  );

  Future<Appeal> decideAppeal(
    String appealId,
    String decision,
    String reason,
  ) => _wrap(
    () async => Appeal.fromJson(
      (await _dio.post(
        '/appeals/$appealId/decision',
        data: {'decision': decision, 'decision_reason': reason},
        options: _idem(),
      )).data,
    ),
  );

  // ---------- Báo cáo tháng ----------
  Future<List<ReportPeriod>> reportPeriods(String groupId) => _wrap(
    () async => itemsOf(
      (await _dio.get('/groups/$groupId/reports')).data,
    ).map(ReportPeriod.fromJson).toList(),
  );

  Future<GroupReport> report(String groupId, String month) => _wrap(
    () async => GroupReport.fromJson(
      (await _dio.get('/groups/$groupId/reports/$month')).data,
    ),
  );

  Future<ReportRow> reportMemberRow(
    String groupId,
    String month,
    String userId,
  ) => _wrap(
    () async => ReportRow.fromJson(
      (await _dio.get('/groups/$groupId/reports/$month/members/$userId')).data,
    ),
  );

  Future<Duration> serverOffset() => _wrap(() async {
    final t0 = DateTime.now();
    final d = (await _dio.get('/time')).data as Map;
    final t1 = DateTime.now();
    final server = DateTime.parse('${d['server_ts']}');
    final mid = t0.add(t1.difference(t0) ~/ 2);
    return server.difference(mid);
  });
}
