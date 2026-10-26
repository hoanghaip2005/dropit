import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum BadgeTone { neutral, accent, success, danger, dark }

/// Huy hiệu trạng thái viên thuốc cao 24 (`h-6 px-2.5 rounded-full font-label-sm`).
/// accent: "Đã lên lịch" · success: "Hoàn thành" · danger: "Có người thoát" (chỉ lỗi/thoát).
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.tone = BadgeTone.neutral, this.icon});
  final String label;
  final BadgeTone tone;
  final IconData? icon;

  static (Color, Color) colors(BadgeTone tone) => switch (tone) {
        BadgeTone.neutral => (DT.surfaceHigh, DT.textSecondary),
        BadgeTone.accent => (DT.accentSoftBg, DT.accent),
        BadgeTone.success => (DT.successSoftBg, DT.success),
        BadgeTone.danger => (DT.warningSoftBg, DT.onWarningSoft),
        BadgeTone.dark => (DT.textPrimary, Colors.white),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = colors(tone);
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(DT.pill)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
        Text(label, style: context.text.labelSmall!.copyWith(color: fg, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Chip Coins: nền cam nhạt `#FFF3E8`, chữ `#C2410C`, biểu tượng đồng xu.
/// [onCard] = chip trắng có bóng (header employee_home: "420 Coins").
class CoinChip extends StatelessWidget {
  const CoinChip(this.text, {super.key, this.onCard = false, this.icon = Icons.monetization_on});
  final String text;
  final bool onCard;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: onCard ? DT.card : DT.accentSoftBg,
          borderRadius: BorderRadius.circular(DT.pill),
          boxShadow: onCard ? DT.softShadow : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 18, color: DT.accent), const SizedBox(width: 6)],
          Flexible(
            child: Text(text,
                style: context.text.labelMedium!.copyWith(
                    color: onCard ? DT.textPrimary : DT.accent, fontFeatures: DT.tabular, fontSize: 13)),
          ),
        ]),
      );
}

/// Chip người trong phòng chờ (`bg-surface-container-high rounded-full`) với biểu tượng trạng thái.
class PersonChip extends StatelessWidget {
  const PersonChip(this.name, {super.key, this.ready = true});
  final String name;
  final bool ready;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: DT.surfaceHigh, borderRadius: BorderRadius.circular(DT.pill)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(ready ? Icons.check_circle : Icons.schedule, size: 16, color: ready ? DT.success : DT.textSecondary),
          const SizedBox(width: 6),
          Text(name, style: context.text.labelLarge),
        ]),
      );
}

/// Bộ chọn viên thuốc; mục chọn cam nhạt, chữ cam và viền rõ.
class PillToggle<T> extends StatelessWidget {
  const PillToggle({super.key, required this.options, required this.value, required this.onChanged, this.big = false});
  final List<PillOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  /// Nút cao có dòng phụ (schedule_focus); mặc định thanh mảnh trong khung trắng (n_10).
  final bool big;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final row = Row(children: [
      for (var i = 0; i < options.length; i++) ...[
        if (i > 0 && big) const SizedBox(width: DT.spaceSm),
        Expanded(
          child: Semantics(
            selected: options[i].value == value,
            button: true,
            child: Material(
              color: options[i].value == value ? DT.accentSoftBg : (big ? (context.ownerStyle ? OwnerStyle.inset : DT.surfaceHigh) : Colors.transparent),
              shape: StadiumBorder(side: BorderSide(color: !context.ownerStyle && options[i].value == value ? DT.accent.withValues(alpha: .45) : Colors.transparent)),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => onChanged(options[i].value),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: big ? 12 : 8),
                  child: Column(children: [
                    Text(options[i].label,
                        style: (big ? t.titleMedium : t.labelLarge)!.copyWith(
                            color: options[i].value == value ? DT.accent : DT.textSecondary,
                            fontWeight: FontWeight.w600)),
                    if (options[i].caption != null)
                      Text(options[i].caption!,
                          style: t.bodySmall!.copyWith(
                              color: options[i].value == value ? DT.accent : DT.textSecondary)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ],
    ]);
    if (big) return row;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: DT.card, borderRadius: BorderRadius.circular(DT.pill), boxShadow: DT.softShadow),
      child: row,
    );
  }
}

class PillOption<T> {
  const PillOption(this.value, this.label, {this.caption});
  final T value;
  final String label;
  final String? caption;
}

/// Chip lọc danh mục (Shop: Khung avatar / Hình nền / Danh hiệu).
class FilterChipPill extends StatelessWidget {
  const FilterChipPill({super.key, required this.label, required this.selected, this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(selected: selected, button: true, child: Material(
        color: selected ? DT.accentSoftBg : DT.card,
        shape: StadiumBorder(side: BorderSide(color: context.ownerStyle ? Colors.transparent : (selected ? DT.accent.withValues(alpha: .45) : DT.outline))),
        elevation: 0,
        shadowColor: Colors.black12,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 26),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (selected) ...[const Icon(Icons.check_rounded, size: 16, color: DT.accent), const SizedBox(width: 6)],
                Text(label, style: context.text.labelLarge!.copyWith(color: selected ? DT.accent : DT.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
              ])),
          ),
        ),
      ));
}

/// Chấm trang onboarding: chấm hiện tại dài 28, đen; chấm khác 8, xám.
class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.count, required this.index});
  final int count;
  final int index;
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Bước ${index + 1}/$count',
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < count; i++)
            Container(
              width: i == index ? 28 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                  color: i == index ? DT.primary : DT.surfaceDim, borderRadius: BorderRadius.circular(DT.pill)),
            ),
        ]),
      );
}
