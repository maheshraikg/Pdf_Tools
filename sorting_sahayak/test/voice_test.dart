import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/core/voice.dart';

void main() {
  test('spoken digits in three languages', () {
    expect(spokenToDigits('five seven four two zero one'), '574201');
    expect(spokenToDigits('574 201'), '574201');
    expect(spokenToDigits('five seven four double zero one'), '574001');
    expect(spokenToDigits('ಐದು ಏಳು ನಾಲ್ಕು ಎರಡು ಸೊನ್ನೆ ಒಂದು'), '574201');
    expect(spokenToDigits('ಐದು ಏಳು ನಾಲ್ಕು ೨೦೧'), '574201');
    expect(spokenToDigits('पांच सात चार दो शून्य एक'), '574201');
    expect(spokenToDigits('PIN is 560 001 please'), '560001');
  });
}
