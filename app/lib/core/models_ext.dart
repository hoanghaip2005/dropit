/// Mô hình cho Shop, thành tích, nhật ký, giải trình/khiếu nại, báo cáo tháng
/// (design/openapi.yaml EP-04…EP-08; chỉ trường app dùng).
library;

import 'models.dart';

DateTime? _dt(Object? v) => v is String ? DateTime.tryParse(v)?.toUtc() : null;
int _int(Object? v, [int d = 0]) => v is num ? v.toInt() : d;
List<Map<String, dynamic>> _list(Object? v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];

// ---------------- Shop (EP-06) — chỉ đồ trang trí (D-01) ----------------

const itemKinds = ['AVATAR_FRAME', 'BACKGROUND', 'TITLE'];

String itemKindText(String k) => switch (k) {
      'AVATAR_FRAME' => 'Khung avatar',
      'BACKGROUND' => 'Hình nền',
      'TITLE' => 'Danh hiệu',
      _ => k,
    };

class ShopItem {
  ShopItem.fromJson(Map<String, dynamic> j)
      : itemId = '${j['item_id']}',
        kind = '${j['kind'] ?? ''}',
        name = '${j['name'] ?? ''}',
        price = _int(j['price']),
        previewUrl = j['preview_url'] as String?,
        owned = j['owned'] == true;
  final String itemId;
  final String kind;
  final String name;
  final int price;
  final String? previewUrl;
  final bool owned;

  /// Khóa ảnh xem trước (đoạn cuối URL) — app tự vẽ màu giữ chỗ cùng công thức server.
  String get previewKey => previewUrl?.split('/').last ?? itemId;
}

class OwnedItem {
  OwnedItem.fromJson(Map<String, dynamic> j)
      : itemId = '${j['item_id']}',
        kind = '${j['kind'] ?? ''}',
        name = '${j['name'] ?? ''}',
        equipped = j['equipped'] == true,
        isDefault = j['is_default'] == true;
  final String itemId;
  final String kind;
  final String name;
  final bool equipped;
  final bool isDefault;
}

// ---------------- Thành tích (EP-05) ----------------

class EarnedBadge {
  EarnedBadge.fromJson(Map<String, dynamic> j)
      : code = '${j['code']}',
        earnedAt = _dt(j['earned_at']),
        visible = j['visible_on_profile'] == true;
  final String code;
  final DateTime? earnedAt;
  final bool visible;
}

class Achievements {
  Achievements.fromJson(Map<String, dynamic> j)
      : currentStreak = _int(j['current_streak']),
        longestStreak = _int(j['longest_streak']),
        nextMilestone = j['next_milestone'] is num ? (j['next_milestone'] as num).toInt() : null,
        streakCountedToday = j['streak_counted_today'] == true,
        showStreak = j['show_streak'] == true,
        progress = _list(j['badge_progress']).map(BadgeProgress.fromJson).toList(),
        badges = _list(j['badges']).map(EarnedBadge.fromJson).toList();

  /// AC-05.04.2: false → "Hôm nay chưa cộng chuỗi" (không phải "đã mất").
  final bool streakCountedToday;

  /// BR-99: đã tự bật hiện chuỗi trên hồ sơ công khai.
  final bool showStreak;

  /// Tiến độ huy hiệu theo số phiên / số giờ / chuỗi.
  final List<BadgeProgress> progress;
  final int currentStreak;
  final int longestStreak;
  final int? nextMilestone;
  final List<EarnedBadge> badges;
}

class BadgeProgress {
  BadgeProgress.fromJson(Map<String, dynamic> j)
      : metric = '${j['metric'] ?? ''}',
        value = _int(j['value']),
        nextName = j['next_badge_name'] as String?,
        nextThreshold = j['next_threshold'] is num ? (j['next_threshold'] as num).toInt() : null;
  final String metric;
  final int value;
  final String? nextName;
  final int? nextThreshold;

