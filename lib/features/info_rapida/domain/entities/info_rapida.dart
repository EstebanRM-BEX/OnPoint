import 'package:equatable/equatable.dart';

part 'producto_info.dart';
part 'ubicacion_info.dart';
part 'paquete_info.dart';

/// Resultado base tipado para una consulta de Información Rápida.
///
/// Gracias a ser una clase sellada (`sealed`), la UI y los blocs pueden hacer
/// un switch exhaustivo por tipo sin posibilidad de estados no manejados:
/// ```dart
/// switch (infoRapida) {
///   case ProductoInfo p => ...;
///   case UbicacionInfo u => ...;
///   case PaqueteInfo pq => ...;
/// }
/// ```
sealed class InfoRapida extends Equatable {
  const InfoRapida();
}
