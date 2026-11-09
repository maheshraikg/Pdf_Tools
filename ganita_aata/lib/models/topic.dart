/// A practice topic, e.g. "Tables 2–5". Topics are grouped into levels.
class Topic {
  const Topic({required this.id, required this.level, this.tables});

  final String id;

  /// 1–5.
  final int level;

  /// For table topics, the table numbers covered.
  final List<int>? tables;

  bool get isTables => tables != null;
}

/// A level in the level map.
class Level {
  const Level({required this.number, required this.fromClass, required this.toClass, required this.topics});

  final int number;
  final int fromClass;
  final int toClass;
  final List<Topic> topics;
}
