import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/shop_catalog.dart';
import '../games/balloon_pop_game.dart';
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
    Tab tab(Widget img, String text) => Tab(
      height: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 28, child: img),
          FittedBox(child: Text(text)),
        ],
      ),
    );
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3EEFF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF3EEFF),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppImage('shop', size: 34),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(l.shop)),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CoinChip(coins: app.active!.coins, compact: true),
            ),
          ],
          bottom: TabBar(
            labelStyle: display(16, weight: FontWeight.w700),
            labelColor: AppColors.secondary,
            unselectedLabelColor: AppColors.inkSoft,
            indicatorColor: AppColors.secondary,
            indicatorWeight: 4,
            tabs: [
              tab(GameImage(app.active!.avatar, width: 28), l.avatars),
              tab(const RotatedBox(quarterTurns: 1, child: GameImage('car_red', height: 28)), l.carColours),
              tab(const AppImage('balloon', size: 28), l.balloonThemes),
            ],
          ),
        ),
        body: const TabBarView(
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
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: kind == ShopKind.avatar ? 0.7 : 0.9,
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
      ShopKind.avatar => AvatarCircle(avatarId: item.id, size: 76, selected: equipped),
      ShopKind.car => RotatedBox(quarterTurns: 1, child: GameImage(item.id, height: 110)),
      ShopKind.balloon => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in item.colors.take(4))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: CustomPaint(size: const Size(30, 58), painter: BalloonPainter(c, false)),
            ),
        ],
      ),
    };
    final Widget button;
    if (equipped) {
      button = Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.good.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: FittedBox(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppImage('check', size: 22),
              const SizedBox(width: 4),
              Text(l.inUse, style: display(16, color: AppColors.goodDark)),
            ],
          ),
        ),
      );
    } else if (owned) {
      button = ChunkyButton(
        key: ValueKey('use_${item.id}'),
        color: Colors.white,
        edgeColor: const Color(0xFFC9BCF7),
        radius: 16,
        depth: 4,
        padding: const EdgeInsets.symmetric(vertical: 8),
        onTap: () => app.equip(item),
        child: FittedBox(
          child: Text(l.use, style: display(18, color: AppColors.secondary)),
        ),
      );
    } else {
      final afford = (app.active?.coins ?? 0) >= item.price;
      button = ChunkyButton(
        key: ValueKey('buy_${item.id}'),
        color: afford ? AppColors.primary : const Color(0xFFBDB7D1),
        radius: 16,
        depth: 4,
        padding: const EdgeInsets.symmetric(vertical: 6),
        onTap: () => _buy(context, app),
        child: FittedBox(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppImage('coin', size: 24),
              const SizedBox(width: 4),
              Text('${item.price}', style: display(20, color: Colors.white)),
            ],
          ),
        ),
      );
    }
    return Panel(
      padding: const EdgeInsets.all(10),
      color: equipped ? const Color(0xFFEFFFF4) : Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Center(child: FittedBox(child: preview)),
          ),
          if (item.kind != ShopKind.avatar)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(l.itemName(item), style: display(18)),
            ),
          SizedBox(width: double.infinity, child: button),
        ],
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
      messenger.showSnackBar(SnackBar(content: Text(l.bought)));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l.needMoreCoins(missing))));
    }
  }
}
