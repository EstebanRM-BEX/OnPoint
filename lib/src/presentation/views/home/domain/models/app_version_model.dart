import 'dart:convert';

class AppVersion {
  final String? jsonrpc;
  final dynamic id;
  final String message;
  final AppVersionResult? result;

  AppVersion({
    this.jsonrpc,
    this.id,
    this.message = '',
    this.result,
  });

  factory AppVersion.fromJson(String str) =>
      AppVersion.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory AppVersion.fromMap(Map<String, dynamic> json) => AppVersion(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        message: json["message"] ?? '',
        result: json["result"] == null
            ? null
            : AppVersionResult.fromMap(json["result"]),
      );

  Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "message": message,
        "result": result?.toMap(),
      };
}

class AppVersionResult {
  final int? code;
  final VersionResult? result;

  AppVersionResult({
    this.code,
    this.result,
  });

  factory AppVersionResult.fromJson(String str) =>
      AppVersionResult.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory AppVersionResult.fromMap(Map<String, dynamic> json) =>
      AppVersionResult(
        code: json["code"],
        result: json["result"] == null
            ? null
            : VersionResult.fromMap(json["result"]),
      );

  Map<String, dynamic> toMap() => {
        "code": code,
        "result": result?.toMap(),
      };
}

class VersionResult {
  final int? id;
  final String? version;
  final DateTime? releaseDate;
  List<String>? notes;
  final String? urlDownload;

  VersionResult({
    this.id,
    this.version,
    this.releaseDate,
    this.notes,
    this.urlDownload,
  });

  factory VersionResult.fromJson(String str) =>
      VersionResult.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory VersionResult.fromMap(Map<String, dynamic> json) => VersionResult(
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

  Map<String, dynamic> toMap() => {
        "id": id,
        "version": version,
        "release_date":
            "${releaseDate!.year.toString().padLeft(4, '0')}-${releaseDate!.month.toString().padLeft(2, '0')}-${releaseDate!.day.toString().padLeft(2, '0')}",
        "notes": notes == null ? [] : List<dynamic>.from(notes!.map((x) => x)),
        "url_download": urlDownload,
      };
}
