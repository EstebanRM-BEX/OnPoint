/// Helpers para leer el JSON de Odoo, que manda `false` en vez de null y
/// campos relacionales como `[id, "nombre"]`.
class OdooParse {
  const OdooParse._();

  /// Texto; `false`/null → ''.
  static String str(dynamic v) {
    if (v == null || v == false) return '';
    if (v is List) return v.length > 1 ? '${v[1]}' : '';
    return '$v';
  }

  static int? integer(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is List && v.isNotEmpty) return integer(v.first);
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double dbl(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static bool boolean(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }

  /// Id de un relacional `[id, nombre]` (o el entero suelto).
  static int? refId(dynamic v) => integer(v);

  /// Nombre de un relacional `[id, nombre]`.
  static String refName(dynamic v) =>
      (v is List && v.length > 1) ? '${v[1]}' : '';

  static DateTime? date(dynamic v) {
    if (v is! String || v.isEmpty) return null;
    return DateTime.tryParse(v);
  }

  static List<Map<String, dynamic>> maps(dynamic v) {
    if (v is! List) return const [];
    return v.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }
}
