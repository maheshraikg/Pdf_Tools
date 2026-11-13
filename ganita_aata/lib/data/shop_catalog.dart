import 'package:flutter/material.dart';

enum ShopKind { avatar, car, balloon }

class ShopItem {
  const ShopItem({required this.id, required this.kind, required this.price, this.colors = const []});

  final String id;
  final ShopKind kind;

  /// 0 = free for everyone.
  final int price;

  /// Car colour (one) or balloon theme colours (several).
  final List<Color> colors;

  bool get isFree => price == 0;
}

/// Everything in the rewards shop. Add new items here; colour and theme
/// names need a `color_*` / `theme_*` string in the ARB files.
class ShopCatalog {
  ShopCatalog._();

  static const items = <ShopItem>[
    // Avatars: Kenney round animals (assets/game/av_<name>.png).
    ShopItem(id: 'av_monkey', kind: ShopKind.avatar, price: 0),
    ShopItem(id: 'av_elephant', kind: ShopKind.avatar, price: 0),
    ShopItem(id: 'av_rabbit', kind: ShopKind.avatar, price: 0),
    ShopItem(id: 'av_panda', kind: ShopKind.avatar, price: 0),
    ShopItem(id: 'av_parrot', kind: ShopKind.avatar, price: 0),
    ShopItem(id: 'av_chick', kind: ShopKind.avatar, price: 0),
    ShopItem(id: 'av_dog', kind: ShopKind.avatar, price: 0),
    ShopItem(id: 'av_owl', kind: ShopKind.avatar, price: 0),
    ShopItem(id: 'av_penguin', kind: ShopKind.avatar, price: 20),
    ShopItem(id: 'av_frog', kind: ShopKind.avatar, price: 20),
    ShopItem(id: 'av_pig', kind: ShopKind.avatar, price: 20),
    ShopItem(id: 'av_chicken', kind: ShopKind.avatar, price: 25),
    ShopItem(id: 'av_cow', kind: ShopKind.avatar, price: 25),
    ShopItem(id: 'av_duck', kind: ShopKind.avatar, price: 25),
    ShopItem(id: 'av_giraffe', kind: ShopKind.avatar, price: 30),
    ShopItem(id: 'av_zebra', kind: ShopKind.avatar, price: 30),
    ShopItem(id: 'av_hippo', kind: ShopKind.avatar, price: 30),
    ShopItem(id: 'av_horse', kind: ShopKind.avatar, price: 30),
    ShopItem(id: 'av_goat', kind: ShopKind.avatar, price: 35),
    ShopItem(id: 'av_bear', kind: ShopKind.avatar, price: 35),
    ShopItem(id: 'av_sloth', kind: ShopKind.avatar, price: 40),
    ShopItem(id: 'av_gorilla', kind: ShopKind.avatar, price: 40),
    ShopItem(id: 'av_rhino', kind: ShopKind.avatar, price: 45),
    ShopItem(id: 'av_crocodile', kind: ShopKind.avatar, price: 45),
    ShopItem(id: 'av_snake', kind: ShopKind.avatar, price: 45),
    ShopItem(id: 'av_walrus', kind: ShopKind.avatar, price: 50),
    ShopItem(id: 'av_whale', kind: ShopKind.avatar, price: 50),
    ShopItem(id: 'av_narwhal', kind: ShopKind.avatar, price: 60),
    ShopItem(id: 'av_moose', kind: ShopKind.avatar, price: 60),
    ShopItem(id: 'av_buffalo', kind: ShopKind.avatar, price: 60),
    // Car colours (assets/game/car_<colour>.png).
    ShopItem(id: 'car_red', kind: ShopKind.car, price: 0, colors: [Color(0xFFE53935)]),
    ShopItem(id: 'car_blue', kind: ShopKind.car, price: 20, colors: [Color(0xFF1E88E5)]),
    ShopItem(id: 'car_green', kind: ShopKind.car, price: 20, colors: [Color(0xFF43A047)]),
    ShopItem(id: 'car_yellow', kind: ShopKind.car, price: 25, colors: [Color(0xFFFDD835)]),
    ShopItem(id: 'car_black', kind: ShopKind.car, price: 30, colors: [Color(0xFF424242)]),
    // Balloon themes.
    ShopItem(
      id: 'theme_rainbow',
      kind: ShopKind.balloon,
      price: 0,
      colors: [Color(0xFFE53935), Color(0xFFFB8C00), Color(0xFF43A047), Color(0xFF1E88E5), Color(0xFF8E24AA)],
    ),
    ShopItem(
      id: 'theme_pastel',
      kind: ShopKind.balloon,
      price: 40,
      colors: [Color(0xFFF48FB1), Color(0xFF90CAF9), Color(0xFFA5D6A7), Color(0xFFFFCC80), Color(0xFFCE93D8)],
    ),
    ShopItem(
      id: 'theme_ocean',
      kind: ShopKind.balloon,
      price: 40,
      colors: [Color(0xFF0277BD), Color(0xFF00ACC1), Color(0xFF26A69A), Color(0xFF5C6BC0)],
    ),
    ShopItem(
      id: 'theme_sunset',
      kind: ShopKind.balloon,
      price: 40,
      colors: [Color(0xFFFF7043), Color(0xFFFFA726), Color(0xFFEC407A), Color(0xFFAB47BC)],
    ),
    ShopItem(
      id: 'theme_candy',
      kind: ShopKind.balloon,
      price: 50,
      colors: [Color(0xFFFF4081), Color(0xFF7C4DFF), Color(0xFF00E5FF), Color(0xFFFFEA00), Color(0xFF76FF03)],
    ),
  ];

  static ShopItem byId(String id) => items.firstWhere((i) => i.id == id, orElse: () => items.first);

  static List<ShopItem> ofKind(ShopKind k) => items.where((i) => i.kind == k).toList();

  static List<ShopItem> get freeAvatars => items.where((i) => i.kind == ShopKind.avatar && i.isFree).toList();

  static Color carColor(String id) {
    final i = byId(id);
    return i.kind == ShopKind.car ? i.colors.first : const Color(0xFFE53935);
  }

  static List<Color> balloonColors(String id) {
    final i = byId(id);
    return i.kind == ShopKind.balloon ? i.colors : ofKind(ShopKind.balloon).first.colors;
  }
}
