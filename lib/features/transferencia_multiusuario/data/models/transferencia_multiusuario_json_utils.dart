/// Helpers de parseo defensivo para las respuestas Odoo, que suelen mandar
/// `false` en vez de `null`/`""` para campos vacíos (numéricos, texto o
/// booleanos legítimos quedan indistinguibles de "vacío" en ese caso).
///
/// Copiado textual de
/// `features/recepcion_multiusuario/data/models/recepcion_multiusuario_json_utils.dart`
/// — mismo backend, mismo problema.
String? dynamicToString(dynamic value) {
  if (value == null || value is bool) return null;
  return value.toString();
}

int? dynamicToInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return null;
}

double? dynamicToDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return null;
}

bool? dynamicToBool(dynamic value) {
  if (value is bool) return value;
  return null;
}
