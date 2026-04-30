import 'package:flutter/foundation.dart';

import '../../domain/entities/ledger_entity.dart';
import '../../domain/entities/premium_reports_entity.dart';
import '../../domain/usecases/get_premium_reports.dart';

class PremiumReportsController extends ChangeNotifier {
  PremiumReportsController({required GetPremiumReports getPremiumReports})
      : _getPremiumReports = getPremiumReports;

  final GetPremiumReports _getPremiumReports;

  bool _isLoading = false;
  PremiumReportsEntity? _reports;
  String? _errorMessage;
  DateTime? _currentMonth;
  LedgerPeriod _ledgerPeriod = LedgerPeriod.days30;

  bool get isLoading => _isLoading;
  PremiumReportsEntity? get reports => _reports;
  String? get errorMessage => _errorMessage;
  LedgerPeriod get ledgerPeriod => _ledgerPeriod;

  Future<void> load(DateTime month) async {
    _currentMonth = month;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reports = await _getPremiumReports(
        month: month,
        ledgerPeriod: _ledgerPeriod,
      );
    } catch (_) {
      _errorMessage = 'No se pudieron cargar los reportes.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setLedgerPeriod(LedgerPeriod period) async {
    if (_ledgerPeriod == period) return;
    _ledgerPeriod = period;
    if (_currentMonth != null) await load(_currentMonth!);
  }
}
