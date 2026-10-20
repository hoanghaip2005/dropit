import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'cards.dart';

/// Avatar chữ cái đầu (`rounded-full bg-secondary-container`). [dark] = tròn đen biểu tượng người (header).
class InitialAvatar extends StatelessWidget {
  const InitialAvatar(this.name, {super.key, this.size = 40, this.dark = false});
  final String name;
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: dark ? DT.primary : DT.accentSoftBg, shape: BoxShape.circle),
      child: dark
          ? Icon(Icons.person, size: size * 0.5, color: Colors.white)
          : Text(initial,
              style: context.text.headlineSmall!
                  .copyWith(color: DT.accent, fontSize: size * 0.42, height: 1)),
    );
  }
}

/// Dòng thành viên: avatar + tên + mô tả + huy hiệu/thao tác phải. Dùng trong thẻ (có gạch ngăn).
class MemberTile extends StatelessWidget {
  const MemberTile(
      {super.key, required this.name, this.subtitle, this.trailing, this.onTap, this.divider = true, this.leading});
  final String name;

  /// Thay avatar chữ cái (vd. [FramedAvatar] có khung đang trang bị — AC-07.04.1).
  final Widget? leading;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool divider;

  @override
  Widget build(BuildContext context) => ListRow(
        leading: leading ?? InitialAvatar(name),
        title: name,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        divider: divider,
      );
}
