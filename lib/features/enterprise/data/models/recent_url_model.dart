import 'package:wms_app/features/enterprise/domain/entities/recent_url.dart';

class RecentUrlModel extends RecentUrl {
  const RecentUrlModel({
    super.id,
    required super.url,
    required super.fecha,
  });

  factory RecentUrlModel.fromEntity(RecentUrl entity) {
    return RecentUrlModel(
      id: entity.id,
      url: entity.url,
      fecha: entity.fecha,
    );
  }

  factory RecentUrlModel.fromJson(Map<String, dynamic> json) {
    return RecentUrlModel(
      id: json['id'],
      url: json['url'],
      fecha: DateTime.parse(
          json['fecha'] ?? json['date']), // Handle both for safety
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'fecha': fecha.toIso8601String(),
    };
  }
}
