import 'package:finaper/core/icons/app_icon_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppIconCatalog', () {
    test('resolve returns the expected icon for a known codePoint', () {
      final icon = AppIconCatalog.resolve(Icons.savings_rounded.codePoint);
      expect(icon, Icons.savings_rounded);
    });

    test('resolve returns fallback for an unknown codePoint', () {
      final icon = AppIconCatalog.resolve(-1);
      expect(icon, AppIconCatalog.fallback);
    });

    test('all supported icon codePoints are unique', () {
      final codePoints = AppIconCatalog.supportedIcons
          .map((icon) => icon.codePoint)
          .toSet();
      expect(codePoints.length, AppIconCatalog.supportedIcons.length);
    });

    test('resolve covers all seeded category icons without falling back', () {
      const seededIcons = [
        Icons.restaurant_rounded,
        Icons.directions_car_rounded,
        Icons.home_rounded,
        Icons.favorite_rounded,
        Icons.movie_rounded,
        Icons.power_rounded,
        Icons.school_rounded,
        Icons.subscriptions_rounded,
        Icons.shopping_bag_rounded,
        Icons.swap_horiz_rounded,
        Icons.more_horiz_rounded,
        Icons.payments_rounded,
        Icons.work_rounded,
        Icons.trending_up_rounded,
        Icons.replay_circle_filled_rounded,
        Icons.card_giftcard_rounded,
      ];
      for (final icon in seededIcons) {
        expect(
          AppIconCatalog.resolve(icon.codePoint),
          icon,
          reason: 'Seeded icon ${icon.codePoint} should resolve without fallback',
        );
      }
    });
  });
}
