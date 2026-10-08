import 'package:wms_app/features/info_rapida/domain/entities/recent_query.dart';

/// Modelo de serialización JSON para [RecentQuery] en SharedPreferences.
class RecentQueryModel {
  final RecentQuery entity;

  const RecentQueryModel(this.entity);

  factory RecentQueryModel.fromEntity(RecentQuery entity) =>
      RecentQueryModel(entity);

  RecentQuery toEntity() => entity;

  factory RecentQueryModel.fromJson(Map<String, dynamic> json) {
    return RecentQueryModel(
      RecentQuery(
        query: json['query'] as String? ?? '',
        isManual: json['isManual'] as bool? ?? false,
        isProduct: json['isProduct'] as bool? ?? false,
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        badge: json['badge'] as String?,
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'query': entity.query,
        'isManual': entity.isManual,
        'isProduct': entity.isProduct,
        'type': entity.type,
        'title': entity.title,
        'subtitle': entity.subtitle,
        'badge': entity.badge,
        'date': entity.date.toIso8601String(),
      };
}
