import 'package:beat_mitra/core/article_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('S10 check digit', () {
    // Example from UPU S10: serial 47312482 -> check digit 9 (RR473124829US).
    expect(s10CheckDigit('47312482'), 9);
    expect(s10CheckDigit('12345678'), 5);
  });

  test('validation', () {
    expect(validateArticleNumber('RR473124829IN'), ArticleNumberStatus.valid);
    expect(validateArticleNumber('ek 123 456 785 in'), ArticleNumberStatus.valid);
    expect(validateArticleNumber('EK123456789IN'), ArticleNumberStatus.badCheckDigit);
    expect(validateArticleNumber('CPA12345'), ArticleNumberStatus.otherFormat);
    expect(validateArticleNumber('x'), ArticleNumberStatus.invalid);
    expect(validateArticleNumber(''), ArticleNumberStatus.invalid);
    expect(isS10ArticleNumber('EK123456789IN'), isTrue);
    expect(isS10ArticleNumber('E123456789IN'), isFalse);
  });

  test('type guess and signature flag', () {
    expect(guessArticleType('EK123456785IN'), ArticleType.speedPost);
    expect(guessArticleType('RR473124829IN'), ArticleType.registered);
    expect(guessArticleType('CP123456785IN'), ArticleType.parcel);
    expect(guessArticleType('LX123'), isNull);
    expect(ArticleType.speedPost.needsSignature, isTrue);
    expect(ArticleType.moneyOrder.needsSignature, isTrue);
    expect(ArticleType.letter.needsSignature, isFalse);
  });
}
