import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Nút tròn trắng 40px có bóng nhỏ (quay lại / đóng / thông báo) — mockup `w-10 h-10 rounded-full shadow-sm`.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 40,
    this.background = DT.card,
    this.foreground = DT.textPrimary,
    this.badge = false,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color background;
  final Color foreground;

  /// Chấm cam nhỏ ở góc (vd. có thông báo chưa đọc).
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: background,
      shape: const CircleBorder(),
      shadowColor: Colors.black26,
      elevation: background == Colors.transparent ? 0 : 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(alignment: Alignment.center, children: [
            Icon(icon, size: 22, color: foreground),
            if (badge)
              Positioned(
                right: size * 0.22,
                top: size * 0.22,
                child: Container(
                    width: 8, height: 8, decoration: const BoxDecoration(color: DT.accent, shape: BoxShape.circle)),
              ),
          ]),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

enum HeaderLeading { back, close, none }

/// Header màn. Ba kiểu theo mockup:
/// - [AppHeader.back]: nút tròn trái, tiêu đề giữa (sign_in_login, session_lobby, c_03, schedule_focus…).
/// - [AppHeader.large]: dòng phụ nhỏ + tiêu đề lớn trái, phần phải tùy ý (employee_home).
/// - [AppHeader.brand]: biểu tượng tròn cam + nhãn vai trò + tiêu đề, avatar phải (manager_dashboard, t_02, the_shop).
class AppHeader extends StatelessWidget {
  const AppHeader.back({
    super.key,
    required this.title,
    this.leading = HeaderLeading.back,
    this.onLeading,
    this.trailing,
  })  : caption = null,
        style = HeaderStyle.back,
        icon = null;

  const AppHeader.large({super.key, required this.title, this.caption, this.trailing})
      : leading = HeaderLeading.none,
        onLeading = null,
        style = HeaderStyle.large,
        icon = null;

  const AppHeader.brand({
    super.key,
    required this.title,
    this.caption,
    this.trailing,
    this.icon = Icons.timer_outlined,
    this.leading = HeaderLeading.none,
    this.onLeading,
  }) : style = HeaderStyle.brand;

  final String title;
  final String? caption;
  final Widget? trailing;
  final HeaderLeading leading;
  final VoidCallback? onLeading;
  final IconData? icon;
  final HeaderStyle style;

  Widget? _leadingButton(BuildContext context) {
    if (leading == HeaderLeading.none) return null;
    final canPop = Navigator.of(context).canPop();
    if (onLeading == null && !canPop) return null;
    return CircleIconButton(
      icon: leading == HeaderLeading.close ? Icons.close : Icons.arrow_back,
      tooltip: leading == HeaderLeading.close ? 'Đóng' : 'Quay lại',
      onPressed: onLeading ?? () => Navigator.of(context).maybePop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    if (context.ownerStyle && style == HeaderStyle.brand && leading == HeaderLeading.none) {
      return AppHeader.large(title: title, caption: caption ?? 'DropIt! · Chủ nhóm', trailing: trailing);
    }
    switch (style) {
      case HeaderStyle.back:
        final lead = _leadingButton(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(DT.margin, DT.spaceSm, DT.margin, DT.spaceSm),
          child: SizedBox(
            height: 44,
            child: Row(children: [
              SizedBox(width: 44, child: lead == null ? null : Align(alignment: Alignment.centerLeft, child: lead)),
              Expanded(
                child: Text(title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.headlineSmall),
              ),
              SizedBox(
                  width: 44, child: trailing == null ? null : Align(alignment: Alignment.centerRight, child: trailing)),
            ]),
          ),
        );
      case HeaderStyle.large:
        return Padding(
          padding: const EdgeInsets.fromLTRB(DT.margin, DT.spaceSm, DT.margin, DT.spaceSm),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (caption != null) Text(caption!, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(title, style: t.headlineMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),
            if (trailing != null) ...[const SizedBox(width: DT.spaceSm), trailing!],
          ]),
        );
      case HeaderStyle.brand:
        final lead = _leadingButton(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(DT.margin, DT.spaceSm, DT.margin, DT.spaceSm),
          child: SizedBox(
            height: 48,
            child: Row(children: [
              lead ??
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset('assets/brand/icon.png', width: 36, height: 36, semanticLabel: 'DropIt!'),
                  ),
              const SizedBox(width: DT.spaceSm),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (caption != null)
                    Text(caption!, style: t.labelSmall!.copyWith(color: DT.textSecondary), maxLines: 1),
                  Text(title, style: t.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              ?trailing,
            ]),
          ),
        );
    }
  }
}

