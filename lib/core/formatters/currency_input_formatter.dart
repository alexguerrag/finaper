import 'package:flutter/services.dart';

/// Formats numeric input with period thousands separator.
///
/// Zero-decimal mode (CLP): digits only, e.g. "20.000"
/// Decimal mode (USD/EUR):   digits + comma decimal, e.g. "1.234,56"
class ThousandsInputFormatter extends TextInputFormatter {
  ThousandsInputFormatter({this.decimalDigits = 0});

  factory ThousandsInputFormatter.forCurrency(String currencyCode) {
    const zeroDecimal = {'CLP', 'COP'};
    return ThousandsInputFormatter(
      decimalDigits: zeroDecimal.contains(currencyCode) ? 0 : 2,
    );
  }

  final int decimalDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (decimalDigits == 0) {
      final digits = text.replaceAll(RegExp(r'[^\d]'), '');
      if (digits.isEmpty) {
        return newValue.copyWith(
          text: '',
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
      final formatted = _addPeriodThousands(digits);
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else {
      // Allow digits and at most one comma for decimal separator.
      final cleaned = text.replaceAll(RegExp(r'[^\d,]'), '');
      final commaIndex = cleaned.indexOf(',');

      final String intRaw;
      final String? decRaw;

      if (commaIndex == -1) {
        intRaw = cleaned;
        decRaw = null;
      } else {
        intRaw = cleaned.substring(0, commaIndex);
        final afterComma = cleaned.substring(commaIndex + 1);
        decRaw = afterComma.length > decimalDigits
            ? afterComma.substring(0, decimalDigits)
            : afterComma;
      }

      final formattedInt = intRaw.isEmpty ? '' : _addPeriodThousands(intRaw);
      final formatted =
          decRaw != null ? '$formattedInt,$decRaw' : formattedInt;

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  static String _addPeriodThousands(String digits) {
    // Strip leading zeros but keep at least one digit.
    final trimmed = digits.replaceAll(RegExp(r'^0+'), '');
    final n = trimmed.isEmpty ? '0' : trimmed;

    final buf = StringBuffer();
    for (int i = 0; i < n.length; i++) {
      if (i > 0 && (n.length - i) % 3 == 0) buf.write('.');
      buf.write(n[i]);
    }
    return buf.toString();
  }

  /// Converts a formatted input string back to a parseable decimal string.
  ///
  /// "20.000" → "20000", "1.234,56" → "1234.56"
  static double? parse(String text) {
    // Remove period thousands separator, replace comma decimal with period.
    final normalized =
        text.replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(normalized);
  }

  /// Formats a numeric value for display in an input field.
  static String formatForInput(double value, {int decimalDigits = 0}) {
    if (decimalDigits == 0) {
      return _addPeriodThousands(value.round().toString());
    }
    final intPart = value.truncate().toString();
    final decPart = (value - value.truncate())
        .toStringAsFixed(decimalDigits)
        .substring(2); // strip "0."
    return '${_addPeriodThousands(intPart)},$decPart';
  }
}
