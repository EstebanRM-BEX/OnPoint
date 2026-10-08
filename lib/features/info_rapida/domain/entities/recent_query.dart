import 'package:equatable/equatable.dart';

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
