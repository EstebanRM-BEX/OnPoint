


import 'package:intl/intl.dart';

//formato de fecha para enviar al servidor
String formatoFecha(DateTime fecha) {
  final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  return formatter.format(fecha);
}

/// Normaliza una fecha a datetime "naive" (sin offset de zona horaria) para
/// enviar a Odoo. Algunos campos guardan localmente el valor tal como lo
/// devolvió Odoo (p.ej. "2026-08-20 20:00:09.613239+00:00", formato Python de
/// un datetime "aware"); reenviar eso tal cual hace que Odoo rechace la
/// petición con "Datetime field expects a naive datetime". Si [raw] trae
/// offset, se parsea y se reformatea sin él; si es null/vacío o no se puede
/// parsear, se usa [fallback] (por defecto la hora actual).
String fechaNaive(String? raw, {DateTime? fallback}) {
  if (raw == null || raw.trim().isEmpty) {
    return formatoFecha(fallback ?? DateTime.now());
  }
  try {
    return formatoFecha(DateTime.parse(raw));
  } catch (_) {
    return formatoFecha(fallback ?? DateTime.now());
  }
}