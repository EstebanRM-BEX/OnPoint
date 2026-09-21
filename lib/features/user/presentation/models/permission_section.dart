import 'package:flutter/material.dart';
import '../../domain/entities/user_configuration.dart';

/// Un permiso del usuario, de solo lectura. [value] es `bool` para los
/// checks o `String` para opciones (p. ej. "Predefinida").
class PermissionItem {
  final String label;
  final Object value;
  final String infoTitle;
  final String infoBody;

  const PermissionItem({
    required this.label,
    required this.value,
    required this.infoTitle,
    required this.infoBody,
  });
}

/// Grupo de permisos de un módulo.
class PermissionSection {
  final String title;
  final String? tag;
  final Color accent;

  /// Roles que ven la sección; `null` = todos.
  final Set<String>? roles;
  final List<PermissionItem> items;

  const PermissionSection({
    required this.title,
    required this.accent,
    required this.items,
    this.tag,
    this.roles,
  });

  bool isVisibleFor(String? rol) =>
      roles == null || roles!.contains(rol) || rol == 'admin';

  /// Definición declarativa de todas las secciones a partir del perfil.
  /// Agregar un permiso nuevo = agregar un [PermissionItem] aquí.
  static List<PermissionSection> fromProfile(UserProfile p) => [
    PermissionSection(
      title: 'Accesos Generales',
      accent: const Color(0xFF0769A6),
      items: [
        PermissionItem(
          label: 'Acceso al modulo de produccion',
          value: p.accessProductionModule ?? false,
          infoTitle: 'Acceso al modulo de produccion',
          infoBody: 'Acceso al modulo de produccion en la aplicacion',
        ),
        PermissionItem(
          label: 'Crear lotes con fechas a vencer',
          value: p.allowPriorExpirationDate ?? false,
          infoTitle: 'Crear lotes con fechas vencidas o por vencer',
          infoBody:
              'permite recibir un lote con fecha de vencimiento anterior a la próxima a vencer en stock',
        ),
        PermissionItem(
          label: 'Crear lotes nuevos sin nombre',
          value: p.manageExpirationDateWithoutLot ?? false,
          infoTitle: 'Crear lotes nuevos sin nombre',
          infoBody: 'permite crear un lote sin colocarle un nombre',
        ),
        PermissionItem(
          label: 'Mover más de lo planteado',
          value: p.allowMoveExcessProduction ?? false,
          infoTitle: 'Mover más de lo planteado (Producción)',
          infoBody:
              'Permite al usuario mover más de lo planteado en picking por batch componentes (Producción)',
        ),
      ],
    ),
    PermissionSection(
      title: 'Permisos Picking',
      tag: 'Recolección',
      accent: const Color(0xFFF59E0B),
      roles: const {'picking'},
      items: [
        PermissionItem(
          label: 'Boton validar Picking cluster',
          value: p.showButtonValidateClusterPicking ?? false,
          infoTitle: 'Boton validar Picking cluster',
          infoBody:
              'Permite mostrar el botón de validar pedido en el proceso de cluster picking en la app',
        ),
        PermissionItem(
          label: 'Ocultar accion de validar picking por pedido',
          value: p.hideValidatePicking ?? false,
          infoTitle: 'Ocultar accion de validar picking',
          infoBody: 'Ocultar accion de validar picking en la aplicacion',
        ),
        PermissionItem(
          label: 'Ubicacion origen manual',
          value: p.locationPickingManual ?? false,
          infoTitle: 'Ubicacion origen manual',
          infoBody:
              'Permite seleccionar la ubicacion de origen en el proceso del picking de forma manual',
        ),
        PermissionItem(
          label: 'Seleccion producto manual',
          value: p.manualProductSelection ?? false,
          infoTitle: 'Seleccionar producto manual',
          infoBody:
              'Permite seleccionar el producto en el proceso del picking de forma manual',
        ),
        PermissionItem(
          label: 'Seleccionar cantidad manual',
          value: p.manualQuantity ?? false,
          infoTitle: 'Seleccionar cantidad manual',
          infoBody:
              'Permite seleccionar la cantidad en el proceso del picking de forma manual',
        ),
        PermissionItem(
          label: 'Ubicacion destino manual',
          value: p.manualSpringSelection ?? false,
          infoTitle: 'Ubicacion destino manual',
          infoBody:
              'Permite seleccionar la ubicacion destino en el proceso del picking de forma manual',
        ),
        PermissionItem(
          label: 'Ver detalles picking',
          value: p.showDetallesPicking ?? false,
          infoTitle: 'Ver detalles picking',
          infoBody:
              'Permite ver los detalles del picking de manera mas detallada, como la cantidad de productos, ubicaciones, etc.',
        ),
        PermissionItem(
          label: 'Ver proximas ubicaciones',
          value: p.showNextLocationsInDetails ?? false,
          infoTitle: 'Ver proximas ubicaciones',
          infoBody:
              'Permite ver las proximas ubicaciones en los detalles del picking',
        ),
      ],
    ),
    PermissionSection(
      title: 'Permisos Packing',
      tag: 'Empaque',
      accent: const Color(0xFF6366F1),
      roles: const {'packing'},
      items: [
        PermissionItem(
          label: 'Ocultar accion de validar packing por pedido',
          value: p.hideValidatePacking ?? false,
          infoTitle: 'Ocultar accion de validar packing',
          infoBody: 'Ocultar accion de validar packing en la aplicacion',
        ),
        PermissionItem(
          label: 'Ubicacion de origen manual',
          value: p.locationPackManual ?? false,
          infoTitle: 'Ubicacion de origen manual',
          infoBody:
              'Permite seleccionar la ubicacion de origen en el proceso del packing de forma manual',
        ),
        PermissionItem(
          label: 'Seleccion producto manual',
          value: p.manualProductSelectionPack ?? false,
          infoTitle: 'Seleccionar producto manual',
          infoBody:
              'Permite seleccionar el producto en el proceso del packing de forma manual',
        ),
        PermissionItem(
          label: 'Seleccionar cantidad manual',
          value: p.manualQuantityPack ?? false,
          infoTitle: 'Seleccionar cantidad manual',
          infoBody:
              'Permite seleccionar la cantidad en el proceso del packing de forma manual',
        ),
        PermissionItem(
          label: 'Ubicacion destino manual',
          value: p.manualSpringSelectionPack ?? false,
          infoTitle: 'Ubicacion destino manual',
          infoBody:
              'Permite seleccionar la ubicacion destino en el proceso del packing de forma manual',
        ),
        PermissionItem(
          label: 'Selec masiva de productos',
          value: p.scanProduct ?? false,
          infoTitle: 'Seleccion masiva de productos',
          infoBody:
              'Permite seleccionar de manera masiva los productos a empacar directamente sin certificar la cantidad en el procesos de packing',
        ),
      ],
    ),
    PermissionSection(
      title: 'Permisos Recepcion',
      tag: 'Entradas',
      accent: const Color(0xFF8B5CF6),
      roles: const {'reception'},
      items: [
        PermissionItem(
          label: 'Mover mas de lo planteado',
          value: p.allowMoveExcess ?? false,
          infoTitle: 'Mover mas de lo planteado',
          infoBody:
              'Permite mover mas de lo planteado en el proceso de recepcion',
        ),
        PermissionItem(
          label: 'Mostrar campo propietario',
          value: p.showOwnerField ?? false,
          infoTitle: 'Mostrar campo propietario',
          infoBody:
              'Permite mostrar el campo de propietario en el proceso de recepcion',
        ),
        PermissionItem(
          label: 'Ocultar cantidad',
          value: p.hideExpectedQty ?? false,
          infoTitle: 'Ocultar cantidad',
          infoBody: 'Ocultar cantidad para el proceso de recepcion',
        ),
        PermissionItem(
          label: 'Seleccionar producto manual',
          value: p.manualProductReading ?? false,
          infoTitle: 'Seleccionar producto manual',
          infoBody:
              'Permite seleccionar el producto en el proceso del recepcion de forma manual',
        ),
        PermissionItem(
          label: 'Ubicacion destino manual',
          value: p.scanDestinationLocationReception ?? false,
          infoTitle: 'Ubicacion destino manual',
          infoBody:
              'Permite seleccionar la ubicacion destino en el proceso de recepcion de forma manual',
        ),
        PermissionItem(
          label: 'Ocultar accion de validar recepcion',
          value: p.hideValidateReception ?? false,
          infoTitle: 'Ocultar accion de validar recepcion',
          infoBody: 'Ocultar accion de validar recepcion en la aplicacion',
        ),
      ],
    ),
    PermissionSection(
      title: 'Permisos Transferencia',
      tag: 'Movimientos',
      accent: const Color(0xFF0EA5E9),
      roles: const {'transfer'},
      items: [
        PermissionItem(
          label: 'Ubicación de origen manual',
          value: p.manualSourceLocationTransfer ?? false,
          infoTitle: 'Ubicación de origen manual',
          infoBody:
              'Permite seleccionar la ubicacion de origen en el proceso de transferencia de forma manual',
        ),
        PermissionItem(
          label: 'Seleccionar producto manual',
          value: p.manualProductSelectionTransfer ?? false,
          infoTitle: 'Seleccionar producto manual',
          infoBody:
              'Permite seleccionar el producto en el proceso de transferencia de forma manual',
        ),
        PermissionItem(
          label: 'Ubicación destino manual',
          value: p.manualDestLocationTransfer ?? false,
          infoTitle: 'Ubicación destino manual',
          infoBody:
              'Permite seleccionar la ubicacion de destino en el proceso de transferencia de forma manual',
        ),
        PermissionItem(
          label: 'Seleccionar cantidad manual',
          value: p.manualQuantityTransfer ?? false,
          infoTitle: 'Seleccionar cantidad manual',
          infoBody:
              'Permite seleccionar la cantidad en el proceso de transferencia de forma manual',
        ),
        PermissionItem(
          label: 'Ocultar accion de validar transferencia',
          value: p.hideValidateTransfer ?? false,
          infoTitle: 'Ocultar accion de validar transferencia',
          infoBody: 'Ocultar accion de validar transferencia en la aplicacion',
        ),
      ],
    ),
    PermissionSection(
      title: 'Permisos Inventario',
      tag: 'Conteo',
      accent: const Color(0xFF14B8A6),
      roles: const {'inventory'},
      items: [
        PermissionItem(
          label: 'Ver cantidad a contar',
          value: p.countQuantityInventory ?? false,
          infoTitle: 'Ver cantidad a contar',
          infoBody:
              'Permite ver la cantidad a contar en el proceso de inventario',
        ),
        PermissionItem(
          label: 'Seleccionar producto manual',
          value: p.manualProductSelectionInventory ?? false,
          infoTitle: 'Seleccionar producto manual',
          infoBody:
              'Permite seleccionar el producto en el proceso de inventario de forma manual',
        ),
        PermissionItem(
          label: 'Ubicación manual',
          value: p.locationManualInventory ?? false,
          infoTitle: 'Ubicación manual',
          infoBody:
              'Permite seleccionar la ubicacion en el proceso de inventario de forma manual',
        ),
      ],
    ),
    PermissionSection(
      title: 'Permisos Informacion Rapida',
      tag: 'Consulta',
      accent: const Color(0xFF10B981),
      items: [
        PermissionItem(
          label: 'Editar producto',
          value: p.updateItemInventory ?? false,
          infoTitle: 'Editar producto',
          infoBody:
              'Permite editar la informacion del producto en el modulo de informacion rapida',
        ),
        PermissionItem(
          label: 'Editar ubicacion',
          value: p.updateLocationInventory ?? false,
          infoTitle: 'Editar Ubicacion',
          infoBody:
              'Permite editar la informacion de la ubicacion en el modulo de informacion rapida',
        ),
      ],
    ),
    PermissionSection(
      title: 'Permisos Devolucion',
      tag: 'Retornos',
      accent: const Color(0xFFF43F5E),
      items: [
        PermissionItem(
          label: 'Ubicacion destino',
          value: p.returnsLocationDestOption == 'predefined'
              ? 'Predefinida'
              : 'Dinamica',
          infoTitle: 'Ubicacion destino devolucion',
          infoBody:
              'Permite seleccionar la ubicacion destino en el proceso de devolucion si se encuentra en modo dinamica',
        ),
        PermissionItem(
          label: 'Mover más de lo planteado',
          value: p.allowMoveExcessProduction ?? false,
          infoTitle: 'Mover más de lo planteado (Producción)',
          infoBody:
              'Permite al usuario mover más de lo planteado en picking por batch componentes (Producción)',
        ),
      ],
    ),
    PermissionSection(
      title: 'Permisos Expedicion',
      tag: 'Despachos',
      accent: const Color(0xFF06B6D4),
      items: [
        PermissionItem(
          label: 'Mostrar accion de confirmar pedido de expedicion',
          value: p.hideValidateExpedition ?? false,
          infoTitle: 'Mostrar accion de confirmar pedido',
          infoBody:
              'Muestra el boton de confirmar el pedido completo de expedicion',
        ),
        PermissionItem(
          label: 'Mostrar accion de validar paquete o producto',
          value: p.hideValidateItemExpedition ?? false,
          infoTitle: 'Mostrar accion de validar paquete o producto',
          infoBody:
              'Muestra el boton de validar un paquete o producto suelto individual dentro de la expedicion',
        ),
        PermissionItem(
          label: 'Validacion multiple',
          value: p.allowValidateMultiple ?? false,
          infoTitle: 'Validacion multiple',
          infoBody:
              'Permite seleccionar varios paquetes y/o productos sueltos en la expedicion y validarlos todos en una sola accion',
        ),
      ],
    ),
  ];
}
