import '../../domain/entities/user_novelty.dart';

class UserNoveltyModel extends Novedad {
  const UserNoveltyModel({
    required super.id,
    required super.name,
    required super.code,
  });

  factory UserNoveltyModel.fromJson(Map<String, dynamic> json) {
    return UserNoveltyModel(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
    };
  }
}
