/// Định dạng giờ hiển thị theo Asia/Ho_Chi_Minh (UTC+7, không DST — NFR-21).
DateTime vn(DateTime utc) => utc.toUtc().add(const Duration(hours: 7));
String two(int n) => n.toString().padLeft(2, '0');
String hhmm(DateTime? t) => t == null ? '--:--' : '${two(vn(t).hour)}:${two(vn(t).minute)}';
String hhmmss(DateTime? t) => t == null ? '--:--:--' : '${hhmm(t)}:${two(vn(t).second)}';
String ddmm(DateTime? t) => t == null ? '' : '${two(vn(t).day)}/${two(vn(t).month)}/${vn(t).year}';
String mmss(Duration d) {
  final s = d.isNegative ? 0 : d.inSeconds;
  return '${two(s ~/ 60)}:${two(s % 60)}';
}

/// "Hôm nay" / "Ngày mai" / dd/mm/yyyy theo giờ VN.
String dayLabel(DateTime? t) {
  if (t == null) return '';
  final d = vn(t);
  final n = vn(DateTime.now().toUtc());
  final a = DateTime(d.year, d.month, d.day);
  final b = DateTime(n.year, n.month, n.day);
  final diff = a.difference(b).inDays;
  if (diff == 0) return 'Hôm nay';
  if (diff == 1) return 'Ngày mai';
  if (diff == -1) return 'Hôm qua';
  return ddmm(t);
}
