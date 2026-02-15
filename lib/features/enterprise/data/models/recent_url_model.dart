import 'package:wms_app/features/enterprise/domain/entities/recent_url.dart';

class RecentUrlModel extends RecentUrl {
  const RecentUrlModel({
    super.id,
    required super.url,
    required super.date,
  });

  factory RecentUrlModel.fromEntity(RecentUrl entity) {
    return RecentUrlModel(
      id: entity.id,
      url: entity.url,
      date: entity.date,
    );
  }

  factory RecentUrlModel.fromJson(Map<String, dynamic> json) {
    return RecentUrlModel(
      id: json['id'],
      url: json['url'],
      date: DateTime.parse(
          json['fecha'] ?? json['date']), // Handle both for safety
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'fecha': date.toIso8601String(),
    };
  }
}
