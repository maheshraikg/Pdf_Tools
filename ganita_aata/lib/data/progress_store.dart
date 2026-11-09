import '../models/stats.dart';

/// Where a child's learning statistics are kept. The app uses the Hive
/// implementation; tests use [MemoryProgressStore].
abstract class ProgressStore {
  Map<String, FactStat> loadFacts(String profileId);
  Map<String, TopicStat> loadTopics(String profileId);
  Map<String, DayStat> loadDays(String profileId);

  void saveFact(String profileId, FactStat f);
  void saveTopic(String profileId, TopicStat t);
  void saveDay(String profileId, DayStat d);
  void appendLog(String profileId, AnswerRecord r);

  Future<void> clear(String profileId);
}

class MemoryProgressStore implements ProgressStore {
  final facts = <String, Map<String, FactStat>>{};
  final topics = <String, Map<String, TopicStat>>{};
  final days = <String, Map<String, DayStat>>{};
  final log = <String, List<AnswerRecord>>{};

  @override
  Map<String, FactStat> loadFacts(String p) => Map.of(facts[p] ?? {});
  @override
  Map<String, TopicStat> loadTopics(String p) => Map.of(topics[p] ?? {});
  @override
  Map<String, DayStat> loadDays(String p) => Map.of(days[p] ?? {});

  @override
  void saveFact(String p, FactStat f) => (facts[p] ??= {})[f.key] = f;
  @override
  void saveTopic(String p, TopicStat t) => (topics[p] ??= {})[t.topicId] = t;
  @override
  void saveDay(String p, DayStat d) => (days[p] ??= {})[d.date] = d;
  @override
  void appendLog(String p, AnswerRecord r) => (log[p] ??= []).add(r);

  @override
  Future<void> clear(String p) async {
    facts.remove(p);
    topics.remove(p);
    days.remove(p);
    log.remove(p);
  }
}
