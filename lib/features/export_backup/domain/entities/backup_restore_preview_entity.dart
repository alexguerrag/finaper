class BackupRestorePreviewEntity {
  const BackupRestorePreviewEntity({
    required this.fileName,
    required this.exportedAt,
    required this.databaseVersion,
    required this.backupFormatVersion,
    required this.accountsCount,
    required this.categoriesCount,
    required this.transactionsCount,
    required this.budgetsCount,
    required this.goalsCount,
    required this.recurringTransactionsCount,
    required this.hasTransactionFormPreferences,
  });

  final String fileName;
  final DateTime? exportedAt;
  final int databaseVersion;
  final int backupFormatVersion;
  final int accountsCount;
  final int categoriesCount;
  final int transactionsCount;
  final int budgetsCount;
  final int goalsCount;
  final int recurringTransactionsCount;
  final bool hasTransactionFormPreferences;
}
