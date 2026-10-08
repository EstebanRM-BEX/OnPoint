import 'package:wms_app/core/error/failures.dart';

/// Error cuando el dispositivo no está registrado o autorizado en el backend (HTTP 403).
class DispositivoNoAutorizadoFailure extends Failure {
  const DispositivoNoAutorizadoFailure([super.message = 'Dispositivo no autorizado']);
}

/// Error cuando la sesión ha expirado en Odoo (código 100).
class SesionExpiradaFailure extends Failure {
  const SesionExpiradaFailure([super.message = 'Sesión expirada, por favor inicie sesión nuevamente']);
}

/// Error cuando no se encuentra producto, ubicación o paquete (HTTP 404).
class NoEncontradoFailure extends Failure {
  const NoEncontradoFailure([super.message = 'Información no encontrada']);
}

/// Aviso del backend indicando que se debe actualizar la versión de la app.
class ActualizarVersionFailure extends Failure {
  const ActualizarVersionFailure([super.message = 'Hay una nueva versión disponible. Por favor actualice la app.']);
}

/// Error cuando el dispositivo no tiene conexión a red activa.
class SinConexionFailure extends Failure {
  const SinConexionFailure([super.message = 'Sin conexión a Internet']);
}

/// Fallo de validación de datos en reglas de negocio locales antes de enviar al backend.
class InfoRapidaValidationFailure extends Failure {
  const InfoRapidaValidationFailure(super.message);
}

/// Regla de propietario incumplida (no se pueden mezclar productos de distinto dueño en transferencia masiva).
class PropietarioMismatchFailure extends Failure {
  const PropietarioMismatchFailure(super.message);
}
