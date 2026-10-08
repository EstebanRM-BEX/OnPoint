import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/picking/domain/usecases/assign_muelle_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/get_barcodes_product_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/get_muelles_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/get_product_image_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/get_products_for_edit_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/get_scan_pick_with_products_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/increment_quantity_separate_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/mark_location_dest_ok_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/mark_location_ok_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/mark_pick_as_done_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/mark_product_ok_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/mark_quantity_ok_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/record_pick_time_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/send_product_to_odoo_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/update_quantity_separate_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/validate_confirm_pick_usecase.dart';
import 'package:wms_app/features/picking/domain/usecases/validate_transfer_usecase.dart';
import 'package:wms_app/features/picking/presentation/bloc/scan/pick_scan_bloc.dart';

class _MarkLocationOk extends Mock implements MarkLocationOkUseCase {}

class _MarkLocationDestOk extends Mock implements MarkLocationDestOkUseCase {}

class _MarkProductOk extends Mock implements MarkProductOkUseCase {}

class _MarkQuantityOk extends Mock implements MarkQuantityOkUseCase {}

class _UpdateQuantity extends Mock implements UpdateQuantitySeparateUseCase {}

class _IncrementQuantity extends Mock
    implements IncrementQuantitySeparateUseCase {}

class _GetScanPick extends Mock implements GetScanPickWithProductsUseCase {}

class _GetBarcodes extends Mock implements GetBarcodesProductUseCase {}

class _GetProductsForEdit extends Mock implements GetProductsForEditUseCase {}

class _GetMuelles extends Mock implements GetMuellesUseCase {}

class _GetProductImage extends Mock implements GetProductImageUseCase {}

class _ValidateConfirm extends Mock implements ValidateConfirmPickUseCase {}

class _ValidateTransfer extends Mock implements ValidateTransferUseCase {}

class _MarkPickAsDone extends Mock implements MarkPickAsDoneUseCase {}

class _RecordPickTime extends Mock implements RecordPickTimeUseCase {}

class _SendProduct extends Mock implements SendProductToOdooUseCase {}

class _AssignMuelle extends Mock implements AssignMuelleUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(ValidateTransferParams(pickId: 0, isBackOrder: false));
    registerFallbackValue(RecordPickTimeParams(pickId: 0, timeType: ''));
    registerFallbackValue(MarkPickAsDoneParams(pickId: 0));
  });

  test(
    'salir de la pantalla mientras se valida no pierde el cierre local del pick',
    () async {
      final validate = _ValidateTransfer();
      final recordTime = _RecordPickTime();
      final markDone = _MarkPickAsDone();
      final odoo = Completer<Either<Failure, String>>();

      when(() => validate(any())).thenAnswer((_) => odoo.future);
      when(() => recordTime(any())).thenAnswer((_) async => const Right(unit));
      when(() => markDone(any())).thenAnswer((_) async => const Right(unit));

      final bloc = PickScanBloc(
        markLocationOkUseCase: _MarkLocationOk(),
        markLocationDestOkUseCase: _MarkLocationDestOk(),
        markProductOkUseCase: _MarkProductOk(),
        markQuantityOkUseCase: _MarkQuantityOk(),
        updateQuantitySeparateUseCase: _UpdateQuantity(),
        incrementQuantitySeparateUseCase: _IncrementQuantity(),
        getScanPickWithProductsUseCase: _GetScanPick(),
        getBarcodesProductUseCase: _GetBarcodes(),
        getProductsForEditUseCase: _GetProductsForEdit(),
        getMuellesUseCase: _GetMuelles(),
        getProductImageUseCase: _GetProductImage(),
        validateConfirmPickUseCase: _ValidateConfirm(),
        validateTransferUseCase: validate,
        markPickAsDoneUseCase: markDone,
        recordPickTimeUseCase: recordTime,
        sendProductToOdooUseCase: _SendProduct(),
        assignMuelleUseCase: _AssignMuelle(),
      )..add(CreateBackOrderOrNot(7, false, false));
      await Future<void>.delayed(Duration.zero);

      // El operario sale mientras Odoo valida.
      final closing = bloc.close();
      odoo.complete(const Right('Validado'));
      await closing;

      verify(
        () => recordTime(
          any(
            that: isA<RecordPickTimeParams>()
                .having((p) => p.pickId, 'pickId', 7)
                .having((p) => p.timeType, 'timeType', 'end_time_transfer'),
          ),
        ),
      ).called(1);
      verify(
        () => markDone(
          any(that: isA<MarkPickAsDoneParams>().having((p) => p.pickId, 'pickId', 7)),
        ),
      ).called(1);
    },
  );
}
