import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/shop_catalog.dart';
import '../games/race_car_game.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/l10n_ext.dart';

/// Spend coins on avatars, car colours and balloon themes.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final app = context.watch<AppState>();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.shop),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CoinChip(coins: app.active!.coins),
            ),
          ],
          bottom: TabBar(
            labelStyle: const TextStyle(fontFamily: 'NotoSansKannada', fontSize: 17, fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: l.avatars),
              Tab(text: l.carColours),
              Tab(text: l.balloonThemes),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _Grid(kind: ShopKind.avatar),
            _Grid(kind: ShopKind.car),
            _Grid(kind: ShopKind.balloon),
          ],
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.kind});

  final ShopKind kind;

  @override
  Widget build(BuildContext context) {
    final items = ShopCatalog.ofKind(kind);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: kind == ShopKind.avatar ? 3 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: kind == ShopKind.avatar ? 0.72 : 0.95,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _ItemCard(item: items[i]),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final app = context.watch<AppState>();
    final owned = app.owns(item);
    final equipped = app.isEquipped(item);
    final Widget preview = switch (item.kind) {
      ShopKind.avatar => AvatarCircle(avatarId: item.id, size: 72, selected: equipped),
      ShopKind.car => CustomPaint(size: const Size(110, 56), painter: CarPainter(item.colors.first)),
      ShopKind.balloon => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in item.colors.take(4))
            Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.circle, size: 28, color: c),
            ),
        ],
      ),
    };
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: equipped ? AppColors.good : Colors.transparent, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Center(child: preview)),
            if (item.kind != ShopKind.avatar)
              Text(l.itemName(item), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: equipped
                  ? FilledButton(
                      onPressed: null,
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                      child: FittedBox(child: Text(l.inUse)),
                    )
                  : owned
                  ? OutlinedButton(
                      key: ValueKey('use_${item.id}'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                      onPressed: () => app.equip(item),
                      child: FittedBox(child: Text(l.use)),
                    )
                  : FilledButton(
                      key: ValueKey('buy_${item.id}'),
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                      onPressed: () => _buy(context, app),
                      child: FittedBox(child: Text('🪙 ${item.price}')),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _buy(BuildContext context, AppState app) {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final missing = item.price - app.active!.coins;
    messenger.hideCurrentSnackBar();
    if (app.buy(item)) {
      app.audio.sfx(Sfx.coin);
      messenger.showSnackBar(SnackBar(content: Text(l.bought, style: const TextStyle(fontSize: 18))));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l.needMoreCoins(missing), style: const TextStyle(fontSize: 18))));
    }
  }
}
