import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/bloc/picking_pick_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/PickhWithProducts_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

void main() {
  late PickingPickBloc bloc;

  setUp(() {
    // Initializing the bloc. 
    // Since we only test a synchronous method that uses a public property, 
    // we don't need to mock the entire environment unless the constructor fails.
    bloc = PickingPickBloc();
  });

  group('calcularUnidadesSeparadas', () {
    test('should return "0.0" when products list is null', () {
      bloc.pickWithProducts = PickWithProducts(products: null);
      expect(bloc.calcularUnidadesSeparadas(), "0.0");
    });

    test('should return "0.0" when products list is empty', () {
      bloc.pickWithProducts = PickWithProducts(products: []);
      expect(bloc.calcularUnidadesSeparadas(), "0.0");
    });

    test('should return "0.0" when total quantities is 0', () {
      bloc.pickWithProducts = PickWithProducts(products: [
        ProductsBatch(quantity: 0, quantitySeparate: 0),
        ProductsBatch(quantity: 0, quantitySeparate: 5),
      ]);
      expect(bloc.calcularUnidadesSeparadas(), "0.0");
    });

    test('should return "50.00" when half of units are separated', () {
      bloc.pickWithProducts = PickWithProducts(products: [
        ProductsBatch(quantity: 10, quantitySeparate: 5),
        ProductsBatch(quantity: 20, quantitySeparate: 10),
      ]);
      expect(bloc.calcularUnidadesSeparadas(), "50.00");
    });

    test('should return "100.00" when all units are separated', () {
      bloc.pickWithProducts = PickWithProducts(products: [
        ProductsBatch(quantity: 10, quantitySeparate: 10),
        ProductsBatch(quantity: 5, quantitySeparate: 5),
      ]);
      expect(bloc.calcularUnidadesSeparadas(), "100.00");
    });

    test('should return "0.00" when no units are separated', () {
      bloc.pickWithProducts = PickWithProducts(products: [
        ProductsBatch(quantity: 10, quantitySeparate: 0),
        ProductsBatch(quantity: 5, quantitySeparate: 0),
      ]);
      expect(bloc.calcularUnidadesSeparadas(), "0.00");
    });

    test('should handle decimal quantities correctly', () {
      bloc.pickWithProducts = PickWithProducts(products: [
        ProductsBatch(quantity: 10.5, quantitySeparate: 2.1), // 20%
      ]);
      expect(bloc.calcularUnidadesSeparadas(), "20.00");
    });

    test('should handle mixed null quantities by treating them as 0', () {
      bloc.pickWithProducts = PickWithProducts(products: [
        ProductsBatch(quantity: 10, quantitySeparate: null),
        ProductsBatch(quantity: null, quantitySeparate: 5),
      ]);
      // totalSeparadas = 0 + 5 = 5
      // totalCantidades = 10 + 0 = 10
      // 5 / 10 * 100 = 50.00
      expect(bloc.calcularUnidadesSeparadas(), "50.00");
    });

    test('should format to 2 decimal places', () {
      bloc.pickWithProducts = PickWithProducts(products: [
        ProductsBatch(quantity: 3, quantitySeparate: 1), // 33.333...%
      ]);
      expect(bloc.calcularUnidadesSeparadas(), "33.33");
    });
  });
}
