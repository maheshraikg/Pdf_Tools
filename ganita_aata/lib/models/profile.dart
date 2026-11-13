/// A child using the app. Only the first name and class are personal data,
/// and they never leave the phone.
class Profile {
  Profile({
    required this.id,
    required this.name,
    required this.schoolClass,
    required this.avatar,
    required this.unlocked,
    required this.currentTopic,
    this.coins = 0,
    Set<String>? owned,
    this.carColor = 'car_red',
    this.balloonTheme = 'theme_rainbow',
    Set<String>? badges,
    this.streak = 0,
    this.lastDailyDate,
    Map<String, int>? speedBest,
  }) : owned = owned ?? {},
       badges = badges ?? {},
       speedBest = speedBest ?? {};

  final String id;
  String name;

  /// 1–8.
  int schoolClass;

  /// Shop item id of the avatar, e.g. `av_monkey`.
  String avatar;
  int coins;

  /// Shop items bought (free items are always owned).
  final Set<String> owned;
  String carColor;
  String balloonTheme;
  final Set<String> badges;

  /// Unlocked topic ids.
  final Set<String> unlocked;
  String currentTopic;

  /// Daily Challenge streak, counted up to [lastDailyDate] (yyyy-mm-dd).
  int streak;
  String? lastDailyDate;

  /// Speed Challenge personal best per topic.
  final Map<String, int> speedBest;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'class': schoolClass,
    'avatar': avatar,
    'coins': coins,
    'owned': owned.toList(),
    'car': carColor,
    'balloon': balloonTheme,
    'badges': badges.toList(),
    'unlocked': unlocked.toList(),
    'topic': currentTopic,
    'streak': streak,
    'lastDaily': lastDailyDate,
    'speedBest': speedBest,
  };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    id: j['id'] as String,
    name: j['name'] as String,
    schoolClass: j['class'] as int? ?? 1,
    avatar: j['avatar'] as String? ?? 'av_monkey',
    coins: j['coins'] as int? ?? 0,
    owned: {...(j['owned'] as List? ?? const []).cast<String>()},
    carColor: j['car'] as String? ?? 'car_red',
    balloonTheme: j['balloon'] as String? ?? 'theme_rainbow',
    badges: {...(j['badges'] as List? ?? const []).cast<String>()},
    unlocked: {...(j['unlocked'] as List? ?? const []).cast<String>()},
    currentTopic: j['topic'] as String? ?? 'num100',
    streak: j['streak'] as int? ?? 0,
    lastDailyDate: j['lastDaily'] as String?,
    speedBest: {for (final e in ((j['speedBest'] as Map?) ?? const {}).entries) e.key as String: e.value as int},
  );
}
