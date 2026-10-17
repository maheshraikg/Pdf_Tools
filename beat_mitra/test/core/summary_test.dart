import 'package:beat_mitra/core/article_number.dart';
import 'package:beat_mitra/core/l10n/app_localizations_en.dart';
import 'package:beat_mitra/data/models.dart';
import 'package:beat_mitra/features/summary/summary_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('day summary counts and share text (no addressee names)', () {
    final s = DaySummary(
      '2026-10-03',
      [
        Article(
          id: 1,
          date: '2026-10-03',
          articleNo: 'EK123456785IN',
          type: ArticleType.speedPost,
          status: ArticleStatus.delivered,
          placeId: 1,
          lat: 12.97,
          lng: 77.64,
          deliveredAt: 1,
        ),
        Article(
          id: 2,
          date: '2026-10-03',
          type: ArticleType.letter,
          status: ArticleStatus.notDelivered,
          reason: 'doorLocked',
          placeId: 2,
          lat: 12.98,
          lng: 77.64,
          deliveredAt: 2,
        ),
        Article(
          id: 3,
          date: '2026-10-03',
          type: ArticleType.letter,
          status: ArticleStatus.notDelivered,
          reason: 'refused',
        ),
        Article(id: 4, date: '2026-10-03', type: ArticleType.parcel),
      ],
      plannedMeters: 1500,
      placeTitles: {1: '12, 4th Cross', 2: '14, 4th Cross'},
    );
    expect(s.count(ArticleStatus.delivered), 1);
    expect(s.count(ArticleStatus.notDelivered, ArticleType.letter), 2);
    expect(s.reattempts.length, 1);
    expect(s.recordedMeters, closeTo(1112, 5));
    final text = s.toText(AppLocalizationsEn());
    expect(text, contains('Total 4: delivered 1, not delivered 2, pending 1'));
    expect(text, contains('14, 4th Cross – Door locked'));
    expect(text, contains('Refused'));
    expect(text, contains('Speed Post: 1/1 delivered'));
  });
}
