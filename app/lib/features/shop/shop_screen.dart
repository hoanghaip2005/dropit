import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme.dart';
import '../../core/api.dart';
import '../../core/models.dart';
import '../../core/models_ext.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

/// Trạng thái nút của một món (rewards_shop / s_02).
enum ItemAction { buy, short, equip, equipped, defaultItem }

ItemAction itemActionOf(ShopItem it, {required int balance, required bool equipped}) {
  if (equipped) return ItemAction.equipped;
  if (it.owned) return ItemAction.equip;
  if (balance < it.price) return ItemAction.short;
  return ItemAction.buy;
}

Future<void> _refreshShop(WidgetRef ref) async {
  ref.invalidate(shopItemsProvider);
  ref.invalidate(inventoryProvider);
  ref.invalidate(meProvider);
  await ref.read(shopItemsProvider.future).then((_) {}, onError: (_) {});
}

/// Trang bị / gỡ chung cho Shop, chi tiết và "Đồ của tôi".
Future<void> equipItem(BuildContext context, WidgetRef ref, String kind, String? itemId) async {
  try {
    await ref.read(apiProvider).equip(kind, itemId);
    ref.invalidate(inventoryProvider);
    ref.invalidate(meProvider);
    if (context.mounted) showSnack(context, itemId == null ? 'Đã gỡ — dùng món mặc định.' : 'Đã trang bị.');
  } catch (e) {
    if (context.mounted) showSnack(context, ApiError.from(e).message);
  }
}

/// V-30 Shop. Mockup: `the_shop`, `rewards_shop`. Ba tab: khung avatar / hình nền / danh hiệu.
/// Chỉ đồ trang trí; giá cố định; không xếp hạng, không độ hiếm (BR-121).
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});
  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  int _cat = 0;

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider).value;
    final items = ref.watch(shopItemsProvider);
    final inv = ref.watch(inventoryProvider).value ?? const <OwnedItem>[];
    final equipped = {for (final o in inv) if (o.equipped) o.itemId};
    final t = context.text;
    final kind = itemKinds[_cat];
    return AppScaffold(
      header: AppHeader.brand(
        title: 'DropIt!',
        icon: Icons.local_fire_department,
        trailing: InkWell(
          onTap: () => context.push('/coins'),
          borderRadius: BorderRadius.circular(DT.pill),
          child: CoinChip(me == null ? '— Coins' : '${me.coinsBalance} Coins', onCard: true),
        ),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(DT.margin, DT.spaceSm, DT.margin, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Shop', style: t.headlineLarge),
                Text('Đổi Coins lấy vật phẩm trang trí', style: t.bodySmall),
              ]),
            ),
            LinkButton(
                key: const Key('myItems'), label: 'Đồ của tôi', onPressed: () => context.push('/shop/mine')),
          ]),
        ),
        const SizedBox(height: DT.spaceMd),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: DT.margin),
          clipBehavior: Clip.none,
          child: Row(children: [
            for (var i = 0; i < itemKinds.length; i++) ...[
              if (i > 0) const SizedBox(width: DT.spaceSm),
              FilterChipPill(
                  label: itemKindText(itemKinds[i]), selected: i == _cat, onTap: () => setState(() => _cat = i)),
            ],
          ]),
        ),
        const SizedBox(height: DT.spaceSm),
        Expanded(
          child: AsyncBody<List<ShopItem>>(
            value: items,
            onRetry: () => _refreshShop(ref),
            errorTitle: 'Chưa tải được Shop.',
            builder: (all) {
              final list = all.where((x) => x.kind == kind).toList();
              if (list.isEmpty) {
                return StateMessage(
                  icon: Icons.local_mall_outlined,
                  title: 'Chưa có ${itemKindText(kind).toLowerCase()} đang bán',
                  body: 'Quay lại sau nhé.',
                );
              }
              return RefreshIndicator(
                color: DT.primary,
                onRefresh: () => _refreshShop(ref),
                child: GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                      DT.margin, DT.spaceSm, DT.margin, DT.navClearance + MediaQuery.paddingOf(context).bottom),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: DT.spaceMd,
                    crossAxisSpacing: DT.spaceMd,
                    mainAxisExtent: 250,
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _ShopCard(
                    item: list[i],
                    action: itemActionOf(list[i],
                        balance: me?.coinsBalance ?? 0, equipped: equipped.contains(list[i].itemId)),
                    myName: me?.displayName ?? '',
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _ShopCard extends ConsumerWidget {
  const _ShopCard({required this.item, required this.action, required this.myName});
  final ShopItem item;
  final ItemAction action;
  final String myName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.text;
    return AppCard(
      key: Key('shopItem-${item.itemId}'),
      onTap: () => context.push('/shop/item/${item.itemId}'),
      padding: const EdgeInsets.all(12),
      children: [
        SizedBox(
          height: 96,
          child: Center(
            child: ItemPreview(kind: item.kind, colorKey: item.previewKey, label: item.name, size: 88, name: myName),
          ),
        ),
        Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleMedium),
        Text(itemKindText(item.kind), style: t.bodySmall),
        const Spacer(),
        switch (action) {
          ItemAction.equipped => _Pill(
              label: 'Đang dùng · Gỡ',
              icon: Icons.check,
              bg: DT.successSoftBg,
              fg: DT.success,
              onTap: () => equipItem(context, ref, item.kind, null)),
          ItemAction.equip => _Pill(
              label: 'Đã sở hữu · Trang bị',
              bg: DT.successSoftBg,
              fg: DT.success,
              onTap: () => equipItem(context, ref, item.kind, item.itemId)),
          _ => Row(children: [
              const Icon(Icons.monetization_on, size: 16, color: DT.accent),
              const SizedBox(width: 4),
              Expanded(
                child: Text('${item.price} Coins',
                    style: t.labelLarge!.copyWith(color: DT.accent, fontFeatures: DT.tabular)),
              ),
              _Pill(
                label: 'Mua',
                bg: action == ItemAction.short ? DT.surfaceHigh : DT.primary,
                fg: action == ItemAction.short ? DT.textSecondary : Colors.white,
                onTap: () => context.push('/shop/item/${item.itemId}'),
              ),
            ]),
        },
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg, this.onTap, this.icon});
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback? onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Material(
        color: bg,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
              Flexible(
                child: Text(label,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.labelMedium!.copyWith(color: fg)),
              ),
            ]),
          ),
        ),
      );
}

