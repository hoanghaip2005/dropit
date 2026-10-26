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

ItemAction itemActionOf(
  ShopItem it, {
  required int balance,
  required bool equipped,
}) {
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
Future<void> equipItem(
  BuildContext context,
  WidgetRef ref,
  String kind,
  String? itemId,
) async {
  try {
    await ref.read(apiProvider).equip(kind, itemId);
    ref.invalidate(inventoryProvider);
    ref.invalidate(meProvider);
    if (context.mounted) {
      showSnack(
        context,
        itemId == null ? 'Đã gỡ — dùng món mặc định.' : 'Đã trang bị.',
      );
    }
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
  bool _equipping = false;

  Future<void> _equip(ShopItem item, bool remove) async {
    if (_equipping) return;
    final api = ref.read(apiProvider);
    setState(() => _equipping = true);
    try {
      await api.equip(item.kind, remove ? null : item.itemId);
      if (!mounted) return;
      ref.invalidate(inventoryProvider);
      ref.invalidate(meProvider);
      await Future.wait([
        ref.read(inventoryProvider.future),
        ref.read(meProvider.future),
      ]);
      if (mounted) {
        showSnack(context, remove ? 'Đã gỡ vật phẩm.' : 'Đã trang bị.');
      }
    } catch (_) {
      if (mounted) {
        showSnack(
          context,
          'Chưa cập nhật được trang bị. Thử tải lại để kiểm tra.',
        );
      }
    } finally {
      if (mounted) setState(() => _equipping = false);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(shopItemsProvider);
    ref.invalidate(inventoryProvider);
    ref.invalidate(meProvider);
    await Future.wait([
      ref.read(shopItemsProvider.future).then((_) {}, onError: (_) {}),
      ref.read(inventoryProvider.future).then((_) {}, onError: (_) {}),
      ref.read(meProvider.future).then((_) {}, onError: (_) {}),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final meState = ref.watch(meProvider);
    final invState = ref.watch(inventoryProvider);
    final items = ref.watch(shopItemsProvider);
    final me = !meState.isLoading && !meState.hasError ? meState.value : null;
    final inventoryKnown =
        !invState.isLoading && !invState.hasError && invState.hasValue;
    final inv = inventoryKnown ? invState.value! : const <OwnedItem>[];
    final t = context.text.apply(
      bodyColor: OwnerStyle.ink,
      displayColor: OwnerStyle.ink,
    );
    final kind = itemKinds[_cat];
    return AppScaffold(
      backgroundColor: OwnerStyle.canvas,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text('DropIt!', style: t.titleLarge),
            TextButton.icon(
              key: const Key('shopCoins'),
              onPressed: () => context.push('/coins'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: DT.accent,
                minimumSize: const Size(44, 44),
              ),
              icon: const Icon(Icons.toll_outlined, size: 18),
              label: Text(
                me == null
                    ? (meState.hasError
                          ? 'Số dư chưa tải được'
                          : 'Đang tải Coins…')
                    : '${me.coinsBalance} Coins${me.cachedAt == null ? '' : ' · Chưa cập nhật'}',
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: Text('Shop', style: t.headlineLarge)),
                TextButton(
                  key: const Key('myItems'),
                  onPressed: () => context.push('/shop/mine'),
                  style: TextButton.styleFrom(
                    foregroundColor: OwnerStyle.ink,
                    minimumSize: const Size(44, 44),
                  ),
                  child: const Text('Đồ của tôi'),
                ),
              ],
            ),
          ),
          if (meState.hasError || invState.hasError || me?.cachedAt != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      invState.hasError
                          ? 'Chưa xác minh được trang bị.'
                          : 'Chưa tải được số dư.',
                      style: t.bodySmall,
                    ),
                  ),
                  TextButton(
                    key: const Key('shopMetadataRetry'),
                    onPressed: () {
                      ref.invalidate(meProvider);
                      ref.invalidate(inventoryProvider);
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (var i = 0; i < itemKinds.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Semantics(
                    selected: i == _cat,
                    child: TextButton.icon(
                      key: Key('shopCategory-${itemKinds[i]}'),
                      onPressed: () => setState(() => _cat = i),
                      style: TextButton.styleFrom(
                        backgroundColor: i == _cat
                            ? OwnerStyle.primary
                            : Colors.white,
                        foregroundColor: i == _cat
                            ? Colors.white
                            : OwnerStyle.muted,
                        minimumSize: const Size(44, 44),
                      ),
                      icon: Icon(
                        i == _cat ? Icons.check : Icons.circle_outlined,
                        size: 16,
                      ),
                      label: Text(itemKindText(itemKinds[i])),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AsyncBody<List<ShopItem>>(
              value: items,
              onRetry: _refresh,
              errorTitle: 'Chưa tải được Shop.',
              builder: (all) {
                final list = all.where((x) => x.kind == kind).toList();
                if (list.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 340,
                          child: StateMessage(
                            icon: Icons.local_mall_outlined,
                            title: all.isEmpty
                                ? 'Shop chưa có vật phẩm'
                                : 'Chưa có ${itemKindText(kind).toLowerCase()} đang bán',
                            body: 'Quay lại sau nhé.',
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final scale = MediaQuery.textScalerOf(context).scale(1);
                    final columns = constraints.maxWidth < 360 || scale >= 1.3
                        ? 1
                        : constraints.maxWidth >= 700
                        ? 3
                        : 2;
                    final rows = <Widget>[];
                    for (var start = 0; start < list.length; start += columns) {
                      rows.add(
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var c = 0; c < columns; c++) ...[
                                if (c > 0) const SizedBox(width: 14),
                                Expanded(
                                  child: start + c >= list.length
                                      ? const SizedBox()
                                      : Builder(
                                          builder: (context) {
                                            final item = list[start + c];
                                            final owned =
                                                item.owned ||
                                                inv.any(
                                                  (o) =>
                                                      o.itemId == item.itemId,
                                                );
                                            final equipped =
                                                inventoryKnown &&
                                                inv.any(
                                                  (o) =>
                                                      o.itemId == item.itemId &&
                                                      o.equipped,
                                                );
                                            return _ShopCard(
                                              item: item,
                                              myName: me?.displayName ?? '',
                                              owned: owned,
                                              equipped: equipped,
                                              inventoryKnown: inventoryKnown,
                                              balance: me?.cachedAt == null
                                                  ? me?.coinsBalance
                                                  : null,
                                              busy: _equipping,
                                              onEquip: () =>
                                                  _equip(item, equipped),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          DT.navClearance +
                              MediaQuery.paddingOf(context).bottom,
                        ),
                        itemCount: rows.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (_, index) => rows[index],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.item,
    required this.myName,
    required this.owned,
    required this.equipped,
    required this.inventoryKnown,
    required this.balance,
    required this.busy,
    required this.onEquip,
  });
  final ShopItem item;
  final String myName;
  final bool owned;
  final bool equipped;
  final bool inventoryKnown;
  final int? balance;
  final bool busy;
  final VoidCallback onEquip;
  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return AppCard(
      key: Key('shopItem-${item.itemId}'),
      color: Colors.white,
      radius: 32,
      padding: const EdgeInsets.all(12),
      children: [
        InkWell(
          key: Key('shopPreview-${item.itemId}'),
          onTap: () => context.push('/shop/item/${item.itemId}'),
          child: AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) => Container(
                decoration: BoxDecoration(
                  color: OwnerStyle.inset,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: ItemPreview(
                    kind: item.kind,
                    colorKey: item.previewKey,
                    label: item.name,
                    size: constraints.maxWidth - 16,
                    name: myName,
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(
          item.name,
          semanticsLabel: item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: t.titleMedium!.copyWith(color: OwnerStyle.ink),
        ),
        Text(
          itemKindText(item.kind),
          style: t.bodySmall!.copyWith(color: OwnerStyle.muted),
        ),
        Text(
          '${item.price} Coins',
          style: t.labelLarge!.copyWith(
            color: DT.accent,
            fontFeatures: DT.tabular,
          ),
        ),
        if (owned)
          Text(
            equipped ? 'Đang dùng' : 'Đã sở hữu',
            key: Key('shopStatus-${item.itemId}'),
            style: t.labelMedium!.copyWith(color: DT.success),
          ),
        if (owned && !inventoryKnown)
          Text(
            'Đang xác minh trang bị',
            style: t.bodySmall!.copyWith(color: OwnerStyle.muted),
          ),
        if (!owned && balance != null && balance! < item.price)
          Text(
            'Chưa đủ Coins',
            style: t.bodySmall!.copyWith(color: OwnerStyle.muted),
          ),
        if (owned)
          _Pill(
            key: Key('shopEquip-${item.itemId}'),
            label: busy
                ? 'Đang cập nhật…'
                : equipped
                ? 'Gỡ trang bị'
                : 'Trang bị',
            bg: OwnerStyle.primary,
            fg: Colors.white,
            icon: equipped ? Icons.check : null,
            onTap: !inventoryKnown || busy ? null : onEquip,
          ),
        _Pill(
          key: Key('shopDetail-${item.itemId}'),
          label: 'Xem vật phẩm',
          bg: owned ? OwnerStyle.inset : OwnerStyle.primary,
          fg: owned ? OwnerStyle.ink : Colors.white,
          onTap: () => context.push('/shop/item/${item.itemId}'),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
    this.onTap,
    this.icon,
  });
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback? onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      minimumSize: const Size.fromHeight(44),
      disabledBackgroundColor: OwnerStyle.line,
      disabledForegroundColor: OwnerStyle.muted,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    ),
  );
}
/// V-31 Chi tiết vật phẩm; mua và trang bị là hai thao tác riêng.
class ShopItemScreen extends ConsumerStatefulWidget {
  const ShopItemScreen({super.key, required this.itemId});
  final String itemId;
  @override
  ConsumerState<ShopItemScreen> createState() => _ShopItemScreenState();
}

class _ShopItemScreenState extends ConsumerState<ShopItemScreen> {
  ({String id, int price, String key})? _intent;
  bool _busy = false;
  bool _purchased = false;
  bool _unavailable = false;
  String? _message;
  int _version = 0;

  @override
  void didUpdateWidget(covariant ShopItemScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemId != widget.itemId) {
      _version++;
      _intent = null;
      _busy = false;
      _purchased = false;
      _unavailable = false;
      _message = null;
    }
  }

  bool _current(int version) => mounted && version == _version;

  Future<void> _reload() async {
    final catalogRefresh = _refreshShop(ref);
    await Future.wait([
      catalogRefresh,
      ref.read(shopItemsProvider.future),
      ref.read(meProvider.future),
      ref.read(inventoryProvider.future),
    ]);
  }

  Future<void> _retry() async {
    try {
      await _reload();
    } catch (_) {
      /* Provider errors remain visible. */
    }
  }

  Future<void> _buy(ShopItem item) async {
    if (_busy || _purchased || _unavailable) return;
    final api = ref.read(apiProvider);
    final version = _version;
    final intent =
        _intent ?? (id: item.itemId, price: item.price, key: const Uuid().v4());
    _intent = intent;
    setState(() {
      _busy = true;
      _message = null;
    });
    bool accepted = false;
    try {
      await api.purchase(intent.id, intent.price, idempotencyKey: intent.key);
      if (!_current(version)) return;
      accepted = true;
      _purchased = true;
      _intent = null;
      ref.invalidate(coinsProvider);
      try {
        await _reload();
        if (_current(version)) {
          _message = 'Đã mua vật phẩm. Bạn có thể trang bị khi muốn.';
        }
      } catch (_) {
        if (_current(version)) {
          _message =
              'Đã mua vật phẩm. Chưa tải lại được trạng thái; hãy kiểm tra lại.';
        }
      }
    } catch (error) {
      if (!_current(version)) return;
      final code = ApiError.from(error).code;
      final definitive = {
        'PRICE_CHANGED',
        'ALREADY_OWNED',
        'INSUFFICIENT_COINS',
        'ITEM_UNAVAILABLE',
      }.contains(code);
      if (definitive) {
        _intent = null;
        _unavailable = code == 'ITEM_UNAVAILABLE';
        if (code == 'ALREADY_OWNED') _purchased = true;
        _message = switch (code) {
          'PRICE_CHANGED' =>
            'Giá vừa thay đổi. Kiểm tra giá mới rồi xác nhận lại.',
          'ALREADY_OWNED' =>
            'Bạn đã sở hữu vật phẩm. Đang kiểm tra lại kho đồ.',
          'INSUFFICIENT_COINS' =>
            'Số dư chưa đủ. Kiểm tra lại Coins trước khi mua.',
          _ => 'Vật phẩm hiện không còn bán.',
        };
        try {
          await _reload();
        } catch (_) {
          /* Show verified provider state. */
        }
      } else {
        _message =
            'Chưa xác nhận được giao dịch. Kiểm tra lại hoặc thử lại cùng giao dịch.';
      }
    } finally {
      if (_current(version)) {
        setState(() {
          _busy = false;
        });
        if (accepted && mounted) showSnack(context, 'Đã mua vật phẩm.');
      }
    }
  }

  Future<void> _equip(ShopItem item, bool remove) async {
    if (_busy) return;
    final api = ref.read(apiProvider);
    final version = _version;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await api.equip(item.kind, remove ? null : item.itemId);
      if (!_current(version)) return;
      try {
        await _reload();
        if (_current(version)) {
          _message = remove ? 'Đã gỡ vật phẩm.' : 'Đã trang bị vật phẩm.';
        }
      } catch (_) {
        if (_current(version)) {
          _message =
              'Đã cập nhật trang bị. Chưa tải lại được trạng thái; hãy kiểm tra lại.';
        }
      }
    } catch (_) {
      if (_current(version)) {
        _message =
            'Chưa xác nhận được trang bị. Kiểm tra lại trạng thái trước khi thử lại.';
      }
    } finally {
      if (_current(version)) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(shopItemsProvider);
    final meState = ref.watch(meProvider);
    final inventory = ref.watch(inventoryProvider);
    final catalogKnown = !catalog.isLoading && !catalog.hasError;
    final item = catalogKnown
        ? catalog.value?.where((i) => i.itemId == widget.itemId).firstOrNull
        : null;
    final me = !meState.isLoading && !meState.hasError ? meState.value : null;
    final balance = me?.cachedAt == null ? me?.coinsBalance : null;
    final inventoryKnown =
        !inventory.isLoading && !inventory.hasError && inventory.hasValue;
    final mine = inventoryKnown ? inventory.value! : const <OwnedItem>[];
    final owned =
        item != null &&
        (_purchased || item.owned || mine.any((i) => i.itemId == item.itemId));
    final equipped =
        item != null &&
        inventoryKnown &&
        mine.any((i) => i.itemId == item.itemId && i.equipped);
    final price = _intent?.price ?? item?.price;
    final short = balance != null && price != null && balance < price;
    final t = context.text.apply(
      bodyColor: OwnerStyle.ink,
      displayColor: OwnerStyle.ink,
    );

    Widget receipt(String label, String value, {bool accent = false}) =>
        LayoutBuilder(
          builder: (context, constraints) {
            final valueText = Text(
              value,
              style: t.titleMedium!.copyWith(
                color: accent ? DT.accent : OwnerStyle.ink,
                fontFeatures: DT.tabular,
              ),
            );
            final labelText = Text(
              label,
              style: t.bodyMedium!.copyWith(color: OwnerStyle.muted),
            );
            return constraints.maxWidth < 350 ||
                    MediaQuery.textScalerOf(context).scale(1) >= 1.3
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [labelText, const SizedBox(height: 4), valueText],
                  )
                : Row(
                    children: [
                      Expanded(child: labelText),
                      const SizedBox(width: 12),
                      Flexible(child: valueText),
                    ],
                  );
          },
        );
    Widget card(List<Widget> children) => AppCard(
      color: Colors.white,
      radius: 32,
      padding: const EdgeInsets.all(20),
      children: children,
    );
    Widget? footer;
    if (item != null) {
      final label = _busy
          ? 'Đang cập nhật…'
          : owned
          ? (equipped ? 'Gỡ trang bị' : 'Trang bị')
          : _unavailable
          ? 'Vật phẩm không còn bán'
          : balance == null
          ? 'Chờ xác minh số dư'
          : _intent != null
          ? 'Thử lại giao dịch (${price!} Coins)'
          : short
          ? 'Thiếu ${price - balance} Coins'
          : 'Xác nhận mua (${price!} Coins)';
      final enabled =
          !_busy &&
          (owned
              ? inventoryKnown
              : !_unavailable &&
                    balance != null &&
                    (_intent != null || !short));
      footer = FilledButton(
        key: Key(owned ? 'itemEquip' : 'buyButton'),
        style: FilledButton.styleFrom(
          backgroundColor: OwnerStyle.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onPressed: enabled
            ? () => owned ? _equip(item, equipped) : _buy(item)
            : null,
        child: Text(label, textAlign: TextAlign.center),
      );
    }
    return PopScope(
      canPop: !_busy && _intent == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_busy) {
          showSnack(context, 'Đang xử lý. Vui lòng chờ kết quả.');
          return;
        }
        final leave = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Giao dịch chưa được xác nhận'),
            content: const Text(
              'Hãy kiểm tra lại trước khi rời. Nếu rời màn này, giao dịch vẫn có thể đã được xử lý.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Ở lại kiểm tra'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Rời màn hình'),
              ),
            ],
          ),
        );
        if (leave == true && context.mounted) Navigator.of(context).pop();
      },
      child: AppScaffold(
        backgroundColor: OwnerStyle.canvas,
        header: Column(
          children: [
            const AppHeader.back(title: 'Chi tiết vật phẩm'),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _message!,
                      key: const Key('buyError'),
                      style: t.bodyMedium,
                    ),
                    TextButton(
                      key: const Key('itemStatusRetry'),
                      onPressed: _busy ? null : _retry,
                      child: const Text('Kiểm tra lại'),
                    ),
                  ],
                ),
              ),
          ],
        ),
        footer: footer,
        body: AsyncBody<List<ShopItem>>(
          value: catalog,
          onRetry: _retry,
          builder: (_) {
            if (item == null) {
              return const StateMessage(
                icon: Icons.search_off,
                title: 'Không tìm thấy vật phẩm',
              );
            }
            return PageList(
              onRefresh: _retry,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemKindText(item.kind),
                      style: t.labelLarge!.copyWith(color: OwnerStyle.muted),
                    ),
                    const SizedBox(height: 8),
                    Text(item.name, style: t.headlineLarge),
                    if (owned)
                      Text(
                        equipped ? 'Đang dùng' : 'Đã sở hữu',
                        style: t.labelLarge!.copyWith(color: DT.success),
                      ),
                  ],
                ),
                card([
                  Text('Xem thử vật phẩm', style: t.titleMedium),
                  _TryOn(item: item, me: me),
                  if (me == null)
                    Text(
                      meState.hasError
                          ? 'Chưa tải được hồ sơ.'
                          : 'Đang tải hồ sơ…',
                      style: t.bodySmall,
                    ),
                  Text(
                    'Sở hữu vĩnh viễn · Chỉ dùng để trang trí',
                    style: t.bodySmall!.copyWith(color: OwnerStyle.muted),
                  ),
                ]),
                card([
                  Text('Chi tiết giao dịch', style: t.titleMedium),
                  receipt(
                    _intent == null
                        ? 'Giá niêm yết'
                        : 'Giá giao dịch đang xác minh',
                    '${price!} Coins',
                    accent: true,
                  ),
                  receipt(
                    'Số dư hiện có',
                    me == null
                        ? (meState.hasError ? 'Chưa tải được' : 'Đang tải…')
                        : '${me.coinsBalance} Coins${me.cachedAt == null ? '' : ' · Chưa cập nhật'}',
                  ),
                  if (!owned)
                    receipt(
                      'Số dư còn lại sau mua',
                      balance == null || short
                          ? '—'
                          : '${balance - price} Coins',
                    ),
                  if (!owned)
                    Text(
                      'Không hoàn Coins sau khi mua.',
                      key: const Key('noRefund'),
                      style: t.labelLarge,
                    ),
                  Text(
                    'Mua để lưu vào Đồ của tôi. Trang bị riêng khi muốn sử dụng.',
                    style: t.bodySmall!.copyWith(color: OwnerStyle.muted),
                  ),
                ]),
                if (meState.hasError ||
                    me?.cachedAt != null ||
                    inventory.hasError ||
                    (owned && !inventoryKnown))
                  card([
                    Text(
                      !inventoryKnown && owned
                          ? 'Chưa xác minh được trang bị.'
                          : 'Thông tin tài khoản chưa được cập nhật.',
                      style: t.bodyMedium,
                    ),
                    TextButton(
                      key: const Key('itemMetadataRetry'),
                      onPressed: _busy ? null : _retry,
                      child: const Text('Kiểm tra lại'),
                    ),
                  ]),
                if (!owned && short && _intent == null)
                  Text(
                    'Thiếu ${price - balance} Coins. Hoàn thành phiên cùng nhóm để nhận Coins.',
                    style: t.bodyMedium,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TryOn extends StatelessWidget {
  const _TryOn({required this.item, required this.me});
  final ShopItem item;
  final MeProfile? me;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final name = me?.displayName ?? '';
      final size = (constraints.maxWidth * .46).clamp(72.0, 132.0);
      return CosmeticSurface(
        artKey: item.kind == 'BACKGROUND' ? item.previewKey : null,
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              FramedAvatar(
                name: name,
                imageUrl: me?.avatarUrl == null
                    ? null
                    : fixHost(me!.avatarUrl!),
                frameKey: item.kind == 'AVATAR_FRAME' ? item.previewKey : null,
                frameColor: item.kind == 'AVATAR_FRAME'
                    ? previewColor(item.previewKey)
                    : null,
                size: size,
              ),
              if (name.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: context.text.titleMedium,
                ),
              ],
              if (item.kind == 'TITLE') ...[
                const SizedBox(height: 12),
                TitleAdornment(artKey: item.previewKey, label: item.name),
              ],
            ],
          ),
        ),
      );
    },
  );
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
        builder: (list) => PageList(
          onRefresh: refresh,
          children: [
            for (final kind in itemKinds) ...[
              SectionHeader(itemKindText(kind), small: true),
              Builder(
                builder: (context) {
                  final mine = list.where((o) => o.kind == kind).toList();
                  if (mine.isEmpty) {
                    return AppCard(
                      children: [
                        Text(
                          'Chưa có ${itemKindText(kind).toLowerCase()}.',
                          style: t.bodyMedium!.copyWith(color: DT.textSecondary),
                        ),
                      ],
                    );
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
                                    child: const Icon(Icons.radio_button_unchecked, color: DT.textSecondary),
                                  )
                                : ItemPreview(
                                    kind: kind,
                                    colorKey: keyOf[mine[i].itemId] ?? mine[i].itemId,
                                    size: 44,
                                  ),
                          ),
                          title: mine[i].name,
                          subtitle: mine[i].isDefault ? 'Món mặc định' : null,
                          trailing: mine[i].equipped
                              ? (mine[i].isDefault
                                    ? const StatusBadge('Đang dùng', tone: BadgeTone.success)
                                    : TextButton(
                                        onPressed: () => equipItem(context, ref, kind, null),
                                        child: const Text('Đang dùng · Gỡ'),
                                      ))
                              : TextButton(
                                  onPressed: () => equipItem(context, ref, kind, mine[i].itemId),
                                  child: const Text('Trang bị'),
                                ),
                        ),
                    ],
                  );
                },
              ),
            ],
            const HintText('Món đang trang bị hiện cho người cùng nhóm. Coins và chuỗi không hiện.'),
          ],
        ),
      ),
    );
  }
}
