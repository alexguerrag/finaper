enum PremiumPackagePeriod { monthly, annual, other }

class PremiumPackage {
  const PremiumPackage({
    required this.id,
    required this.title,
    required this.priceString,
    required this.period,
    required this.rawPackage,
  });

  final String id;
  final String title;
  final String priceString;
  final PremiumPackagePeriod period;

  /// Referencia opaca al objeto Package de RevenueCat.
  /// Solo la capa data hace el cast de vuelta a Package.
  final Object rawPackage;
}
