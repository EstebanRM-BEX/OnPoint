import 'package:equatable/equatable.dart';

/// Permisos del usuario relevantes para las operaciones de Información Rápida.
class ConfigInfoRapidaUsuario extends Equatable {
  /// Permiso para modificar datos del producto (código de barras, peso, volumen, precio).
  final bool updateItemInventory;

  /// Permiso para modificar datos de la ubicación (nombre, código de barras).
  final bool updateLocationInventory;

  const ConfigInfoRapidaUsuario({
    this.updateItemInventory = false,
    this.updateLocationInventory = false,
  });

  @override
  List<Object?> get props => [
        updateItemInventory,
        updateLocationInventory,
      ];
}
