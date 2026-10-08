/// Formatea cantidades como lo hacía el legacy (que recibía `dynamic` del
/// JSON): enteros sin ".0" y decimales tal cual.
String formatCantidad(num? value) {
  if (value == null) return '0';
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toString();
}

/// Devuelve [fallback] si el texto viene vacío (las entities usan `''` en
/// lugar de `null`).
String orDefault(String? value, String fallback) =>
    (value == null || value.trim().isEmpty) ? fallback : value;
