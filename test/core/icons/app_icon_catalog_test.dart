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

    // -------------------------------------------------------------------------
    // Seeded categories — system (DatabaseHelper._seedCategories, all versions)
    // -------------------------------------------------------------------------
    test('resolve covers all system-seeded expense category icons', () {
      const icons = [
        Icons.restaurant_rounded,       // Alimentación
        Icons.directions_car_rounded,   // Transporte
        Icons.home_rounded,             // Casa
        Icons.favorite_rounded,         // Salud
        Icons.movie_rounded,            // Ocio / Entretenimiento
        Icons.power_rounded,            // Servicios
        Icons.school_rounded,           // Educación
        Icons.subscriptions_rounded,    // Suscripciones / Streaming
        Icons.shopping_bag_rounded,     // Compras
        Icons.swap_horiz_rounded,       // Transferencia enviada (system)
        Icons.more_horiz_rounded,       // Otros — gasto por defecto (system)
      ];
      for (final icon in icons) {
        expect(
          AppIconCatalog.resolve(icon.codePoint),
          icon,
          reason: 'System expense icon ${icon.codePoint} debe resolver sin fallback',
        );
      }
    });

    test('resolve covers all system-seeded income category icons', () {
      const icons = [
        Icons.payments_rounded,              // Salario
        Icons.work_rounded,                  // Honorarios / Freelance
        Icons.trending_up_rounded,           // Inversiones
        Icons.replay_circle_filled_rounded,  // Reembolso
        Icons.card_giftcard_rounded,         // Bonos
        Icons.swap_horiz_rounded,            // Transferencia recibida (system)
        Icons.more_horiz_rounded,            // Otros — ingreso por defecto (system)
      ];
      for (final icon in icons) {
        expect(
          AppIconCatalog.resolve(icon.codePoint),
          icon,
          reason: 'System income icon ${icon.codePoint} debe resolver sin fallback',
        );
      }
    });

    // -------------------------------------------------------------------------
    // Seeded categories — v14 (DatabaseHelper migration to schema v14)
    // -------------------------------------------------------------------------
    test('resolve covers all v14-seeded expense category icons', () {
      const icons = [
        Icons.directions_car_rounded,      // Automóvil
        Icons.local_gas_station_rounded,   // Combustible
        Icons.toll_rounded,                // Autopistas / Peajes
        Icons.shopping_cart_rounded,       // Supermercado
        Icons.checkroom_rounded,           // Ropa y Calzado
        Icons.home_repair_service_rounded, // Servicios Hogar
        Icons.house_rounded,               // Arriendo / Hipoteca
        Icons.local_cafe_rounded,          // Snack / Bebidas
        Icons.lunch_dining_rounded,        // Restaurante
        Icons.phone_android_rounded,       // Comunicaciones
        Icons.fitness_center_rounded,      // Deportes
        Icons.healing_rounded,             // Dental
        Icons.local_pharmacy_rounded,      // Farmacia
        Icons.cleaning_services_rounded,   // Artículos de Aseo
        Icons.pets_rounded,                // Mascotas
        Icons.security_rounded,            // Seguros
        Icons.receipt_long_rounded,        // Facturas
        Icons.currency_exchange_rounded,   // Gasto Financiero
        Icons.apartment_rounded,           // Gastos Edificio / Condominio
        Icons.card_giftcard_rounded,       // Regalos
        Icons.volunteer_activism_rounded,  // Donaciones
        Icons.flight_rounded,              // Viajes / Vacaciones
      ];
      for (final icon in icons) {
        expect(
          AppIconCatalog.resolve(icon.codePoint),
          icon,
          reason: 'v14 expense icon ${icon.codePoint} debe resolver sin fallback',
        );
      }
    });

    test('resolve covers all v14-seeded income category icons', () {
      const icons = [
        Icons.domain_rounded,   // Arriendo Recibido
        Icons.elderly_rounded,  // Pensión / Jubilación
      ];
      for (final icon in icons) {
        expect(
          AppIconCatalog.resolve(icon.codePoint),
          icon,
          reason: 'v14 income icon ${icon.codePoint} debe resolver sin fallback',
        );
      }
    });

    // -------------------------------------------------------------------------
    // Account and goal icons
    // -------------------------------------------------------------------------
    test('resolve covers all account type icons', () {
      const icons = [
        Icons.account_balance_wallet_rounded, // cash
        Icons.account_balance_rounded,        // bank
        Icons.savings_rounded,                // savings
        Icons.credit_card_rounded,            // creditCard
        Icons.trending_up_rounded,            // investment
      ];
      for (final icon in icons) {
        expect(
          AppIconCatalog.resolve(icon.codePoint),
          icon,
          reason: 'Account icon ${icon.codePoint} debe resolver sin fallback',
        );
      }
    });

    test('resolve covers all goal preset icons', () {
      const icons = [
        Icons.savings_rounded,          // Ahorro
        Icons.flight_takeoff_rounded,   // Viaje
        Icons.home_rounded,             // Casa
        Icons.directions_car_rounded,   // Auto
        Icons.health_and_safety_rounded,// Emergencia
        Icons.flag_rounded,             // General
      ];
      for (final icon in icons) {
        expect(
          AppIconCatalog.resolve(icon.codePoint),
          icon,
          reason: 'Goal icon ${icon.codePoint} debe resolver sin fallback',
        );
      }
    });

    test('resolve covers category kind icons', () {
      const icons = [
        Icons.local_offer_rounded,  // expense kind
        Icons.attach_money_rounded, // income kind
      ];
      for (final icon in icons) {
        expect(
          AppIconCatalog.resolve(icon.codePoint),
          icon,
          reason: 'Category kind icon ${icon.codePoint} debe resolver sin fallback',
        );
      }
    });
  });
}
