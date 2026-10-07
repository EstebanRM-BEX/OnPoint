/// Formatos de texto compartidos por las tarjetas del packing.
abstract final class PackFormatos {
  /// Cantidad sin ".0" cuando es entera.
  static String cantidad(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  /// Segundos → "HH:MM:SS" (tiempo de separación).
  static String duracion(double segundos) {
    final total = segundos.isFinite && segundos > 0 ? segundos.round() : 0;
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(total ~/ 3600)}:${dos((total % 3600) ~/ 60)}:${dos(total % 60)}';
  }
}
