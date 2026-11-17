import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_track/core/theme/app_theme.dart';

void main() {
  test('AppTheme provides light and dark Material 3 themes', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.light.useMaterial3, isTrue);
    expect(AppTheme.dark.useMaterial3, isTrue);
  });
}
