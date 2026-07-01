import 'package:checkplan/core/validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts a normal title', () => expect(titleError('Groceries'), isNull));

  test('rejects empty and whitespace-only titles', () {
    expect(titleError(''), isNotNull);
    expect(titleError('   '), isNotNull);
  });

  test('rejects titles longer than the maximum', () {
    expect(titleError('a' * (maxTitleLength + 1)), isNotNull);
    expect(titleError('a' * maxTitleLength), isNull);
  });

  group('passwordPairError', () {
    test('accepts a long-enough password that matches its confirmation', () {
      expect(passwordPairError('correct horse', 'correct horse'), isNull);
    });

    test('rejects a password shorter than the minimum', () {
      final short = 'a' * (minPasswordLength - 1);
      expect(passwordPairError(short, short), isNotNull);
    });

    test('rejects when the confirmation does not match', () {
      expect(passwordPairError('hunter2xyz', 'hunter2xy-'), isNotNull);
    });

    test('does not trim — a password is exactly what was typed', () {
      // Trailing space is a legitimate password character; only an exact match
      // passes, and a mismatch on whitespace is still a mismatch.
      expect(passwordPairError('secret  ', 'secret  '), isNull);
      expect(passwordPairError('secret  ', 'secret'), isNotNull);
    });
  });
}
