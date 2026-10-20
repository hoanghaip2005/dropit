import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api.dart';
import '../theme/theme.dart';
import 'buttons.dart';
import 'layout.dart';

/// Khung xương tĩnh khi đang tải (không hiệu ứng nhấp nháy).
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 3});
  final int count;
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(DT.margin, DT.spaceSm, DT.margin, DT.spaceLg),
        children: [
          for (var i = 0; i < count; i++)
            Container(
              key: ValueKey('skeleton$i'),
              height: i == 0 ? 140 : 88,
              margin: const EdgeInsets.only(bottom: DT.spaceMd),
              decoration: BoxDecoration(color: DT.skeleton, borderRadius: BorderRadius.circular(DT.radiusCard)),
            ),
        ],
      );
}

/// Trạng thái rỗng / thông điệp giữa màn: vòng tròn biểu tượng, tiêu đề, mô tả, nút.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
    this.onAction,
    this.secondaryAction,
    this.onSecondaryAction,
    this.tone = StateTone.neutral,
  });
  final IconData icon;
  final String title;
  final String? body;
  final String? action;
  final VoidCallback? onAction;
  final String? secondaryAction;
  final VoidCallback? onSecondaryAction;
  final StateTone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final (bg, fg) = switch (tone) {
      StateTone.neutral => (DT.card, DT.textSecondary),
      StateTone.accent => (DT.accentSoftBg, DT.accent),
      StateTone.success => (DT.successSoftBg, DT.success),
      StateTone.danger => (DT.warningSoftBg, DT.warning),
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DT.spaceLg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle, boxShadow: tone == StateTone.neutral ? DT.cardShadow : null),
              child: Icon(icon, size: 36, color: fg),
            ),
            const SizedBox(height: DT.spaceMd),
            Text(title, textAlign: TextAlign.center, style: t.headlineSmall),
            if (body != null) ...[
              const SizedBox(height: DT.spaceSm),
              Text(body!, textAlign: TextAlign.center, style: t.bodyMedium!.copyWith(color: DT.textSecondary)),
            ],
            if (action != null) ...[
              const SizedBox(height: DT.spaceLg),
              PrimaryButton(label: action!, onPressed: onAction, compact: true),
            ],
            if (secondaryAction != null) ...[
              const SizedBox(height: DT.spaceSm),
              SecondaryButton(label: secondaryAction!, onPressed: onSecondaryAction),
            ],
          ]),
        ),
      ),
    );
  }
}

enum StateTone { neutral, accent, success, danger }

/// Tên gọi khác cho trạng thái rỗng.
typedef EmptyState = StateMessage;

/// Lỗi tải dữ liệu / mất mạng + "Thử lại".
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, required this.onRetry, this.title});
  final Object error;
  final VoidCallback onRetry;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final e = ApiError.from(error);
    if (e.offline) {
      return StateMessage(
        icon: Icons.wifi_off,
        title: 'Không có kết nối mạng',
        body: 'Kiểm tra mạng rồi thử lại.',
        action: 'Thử lại',
        onAction: onRetry,
      );
    }
    return StateMessage(
      icon: Icons.error_outline,
      tone: StateTone.danger,
      title: title ?? 'Chưa tải được dữ liệu',
      body: e.message,
      action: 'Thử lại',
      onAction: onRetry,
    );
  }
}

/// Bọc AsyncValue: tải / lỗi / mất mạng / rỗng / có dữ liệu.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.value,
    required this.onRetry,
    required this.builder,
    this.isEmpty,
    this.empty,
    this.errorTitle,
  });
  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final String? errorTitle;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorState(error: e, onRetry: onRetry, title: errorTitle),
      data: (d) {
        if (isEmpty != null && isEmpty!(d) && empty != null) return empty!;
        return builder(d);
      },
    );
  }
}

enum BannerTone { info, accent, success, danger }

/// Banner thông báo trong luồng nội dung (cảnh báo, gợi ý, lỗi biểu mẫu).
class AppBanner extends StatelessWidget {
  const AppBanner({super.key, required this.text, this.title, this.tone = BannerTone.info, this.icon, this.action, this.onAction});
  final String text;
  final String? title;
  final BannerTone tone;
  final IconData? icon;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final (bg, fg, ic) = switch (tone) {
      BannerTone.info => (DT.card, DT.textSecondary, Icons.info_outline),
      BannerTone.accent => (DT.accentSoftBg, DT.accent, Icons.campaign_outlined),
      BannerTone.success => (DT.successSoftBg, DT.success, Icons.check_circle_outline),
      BannerTone.danger => (DT.warningSoftBg, DT.warning, Icons.error_outline),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DT.spaceMd),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DT.radiusCard),
        boxShadow: tone == BannerTone.info ? DT.cardShadow : null,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon ?? ic, size: 20, color: fg),
        const SizedBox(width: DT.spaceSm + 4),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (title != null) ...[Text(title!, style: t.titleMedium), const SizedBox(height: 2)],
            Text(text,
                style: t.bodyMedium!.copyWith(
                    color: tone == BannerTone.danger ? DT.onWarningSoft : DT.textPrimary)),
            if (action != null) LinkButton(label: action!, onPressed: onAction, color: fg),
          ]),
        ),
      ]),
    );
  }
}

/// Ghi chú nhỏ có biểu tượng (`flex gap-space-sm font-body-sm text-on-surface-variant`).
class HintText extends StatelessWidget {
  const HintText(this.text, {super.key, this.icon = Icons.info_outline, this.color = DT.textSecondary});
  final String text;
  final IconData? icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icon != null) ...[Icon(icon, size: 18, color: color), const SizedBox(width: DT.spaceSm)],
        Expanded(child: Text(text, style: context.text.bodySmall!.copyWith(color: color))),
      ]);
}

/// Màn placeholder "Sắp có" theo khung mockup (header + thông điệp).
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title, required this.code, this.body});
  final String title;
  final String code;
  final String? body;
  @override
  Widget build(BuildContext context) => AppScaffold(
        header: AppHeader.back(title: title),
        body: StateMessage(
          icon: Icons.hourglass_empty,
          tone: StateTone.accent,
          title: 'Sắp có',
          body: body ?? '$title ($code) sẽ có ở bản sau.',
        ),
      );
}

void showSnack(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
