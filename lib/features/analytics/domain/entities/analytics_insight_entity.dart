enum InsightSeverity { positive, warning, neutral }

class AnalyticsInsightEntity {
  const AnalyticsInsightEntity({
    required this.message,
    required this.severity,
  });

  final String message;
  final InsightSeverity severity;
}
