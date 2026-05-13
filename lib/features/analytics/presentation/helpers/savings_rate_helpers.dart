/// [formattedAmount] must be the absolute value already formatted by the caller.
String savingsRateMessage(double rate, String formattedAmount) {
  if (rate >= 0) {
    return 'Ahorraste $formattedAmount de tus ingresos.';
  }
  if (rate.abs() <= 5) {
    return 'Gastaste $formattedAmount más de lo que ingresaste. '
        'Estás casi en equilibrio este mes.';
  }
  return 'Tus gastos superaron tus ingresos por $formattedAmount este mes.';
}

String deltaBadgeText(double delta, bool higherIsGood) {
  final isPositive = delta >= 0;
  final isGood = higherIsGood ? isPositive : !isPositive;
  if (delta.abs() > 50) {
    return isGood ? 'Mejoró vs mes anterior' : 'Bajó vs mes anterior';
  }
  final sign = isPositive ? '+' : '';
  return '$sign${delta.toStringAsFixed(1)} puntos vs mes anterior';
}
