import 'package:flutter/material.dart';

/// Token thiết kế từ `mockup/dropit/DESIGN.md` (đã sửa tương phản) và lớp
/// Tailwind của các màn `mockup/*/code.html`.
///
/// Dùng `DT.xxx` cho hằng số; trong widget có thể đọc `context.dropit`
/// (ThemeExtension [DropItColors] ở `app_theme.dart`).
class DT {
  DT._();

  // ---- Nền / bề mặt
  static const background = Color(0xFFF4F5F7); // canvas off-white
  static const card = Color(0xFFFFFFFF);
  static const surfaceHigh = Color(0xFFF0F1F4); // ô nhập / chip xám nhạt trong thẻ
  static const surfaceDim = Color(0xFFEBECEF); // rãnh thanh tiến độ, chấm trang
  static const skeleton = Color(0xFFEBE7E7);

  // ---- Chữ
  static const primary = Color(0xFF1C1C1E); // đen nhám: nút chính, thanh điều hướng
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF6C6C70);

  // ---- Nhấn / chức năng
  static const accent = Color(0xFFB02F00); // Coins, chữ/biểu tượng nhấn
  static const accentSoftBg = Color(0xFFFFF1EC);
  static const accentDecor = Color(0xFFFF5722); // chỉ trang trí, không làm chữ
  static const success = Color(0xFF1B7F3B);
  static const successSoftBg = Color(0xFFE8F9ED);
  static const successDecor = Color(0xFF34C759);
  static const warning = Color(0xFFBA1A1A); // chỉ lỗi / cảnh báo thoát
  static const warningSoftBg = Color(0xFFFFDAD6);
  static const onWarningSoft = Color(0xFF93000A);

  // ---- Viền
  static const outline = Color(0xFFE5E7EB);
  static const outlineVariant = Color(0xFFC7C6CA);
  static const divider = Color(0xFFF0F0F2);

  // ---- Lockdown (đen tĩnh)
  static const lockdownBg = Color(0xFF000000);
  static const lockdownSurface = Color(0xFF1C1C1E);
  static const lockdownButton = Color(0xFF5C5C5C);
  static const lockdownTextSecondary = Color(0xFFA1A1A6);

  // ---- Bo góc (rounded: sm 8, DEFAULT 16, md 24, lg 32, full)
  static const radiusSm = 8.0;
  static const radius = 16.0;
  static const radiusMd = 24.0;
  static const radiusLg = 32.0;
  static const radiusCard = radius; // thẻ chuẩn mockup (`rounded-DEFAULT`)
  static const pill = 999.0;

  // ---- Khoảng cách (8px base)
  static const spaceXs = 4.0;
  static const spaceSm = 8.0;
  static const spaceMd = 16.0;
  static const spaceLg = 24.0;
  static const spaceXl = 32.0;
  static const margin = 16.0; // `px-margin` mobile
  static const gutter = 16.0;

  // ---- Kích thước
  static const buttonHeight = 56.0;
  static const buttonHeightCompact = 48.0;
  static const inputHeight = 52.0;
  static const navHeight = 64.0;

  /// Khoảng đáy để nội dung cuộn không bị thanh điều hướng nổi che.
  static const navClearance = 104.0;

  // ---- Bóng
  /// Thẻ: `0 4px 20px -2px rgba(17,17,17,.05)`.
  static const cardShadow = [
    BoxShadow(color: Color(0x0D111111), blurRadius: 20, spreadRadius: -2, offset: Offset(0, 4)),
  ];

  /// Nút tròn, ô nhập, chip trắng (`shadow-sm`).
  static const softShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  /// Thanh điều hướng nổi: `0 12px 32px -4px rgba(17,17,17,.30)`.
  static const navShadow = [
    BoxShadow(color: Color(0x4D111111), blurRadius: 32, spreadRadius: -4, offset: Offset(0, 12)),
  ];

  /// "Card elevation" lớn của DESIGN.md (thẻ hero).
  static const heroShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 40, offset: Offset(0, 20)),
  ];

  static const tabular = [FontFeature.tabularFigures()];
}
