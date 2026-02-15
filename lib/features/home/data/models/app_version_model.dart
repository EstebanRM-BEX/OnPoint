import 'dart:convert';
import 'package:wms_app/features/home/domain/entities/app_version.dart';

/// Data model for AppVersion that extends the domain entity.
/// Includes JSON serialization/deserialization logic.
class AppVersionModel extends AppVersion {
  const AppVersionModel({
    String? jsonrpc,
    dynamic id,
    String message = '',
    AppVersionResultModel? result,
  }) : super(
          jsonrpc: jsonrpc,
          id: id,
          message: message,
          result: result,
        );

  factory AppVersionModel.fromJson(String str) =>
      AppVersionModel.fromMap(json.decode(str));

  factory AppVersionModel.fromMap(Map<String, dynamic> json) => AppVersionModel(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        message: json["message"] ?? '',
        result: json["result"] == null
            ? null
            : AppVersionResultModel.fromMap(json["result"]),
      );

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "message": message,
        "result": (result as AppVersionResultModel?)?.toMap(),
      };
}

class AppVersionResultModel extends AppVersionResult {
  const AppVersionResultModel({
    int? code,
    VersionResultModel? result,
  }) : super(code: code, result: result);

  factory AppVersionResultModel.fromJson(String str) =>
      AppVersionResultModel.fromMap(json.decode(str));

  factory AppVersionResultModel.fromMap(Map<String, dynamic> json) =>
      AppVersionResultModel(
        code: json["code"],
        result: json["result"] == null
            ? null
            : VersionResultModel.fromMap(json["result"]),
      );

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => {
        "code": code,
        "result": (result as VersionResultModel?)?.toMap(),
      };
}

class VersionResultModel extends VersionResult {
  const VersionResultModel({
    int? id,
    String? version,
    DateTime? releaseDate,
    List<String>? notes,
    String? urlDownload,
  }) : super(
          id: id,
          version: version,
          releaseDate: releaseDate,
          notes: notes,
          urlDownload: urlDownload,
        );

  factory VersionResultModel.fromJson(String str) =>
      VersionResultModel.fromMap(json.decode(str));

  factory VersionResultModel.fromMap(Map<String, dynamic> json) =>
      VersionResultModel(
        id: json["id"],
        version: json["version"],
        releaseDate: json["release_date"] == null
            ? null
            : DateTime.parse(json["release_date"]),
        notes: json["notes"] == null
            ? []
            : List<String>.from(json["notes"]!.map((x) => x)),
        urlDownload: json["url_download"],
      );

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => {
        "id": id,
        "version": version,
        "release_date": releaseDate == null
            ? null
            : "${releaseDate!.year.toString().padLeft(4, '0')}-${releaseDate!.month.toString().padLeft(2, '0')}-${releaseDate!.day.toString().padLeft(2, '0')}",
        "notes": notes == null ? [] : List<dynamic>.from(notes!.map((x) => x)),
        "url_download": urlDownload,
      };
}
