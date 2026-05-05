enum EntitlementStatus {
  free,
  trial,
  premium,
  expired,
}

extension EntitlementStatusX on EntitlementStatus {
  bool get hasPremiumAccess =>
      this == EntitlementStatus.trial || this == EntitlementStatus.premium;

  bool get isPaid => this == EntitlementStatus.premium;

  bool get isTrial => this == EntitlementStatus.trial;

  bool get isExpired => this == EntitlementStatus.expired;
}
