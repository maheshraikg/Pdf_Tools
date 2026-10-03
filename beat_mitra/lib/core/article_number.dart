/// Article (tracking) number helpers. India Post uses the UPU S10 format:
/// two letters, eight digits + one check digit, two letters ("EK123456789IN").
library;

final RegExp _s10 = RegExp(r'^[A-Z]{2}\d{9}[A-Z]{2}$');

/// Cleans user / scanner input: upper case, no spaces or dashes.
String cleanArticleNumber(String input) => input.toUpperCase().replaceAll(RegExp(r'[\s\-_.]'), '');

/// True when [input] has the S10 shape (letters/digits), check digit ignored.
bool isS10ArticleNumber(String input) => _s10.hasMatch(cleanArticleNumber(input));

/// UPU S10 check digit for the 8 serial digits.
int s10CheckDigit(String eightDigits) {
  const weights = [8, 6, 4, 2, 3, 5, 9, 7];
  var sum = 0;
  for (var i = 0; i < 8; i++) {
    sum += (eightDigits.codeUnitAt(i) - 48) * weights[i];
  }
  final c = 11 - (sum % 11);
  if (c == 10) return 0;
  if (c == 11) return 5;
  return c;
}

enum ArticleNumberStatus {
  /// S10 shape and the check digit is right.
  valid,

  /// S10 shape but the check digit does not match (probably a typo).
  badCheckDigit,

  /// Some other format: allowed, but shown with a warning.
  otherFormat,

  /// Empty or too short to be useful.
  invalid,
}

ArticleNumberStatus validateArticleNumber(String input) {
  final s = cleanArticleNumber(input);
  if (s.length < 4 || !RegExp(r'^[A-Z0-9]+$').hasMatch(s)) return ArticleNumberStatus.invalid;
  if (!_s10.hasMatch(s)) return ArticleNumberStatus.otherFormat;
  final digits = s.substring(2, 11);
  return s10CheckDigit(digits.substring(0, 8)) == digits.codeUnitAt(8) - 48
      ? ArticleNumberStatus.valid
      : ArticleNumberStatus.badCheckDigit;
}

/// Article types used in the app.
enum ArticleType { letter, registered, speedPost, parcel, moneyOrder, other }

extension ArticleTypeX on ArticleType {
  /// Registered, Speed Post and money orders need a signature / OTP.
  bool get needsSignature =>
      this == ArticleType.registered || this == ArticleType.speedPost || this == ArticleType.moneyOrder;

  String get code => name;

  static ArticleType fromCode(String? code) =>
      ArticleType.values.firstWhere((t) => t.name == code, orElse: () => ArticleType.other);
}

/// Guess the type from the S10 service indicator (first letter).
ArticleType? guessArticleType(String input) {
  final s = cleanArticleNumber(input);
  if (!_s10.hasMatch(s)) return null;
  switch (s[0]) {
    case 'E':
      return ArticleType.speedPost;
    case 'R':
      return ArticleType.registered;
    case 'C':
    case 'P':
      return ArticleType.parcel;
    default:
      return null;
  }
}
