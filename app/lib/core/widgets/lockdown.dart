import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Thành phần cho bối cảnh tối Lockdown — tĩnh tuyệt đối: không hoạt ảnh,
/// không glow/pulse, chỉ số đổi mỗi giây. Viền ≥3:1 (`#5C5C5C`).

const lockWhite = TextStyle(color: Colors.white);
const lockGrey = TextStyle(color: DT.lockdownTextSecondary, fontSize: 14);

/// Khung thẻ tối (nền `#1C1C1E`, viền `#5C5C5C`, bo 24).
BoxDecoration lockPanelDecoration() => BoxDecoration(
      color: DT.lockdownSurface,
      border: Border.all(color: DT.lockdownButton),
      borderRadius: BorderRadius.circular(DT.radiusMd),
    );

/// Nút Lockdown `#5C5C5C` chữ trắng, viền xám nhạt, cao 56.
class LockdownButton extends StatelessWidget {
  const LockdownButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: DT.buttonHeight,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: DT.lockdownButton,
            foregroundColor: Colors.white,
            disabledBackgroundColor: DT.lockdownButton.withValues(alpha: 0.5),
            side: const BorderSide(color: DT.lockdownTextSecondary),
            splashFactory: NoSplash.splashFactory,
            animationDuration: Duration.zero,
          ),
          onPressed: onPressed,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 6)],
            Text(label),
          ]),
        ),
      );
}

/// Chỉ báo "Phiên đang được ghi" (viền xám, chấm đỏ tĩnh).
class RecordingPill extends StatelessWidget {
  const RecordingPill({super.key, this.label = 'Phiên đang được ghi', this.textKey});
  final String label;
  final Key? textKey;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: DT.lockdownTextSecondary),
          borderRadius: BorderRadius.circular(DT.pill),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: DT.warning, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, key: textKey, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ]),
      );
}

/// Vòng đếm ngược TĨNH (n_07): viền tròn dày, số lớn ở giữa, nhãn nhỏ. Không vẽ cung chạy.
class CountdownRing extends StatelessWidget {
  const CountdownRing({
    super.key,
    required this.value,
    this.label,
    this.size = 160,
    this.ringColor = DT.warning,
    this.textColor = Colors.white,
    this.labelColor = DT.lockdownTextSecondary,
    this.valueKey,
  });
  final String value;
  final String? label;
  final double size;
  final Color ringColor;
  final Color textColor;
  final Color labelColor;
  final Key? valueKey;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ringColor, width: 8)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value,
              key: valueKey,
              style: TextStyle(
                  color: textColor, fontSize: size * 0.4, fontWeight: FontWeight.w700, height: 1, fontFeatures: DT.tabular)),
          if (label != null) Text(label!, style: TextStyle(color: labelColor, fontSize: 14, fontWeight: FontWeight.w500)),
        ]),
      );
}

/// Chip tối (`bg-[#333] rounded-full`) dùng trong màn đen, vd. thông tin phụ.
class LockChip extends StatelessWidget {
  const LockChip(this.text, {super.key, this.icon});
  final String text;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: DT.spaceMd, vertical: 6),
        decoration: BoxDecoration(color: DT.lockdownSurface, borderRadius: BorderRadius.circular(DT.pill)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 18, color: Colors.white), const SizedBox(width: 6)],
          Flexible(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
      );
}
