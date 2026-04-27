import 'package:intl/date_symbol_data_local.dart';

/// Initializes intl locale data for test environments.
///
/// In production this is handled automatically by flutter_localizations when
/// the widget tree bootstraps. Unit tests bypass that bootstrapping, so any
/// test that exercises date-formatting code must call this in setUpAll.
Future<void> initTestLocales() => initializeDateFormatting();