  String get label => switch (metric) {
        'REWARDED_SESSIONS' => 'Phiên hoàn thành có thưởng',
        'FOCUS_HOURS' => 'Giờ tập trung',
        'STREAK_DAYS' => 'Chuỗi dài nhất (ngày)',
        _ => metric,
      };

  /// 0..1 tới mốc kế tiếp; null nếu đã đạt hết mốc.
  double? get ratio => nextThreshold == null || nextThreshold == 0 ? null : (value / nextThreshold!).clamp(0, 1).toDouble();
}

class AttendanceMonth {
  AttendanceMonth.fromJson(Map<String, dynamic> j)
      : month = '${j['month'] ?? ''}',
        days = _list(j['days']).map((d) => '${d['date']}').toList(),
        attended = {
          for (final d in _list(j['days']))
            if (d['attended'] == true) '${d['date']}'
        };
  final String month;
  final List<String> days;
  final Set<String> attended;
}

// ---------------- Lịch sử phiên (US-03.14) ----------------

class HistoryPage {
  HistoryPage(this.items, this.nextCursor);
  final List<MySessionResult> items;
  final String? nextCursor;
}

/// Server aggregate of session rewards for today's Vietnamese reward date.
/// Independent of history/coin-ledger pagination and selected history day.
class HistoryRewardToday {
  HistoryRewardToday.fromJson(Map<String, dynamic> j)
      : rewardDate = j['reward_date'] as String,
        coinsAwarded = (j['coins_awarded'] as num).toInt(),
        dailyCap = (j['daily_cap'] as num).toInt();
  final String rewardDate;
  final int coinsAwarded;
  final int dailyCap;
}

// ---------------- Nhật ký (EP-07, BR-100) ----------------

const journalMaxChars = 5000;

class JournalEntry {
  JournalEntry.fromJson(Map<String, dynamic> j)
      : date = '${j['date']}',
        text = '${j['text'] ?? ''}',
        updatedAt = _dt(j['updated_at']);
  final String date;
  final String text;
  final DateTime? updatedAt;
}

// ---------------- Giải trình / khiếu nại (EP-04) ----------------

const explanationMaxChars = 500;
const appealMaxChars = 1000;

class Explanation {
  Explanation.fromJson(Map<String, dynamic> j)
      : sessionId = '${j['session_id'] ?? ''}',
        userId = '${j['user_id'] ?? ''}',
        displayName = '${j['display_name'] ?? ''}',
        exitedAt = _dt(j['exited_at']),
        body = '${j['body'] ?? ''}',
        addedAfterReport = j['added_after_report'] == true,
        submittedAt = _dt(j['submitted_at']),
        editedAt = _dt(j['edited_at']),
        editDeadline = _dt(j['edit_deadline']),
        canEdit = j['can_edit'] == true,
        version = j['version'] is num ? (j['version'] as num).toInt() : null,
        history = _list(j['history']),
        updatedAt = _dt(j['updated_at']);

  /// Lần gửi đầu; [editedAt] != null → nhãn "đã sửa lúc …" (AC-04.06.6).
  final DateTime? submittedAt;
  final DateTime? editedAt;
  final DateTime? editDeadline;
  final bool canEdit;
  final int? version;

  /// Bản cũ (chỉ có ở GET giải trình của chính mình), mới nhất trước.
  final List<Map<String, dynamic>> history;
  final String sessionId;
  final String userId;
  final String displayName;
  final DateTime? exitedAt;
  final String body;
  final bool addedAfterReport;
  final DateTime? updatedAt;
}

String appealStatusText(String s) => switch (s) {
      'PENDING' => 'Chờ xử lý',
      'IN_REVIEW' => 'Đang xử lý',
      'ESCALATED' => 'Chuyển quản trị',
      'EXEMPTED' => 'Miễn trừ',
      'REJECTED' => 'Bác',
      _ => s,
    };

