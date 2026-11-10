import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/languages.dart';
import '../services/app_state.dart';
import 'app_theme.dart';
import 'common.dart';

/// All app languages as big tappable tiles (native name + English name).
class LanguageGrid extends StatelessWidget {
  const LanguageGrid({super.key, this.onPicked});

  final VoidCallback? onPicked;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.3,
      children: [
        for (var i = 0; i < Languages.all.length; i++)
          Builder(
            builder: (context) {
              final lang = Languages.all[i];
              final on = app.lang == lang.code;
              return ChunkyButton(
                key: ValueKey('lang_${lang.code}'),
                color: on ? AppColors.card(i).$1 : Colors.white,
                edgeColor: on ? AppColors.card(i).$2 : const Color(0xFFD5CFEA),
                radius: 20,
                depth: 5,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                onTap: () {
                  context.read<AppState>().setLanguage(lang.code);
                  onPicked?.call();
                },
                child: Row(
                  children: [
                    if (on) const AppImage('check', size: 26),
                    if (on) const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(lang.nativeName, style: display(24, color: on ? Colors.white : AppColors.ink)),
                          ),
                          if (lang.code != 'en')
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                lang.englishName,
                                style: TextStyle(fontSize: 12, color: on ? Colors.white : AppColors.inkSoft),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
