enum TransactionEntryType {
  standard('standard'),
  transferIn('transfer_in'),
  transferOut('transfer_out');

  const TransactionEntryType(this.storageValue);

  final String storageValue;

  bool get isTransfer => this != TransactionEntryType.standard;

  static TransactionEntryType fromStorage(String? raw) {
    switch (raw) {
      case 'transfer_in':
        return TransactionEntryType.transferIn;
      case 'transfer_out':
        return TransactionEntryType.transferOut;
      case 'standard':
      default:
        return TransactionEntryType.standard;
    }
  }
}
