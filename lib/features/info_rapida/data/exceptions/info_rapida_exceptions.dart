/// Excepciones específicas de la capa de datos para Información Rápida.
class DispositivoNoAutorizadoException implements Exception {
  final String message;
  const DispositivoNoAutorizadoException([
    this.message = 'Este dispositivo no está autorizado para usar la aplicación.',
  ]);

  @override
  String toString() => 'DispositivoNoAutorizadoException: $message';
}

class ActualizarVersionException implements Exception {
  final String message;
  const ActualizarVersionException([
    this.message = 'Hay una actualización requerida para continuar utilizando la app.',
  ]);

  @override
  String toString() => 'ActualizarVersionException: $message';
}

class NoEncontradoException implements Exception {
  final String message;
  const NoEncontradoException([
    this.message = 'El producto, ubicación o paquete consultado no fue encontrado.',
  ]);

  @override
  String toString() => 'NoEncontradoException: $message';
}
