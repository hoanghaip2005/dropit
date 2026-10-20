import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'buttons.dart';

/// Hộp xác nhận theo mockup: thẻ bo 24, tiêu đề, nội dung / gạch đầu dòng,
/// nút xác nhận (đen; đỏ nếu [destructive]) và nút hủy viền, xếp dọc.
/// [dark] = biến thể Lockdown (nền `#1C1C1E`, viền `#5C5C5C`, không hoạt ảnh).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  List<String> bullets = const [],
  required String confirmLabel,
  String cancelLabel = 'Hủy',
  bool destructive = false,
  bool dark = false,
  Key? confirmKey,
  Key? cancelKey,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: dark ? Colors.black.withValues(alpha: 0.8) : null,
    // Lockdown: không hoạt ảnh.
    builder: (ctx) => ConfirmDialog(
      title: title,
      message: message,
      bullets: bullets,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
      dark: dark,
      confirmKey: confirmKey,
      cancelKey: cancelKey,
    ),
  );
  return ok == true;
}

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    this.message,
    this.bullets = const [],
    required this.confirmLabel,
    this.cancelLabel = 'Hủy',
    this.destructive = false,
    this.dark = false,
    this.confirmKey,
    this.cancelKey,
  });
  final String title;
  final String? message;
  final List<String> bullets;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final bool dark;
  final Key? confirmKey;
  final Key? cancelKey;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final fg = dark ? Colors.white : DT.textPrimary;
    return Dialog(
      backgroundColor: dark ? DT.lockdownSurface : DT.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: DT.margin, vertical: DT.spaceLg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DT.radiusMd),
        side: dark ? const BorderSide(color: DT.lockdownButton) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(DT.spaceLg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: t.headlineSmall!.copyWith(color: fg)),
          if (message != null) ...[
            const SizedBox(height: DT.spaceSm),
            Text(message!, style: t.bodyMedium!.copyWith(color: dark ? Colors.white : DT.textSecondary)),
          ],
          for (final b in bullets)
            Padding(
              padding: const EdgeInsets.only(top: DT.spaceXs),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('•  ', style: t.bodyMedium!.copyWith(color: fg)),
                Expanded(child: Text(b, style: t.bodyMedium!.copyWith(color: fg))),
              ]),
            ),
          const SizedBox(height: DT.spaceLg),
          PrimaryButton(
            key: confirmKey,
            label: confirmLabel,
            compact: true,
            background: destructive ? DT.warning : (dark ? Colors.white : null),
            foreground: dark && !destructive ? DT.textPrimary : Colors.white,
            onPressed: () => Navigator.pop(context, true),
          ),
          const SizedBox(height: DT.spaceSm),
          dark
              ? OutlinedButton(
                  key: cancelKey,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: DT.lockdownTextSecondary),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(cancelLabel),
                )
              : SecondaryButton(key: cancelKey, label: cancelLabel, onPressed: () => Navigator.pop(context, false)),
        ]),
      ),
    );
  }
}
