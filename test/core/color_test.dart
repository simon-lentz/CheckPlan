import 'package:checkplan/core/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('readableOn returns white on a dark colour, black on a light one', () {
    expect(readableOn(Colors.black), Colors.white);
    expect(readableOn(Colors.white), Colors.black);
  });
}
