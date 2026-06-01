/// Resultado del envío de producto a Odoo desde el módulo scan.
class ScanSendResult {
  final bool success;
  final String message;

  ScanSendResult({
    required this.success,
    required this.message,
  });
}
