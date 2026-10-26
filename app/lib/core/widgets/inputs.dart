import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';

/// Ô nhập viên thuốc trắng có biểu tượng trái (sign_in_login: `rounded-full h-[52px] shadow-sm`).
/// [errorText] hiện chữ đỏ nhỏ bên dưới.
class PillTextField extends StatelessWidget {
  const PillTextField({
    super.key,
    this.controller,
    this.hint,
    this.icon,
    this.trailing,
    this.errorText,
    this.keyboardType,
    this.obscure = false,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLength,
    this.style,
    this.fieldKey,
  });
  final TextEditingController? controller;
  final String? hint;
  final IconData? icon;
  final Widget? trailing;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscure;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextStyle? style;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Container(
        height: DT.inputHeight,
        padding: const EdgeInsets.symmetric(horizontal: DT.spaceMd),
        decoration: BoxDecoration(
          color: DT.card,
          borderRadius: BorderRadius.circular(DT.radius),
          boxShadow: context.ownerStyle ? null : DT.softShadow,
          border: Border.all(color: errorText != null ? DT.warning : (context.ownerStyle ? OwnerStyle.line : DT.outline)),
        ),
        child: Row(children: [
          if (icon != null) ...[Icon(icon, color: DT.textSecondary), const SizedBox(width: DT.spaceSm + 4)],
          Expanded(
            child: TextField(
              key: fieldKey,
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscure,
              onSubmitted: onSubmitted,
              textCapitalization: textCapitalization,
              inputFormatters: inputFormatters,
              maxLength: maxLength,
              style: style ?? t.bodyLarge,
              decoration: InputDecoration(
                hintText: hint,
                filled: false,
                counterText: '',
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          ?trailing,
        ]),
      ),
      if (errorText != null)
        Padding(
          padding: const EdgeInsets.only(top: 6, left: DT.spaceMd),
          child: Text(errorText!, style: t.bodySmall!.copyWith(color: DT.warning)),
        ),
    ]);
  }
}

/// Nhãn trường trong thẻ (`font-label-md text-on-surface-variant`).
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: context.text.labelLarge!.copyWith(color: DT.textSecondary));
}

/// Kiểu InputDecoration cho ô nhập trong thẻ trắng (nền xám nhạt `bg-surface-container-high`).
InputDecoration inCardInput({String? label, String? hint, String? helper, String? error}) => InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperMaxLines: 3,
      errorText: error,
      fillColor: DT.surfaceHigh,
    );
