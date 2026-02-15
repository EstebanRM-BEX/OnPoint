import 'package:wms_app/features/login/domain/entities/user.dart';

/// Data model for User that extends the domain entity.
/// Includes technical data that doesn't belong in the domain layer.
class UserModel extends User {
  // Technical data that stays in the data layer
  final String? db;
  final String? serverVersion;
  final String? webBaseUrl;

  const UserModel({
    required int uid,
    required String name,
    required String username,
    this.db,
    this.serverVersion,
    this.webBaseUrl,
  }) : super(
          uid: uid,
          name: name,
          username: username,
        );

  /// Create UserModel from JSON response
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final result = json['result'];

    if (result == null) {
      throw const FormatException('Invalid JSON: result is null');
    }

    return UserModel(
      uid: result['uid'] ?? 0,
      name: result['name'] ?? '',
      username: result['username'] ?? '',
      db: result['db'],
      serverVersion: result['server_version'],
      webBaseUrl: result['web.base.url'],
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'username': username,
        'db': db,
        'server_version': serverVersion,
        'web.base.url': webBaseUrl,
      };
}