/// Kiểu header (xem [AppHeader]).
enum HeaderStyle { back, large, brand }

/// Khung màn chuẩn: nền canvas, header, nội dung cuộn padding 16 / khoảng cách 16,
/// [footer] dính đáy (nút chính kiểu `mt-auto`). Tự chừa chỗ cho thanh điều hướng nổi.
///
/// Truyền [children] (ListView do khung tạo, có kéo-làm-mới nếu có [onRefresh])
/// hoặc [body] (tự quản lý cuộn).
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.header,
    this.children,
    this.body,
    this.footer,
    this.onRefresh,
    this.gap = DT.spaceMd,
    this.padding = const EdgeInsets.fromLTRB(DT.margin, DT.spaceSm, DT.margin, DT.spaceLg),
    this.backgroundColor = DT.background,
  }) : assert(children != null || body != null);

  final Widget? header;
  final List<Widget>? children;
  final Widget? body;
  final Widget? footer;
  final Future<void> Function()? onRefresh;
  final double gap;
  final EdgeInsets padding;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    Widget content;
    if (children != null) {
      final items = <Widget>[];
      for (var i = 0; i < children!.length; i++) {
        if (i > 0) items.add(SizedBox(height: gap));
        items.add(children![i]);
      }
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding.copyWith(bottom: padding.bottom + (footer == null ? bottomInset : 0)),
        children: items,
      );
      if (onRefresh != null) {
        content = RefreshIndicator(color: DT.primary, onRefresh: onRefresh!, child: content);
      }
    } else {
      content = body!;
    }
    return Scaffold(
      backgroundColor: context.ownerStyle && backgroundColor == DT.background ? OwnerStyle.canvas : backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          ?header,
          Expanded(child: content),
          if (footer != null)
            Padding(
              padding: EdgeInsets.fromLTRB(DT.margin, DT.spaceSm, DT.margin, DT.spaceMd + bottomInset),
              child: footer,
            ),
        ]),
      ),
    );
  }
}

class NavItem {
  const NavItem({required this.path, required this.icon, required this.activeIcon, required this.label});
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Navigation nổi dùng chung: nền trắng, mục chọn cam nhạt và icon cam.
/// [light] giữ tương thích với các shell; cả hai vai trò dùng cùng visual system.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav(
      {super.key, required this.items, required this.currentIndex, required this.onTap, this.light = false});
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool light;

  Color _fg(bool on) => light ? (on ? DT.accent : DT.textSecondary) : (on ? DT.accentDecor : const Color(0xFFA1A1A6));

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: DT.spaceMd),
      child: Center(
        heightFactor: 1,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.symmetric(horizontal: DT.margin),
          height: DT.navHeight,
          padding: const EdgeInsets.symmetric(horizontal: DT.spaceSm),
          decoration: BoxDecoration(
            color: light ? DT.card : const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(DT.pill),
            boxShadow: DT.navShadow,
          ),
          child: Row(children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: Semantics(
                  selected: i == currentIndex,
                  button: true,
                  label: items[i].label,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(DT.pill),
                    onTap: () => onTap(i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                      decoration: BoxDecoration(
                        color: light && i == currentIndex
                            ? DT.accentSoftBg
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(DT.pill),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(i == currentIndex ? items[i].activeIcon : items[i].icon,
                            size: 22, color: _fg(i == currentIndex)),
                        const SizedBox(height: 2),
                        ExcludeSemantics(
                          child: Text(items[i].label,
                              maxLines: 1,
                              style: t.labelSmall!.copyWith(
                                color: _fg(i == currentIndex),
                                fontWeight: i == currentIndex ? FontWeight.w600 : FontWeight.w500,
                              )),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Danh sách nội dung chuẩn (padding 16, khoảng cách 16, chừa thanh điều hướng, kéo-làm-mới)
/// — dùng làm `body` của [AppScaffold], nhất là trong `AsyncBody.builder`.
class PageList extends StatelessWidget {
  const PageList({super.key, required this.children, this.onRefresh, this.controller});
  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  /// Theo dõi cuộn (vd. màn đồng ý: chỉ bật nút sau khi cuộn hết — AC-01.05.5).
  final ScrollController? controller;
  @override
  Widget build(BuildContext context) {
    final list = ListView.separated(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
          DT.margin, DT.spaceSm, DT.margin, DT.spaceLg + MediaQuery.paddingOf(context).bottom),
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: DT.spaceMd),
      itemBuilder: (_, i) => children[i],
    );
    return onRefresh == null ? list : RefreshIndicator(color: DT.primary, onRefresh: onRefresh!, child: list);
  }
}

