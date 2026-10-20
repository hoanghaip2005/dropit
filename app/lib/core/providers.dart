import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api.dart';
import 'models.dart';
import 'models_ext.dart';
import 'offline.dart';

/// Hồ sơ của tôi; mất mạng → bản lưu gần nhất kèm `cachedAt` (AC-07.01.3).
final meProvider = FutureProvider.autoDispose<MeProfile>((ref) async {
  final cache = ref.read(offlineCacheProvider);
  try {
    final m = await ref.watch(apiProvider).me();
    await cache.put('me', m.toJson());
    return m;
  } on ApiError catch (e) {
    final c = e.offline ? cache.get('me') : null;
    if (c == null) rethrow;
    return MeProfile.fromJson({...c.data, 'cached_at': c.at.toIso8601String()});
  }
});
final myGroupsProvider = FutureProvider.autoDispose<List<MyGroup>>((ref) => ref.watch(apiProvider).myGroups());
final upcomingProvider = FutureProvider.autoDispose<SessionSummary?>((ref) => ref.watch(apiProvider).upcoming());
final membersProvider =
    FutureProvider.autoDispose.family<GroupMembers, String>((ref, id) => ref.watch(apiProvider).members(id));
final inviteCodeProvider =
    FutureProvider.autoDispose.family<String, String>((ref, id) => ref.watch(apiProvider).inviteCode(id));
final schedulesProvider =
    FutureProvider.autoDispose.family<List<SessionSummary>, String>((ref, id) => ref.watch(apiProvider).schedules(id));
final sessionInfoProvider =
    FutureProvider.autoDispose.family<SessionSummary, String>((ref, id) => ref.watch(apiProvider).session(id));
final ownerDetailProvider =
    FutureProvider.autoDispose.family<SessionOwnerView, String>((ref, id) => ref.watch(apiProvider).ownerDetail(id));
final resultProvider =
    FutureProvider.autoDispose.family<MySessionResult, String>((ref, id) => ref.watch(apiProvider).result(id));
typedef CoinsView = ({int balance, List<CoinEntry> items, DateTime? cachedAt});

/// Coins; mất mạng → số dư lần tải gần nhất kèm `cachedAt` ("có thể chưa cập nhật", AC-06.02.5).
final coinsProvider = FutureProvider.autoDispose<CoinsView>((ref) async {
  final cache = ref.read(offlineCacheProvider);
  try {
    final r = await ref.watch(apiProvider).coins();
    await cache.put('coins', {'balance': r.balance, 'items': [for (final e in r.items) e.toJson()]});
    return (balance: r.balance, items: r.items, cachedAt: null);
  } on ApiError catch (e) {
    final c = e.offline ? cache.get('coins') : null;
    if (c == null) rethrow;
    return (
      balance: (c.data['balance'] as num?)?.toInt() ?? 0,
      items: itemsOf(c.data).map(CoinEntry.fromJson).toList(),
      cachedAt: c.at,
    );
  }
});
final notificationsProvider = FutureProvider.autoDispose((ref) => ref.watch(apiProvider).notifications());
final invitePreviewProvider = FutureProvider.autoDispose
    .family<ConsentDocument, String>((ref, code) => ref.watch(apiProvider).previewInvite(code));

// ---------- Vai trò hiển thị ----------
/// Chỉ là chủ nhóm (không là thành viên nhóm nào) → thanh điều hướng chủ nhóm, ẩn Coins/chuỗi (BR-53).
/// `null` khi chưa tải xong.
final ownerOnlyProvider = Provider.autoDispose<bool?>((ref) {
  final g = ref.watch(myGroupsProvider).value;
  if (g == null) return null;
  return g.isNotEmpty && g.every((x) => x.isOwner);
});

// ---------- Shop / thành tích / lịch sử / nhật ký / báo cáo ----------
final shopItemsProvider = FutureProvider.autoDispose((ref) => ref.watch(apiProvider).shopItems());
final inventoryProvider = FutureProvider.autoDispose((ref) => ref.watch(apiProvider).inventory());
final achievementsProvider = FutureProvider.autoDispose((ref) => ref.watch(apiProvider).achievements());
final attendanceProvider = FutureProvider.autoDispose
    .family<AttendanceMonth, String>((ref, month) => ref.watch(apiProvider).attendance(month));
final historyProvider = FutureProvider.autoDispose((ref) => ref.watch(apiProvider).history(limit: 50));
final journalProvider = FutureProvider.autoDispose((ref) => ref.watch(apiProvider).journal());
final explanationsProvider = FutureProvider.autoDispose
    .family<List<Explanation>, String>((ref, sid) => ref.watch(apiProvider).explanations(sid));
final appealProvider =
    FutureProvider.autoDispose.family<Appeal, String>((ref, id) => ref.watch(apiProvider).appeal(id));
final reportPeriodsProvider = FutureProvider.autoDispose
    .family<List<ReportPeriod>, String>((ref, gid) => ref.watch(apiProvider).reportPeriods(gid));
final reportProvider = FutureProvider.autoDispose
    .family<GroupReport, (String, String)>((ref, k) => ref.watch(apiProvider).report(k.$1, k.$2));
final reportRowProvider = FutureProvider.autoDispose.family<ReportRow, (String, String, String)>(
    (ref, k) => ref.watch(apiProvider).reportMemberRow(k.$1, k.$2, k.$3));

/// Coins thưởng đã nhận hôm nay (giờ VN) so với trần 100/ngày (D-09).
final coinsTodayProvider = FutureProvider.autoDispose<int>((ref) async {
  final c = await ref.watch(coinsProvider.future);
  final now = DateTime.now().toUtc().add(const Duration(hours: 7));
  final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return c.items
      .where((e) => e.type == 'SESSION_REWARD' && e.rewardDate == today)
      .fold<int>(0, (s, e) => s + e.amount);
});

// ---------- Hồ sơ công khai (V-32) / Dữ liệu của tôi (V-25) / giải trình của tôi ----------
final publicProfileProvider =
    FutureProvider.autoDispose.family<PublicProfile, String>((ref, uid) => ref.watch(apiProvider).publicProfile(uid));
final myExplanationProvider =
    FutureProvider.autoDispose.family<Explanation?, String>((ref, sid) => ref.watch(apiProvider).myExplanation(sid));

/// Phiên mà người dùng đang có trạng thái chưa kết thúc (WAITING/FOCUSING/GRACE/DISCONNECTED) — BR-70 khóa Đăng xuất.
class LiveSession extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? sessionId) => state = sessionId;
  void clearIf(String sessionId) {
    if (state == sessionId) state = null;
  }
}

final liveSessionProvider = NotifierProvider<LiveSession, String?>(LiveSession.new);
