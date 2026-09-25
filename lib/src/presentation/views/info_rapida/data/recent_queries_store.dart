import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/src/presentation/views/info_rapida/models/info_rapida_model.dart';

/// Consulta exitosa de Información Rápida, con lo necesario para mostrarla
/// y para repetirla con los mismos parámetros de [GetInfoRapida].
class RecentQuery {
  /// Parámetros originales de la consulta (para repetirla).
  final String query;
  final bool isManual;
  final bool isProduct;

  /// 'product' | 'ubicacion' | 'paquete' (tipo que devolvió el backend).
  final String type;
  final String title;
  final String subtitle;
  final String? badge;
  final DateTime date;

  const RecentQuery({
    required this.query,
    required this.isManual,
    required this.isProduct,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    this.badge,
  });

  /// Construye la entrada a partir de la respuesta del backend.
  factory RecentQuery.fromResult({
    required String query,
    required bool isManual,
    required bool isProduct,
    required InfoRapidaResult result,
  }) {
    final info = result.result;
    final type = result.type ?? '';
    String? text(Object? v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty || s == 'false' || s == 'null') ? null : s;
    }

    String title;
    String subtitle;
    String? badge;
    switch (type) {
      case 'product':
        title = text(info?.referencia) ?? text(info?.codigoBarras) ?? query;
        subtitle = text(info?.nombre) ?? '';
        final qty = text(info?.cantidadDisponible);
        badge = qty == null
            ? null
            : '$qty ${text(info?.unidadMedida) ?? 'un.'}';
      case 'ubicacion':
        title = text(info?.nombre) ?? query;
        subtitle = [
          text(info?.nombreAlmacen),
          text(info?.ubicacionPadre),
        ].whereType<String>().join(' • ');
        final n = text(info?.numeroProductos);
        badge = n == null ? null : '$n prod.';
      default: // paquete u otros
        title = text(info?.nombre) ?? query;
        subtitle = text(info?.nombreCompleto) ?? '';
        final n = text(info?.numeroProductos) ?? text(info?.totalProductos);
        badge = n == null ? null : '$n prod.';
    }

    return RecentQuery(
      query: query,
      isManual: isManual,
      isProduct: isProduct,
      type: type,
      title: title,
      subtitle: subtitle,
      badge: badge,
      date: DateTime.now(),
    );
  }

  /// Dos consultas son "la misma" si apuntan a la misma entidad.
  String get dedupeKey => '$type|${title.toUpperCase()}';

  Map<String, dynamic> toJson() => {
    'query': query,
    'isManual': isManual,
    'isProduct': isProduct,
    'type': type,
    'title': title,
    'subtitle': subtitle,
    'badge': badge,
    'date': date.toIso8601String(),
  };

  factory RecentQuery.fromJson(Map<String, dynamic> json) => RecentQuery(
    query: json['query'] as String,
    isManual: json['isManual'] as bool? ?? false,
    isProduct: json['isProduct'] as bool? ?? false,
    type: json['type'] as String? ?? '',
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String? ?? '',
    badge: json['badge'] as String?,
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
  );
}

/// Historial local de las últimas consultas de Información Rápida.
///
/// Se guarda por base de datos (empresa): al cambiar de servidor no se ven
/// códigos de otra empresa.
class RecentQueriesStore {
  RecentQueriesStore._();
  static final RecentQueriesStore instance = RecentQueriesStore._();

  static const int maxItems = 5;

  String get _key =>
      'info_rapida_recent_${getIt<IStorageService>().nameDatabase}';

  Future<List<RecentQuery>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      return (jsonDecode(raw) as List)
          .map((e) => RecentQuery.fromJson(Map<String, dynamic>.from(e)))
          .take(maxItems) // nunca más de 5, aunque lo guardado tenga más
          .toList();
    } catch (e) {
      // Historial corrupto o de un formato anterior: se descarta.
      debugPrint('RecentQueriesStore.getAll: $e');
      return [];
    }
  }

  /// Agrega [query] al inicio, sin duplicados y con tope de [maxItems].
  Future<void> add(RecentQuery query) async {
    final items = await getAll()
      ..removeWhere((q) => q.dedupeKey == query.dedupeKey)
      ..insert(0, query);
    await _save(items.take(maxItems).toList());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _save(List<RecentQuery> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}
