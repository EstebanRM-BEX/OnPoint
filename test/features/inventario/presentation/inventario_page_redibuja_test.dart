import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/features/inventario/presentation/bloc/inventario_bloc.dart';
import 'package:wms_app/features/inventario/presentation/pages/inventario_page.dart';

/// Las búsquedas se abren encima de la página de inventario con push (la
/// página queda viva debajo): sus estados no deben redibujarla con cada
/// tecla (docs/plan_performance_pantallas.md, fase 1).
void main() {
  test('los estados de búsqueda y filtro no redibujan la página', () {
    for (final estado in <InventarioState>[
      SearchLoading(),
      SearchProductSuccess(const []),
      SearchLocationSuccess(const []),
      SearchLoteSuccess(const []),
      SearchFailure('x'),
      FilterUbicacionesLoading(),
      FilterUbicacionesSuccess(const []),
      FilterUbicacionesFailure('x'),
    ]) {
      expect(inventarioPageRedibuja(estado), isFalse, reason: '$estado');
    }
  });

  test('los estados del flujo de escaneo sí la redibujan', () {
    for (final estado in <InventarioState>[
      CleanFieldsState(),
      SendProductLoading(),
      SendProductSuccess(),
      GetLotesProductLoading(),
      InventarioSessionExpiredState(),
    ]) {
      expect(inventarioPageRedibuja(estado), isTrue, reason: '$estado');
    }
  });
}