class Appeal {
  Appeal.fromJson(Map<String, dynamic> j)
      : appealId = '${j['appeal_id'] ?? ''}',
        sessionId = '${j['session_id'] ?? ''}',
        status = '${j['status'] ?? ''}',
        body = '${j['body'] ?? ''}',
        suspectSystemError = j['suspect_system_error'] == true,
        decisionReason = j['decision_reason'] as String?,
        decidedAt = _dt(j['decided_at']),
        displayName = j['display_name'] as String?,
        exitedAt = _dt(j['exited_at']);
  final String appealId;
  final String sessionId;
  final String status;
  final String body;
  final bool suspectSystemError;
  final String? decisionReason;
  final DateTime? decidedAt;
  final String? displayName;
  final DateTime? exitedAt;
  bool get open => status == 'PENDING' || status == 'IN_REVIEW';
}

// ---------------- Báo cáo tháng (EP-08) ----------------

class ReportPeriod {
  ReportPeriod.fromJson(Map<String, dynamic> j)
      : month = '${j['month']}',
        status = '${j['status'] ?? ''}',
        generatedAt = _dt(j['generated_at']);
  final String month;
  final String status;
  final DateTime? generatedAt;
}

/// Một dòng báo cáo — KHÔNG có Coins/chuỗi (BR-53, BR-61).
class ReportRow {
  ReportRow.fromJson(Map<String, dynamic> j)
      : userId = '${j['user_id'] ?? ''}',
        displayName = '${j['display_name'] ?? ''}',
        expected = _int(j['expected_sessions']),
        completed = _int(j['completed_sessions']),
        completionRate = j['completion_rate'] is num ? (j['completion_rate'] as num).toDouble() : null,
        exited = _int(j['exited_count']),
        lost = _int(j['lost_count']),
        absent = _int(j['absent_count']),
        focusMinutes = _int(j['focus_minutes']),
        attendanceDays = _int(j['attendance_days']),
        explanations = _list(j['explanations']);
  final String userId;
  final String displayName;
  final int expected;
  final int completed;
  final double? completionRate;
  final int exited;
  final int lost;
  final int absent;
  final int focusMinutes;
  final int attendanceDays;
  final List<Map<String, dynamic>> explanations;
  int get present => expected - absent;
}

class GroupReport {
  GroupReport.fromJson(Map<String, dynamic> j)
      : view = '${j['view'] ?? ''}',
        groupId = '${j['group_id'] ?? ''}',
        month = '${j['month'] ?? ''}',
        purpose = j['report_purpose'] as String?,
        generatedAt = _dt(j['generated_at']),
        rows = sortByName(_list(j['rows']).map(ReportRow.fromJson).toList(), (r) => r.displayName),
        myRow = j['my_row'] is Map ? ReportRow.fromJson(Map<String, dynamic>.from(j['my_row'] as Map)) : null,
        totals = j['group_totals'] is Map ? Map<String, dynamic>.from(j['group_totals'] as Map) : null;
  final String view;
  final String groupId;
  final String month;
  final String? purpose;
  final DateTime? generatedAt;

  /// Sắp theo tên A→Z (BR-115) — không xếp hạng.
  final List<ReportRow> rows;
  final ReportRow? myRow;
  final Map<String, dynamic>? totals;
  bool get isOwnerView => view == 'OWNER';
}

/// Sắp theo tên A→Z không phân biệt hoa thường (BR-115). Không bao giờ sắp theo chỉ số.
List<T> sortByName<T>(List<T> list, String Function(T) name) => list
  ..sort((a, b) {
    final c = foldVi(name(a)).compareTo(foldVi(name(b)));
    return c != 0 ? c : name(a).compareTo(name(b));
  });

const _viGroups = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};
final _viMap = {
  for (final e in _viGroups.entries)
    for (final ch in e.value.split('')) ch: e.key,
};

/// Bỏ dấu tiếng Việt để sắp A→Z kiểu từ điển ("Đỗ" đứng cạnh "D").
String foldVi(String s) => s.toLowerCase().split('').map((c) => _viMap[c] ?? c).join();
