import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../panchanga/festivals.dart';
import '../panchanga/names.dart';
import 'day_detail_screen.dart';
import 'day_widgets.dart';

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
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(
                          gregMonthName(lang, month),
                          style: t.textTheme.titleMedium?.copyWith(
                            color: t.colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  }
                  final past = o.date.isBefore(today);
                  items.add(
                    Opacity(
                      opacity: past ? 0.55 : 1,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 64,
                            child: Column(
                              children: [
                                Text(
                                  '${o.date.day}',
                                  style: t.textTheme.titleLarge,
                                ),
                                LipiText(
                                  varaShort[o.date.weekday % 7].of(lang),
                                  style: t.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: FestivalTile(
                              o: o,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => DayDetailScreen(date: o.date),
                                ),
                              ),
                            ),
                          ),
                        ],
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
