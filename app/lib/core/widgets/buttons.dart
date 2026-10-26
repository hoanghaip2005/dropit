import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Nút chính nền cam `#FF7A00`, chữ đen `#141414` (7.05:1), cao 56 (48 khi [compact]).
/// [trailingIcon] mặc định không có; mockup thường dùng `Icons.arrow_forward`.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.compact = false,
    this.background,
    this.foreground,
  });

  /// Nút nhấn cam (Coins / hành động nhấn). Không bao giờ đỏ.
  const PrimaryButton.accent({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.compact = false,
  })  : background = DT.primary,
        foreground = DT.onPrimary;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool loading;
  final bool compact;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? (background == null || background == DT.primary ? DT.onPrimary : Colors.white);
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size.fromHeight(compact ? DT.buttonHeightCompact : DT.buttonHeight),
        backgroundColor: background,
        foregroundColor: fg,
        disabledBackgroundColor: loading ? (background ?? Theme.of(context).colorScheme.primary) : (context.ownerStyle ? OwnerStyle.line : DT.surfaceDim),
        disabledForegroundColor: loading ? fg : DT.textSecondary,
      ),
      child: _ButtonContent(label: label, icon: icon, trailingIcon: trailingIcon, loading: loading, color: fg),
    );
  }
}

/// Nút phụ: viên thuốc trắng, viền `#E5E7EB`, chữ đen (cao 48).
/// [destructive] đổi viền + chữ sang đỏ cảnh báo (chỉ cho hành động thoát/rời).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.destructive = false,
    this.tall = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool loading;
  final bool destructive;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final fg = destructive ? DT.warning : (context.ownerStyle ? OwnerStyle.ink : DT.accent);
    return OutlinedButton(
      onPressed: loading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        minimumSize: Size.fromHeight(tall ? DT.buttonHeight : DT.buttonHeightCompact),
        side: BorderSide(color: destructive ? DT.warning : (context.ownerStyle ? OwnerStyle.line : DT.outline)),
      ),
      child: _ButtonContent(label: label, icon: icon, trailingIcon: trailingIcon, loading: loading, color: fg),
    );
  }
}

/// Liên kết chữ cam (`text-secondary font-label-lg`), vd. "Xem chi tiết phiên".
class LinkButton extends StatelessWidget {
  const LinkButton({super.key, required this.label, required this.onPressed, this.color = DT.accent});
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label),
      );
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.label, this.icon, this.trailingIcon, required this.loading, required this.color});
  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool loading;
  final Color color;
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: color));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
      Flexible(child: Text(label, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
      if (trailingIcon != null) ...[const SizedBox(width: 8), Icon(trailingIcon, size: 20)],
    ]);
  }
}
