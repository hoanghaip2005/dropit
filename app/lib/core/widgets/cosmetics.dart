import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import 'members.dart';

/// Màu giữ chỗ của món Shop — cùng công thức với ảnh SVG server (`/assets/shop/{key}`:
/// hue = băm chuỗi khóa, `hsl(h,60%,55%)`). App tự vẽ để không cần thư viện SVG.
Color previewColor(String key) {
  var h = 0;
  for (final c in key.codeUnits) {
    h = (h * 31 + c) % 360;
  }
  return HSLColor.fromAHSL(1, h.toDouble(), 0.6, 0.55).toColor();
}

/// Ảnh xem trước món: khung = vòng màu quanh avatar; hình nền = dải chuyển màu; danh hiệu = viên thuốc chữ.
/// Chỉ trang trí, không thể hiện độ hiếm (BR-121).
class ItemPreview extends StatelessWidget {
  const ItemPreview({super.key, required this.kind, required this.colorKey, this.label, this.size = 96, this.name});
  final String kind;
  final String colorKey;
  final String? label;
  final double size;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final c = previewColor(colorKey);
    switch (kind) {
      case 'AVATAR_FRAME':
        return FramedAvatar(name: name ?? '', frameColor: c, size: size);
      case 'BACKGROUND':
        return Container(
          width: double.infinity,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DT.radiusCard),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c, Color.lerp(c, Colors.white, 0.55)!],
            ),
          ),
          child: Icon(Icons.wallpaper, color: Colors.white.withValues(alpha: 0.9), size: size * 0.32),
        );
      default:
        return SizedBox(
          height: size,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(DT.pill)),
              child: Text(label ?? 'Danh hiệu',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge!.copyWith(color: Colors.white)),
            ),
          ),
        );
    }
  }
}

/// Avatar có khung trang bị (vòng màu) và ảnh tải lên (nếu có); không có ảnh → chữ cái đầu.
class FramedAvatar extends StatelessWidget {
  const FramedAvatar({super.key, required this.name, this.imageUrl, this.frameColor, this.size = 104});
  final String name;
  final String? imageUrl;

  /// null = khung mặc định (viền đen mảnh).
  final Color? frameColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ring = frameColor == null ? 3.0 : size * 0.07;
    final inner = size - ring * 2;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ring),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: frameColor ?? DT.primary,
        gradient: frameColor == null
            ? null
            : SweepGradient(colors: [frameColor!, Color.lerp(frameColor, Colors.white, 0.5)!, frameColor!]),
        boxShadow: DT.cardShadow,
      ),
      child: imageUrl == null
          ? InitialAvatar(name, size: inner)
          : ClipOval(
              child: Image.network(
                imageUrl!,
                width: inner,
                height: inner,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => InitialAvatar(name, size: inner),
              ),
            ),
    );
  }
}

/// V-35 Khối "Mục đích sử dụng báo cáo" — luôn đặt ĐẦU màn báo cáo, không ẩn được.
class PurposeCard extends StatelessWidget {
  const PurposeCard({super.key, required this.purpose, this.generatedAt, this.ownerName});
  final String? purpose;
  final String? generatedAt;
  final String? ownerName;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final has = purpose != null && purpose!.trim().isNotEmpty;
    return Container(
      key: const Key('purposeCard'),
      width: double.infinity,
      padding: const EdgeInsets.all(DT.spaceMd),
      decoration: BoxDecoration(color: DT.accentSoftBg, borderRadius: BorderRadius.circular(DT.radiusMd)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.info_outline, size: 18, color: DT.accent),
          const SizedBox(width: DT.spaceSm),
          Expanded(child: Text('Mục đích sử dụng báo cáo', style: t.labelMedium!.copyWith(color: DT.accent))),
        ]),
        const SizedBox(height: DT.spaceSm),
        Text(has ? purpose! : 'Chưa khai báo mục đích — báo cáo chỉ mang tính tham khảo.',
            style: t.bodyLarge!.copyWith(color: DT.textPrimary)),
        const SizedBox(height: DT.spaceSm),
        Text(
          ownerName == null
              ? 'Do chủ nhóm khai báo lúc tạo nhóm.'
              : 'Do chủ nhóm $ownerName khai báo lúc tạo nhóm.',
          style: t.bodySmall,
        ),
        if (generatedAt != null) Text('Mục đích tại thời điểm tạo báo cáo $generatedAt.', style: t.bodySmall),
        Text(
          'DropIt! không quyết định việc báo cáo được dùng để đánh giá hay kỷ luật; đó là quyết định của nơi bạn làm việc.',
          style: t.bodySmall,
        ),
      ]),
    );
  }
}

/// Ô nhập nhiều dòng trong thẻ có bộ đếm "n/max ký tự" (nhật ký, giải trình, khiếu nại).
/// Vượt giới hạn: chữ đỏ + [overLimitText]; không tự cắt để người dùng thấy rõ.
class CountedTextArea extends StatelessWidget {
  const CountedTextArea({
    super.key,
    required this.controller,
    required this.max,
    this.hint,
    this.minLines = 6,
    this.overLimitText,
    this.enabled = true,
    this.fieldKey,
    this.counterKey,
    this.enforce = true,
  });
  final TextEditingController controller;
  final int max;
  final String? hint;
  final int minLines;
  final String? overLimitText;
  final bool enabled;
  final Key? fieldKey;
  final Key? counterKey;

  /// Chặn gõ quá [max] ký tự (dán dài cũng bị cắt ở [max]).
  final bool enforce;

  static String fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, v, _) {
        final n = v.text.characters.length;
        final over = n > max;
        final atLimit = n >= max;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            key: fieldKey,
            controller: controller,
            enabled: enabled,
            inputFormatters: enforce ? [LengthLimitingTextInputFormatter(max)] : null,
            minLines: minLines,
            maxLines: minLines + 8,
            keyboardType: TextInputType.multiline,
            style: t.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: DT.surfaceHigh,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(DT.radiusCard), borderSide: BorderSide.none),
              enabledBorder:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(DT.radiusCard), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DT.radiusCard),
                  borderSide: BorderSide(color: over ? DT.warning : DT.primary)),
            ),
          ),
          const SizedBox(height: DT.spaceXs),
          Row(children: [
            Expanded(
              child: atLimit && overLimitText != null
                  ? Text(overLimitText!, style: t.bodySmall!.copyWith(color: DT.warning))
                  : const SizedBox.shrink(),
            ),
            Text('${fmt(n)}/${fmt(max)} ký tự',
                key: counterKey,
                style: t.bodySmall!.copyWith(color: over ? DT.warning : DT.textSecondary, fontFeatures: DT.tabular)),
          ]),
        ]);
      },
    );
  }
}
