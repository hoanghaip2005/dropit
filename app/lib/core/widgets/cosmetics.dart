import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/theme.dart';
import 'members.dart';
import 'cosmetic_effect.dart';

/// Artwork dùng chung cho Shop, xem thử và trang bị.
String? itemArtwork(String key) => const {
  'frame_leaf', 'frame_sunset', 'frame_galaxy',
  'frame_frost', 'frame_phoenix', 'frame_tidal', 'frame_cyber', 'frame_sakura', 'frame_royal',
  'title_ice_guardian', 'title_flame_keeper', 'title_ocean_soul', 'title_crowned',
  'title_night_owl', 'title_early_bird',
}.contains(key) ? 'assets/cosmetics/$key.png' : const {
  'frame_leaf', 'frame_sunset', 'frame_galaxy',
  'bg_library', 'bg_night_sea', 'bg_misty_forest',
  'title_night_owl', 'title_early_bird',
}.contains(key) ? 'assets/cosmetics/$key.svg' : null;

Widget _artwork(String path, {double? width, double? height, String? label}) => path.endsWith('.png')
  ? Image.asset(path, width: width, height: height, semanticLabel: label, excludeFromSemantics: label == null, filterQuality: FilterQuality.high)
  : SvgPicture.asset(path, width: width, height: height, semanticsLabel: label, excludeFromSemantics: label == null);

/// Màu trang bị: ổn định theo thiết kế, chỉ dùng băm cho món chưa có thiết kế.
Color previewColor(String key) {
  const palette = <String, Color>{
    'frame_default': DT.primary,
    'frame_leaf': Color(0xFF3E8967),
    'frame_sunset': Color(0xFFC88136),
    'frame_galaxy': Color(0xFF53546C),
    'frame_frost': Color(0xFF55BADD),
    'frame_phoenix': Color(0xFFDF633C),
    'frame_tidal': Color(0xFF40B7AD),
    'frame_cyber': Color(0xFF60C9ED),
    'frame_sakura': Color(0xFFE58DAA),
    'frame_royal': Color(0xFFE5B85E),
    'title_ice_guardian': Color(0xFF55BADD),
    'title_flame_keeper': Color(0xFFDF633C),
    'title_ocean_soul': Color(0xFF40B7AD),
    'title_crowned': Color(0xFFE5B85E),
    'bg_default': DT.surfaceHigh,
    'bg_library': Color(0xFFCAB59C),
    'bg_night_sea': Color(0xFF38576D),
    'bg_misty_forest': Color(0xFF75968A),
    'title_night_owl': Color(0xFF8170A8),
    'title_early_bird': Color(0xFFD9983D),
  };
  if (palette.containsKey(key)) return palette[key]!;
  var h = 0;
  for (final c in key.codeUnits) {
    h = (h * 31 + c) % 360;
  }
  return HSLColor.fromAHSL(1, h.toDouble(), 0.6, 0.55).toColor();
}

/// Dùng cùng renderer khi trưng bày và khi trang bị.
class ItemPreview extends StatelessWidget {
  const ItemPreview({super.key, required this.kind, required this.colorKey, this.label, this.size = 96, this.name});
  final String kind;
  final String colorKey;
  final String? label;
  final double size;
  final String? name;

  @override
  Widget build(BuildContext context) {
    if (kind == 'AVATAR_FRAME') {
      return Center(child: FramedAvatar(name: name ?? '', frameKey: colorKey, frameColor: previewColor(colorKey), size: size));
    }
    if (kind == 'BACKGROUND') {
      return SizedBox(height: size, width: double.infinity,
        child: CosmeticSurface(artKey: colorKey, child: const SizedBox.expand()));
    }
    if (size <= 48) {
      final art = itemArtwork(colorKey);
      return SizedBox(height: size, child: art == null
        ? Icon(Icons.workspace_premium, color: previewColor(colorKey))
        : _artwork(art, label: label ?? 'Huy hiệu danh hiệu'));
    }
    return SizedBox(height: size, child: Center(child: TitleAdornment(artKey: colorKey, label: label ?? 'Danh hiệu')));
  }
}

