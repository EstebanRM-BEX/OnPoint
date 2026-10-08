import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/packing_pedido/data/models/odoo_parse.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/models/response_products_model.dart';

/// Mapeadores para convertir modelos de base de datos local y cachés
/// a las entidades inmutables del dominio de Información Rápida.
class CatalogoMappers {
  const CatalogoMappers._();

  /// Convierte un [Product] del catálogo de SQLite/memoria en un [ProductoCatalogo].
  static ProductoCatalogo? toProductoCatalogo(Product p) {
    final id = p.productId;
    if (id == null) return null;

    final otherBarcodes = <String>[];
    if (p.otherBarcodes != null) {
      for (final b in p.otherBarcodes!) {
        final code = OdooParse.str(b.barcode).trim();
        if (code.isNotEmpty) {
          otherBarcodes.add(code);
        }
      }
    }

    final code = OdooParse.str(p.code).trim();
    final barcode = OdooParse.str(p.barcode).trim();
    final lotName = OdooParse.str(p.lotName).trim();

    return ProductoCatalogo(
      id: id,
      name: p.name ?? '',
      code: code.isEmpty ? null : code,
      barcode: barcode.isEmpty ? null : barcode,
      lotName: lotName.isEmpty ? null : lotName,
      lotId: OdooParse.integer(p.lotId),
      locationName: p.locationName,
      locationId: p.locationId,
      quantity: p.quantity != null ? OdooParse.dbl(p.quantity) : null,
      otherBarcodes: List.unmodifiable(otherBarcodes),
    );
  }

  /// Convierte un [ResultUbicaciones] del catálogo local en un [UbicacionCatalogo].
  static UbicacionCatalogo? toUbicacionCatalogo(ResultUbicaciones u) {
    final id = u.id;
    if (id == null) return null;

    final barcode = u.barcode?.trim();

    return UbicacionCatalogo(
      id: id,
      name: u.name ?? '',
      barcode: (barcode == null || barcode.isEmpty) ? null : barcode,
      idWarehouse: u.idWarehouse,
      warehouseName: u.warehouseName,
      locationParentId: u.locationId,
      locationParentName: u.locationName,
      isADock: u.isADockAlter ?? false,
    );
  }
}
