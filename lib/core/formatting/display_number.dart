String formatDisplayNumber(num value, {int fractionDigits = 2}) {
  final numericValue = value.toDouble();

  if (numericValue.isNaN || numericValue.isInfinite) {
    return numericValue.toString();
  }

  final absoluteValue = numericValue.abs();
  final fixed = absoluteValue.toStringAsFixed(fractionDigits);
  final parts = fixed.split('.');
  final integerPart = _groupThousands(parts.first);
  final decimalPart = parts.length > 1 ? parts[1].replaceFirst(RegExp(r'0+$'), '') : '';
  final sign = numericValue.isNegative && numericValue != 0 ? '-' : '';

  if (decimalPart.isEmpty) {
    return '$sign$integerPart';
  }

  return '$sign$integerPart.$decimalPart';
}

String _groupThousands(String digits) {
  if (digits.length <= 3) {
    return digits;
  }

  final buffer = StringBuffer();
  final start = digits.length % 3;

  if (start != 0) {
    buffer.write(digits.substring(0, start));
    if (digits.length > start) {
      buffer.write(',');
    }
  }

  for (var index = start; index < digits.length; index += 3) {
    buffer.write(digits.substring(index, index + 3));
    if (index + 3 < digits.length) {
      buffer.write(',');
    }
  }

  return buffer.toString();
}