/// V-31 Chi tiết vật phẩm và xác nhận mua. Mockup: `s_02_chi_ti_t_v_t_ph_m_v_x_c_nh_n_mua`.
/// Một `Idempotency-Key` cho mỗi ý định mua: bấm hai lần / thử lại sau lỗi mạng chỉ trừ Coins một lần.
class ShopItemScreen extends ConsumerStatefulWidget {
  const ShopItemScreen({super.key, required this.itemId});
  final String itemId;
  @override
  ConsumerState<ShopItemScreen> createState() => _ShopItemScreenState();
}

class _ShopItemScreenState extends ConsumerState<ShopItemScreen> {
  String _key = const Uuid().v4();
  bool _busy = false;
  String? _err;

  Future<void> _buy(ShopItem it) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await ref.read(apiProvider).purchase(it.itemId, it.price, idempotencyKey: _key);
      _key = const Uuid().v4();
      ref.invalidate(shopItemsProvider);
      ref.invalidate(inventoryProvider);
      ref.invalidate(meProvider);
      ref.invalidate(coinsProvider);
      if (mounted) showSnack(context, 'Đã mua ${it.name} (-${it.price} Coins)');
    } catch (e) {
      final a = ApiError.from(e);
      setState(() => _err = switch (a.code) {
            'INSUFFICIENT_COINS' => 'Bạn chưa đủ Coins cho món này. Coins của bạn không bị trừ.',
            'ALREADY_OWNED' => 'Bạn đã sở hữu món này.',
            'PRICE_CHANGED' => 'Giá vừa thay đổi. Kiểm tra lại giá rồi mua.',
            'ITEM_UNAVAILABLE' => 'Món này không còn bán.',
            _ => 'Chưa mua được. Coins của bạn không bị trừ. Thử lại.',
          });
      if (a.code == 'ALREADY_OWNED' || a.code == 'PRICE_CHANGED' || a.code == 'INSUFFICIENT_COINS') {
        _key = const Uuid().v4();
        ref.invalidate(shopItemsProvider);
        ref.invalidate(meProvider);
        ref.invalidate(inventoryProvider);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(shopItemsProvider);
    final me = ref.watch(meProvider).value;
    final inv = ref.watch(inventoryProvider).value ?? const <OwnedItem>[];
    final t = context.text;
    final it = items.value?.where((x) => x.itemId == widget.itemId).firstOrNull;
    final balance = me?.coinsBalance ?? 0;
    final isEquipped = inv.any((o) => o.itemId == widget.itemId && o.equipped);
    final action = it == null ? null : itemActionOf(it, balance: balance, equipped: isEquipped);

    Widget footer() {
      if (it == null || action == null) return const SizedBox.shrink();
      return switch (action) {
        ItemAction.equipped => SecondaryButton(
            label: 'Đang dùng · Gỡ', icon: Icons.check, onPressed: () => equipItem(context, ref, it.kind, null)),
        ItemAction.equip => PrimaryButton(
            label: 'Trang bị', icon: Icons.check_circle_outline, onPressed: () => equipItem(context, ref, it.kind, it.itemId)),
        ItemAction.short => PrimaryButton(
            key: const Key('buyButton'), label: 'Thiếu ${it.price - balance} Coins', onPressed: null),
        _ => PrimaryButton(
            key: const Key('buyButton'),
            label: 'Xác nhận mua (${it.price} Coins)',
            icon: Icons.bolt,
            loading: _busy,
            onPressed: me == null ? null : () => _buy(it),
          ),
      };
    }

    return AppScaffold(
      header: const AppHeader.back(title: 'Chi tiết vật phẩm'),
      footer: footer(),
      body: AsyncBody<List<ShopItem>>(
        value: items,
        onRetry: () => _refreshShop(ref),
        builder: (_) {
          if (it == null) {
            return const StateMessage(icon: Icons.search_off, title: 'Không tìm thấy vật phẩm');
          }
          return PageList(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              StatusBadge(itemKindText(it.kind), tone: BadgeTone.accent),
              const SizedBox(height: DT.spaceSm),
              Text(it.name, style: t.headlineLarge),
              Text('${itemKindText(it.kind)} · trang trí, không có lợi thế', style: t.bodySmall),
            ]),
            AppCard(gap: DT.spaceMd, children: [
              Row(children: [
                const Icon(Icons.visibility_outlined, size: 20),
                const SizedBox(width: DT.spaceSm),
                Expanded(child: Text('Thử trước vật phẩm', style: t.titleMedium)),
                Text('Hồ sơ của bạn', style: t.bodySmall),
              ]),
              _TryOn(item: it, me: me),
            ]),
            AppCard(children: [
              InfoRow(
                icon: Icons.all_inclusive,
                title: 'Thời hạn sở hữu: Vĩnh viễn',
                subtitle: 'Lưu trong Đồ của tôi. Trang bị hoặc Gỡ bất cứ lúc nào.',
              ),
            ]),
            AppCard(children: [
              Text('Chi tiết giao dịch', style: t.titleMedium),
              ReceiptRow(label: 'Giá niêm yết', value: '${it.price} Coins', valueColor: DT.accent),
              ReceiptRow(label: 'Số dư hiện có', value: '$balance Coins'),
              if (!it.owned)
                ReceiptRow(
                  label: 'Số dư còn lại sau mua',
                  value: balance >= it.price ? '${balance - it.price} Coins' : '—',
                  total: true,
                ),
              if (!it.owned)
                // AC-06.04.9 / BR-94: không có chức năng hoàn
                Text('Không hoàn Coins sau khi mua.',
                    key: const Key('noRefund'), style: t.labelLarge!.copyWith(color: DT.textPrimary)),
            ]),
            if (_err != null) AppBanner(key: const Key('buyError'), tone: BannerTone.danger, text: _err!),
            if (action == ItemAction.short)
              AppBanner(
                tone: BannerTone.accent,
                text: 'Thiếu ${it.price - balance} Coins. Hoàn thành phiên cùng nhóm để nhận Coins.',
              ),
            const HintText(
                'Vật phẩm kích hoạt ngay sau khi mua và không hoàn lại Coins. Vật phẩm chỉ để trang trí, không tăng Coins hay lợi thế nào.'),
          ]);
        },
      ),
    );
  }
}