/// Huy hiệu thành tích: cùng artwork trên bộ sưu tập và hồ sơ.
class AchievementEmblem extends StatelessWidget {
  const AchievementEmblem({super.key, required this.code, this.size = 80, this.earned = true});
  final String code;
  final double size;
  final bool earned;
  @override
  Widget build(BuildContext context) {
    final known = RegExp(r'^(STREAK_(3|7|14|30|60|100)|SESS_(10|50|100|500)|HOURS_(10|50|100))$').hasMatch(code);
    final threshold = code.split('_').last;
    final ink = code.startsWith('STREAK') ? const Color(0xFFAC4A2B)
        : code.startsWith('SESS') ? const Color(0xFF276B58) : const Color(0xFF4F527D);
    final family = code.startsWith('STREAK') ? 'streak' : code.startsWith('SESS') ? 'sessions' : 'hours';
    final milestones = code.startsWith('STREAK') ? [3,7,14,30,60,100] : code.startsWith('SESS') ? [10,50,100,500] : [10,50,100];
    final tier = milestones.indexOf(int.tryParse(threshold) ?? 0);
    final medal = SizedBox(width: size, height: size, child: Stack(alignment: Alignment.center, children: [
      if (known) Positioned(top: 0, left: 0, right: 0, height: size * .85,
        child: Image.asset('assets/cosmetics/badge_$family.png', excludeFromSemantics: true, filterQuality: FilterQuality.high))
      else Icon(Icons.workspace_premium_outlined, size: size * .7, color: ink),
      if (known) Positioned(bottom: 0, child: Container(
        padding: EdgeInsets.symmetric(horizontal: size * .12, vertical: size * .025),
        decoration: BoxDecoration(color: Color.lerp(ink, Colors.white, .92), borderRadius: BorderRadius.circular(8), border: Border.all(color: ink.withValues(alpha: .3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (tier >= 2) ...[Icon(Icons.star_rounded, size: size * .14, color: ink), SizedBox(width: size * .025)],
          Text(threshold, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: size * .15, color: ink)),
          if (tier >= 4) ...[SizedBox(width: size * .025), Icon(Icons.star_rounded, size: size * .14, color: ink)],
        ]))),
    ]));
    return Semantics(label: '$code, ${earned ? 'đã đạt' : 'chưa đạt'}', child: earned ? medal
      : Opacity(opacity: .5, child: ColorFiltered(colorFilter: const ColorFilter.matrix([
        .2126,.7152,.0722,0,0, .2126,.7152,.0722,0,0, .2126,.7152,.0722,0,0, 0,0,0,1,0,
      ]), child: medal)));
  }
}

/// Phông cảnh nhẹ để tên, danh hiệu và avatar luôn đọc được.
class CosmeticSurface extends StatelessWidget {
  const CosmeticSurface({super.key, this.artKey, required this.child, this.padding = EdgeInsets.zero, this.radius = DT.radiusLg});
  final String? artKey;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final art = artKey == null ? null : itemArtwork(artKey!);
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: Stack(children: [
      Positioned.fill(child: art == null
        ? const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [DT.accentSoftBg, DT.background])))
        : SvgPicture.asset(art, fit: BoxFit.cover, excludeFromSemantics: true)),
      Padding(padding: padding, child: SizedBox(width: double.infinity, child: child)),
    ]));
  }
}

class TitleAdornment extends StatelessWidget {
  const TitleAdornment({super.key, required this.artKey, required this.label});
  final String artKey;
  final String label;
  @override
  Widget build(BuildContext context) {
    final night = artKey == 'title_night_owl';
    final expanded = const {'title_ice_guardian', 'title_flame_keeper', 'title_ocean_soul', 'title_crowned'}.contains(artKey);
    final art = itemArtwork(artKey);
    final metal = expanded ? previewColor(artKey) : night ? const Color(0xFFB5A1E2) : const Color(0xFFE9BA66);
    final ink = Color.lerp(metal, DT.textPrimary, .7)!;
    return CosmeticEffect(color: metal, child: Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 14, 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [DT.card, Color.lerp(metal, DT.card, .88)!]),
        borderRadius: BorderRadius.circular(12), border: Border.all(color: metal.withValues(alpha: .5)),
        boxShadow: DT.softShadow,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (art != null) Container(
          width: 40, height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [metal.withValues(alpha: .12), Colors.transparent])),
          child: _artwork(art, width: 36, height: 36))
        else Icon(Icons.workspace_premium, color: ink, size: 28),
        const SizedBox(width: 6),
        Flexible(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: context.text.labelMedium!.copyWith(color: ink, fontWeight: FontWeight.w700, letterSpacing: .1))),
      ]),
    ));
  }
}

