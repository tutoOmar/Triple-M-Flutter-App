String formatDisplayNumber(num value, {int fractionDigits = 2}) {
  final numericValue = value.toDouble();

  if (numericValue.isNaN || numericValue.isInfinite) {
    return numericValue.toString();
  }

  final fixed = numericValue.toStringAsFixed(fractionDigits);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}