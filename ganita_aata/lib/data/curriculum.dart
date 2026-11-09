import '../models/topic.dart';

/// The content levels and topics, in unlock order.
///
/// To add a topic: add it here, teach [SumGenerator] how to make its sums,
/// and add `topic_<id>` strings to both ARB files (see README).
class Curriculum {
  Curriculum._();

  static const levels = <Level>[
    Level(
      number: 1,
      fromClass: 1,
      toClass: 2,
      topics: [
        Topic(id: 'num100', level: 1),
        Topic(id: 'add1', level: 1),
        Topic(id: 'sub1', level: 1),
      ],
    ),
    Level(
      number: 2,
      fromClass: 3,
      toClass: 3,
      topics: [
        Topic(id: 'add2', level: 2),
        Topic(id: 'sub2', level: 2),
        Topic(id: 'tab2_5', level: 2, tables: [2, 3, 4, 5]),
      ],
    ),
    Level(
      number: 3,
      fromClass: 4,
      toClass: 4,
      topics: [
        Topic(id: 'tab6_10', level: 3, tables: [6, 7, 8, 9, 10]),
        Topic(id: 'add3', level: 3),
        Topic(id: 'sub3', level: 3),
        Topic(id: 'div1', level: 3),
      ],
    ),
    Level(
      number: 4,
      fromClass: 5,
      toClass: 5,
      topics: [
        Topic(id: 'tab11_20', level: 4, tables: [11, 12, 13, 14, 15, 16, 17, 18, 19, 20]),
        Topic(id: 'mul21', level: 4),
        Topic(id: 'divRem', level: 4),
      ],
    ),
    Level(
      number: 5,
      fromClass: 6,
      toClass: 8,
      topics: [
        Topic(id: 'mixed', level: 5),
        Topic(id: 'squares', level: 5),
        Topic(id: 'cubes', level: 5),
        Topic(id: 'percent', level: 5),
        Topic(id: 'fractions', level: 5),
      ],
    ),
  ];

  /// All topics in unlock order.
  static final List<Topic> topics = [for (final l in levels) ...l.topics];

  static Topic topic(String id) => topics.firstWhere((t) => t.id == id, orElse: () => topics.first);

  static Level level(int n) => levels[(n.clamp(1, levels.length)) - 1];

  /// The level that matches a school class (1–8).
  static int levelForClass(int schoolClass) =>
      levels.firstWhere((l) => schoolClass <= l.toClass, orElse: () => levels.last).number;

  /// The topic after [id] in unlock order, or null for the last topic.
  static Topic? nextTopic(String id) {
    final i = topics.indexWhere((t) => t.id == id);
    return (i < 0 || i + 1 >= topics.length) ? null : topics[i + 1];
  }

  /// Topics unlocked for a new child: every topic of earlier levels plus the
  /// first topic of the child's own level.
  static Set<String> initialUnlocked(int schoolClass) {
    final lvl = levelForClass(schoolClass);
    return {
      for (final t in topics)
        if (t.level < lvl) t.id,
      level(lvl).topics.first.id,
    };
  }

  /// The topic that drills table [n] (2–20).
  static Topic topicForTable(int n) =>
      topics.firstWhere((t) => t.tables?.contains(n) ?? false, orElse: () => topics.first);
}