class _TryOn extends StatelessWidget {
  const _TryOn({required this.item, required this.me});
  final ShopItem item;
  final MeProfile? me;
  @override
  Widget build(BuildContext context) {
    final name = me?.displayName ?? '';
    final c = previewColor(item.previewKey);
    return Container(
      padding: const EdgeInsets.all(DT.spaceMd),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DT.radiusCard),
        gradient: item.kind == 'BACKGROUND'
            ? LinearGradient(colors: [c, Color.lerp(c, Colors.white, 0.55)!])
            : const LinearGradient(colors: [DT.accentSoftBg, DT.background]),
      ),
      child: Column(children: [
        FramedAvatar(
          name: name,
          imageUrl: me?.avatarUrl == null ? null : fixHost(me!.avatarUrl!),
          frameColor: item.kind == 'AVATAR_FRAME' ? c : null,
          size: 96,
        ),
        const SizedBox(height: DT.spaceSm),
        Text(name, style: context.text.titleMedium),
        if (item.kind == 'TITLE') ...[
          const SizedBox(height: DT.spaceXs),
          ItemPreview(kind: 'TITLE', colorKey: item.previewKey, label: item.name, size: 32),
        ],
      ]),
    );
  }
}

/// Đồ của tôi (US-06.05): trang bị / gỡ theo loại; gỡ → món mặc định (BR-95).
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inv = ref.watch(inventoryProvider);
    final shop = ref.watch(shopItemsProvider).value ?? const <ShopItem>[];
    final keyOf = {for (final s in shop) s.itemId: s.previewKey};
    final t = context.text;
    Future<void> refresh() async {
      ref.invalidate(inventoryProvider);
      await ref.read(inventoryProvider.future).then((_) {}, onError: (_) {});
    }

    return AppScaffold(
      header: const AppHeader.back(title: 'Đồ của tôi'),
      body: AsyncBody<List<OwnedItem>>(
        value: inv,
        onRetry: refresh,
        builder: (list) => PageList(onRefresh: refresh, children: [
          for (final kind in itemKinds) ...[
            SectionHeader(itemKindText(kind), small: true),
            Builder(builder: (context) {
              final mine = list.where((o) => o.kind == kind).toList();
              if (mine.isEmpty) {
                return AppCard(children: [
                  Text('Chưa có ${itemKindText(kind).toLowerCase()}.', style: t.bodyMedium!.copyWith(color: DT.textSecondary)),
                ]);
              }
              return AppCard(
                padding: const EdgeInsets.symmetric(horizontal: DT.spaceMd, vertical: DT.spaceXs),
                children: [
                  for (var i = 0; i < mine.length; i++)
                    ListRow(
                      divider: i < mine.length - 1,
                      leading: SizedBox(
                        width: 44,
                        height: 44,
                        child: mine[i].isDefault
                            ? Container(
                                decoration: const BoxDecoration(color: DT.surfaceHigh, shape: BoxShape.circle),
                                child: const Icon(Icons.radio_button_unchecked, color: DT.textSecondary))
                            : ItemPreview(
                                kind: kind == 'TITLE' ? 'BACKGROUND' : kind,
                                colorKey: keyOf[mine[i].itemId] ?? mine[i].itemId,
                                size: 44),
                      ),
                      title: mine[i].name,
                      subtitle: mine[i].isDefault ? 'Món mặc định' : null,
                      trailing: mine[i].equipped
                          ? (mine[i].isDefault
                              ? const StatusBadge('Đang dùng', tone: BadgeTone.success)
                              : TextButton(
                                  onPressed: () => equipItem(context, ref, kind, null),
                                  child: const Text('Đang dùng · Gỡ')))
                          : TextButton(
                              onPressed: () => equipItem(context, ref, kind, mine[i].itemId),
                              child: const Text('Trang bị')),
                    ),
                ],
              );
            }),
          ],
          const HintText('Món đang trang bị hiện cho người cùng nhóm. Coins và chuỗi không hiện.'),
        ]),
      ),
    );
  }
}