/// Avatar thật bên dưới, artwork trong suốt phủ lên trên.
class FramedAvatar extends StatelessWidget {
  const FramedAvatar({super.key, required this.name, this.imageUrl, this.frameKey, this.frameColor, this.size = 104});
  final String name;
  final String? imageUrl;
  final String? frameKey;
  final Color? frameColor;
  final double size;
  @override
  Widget build(BuildContext context) {
    final art = frameKey == null ? null : itemArtwork(frameKey!);
    final inset = art == null ? (frameColor == null ? 3.0 : size * .07)
      : size * (frameKey == 'frame_royal' ? .30 : art.endsWith('.png') ? .19 : .145);
    final inner = size - inset * 2;
    final avatar = SizedBox(width: size, height: size, child: Stack(alignment: Alignment.center, children: [
      if (art == null) Container(decoration: BoxDecoration(shape: BoxShape.circle, color: frameColor ?? DT.primary)),
      SizedBox(width: inner, height: inner, child: ClipOval(child: imageUrl == null
        ? InitialAvatar(name, size: inner)
        : Image.network(imageUrl!, width: inner, height: inner, fit: BoxFit.cover,
            errorBuilder: (_, _, _) => InitialAvatar(name, size: inner)))),
      if (art != null) Positioned.fill(child: art.endsWith('.png')
        ? Image.asset(art, excludeFromSemantics: true, filterQuality: FilterQuality.high)
        : SvgPicture.asset(art, excludeFromSemantics: true)),
    ]));
    return art == null ? avatar : CosmeticEffect(color: previewColor(frameKey!), circular: true, child: avatar);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: DT.accent),
              const SizedBox(width: DT.spaceSm),
              Expanded(
                child: Text('Mục đích sử dụng báo cáo', style: t.labelMedium!.copyWith(color: DT.accent)),
              ),
            ],
          ),
          const SizedBox(height: DT.spaceSm),
          Text(
            has ? purpose! : 'Chưa khai báo mục đích — báo cáo chỉ mang tính tham khảo.',
            style: t.bodyLarge!.copyWith(color: DT.textPrimary),
          ),
          const SizedBox(height: DT.spaceSm),
          Text(
            ownerName == null ? 'Do chủ nhóm khai báo lúc tạo nhóm.' : 'Do chủ nhóm $ownerName khai báo lúc tạo nhóm.',
            style: t.bodySmall,
          ),
          if (generatedAt != null) Text('Mục đích tại thời điểm tạo báo cáo $generatedAt.', style: t.bodySmall),
          Text(
            'DropIt! không quyết định việc báo cáo được dùng để đánh giá hay kỷ luật; đó là quyết định của nơi bạn làm việc.',
            style: t.bodySmall,
          ),
        ],
      ),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DT.radiusCard),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DT.radiusCard),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DT.radiusCard),
                  borderSide: BorderSide(color: over ? DT.warning : DT.primary),
                ),
              ),
            ),
            const SizedBox(height: DT.spaceXs),
            Row(
              children: [
                Expanded(
                  child: atLimit && overLimitText != null
                      ? Text(overLimitText!, style: t.bodySmall!.copyWith(color: DT.warning))
                      : const SizedBox.shrink(),
                ),
                Text(
                  '${fmt(n)}/${fmt(max)} ký tự',
                  key: counterKey,
                  style: t.bodySmall!.copyWith(color: over ? DT.warning : DT.textSecondary, fontFeatures: DT.tabular),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
