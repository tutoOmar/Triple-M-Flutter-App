import 'package:flutter/services.dart';

import 'display_number.dart';

class MoneyTextInputFormatter extends TextInputFormatter {
  const MoneyTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final parsed = parseMoneyText(newValue.text);

    if (parsed == null) {
      return newValue.text.isEmpty ? const TextEditingValue(text: '') : oldValue;
    }

    final formatted = formatDisplayNumber(parsed, fractionDigits: 0);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

int? parseMoneyText(String value) {
  final sanitized = value.replaceAll(RegExp(r'[\s,]'), '');

  if (sanitized.isEmpty || !RegExp(r'^\d+$').hasMatch(sanitized)) {
    return null;
  }

  return int.tryParse(sanitized);
}