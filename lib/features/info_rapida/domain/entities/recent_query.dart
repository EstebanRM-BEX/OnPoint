import 'package:equatable/equatable.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';

/// Consulta exitosa previa de Información Rápida para el historial de accesos directos.
class RecentQuery extends Equatable {
  final String query;
  final bool isManual;
  final bool isProduct;

  /// Tipo de entidad devuelto: `'product'` | `'ubicacion'` | `'paquete'`.
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

  /// Arma la entrada del historial con el mismo formato del legacy
  /// (`RecentQuery.fromResult`): producto por referencia, ubicación y paquete
  /// por nombre.
  factory RecentQuery.fromInfo({
    required String query,
    required bool isManual,
    required InfoRapida info,
    DateTime? date,
  }) {
    String? text(String? v) {
      final s = v?.trim();
      return (s == null || s.isEmpty || s == 'false') ? null : s;
    }

    String? numText(num? v) {
      if (v == null) return null;
      return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    }

    final now = date ?? DateTime.now();
    switch (info) {
      case ProductoInfo p:
        final qty = numText(p.cantidadDisponible);
        return RecentQuery(
          query: query,
          isManual: isManual,
          isProduct: true,
          type: 'product',
          title: text(p.referencia) ?? text(p.codigoBarras) ?? query,
          subtitle: text(p.nombre) ?? '',
          badge: qty == null ? null : '$qty ${text(p.unidadMedida) ?? 'un.'}',
          date: now,
        );
      case UbicacionInfo u:
        final n = u.numeroProductos;
        return RecentQuery(
          query: query,
          isManual: isManual,
          isProduct: false,
          type: 'ubicacion',
          title: text(u.nombre) ?? query,
          subtitle: [text(u.nombreAlmacen), text(u.ubicacionPadre)]
              .whereType<String>()
              .join(' • '),
          badge: n == null ? null : '$n prod.',
          date: now,
        );
      case PaqueteInfo pq:
        final n = pq.numeroProductos?.toString() ?? numText(pq.totalProductos);
        return RecentQuery(
          query: query,
          isManual: isManual,
          isProduct: false,
          type: 'paquete',
          title: text(pq.nombre) ?? query,
          subtitle: text(pq.nombreAlmacen) ?? '',
          badge: n == null ? null : '$n prod.',
          date: now,
        );
    }
  }

  /// Clave única para desduplicar consultas hacia la misma entidad.
  String get dedupeKey => '$type|${title.toUpperCase()}';

  RecentQuery copyWith({
    String? query,
    bool? isManual,
    bool? isProduct,
    String? type,
    String? title,
    String? subtitle,
    String? badge,
    DateTime? date,
  }) {
    return RecentQuery(
      query: query ?? this.query,
      isManual: isManual ?? this.isManual,
      isProduct: isProduct ?? this.isProduct,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      badge: badge ?? this.badge,
      date: date ?? this.date,
    );
  }

  @override
  List<Object?> get props => [
        query,
        isManual,
        isProduct,
        type,
        title,
        subtitle,
        badge,
        date,
      ];
}
