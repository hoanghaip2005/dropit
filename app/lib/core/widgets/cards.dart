import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Thẻ trắng bo 16, bóng mềm, padding 16 (`bg-surface-bright rounded-DEFAULT p-space-md shadow-sm`).
/// [gap] > 0 và [children] → cột có khoảng cách đều (mockup `flex-col gap-space-sm`).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.child,
    this.children,
    this.gap = DT.spaceSm,
    this.padding = const EdgeInsets.all(DT.spaceMd),
    this.onTap,
    this.radius = DT.radiusCard,
    this.color = DT.card,
    this.border,
  }) : assert(child != null || children != null);

  final Widget? child;
  final List<Widget>? children;
  final double gap;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double radius;
  final Color color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    Widget inner = child ??
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < children!.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            children![i],
          ],
        ]);
    final r = BorderRadius.circular(radius);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: color, borderRadius: r, boxShadow: DT.cardShadow, border: border),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(padding: padding, child: inner),
        ),
      ),
    );
  }
}

/// Tiêu đề mục ngoài thẻ (`font-headline-sm`) + mô tả phụ + hành động phải.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.subtitle, this.trailing, this.small = false});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Kiểu nhóm ngày nhỏ xám (`font-label-lg text-on-surface-variant`), vd. "Hôm nay".
  final bool small;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: small ? t.titleMedium!.copyWith(color: DT.textSecondary) : t.headlineSmall),
          if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: t.bodySmall)],
        ]),
      ),
      ?trailing,
    ]);
  }
}

/// Giữ tên cũ.
class SectionTitle extends SectionHeader {
  const SectionTitle(super.title, {super.key});
}

/// Dòng biểu tượng + tiêu đề + mô tả (`flex gap-space-sm items-start`) — quy tắc phiên, chi tiết sự kiện…
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor = DT.accent,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final row = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 22, color: iconColor),
      const SizedBox(width: DT.spaceSm + 4),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: t.titleMedium),
          if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: t.bodySmall)],
        ]),
      ),
      if (trailing != null) ...[const SizedBox(width: DT.spaceSm), trailing!],
    ]);
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DT.radiusSm),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: row),
    );
  }
}

/// Dòng danh sách trong thẻ, có gạch ngăn (`py-space-sm border-b border-outline-variant`).
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.divider = true,
    this.titleStyle,
  });
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool divider;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: DT.spaceSm + 4),
        decoration: divider ? const BoxDecoration(border: Border(bottom: BorderSide(color: DT.divider))) : null,
        child: Row(children: [
          if (leading != null) ...[leading!, const SizedBox(width: DT.spaceSm + 4)],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: titleStyle ?? t.titleMedium),
              if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: t.bodySmall)],
            ]),
          ),
          if (trailing != null) ...[const SizedBox(width: DT.spaceSm), trailing!],
          if (onTap != null && trailing == null) const Icon(Icons.chevron_right, color: DT.textSecondary),
        ]),
      ),
    );
  }
}

/// Ô số liệu (`grid-cols-2` của manager_dashboard / n_10): nhãn, số lớn, chú thích.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.caption, this.icon, this.valueColor});
  final String label;
  final String value;
  final String? caption;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return AppCard(
      children: [
        Row(children: [
          Expanded(child: Text(label, style: t.labelLarge!.copyWith(color: DT.textSecondary))),
          if (icon != null)
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: DT.accentSoftBg, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: DT.accent),
            ),
        ]),
        Text(value,
            style: t.headlineLarge!.copyWith(color: valueColor, fontFeatures: DT.tabular),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        if (caption != null) Text(caption!, style: t.bodySmall),
      ],
    );
  }
}

/// Hai ô cạnh nhau, cao bằng nhau.
class StatRow extends StatelessWidget {
  const StatRow({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: DT.spaceSm),
            Expanded(child: children[i]),
          ],
        ]),
      );
}

/// Dòng biên nhận "nhãn ……… giá trị" (success_reward). [total] = dòng tổng có gạch trên.
class ReceiptRow extends StatelessWidget {
  const ReceiptRow({super.key, required this.label, required this.value, this.valueColor, this.total = false});
  final String label;
  final String value;
  final Color? valueColor;
  final bool total;
  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final style = total ? t.headlineSmall : t.bodyMedium;
    final row = Row(children: [
      Expanded(child: Text(label, style: style)),
      Text(value,
          style: (total ? t.headlineSmall : t.titleMedium)!
              .copyWith(color: valueColor, fontFeatures: DT.tabular)),
    ]);
    if (!total) return row;
    return Container(
      padding: const EdgeInsets.only(top: DT.spaceSm),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: DT.divider))),
      child: row,
    );
  }
}

/// Thanh tiến độ tròn đầu (`h-2 rounded-full bg-surface-dim` + phần cam).
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.color = DT.accent});
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(DT.pill),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          minHeight: 8,
          color: color,
          backgroundColor: DT.surfaceDim,
        ),
      );
}
