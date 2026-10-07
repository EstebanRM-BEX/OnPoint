import 'package:wms_app/core/error/failures.dart';

/// Regla de negocio incumplida: la operación ni siquiera llega al backend.
class PackingValidationFailure extends Failure {
  const PackingValidationFailure(super.message);
}

/// Odoo procesó la operación pero el dispositivo no pudo reflejarla: hay que
/// refrescar los pedidos desde la API.
class PackingDesyncFailure extends Failure {
  const PackingDesyncFailure(super.message);
}

/// Al validar, Odoo avisa que hay productos con fecha de caducidad
/// alcanzada (`expiry.picking.confirmation`). Se puede reintentar aceptándolos.
class PackingVencidosFailure extends Failure {
  const PackingVencidosFailure(super.message);
}
