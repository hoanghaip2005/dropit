/// Mô hình dữ liệu theo `design/openapi.yaml` (chỉ trường app dùng).
library;

DateTime? _dt(Object? v) => v is String ? DateTime.tryParse(v)?.toUtc() : null;
int _int(Object? v, [int d = 0]) => v is num ? v.toInt() : d;
List<Map<String, dynamic>> _list(Object? v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];

class MeProfile {
  MeProfile.fromJson(Map<String, dynamic> j)
      : userId = '${j['user_id'] ?? ''}',
        displayName = '${j['display_name'] ?? ''}',
        email = j['email'] as String?,
        coinsBalance = _int(j['coins_balance']),
        currentStreak = _int(j['current_streak']),
        longestStreak = _int(j['longest_streak']),
        avatarUrl = j['avatar_url'] as String?,
        frameItemId = j['frame_item_id'] as String?,
        backgroundItemId = j['background_item_id'] as String?,
        titleItemId = j['title_item_id'] as String?,
        showStreak = j['show_streak'] == true,
        cachedAt = _dt(j['cached_at']);

  /// Khác null = bản lưu trên máy (mất mạng) — hiện "Chưa cập nhật" (AC-07.01.3).
  final DateTime? cachedAt;

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'display_name': displayName,
        'email': email,
        'coins_balance': coinsBalance,
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'avatar_url': avatarUrl,
        'frame_item_id': frameItemId,
        'background_item_id': backgroundItemId,
        'title_item_id': titleItemId,
        'show_streak': showStreak,
      };
  final String userId;
  final String displayName;
  final String? email;

  /// BR-99: tự bật hiện chuỗi trên hồ sơ công khai.
  final bool showStreak;
  final int coinsBalance;
  final int currentStreak;
  final int longestStreak;
  final String? avatarUrl;
  final String? frameItemId;
  final String? backgroundItemId;
  final String? titleItemId;
}

class SessionSummary {
  SessionSummary.fromJson(Map<String, dynamic> j)
      : sessionId = '${j['session_id']}',
        groupId = '${j['group_id'] ?? ''}',
        groupName = j['group_name'] as String?,
        status = '${j['status'] ?? 'SCHEDULED'}',
        startedAt = _dt(j['started_at']) ?? DateTime.now().toUtc(),
        endsAt = _dt(j['ends_at']),
        durationMin = _int(j['duration_min'], 25),
        lobbyOpensAt = _dt(j['lobby_opens_at']),
        forfeited = j['forfeited'] == true,
        cancelReason = j['cancel_reason'] as String?;
  final String sessionId;
  final String groupId;
  final String? groupName;
  final String status;
  final DateTime startedAt;
  final DateTime? endsAt;
  final int durationMin;
  final DateTime? lobbyOpensAt;
  final bool forfeited;
  final String? cancelReason;

  /// D-09: 25' = +10, 50' = +25 Coins nếu cả phiên không ai rời app.
  int get expectedCoins => durationMin >= 50 ? 25 : 10;
}

class MyGroup {
  MyGroup.fromJson(Map<String, dynamic> j)
      : groupId = '${j['group_id']}',
        name = '${j['name'] ?? ''}',
        role = '${j['role'] ?? 'MEMBER'}',
        status = '${j['status'] ?? 'ACTIVE'}',
        memberCount = _int(j['member_count']),
        belowMinimum = j['below_minimum'] == true,
        monthCompletionRate = j['month_completion_rate'] is num ? (j['month_completion_rate'] as num).toDouble() : null,
        nextSession = j['next_session'] is Map
            ? SessionSummary.fromJson(Map<String, dynamic>.from(j['next_session'] as Map))
            : null;
  final String groupId;
  final String name;
  final String role;

  /// ACTIVE | SCHEDULE_SUSPENDED | DISSOLVING (AC-02.06.1).
  final String status;
  final int memberCount;
  final bool belowMinimum;

  /// Tỉ lệ hoàn thành phiên tháng này của RIÊNG nhóm này, đến hôm qua (BR-117). null = chưa có phiên.
  final double? monthCompletionRate;
  final SessionSummary? nextSession;
  bool get isOwner => role == 'OWNER';
}

class PublicUser {
  PublicUser.fromJson(Map<String, dynamic> j)
      : userId = '${j['user_id'] ?? ''}',
        displayName = '${j['display_name'] ?? ''}',
        avatarUrl = j['avatar_url'] as String?,
        frameItemId = j['frame_item_id'] as String?,
        backgroundItemId = j['background_item_id'] as String?,
        titleItemId = j['title_item_id'] as String?,
        joinedAt = _dt(j['joined_at']);
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? frameItemId;
  final String? backgroundItemId;
  final String? titleItemId;
  final DateTime? joinedAt;
}

/// V-32 Hồ sơ công khai người cùng nhóm — không Coins; chuỗi/huy hiệu chỉ khi người đó tự bật (BR-99).
class PublicProfile {
  PublicProfile.fromJson(Map<String, dynamic> j)
      : user = PublicUser.fromJson(j['user'] is Map ? Map<String, dynamic>.from(j['user'] as Map) : const {}),
        role = '${j['role'] ?? 'MEMBER'}',
        shownBadges = (j['shown_badges'] is List) ? [for (final b in j['shown_badges'] as List) '$b'] : const [],
        shownStreak = j['shown_streak'] is num ? (j['shown_streak'] as num).toInt() : null;
  final PublicUser user;
  final String role;
  final List<String> shownBadges;
  final int? shownStreak;
}

