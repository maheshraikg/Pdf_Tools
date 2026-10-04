import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../panchanga/festivals.dart';
import '../panchanga/names.dart';
import 'day_detail_screen.dart';
import '../app/theme.dart';
import '../art/festival_art.dart';
import 'fancy.dart';

/// Year list of festivals, vratas and sankramanas, grouped by month.
class FestivalsScreen extends StatefulWidget {
  const FestivalsScreen({super.key});

  @override
  State<FestivalsScreen> createState() => _FestivalsScreenState();
}

class _FestivalsScreenState extends State<FestivalsScreen> {
  int? _year;
  final Set<FestivalCategory> _cats = {
    FestivalCategory.major,
    FestivalCategory.tulu,
  };
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s, lang = context.lang, repo = context.repo;
    final today = todayAt(repo.engine);
    final year = _year ?? today.year;
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: LipiText(s.festivals),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _year = year - 1),
          ),
          Center(child: Text('$year', style: t.textTheme.titleMedium)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() => _year = year + 1),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (final c in FestivalCategory.values)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: FilterChip(
                      label: LipiText(c.label.of(lang)),
                      selected: _cats.contains(c),
                      onSelected: (v) => setState(() {
                        if (v) {
                          _cats.add(c);
                        } else {
                          _cats.remove(c);
                        }
                      }),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<FestivalOccurrence>>(
              future: repo.festivals(year),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 8),
                        LipiText(s.loading),
                      ],
                    ),
                  );
                }
                final list = snap.data!
                    .where((o) => _cats.contains(o.festival.category))
                    .toList();
                if (list.isEmpty) return Center(child: LipiText(s.noFestivals));
                final items = <Widget>[];
                int? month;
                for (final o in list) {
                  if (o.date.month != month) {
                    month = o.date.month;
                    items.add(
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: TuluColors.flagGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                gregMonthName(lang, month),
                                style: t.textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Expanded(child: FlowerDivider()),
                          ],
                        ),
                      ),
                    );
                  }
                  final past = o.date.isBefore(today);
                  final isToday = o.date == today;
                  items.add(
                    Opacity(
                      opacity: past ? 0.55 : 1,
                      child: Card(
                        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                        color: isToday
                            ? t.colorScheme.secondaryContainer
                            : null,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => showFestivalSheet(context, o),
                          onLongPress: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DayDetailScreen(date: o.date),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Hero(
                                  tag: 'art-${o.festival.id}-${o.date}',
                                  child: FestivalArt.of(
                                    o.festival,
                                    size: 56,
                                    animate: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      LipiText(
                                        o.festival.name.of(lang),
                                        style: t.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      LipiText(
                                        [
                                          varaNames[o.date.weekday % 7].of(
                                            lang,
                                          ),
                                          if (o.festival.category ==
                                                  FestivalCategory.vrata &&
                                              o.detail.isNotEmpty)
                                            o.detail.split(';').first,
                                        ].join(' · '),
                                        style: t.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 48,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: TuluColors.red.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${o.date.day}',
                                        style: t.textTheme.titleLarge?.copyWith(
                                          color: TuluColors.red,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: LipiText(
                                          varaShort[o.date.weekday % 7].of(
                                            lang,
                                          ),
                                          maxLines: 1,
                                          style: t.textTheme.labelSmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return ListView(
                  controller: _controller,
                  padding: const EdgeInsets.only(bottom: 24),
                  children: items,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
