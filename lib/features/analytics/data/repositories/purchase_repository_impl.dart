import '../../domain/entities/premium_package.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../datasources/revenuecat_purchase_datasource.dart';

class PurchaseRepositoryImpl implements PurchaseRepository {
  const PurchaseRepositoryImpl(this._dataSource);

  final RevenueCatPurchaseDataSource _dataSource;

  @override
  Future<List<PremiumPackage>> getPackages() => _dataSource.getPackages();

  @override
  Future<void> purchase(PremiumPackage package) => _dataSource.purchase(package);

  @override
  Future<bool> restorePurchases() => _dataSource.restorePurchases();
}