class GroupMembers {
  GroupMembers.fromJson(Map<String, dynamic> j)
      : owner = j['owner'] is Map ? PublicUser.fromJson(Map<String, dynamic>.from(j['owner'] as Map)) : null,
        members = _list(j['members']).map(PublicUser.fromJson).toList(),
        memberCount = _int(j['member_count']),
        belowMinimum = j['below_minimum'] == true;
  final PublicUser? owner;
  final List<PublicUser> members;
  final int memberCount;
  final bool belowMinimum;
}

class ConsentItem {
  ConsentItem.fromJson(Map<String, dynamic> j)
      : code = '${j['code']}',
        text = '${j['text'] ?? ''}',
        required = j['required'] != false;
  final String code;
  final String text;
  final bool required;
}

class ConsentDocument {
  ConsentDocument.fromJson(Map<String, dynamic> j)
      : groupId = '${j['group_id']}',
        groupName = '${j['group_name'] ?? ''}',
        ownerDisplayName = j['owner_display_name'] as String?,
        reportPurpose = j['report_purpose'] as String?,
        consentVersion = _int(j['consent_version'], 1),
        memberCount = _int(j['member_count']),
        isFull = j['is_full'] == true,
        items = _list(j['items']).map(ConsentItem.fromJson).toList();
  final String groupId;
  final String groupName;
  final String? ownerDisplayName;
  final String? reportPurpose;
  final int consentVersion;
  final int memberCount;
  final bool isFull;
  final List<ConsentItem> items;
}

class SessionOwnerView {
  SessionOwnerView.fromJson(Map<String, dynamic> j)
      : sessionId = '${j['session_id']}',
        status = '${j['status'] ?? ''}',
        startedAt = _dt(j['started_at']),
        endsAt = _dt(j['ends_at']),
        forfeited = j['forfeited'] == true,
        forfeitTrigger = j['forfeit_trigger_display_name'] as String?,
        cancelReason = j['cancel_reason'] as String?,
        cancelledAt = _dt(j['cancelled_at']),
        fetchedAt = _dt(j['fetched_at']) ?? DateTime.now().toUtc(),
        members = _list(j['members']),
        exitEvents = _list(j['exit_events']);
  final String sessionId;
  final String status;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final bool forfeited;
  final String? forfeitTrigger;
  final String? cancelReason;
  final DateTime? cancelledAt;
  final DateTime fetchedAt;
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> exitEvents;
}

class MySessionResult {
  MySessionResult.fromJson(Map<String, dynamic> j)
      : sessionId = '${j['session_id'] ?? ''}',
        groupName = j['group_name'] as String?,
        startedAt = _dt(j['started_at']),
        durationMin = _int(j['duration_min'], 25),
        finalState = '${j['final_state'] ?? ''}',
        focusSeconds = _int(j['focus_seconds']),
        forfeited = j['forfeited'] == true,
        forfeitTrigger = j['forfeit_trigger_display_name'] as String?,
        coinsAwarded = _int(j['coins_awarded']),
        rewardCapReached = j['reward_cap_reached'] == true,
        streakAfter = _int(j['streak_after']),
        streakBroken = j['streak_broken'] == true,
        canExplain = j['can_explain'] == true,
        canAppeal = j['can_appeal'] == true,
        exempted = j['exempted'] == true,
        participants = _list(j['participants']);
  final String sessionId;
  final String? groupName;
  final DateTime? startedAt;
  final int durationMin;
  final String finalState;
  final int focusSeconds;
  final bool forfeited;
  final String? forfeitTrigger;
  final int coinsAwarded;
  final bool rewardCapReached;
  final int streakAfter;
  final bool streakBroken;
  final bool canExplain;
  final bool canAppeal;
  final bool exempted;

  /// Giờ kết thúc theo lịch (started_at + thời lượng) — dùng tính hạn giải trình (BR-85).
  DateTime? get endsAtGuess => startedAt?.add(Duration(minutes: durationMin));

  /// Người trong phiên (tên + trạng thái cuối), sắp theo tên (BR-115).
  final List<Map<String, dynamic>> participants;
}

class CoinEntry {
  CoinEntry.fromJson(Map<String, dynamic> j)
      : amount = _int(j['amount']),
        type = '${j['type'] ?? ''}',
        reason = j['reason'] as String?,
        balanceAfter = _int(j['balance_after']),
        rewardDate = j['reward_date'] as String?,
        createdAt = _dt(j['created_at']);
  Map<String, dynamic> toJson() => {
        'amount': amount,
        'type': type,
        'reason': reason,
        'balance_after': balanceAfter,
        'reward_date': rewardDate,
        'created_at': createdAt?.toIso8601String(),
      };
  final int amount;
  final String type;
  final String? reason;
  final int balanceAfter;
  final String? rewardDate;
  final DateTime? createdAt;
}

class AppNotification {
  AppNotification.fromJson(Map<String, dynamic> j)
      : id = '${j['notification_id'] ?? ''}',
        type = '${j['type'] ?? ''}',
        title = '${j['title'] ?? ''}',
        body = '${j['body'] ?? ''}',
        sessionId = j['session_id'] as String?,
        groupId = j['group_id'] as String?,
        data = j['data'] is Map ? Map<String, dynamic>.from(j['data'] as Map) : const {},
        serverTs = _dt(j['server_ts']),
        read = j['read'] == true;
  final String id;
  final String? groupId;

  /// `data` của thông báo (vd. `appeal_id` cho APPEAL_CREATED — backend README "Phát hiện khi code").
  final Map<String, dynamic> data;
  final String type;
  final String title;
  final String body;
  final String? sessionId;
  final DateTime? serverTs;
  final bool read;
}

List<Map<String, dynamic>> itemsOf(Object? data, [String key = 'items']) =>
    data is Map ? _list(data[key]) : const [];
