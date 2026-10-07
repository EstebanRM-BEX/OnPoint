import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';

const pedidoTest = PedidoPack(id: 10, name: 'WH/PACK/0010');

ProductoPacking productoTest({
  int id = 1,
  int pedidoId = 10,
  double quantity = 10,
  double quantitySeparate = 0,
  EstadoProductoPacking estado = EstadoProductoPacking.porHacer,
  bool certificado = false,
  int? idPackage,
  bool manejaTemperatura = false,
  String productName = 'Producto A',
  String barcodeLocation = 'LOC-A1',
}) {
  return ProductoPacking(
    id: id,
    pedidoId: pedidoId,
    idMove: 100,
    idProduct: 500,
    productName: productName,
    productCode: 'PA-01',
    barcode: '7701234',
    barcodeLocation: barcodeLocation,
    quantity: quantity,
    quantitySeparate: quantitySeparate,
    estado: estado,
    certificado: certificado,
    idPackage: idPackage,
    manejaTemperatura: manejaTemperatura,
  );
}

PaquetePacking paqueteTest({
  int id = 1,
  int pedidoId = 10,
  String consecutivo = 'Caja1',
  String packingBarcode = 'PACK0001',
  int? locationDestId,
}) {
  return PaquetePacking(
    id: id,
    pedidoId: pedidoId,
    name: 'PACK-$id',
    packingBarcode: packingBarcode,
    consecutivo: consecutivo,
    locationDestId: locationDestId,
    locationDestName: locationDestId == null ? '' : 'MUELLE-1',
  );
}
