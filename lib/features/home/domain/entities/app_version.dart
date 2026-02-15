/// Domain entity for app version information.
/// This is a pure business object without any framework dependencies.
class AppVersion {
  final String? jsonrpc;
  final dynamic id;
  final String message;
  final AppVersionResult? result;

  const AppVersion({
    this.jsonrpc,
    this.id,
    this.message = '',
    this.result,
  });
}

class AppVersionResult {
  final int? code;
  final VersionResult? result;

  const AppVersionResult({
    this.code,
    this.result,
  });
}

class VersionResult {
  final int? id;
  final String? version;
  final DateTime? releaseDate;
  final List<String>? notes;
  final String? urlDownload;

  const VersionResult({
    this.id,
    this.version,
    this.releaseDate,
    this.notes,
    this.urlDownload,
  });
}
