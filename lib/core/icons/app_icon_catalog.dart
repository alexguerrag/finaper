import 'package:flutter/material.dart';

class AppIconCatalog {
  const AppIconCatalog._();

  static const IconData fallback = Icons.help_outline_rounded;

  static const List<IconData> supportedIcons = [
    // Accounts (from add_account_sheet.dart — _iconForType)
    Icons.account_balance_wallet_rounded,
    Icons.account_balance_rounded,
    Icons.savings_rounded,
    Icons.credit_card_rounded,
    Icons.trending_up_rounded,

    // Category kinds (from add_category_sheet.dart — _iconForKind)
    Icons.local_offer_rounded,
    Icons.attach_money_rounded,

    // Goal presets (from add_goal_sheet.dart)
    Icons.flight_takeoff_rounded,
    Icons.home_rounded,
    Icons.directions_car_rounded,
    Icons.health_and_safety_rounded,
    Icons.flag_rounded,

    // Seeded expense categories — system (database_helper.dart)
    Icons.restaurant_rounded,
    Icons.favorite_rounded,
    Icons.movie_rounded,
    Icons.power_rounded,
    Icons.school_rounded,
    Icons.subscriptions_rounded,
    Icons.shopping_bag_rounded,
    Icons.swap_horiz_rounded,
    Icons.more_horiz_rounded,

    // Seeded expense categories — v14
    Icons.local_gas_station_rounded,
    Icons.toll_rounded,
    Icons.shopping_cart_rounded,
    Icons.checkroom_rounded,
    Icons.home_repair_service_rounded,
    Icons.house_rounded,
    Icons.local_cafe_rounded,
    Icons.lunch_dining_rounded,
    Icons.phone_android_rounded,
    Icons.fitness_center_rounded,
    Icons.healing_rounded,
    Icons.local_pharmacy_rounded,
    Icons.cleaning_services_rounded,
    Icons.pets_rounded,
    Icons.security_rounded,
    Icons.receipt_long_rounded,
    Icons.currency_exchange_rounded,
    Icons.apartment_rounded,
    Icons.card_giftcard_rounded,
    Icons.volunteer_activism_rounded,
    Icons.flight_rounded,

    // Seeded income categories — system
    Icons.payments_rounded,
    Icons.work_rounded,
    Icons.replay_circle_filled_rounded,

    // Seeded income categories — v14
    Icons.domain_rounded,
    Icons.elderly_rounded,
  ];

  static final Map<int, IconData> _byCodePoint = {
    for (final icon in supportedIcons) icon.codePoint: icon,
  };

  static IconData resolve(int codePoint) =>
      _byCodePoint[codePoint] ?? fallback;
}
