// ignore_for_file: unnecessary_type_check, unnecessary_null_comparison, avoid_print, unnecessary_import, unrelated_type_equality_checks, use_build_context_synchronously

import 'dart:math';

import 'package:wms_app/src/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/models/novedades_response_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/wms_picking/data/wms_picking_repository.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/history/models/batch_history_id_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/history/models/hisotry_done_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/product_template_model.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

part 'wms_picking_event.dart';
part 'wms_picking_state.dart';

class WMSPickingBloc extends Bloc<PickingEvent, PickingState> {
  //*batchs
  List<BatchsModel> listOfBatchs = [];
  List<BatchsModel> filteredBatchs = []; // Lista para los productos filtrados
  List<BatchsModel> listOfBatchsByComponents = [];
  List<BatchsModel> filteredBatchsByComponents =
      []; // Lista para los productos filtrados

  List<HistoryBatch> historyBatchs = []; // Lista para los productos filtrados
  List<HistoryBatch> filtersHistoryBatchs =
      []; // Lista para los productos filtrados

  List<Novedad> listOfNovedades = [];
  bool isKeyboardVisible = false;
  List<Origin> listOfOrigins = [];

  String scannedToDo = '';

  HistoryBatchId historyBatchId = HistoryBatchId();

  WmsPickingRepository wmsPickingRepository = WmsPickingRepository();

  //*controller para la busqueda
  TextEditingController searchController = TextEditingController();
  TextEditingController searchHistoryController = TextEditingController();

  //*instancia de la base de datos
  final DataBaseSqlite _databas = DataBaseSqlite();

  WMSPickingBloc() : super(ProductspickingInitial()) {
    //*obtener todos los batchs desde odoo
    on<LoadAllBatchsEvent>(_onLoadAllBatchsEvent);
    //*obtener todos los batchs desde de picking por componentes
    on<LoadAllBatchsByComponentsEvent>(_onLoadAllBatchsByComponentsEvent);
    //*obtener todos los batchs desde el historial de odoo
    on<LoadHistoryBatchsEvent>(_onLoadHistoryBatchsEvent);
    //*obtener un batch por id del hisorial
    on<LoadHistoryBatchIdEvent>(_onLoadHistoryBatchIdEvent);

    //*Buscar un batch en el historial
    on<SearchBatchHistoryEvent>(_onSearchBacthHistoryEvent);
    // *filtrar por estado los batchs desde SQLite
    on<FilterBatchesBStatusEvent>(_onFilterBatchesBStatusEvent);
    //evento para mostrar el teclado
    on<ShowKeyboardEvent>(_onShowKeyboardEvent);

    //evento para obtener todas las novedades desde odoo
    on<LoadAllNovedades>(_onLoadAllNovedadesEvent);

    on<LoadDocOriginsEvent>(_onLoadDocOriginsEvent);

    on<UpdateScannedValuePickingEvent>(_onUpdateScannedValueEvent);
    on<ClearScannedValuePickingEvent>(_onClearScannedValueEvent);
  }

//*evento para limpiar el valor del scan
  void _onClearScannedValueEvent(
      ClearScannedValuePickingEvent event, Emitter<PickingState> emit) {
    try {
      switch (event.scan) {
        case 'toDo':
          scannedToDo = '';
          emit(ClearScannedValueState());
          break;

        default:
          print('Scan type not recognized: ${event.scan}');
      }
      emit(ClearScannedValueState());
    } catch (e, s) {
      print("❌ Error en _onClearScannedValueEvent: $e, $s");
    }
  }

  //*evento para actualizar el valor del scan
  void _onUpdateScannedValueEvent(
      UpdateScannedValuePickingEvent event, Emitter<PickingState> emit) {
    try {
      print('scannedValue: ${event.scannedValue}');
      switch (event.scan) {
        case 'toDo':
          // Acumulador de valores escaneados
          scannedToDo += event.scannedValue.trim();
          print('scannedToDo: $scannedToDo.');
          emit(UpdateScannedValueState(scannedToDo, event.scan));
          break;
        default:
          print('Scan type not recognized: ${event.scan}');
      }
    } catch (e, s) {
      print("❌ Error en _onUpdateScannedValueEvent: $e, $s");
    }
  }

  void _onLoadDocOriginsEvent(
      LoadDocOriginsEvent event, Emitter<PickingState> emit) async {
    try {
      final batchsFromDB = await _databas.docOriginRepository
          .getAllOriginsByIdBatch(event.idBatch, 'picking');

      listOfOrigins.clear();

      listOfOrigins = batchsFromDB;
      print('listOfOrigins: ${listOfOrigins.length}');

      emit(LoadDocOriginsState(listOfOrigins: listOfOrigins));
    } catch (e, s) {
      print('Error LoadDocOriginsEvent: $e, $s');
    }
  }

  //*metodo para cargar todas las novedades

  void _onLoadAllNovedadesEvent(
      LoadAllNovedades event, Emitter<PickingState> emit) async {
    try {
      final novedadeslist = await wmsPickingRepository.getnovedades(
        false,
      );
      listOfNovedades.clear();
      listOfNovedades.addAll(novedadeslist);

      // Si hay novedades para insertar, ejecutar la inserción en batch
      if (listOfNovedades.isNotEmpty) {
        try {
          await DataBaseSqlite()
              .novedadesRepository
              .syncNovedades(listOfNovedades);
          print('Novedades insertadas con éxito.');
        } catch (e) {
          print('Error inserting batch of novedades: $e');
        }
      }

      emit(LoadSuccessNovedadesState(listOfNovedades: listOfNovedades));
    } catch (e, s) {
      print('Error LoadAllNovedadesEvent: $e, $s');
    }
  }

  void _onShowKeyboardEvent(
      ShowKeyboardEvent event, Emitter<PickingState> emit) {
    isKeyboardVisible = event.showKeyboard;
    emit(ShowKeyboardState(showKeyboard: isKeyboardVisible));
  }

  void _onFilterBatchesBStatusEvent(
      FilterBatchesBStatusEvent event, Emitter<PickingState> emit) async {
    final int userId = await PrefUtils.getUserId();

    final batchsFromDB =
        await _databas.batchPickingRepository.getAllBatchs(userId, event.type);

    if (event.type == 'components') {
      filteredBatchsByComponents.clear();
      filteredBatchsByComponents = batchsFromDB;
    } else {
      filteredBatchs.clear();
      filteredBatchs = batchsFromDB;
    }

    emit(LoadBatchsSuccesBDState(
        listOfBatchs: event.type == 'components'
            ? filteredBatchsByComponents
            : filteredBatchs));
  }

  void _onLoadAllBatchsEvent(
      LoadAllBatchsEvent event, Emitter<PickingState> emit) async {
    try {
      emit(BatchsPickingLoadingState());

      final response = await wmsPickingRepository.resBatchs(
        event.isLoadinDialog,
      );

      listOfBatchs.clear();
      filteredBatchs.clear();

      if (response.result != null && response.result is List) {
        int userId = await PrefUtils.getUserId();
        listOfBatchs.addAll(response.result ?? []);

        if ((response.updateVersion ?? false) == true) {
          emit(NeedUpdateVersionState());
        }

        if (listOfBatchs.isNotEmpty) {
          await DataBaseSqlite()
              .batchPickingRepository
              .insertAllBatches(listOfBatchs, userId, 'batch');

          // Convertir el mapa en una lista de productos únicos con cantidades sumadas
          final productsIterable =
              _extractAllProducts(listOfBatchs).toList(growable: false);

          final originsIterable =
              _extractAllOrigins(listOfBatchs).toList(growable: false);

          final allBarcodes = _extractAllBarcodes(response.result ?? [])
              .toList(growable: false);

          // print('response muelles: ${responseMuelles.length}');
          print('productsToInsert: ${productsIterable.length}');
          print('allBarcodes: ${allBarcodes.length}');
          print('originsIterable: ${originsIterable.length}');
          // Enviar la lista agrupada a insertBatchProducts
          await DataBaseSqlite()
              .insertBatchProducts(productsIterable, event.type);

          await DataBaseSqlite()
              .docOriginRepository
              .insertAllDocsOrigins(originsIterable, 'picking');

          if (allBarcodes.isNotEmpty) {
            // Enviar la lista agrupada a insertBarcodesPackageProduct
            await DataBaseSqlite()
                .barcodesPackagesRepository
                .insertOrUpdateBarcodes(allBarcodes, 'picking');
          }

          // //* Carga los batches desde la base de datos
          add(FilterBatchesBStatusEvent(
            '',
            'batch',
          ));
        }

        emit(LoadBatchsSuccesState(listOfBatchs: listOfBatchs));
      } else {
        print('Error resBatchs: response is null');
      }
    } catch (e, s) {
      print('Error LoadAllBatchsEvent: $e, $s');
      emit(BatchsPickingErrorState(e.toString()));
    }
  }

  void _onLoadAllBatchsByComponentsEvent(
      LoadAllBatchsByComponentsEvent event, Emitter<PickingState> emit) async {
    try {
      emit(BatchsPickingLoadingState());

      final response = await wmsPickingRepository.resBatchsByComponents(
        event.isLoadinDialog,
      );

      listOfBatchsByComponents.clear();
      filteredBatchsByComponents.clear();

      if (response.result != null && response.result is List) {
        int userId = await PrefUtils.getUserId();
        listOfBatchsByComponents.addAll(response.result ?? []);

        if ((response.updateVersion ?? false) == true) {
          emit(NeedUpdateVersionState());
        }

        if (listOfBatchsByComponents.isNotEmpty) {
          await DataBaseSqlite()
              .batchPickingRepository
              .insertAllBatches(listOfBatchsByComponents, userId, 'components');
          // Convertir el mapa en una lista de productos únicos con cantidades sumadas
          final productsIterable = _extractAllProducts(listOfBatchsByComponents)
              .toList(growable: false);

          final originsIterable = _extractAllOrigins(listOfBatchsByComponents)
              .toList(growable: false);

          final allBarcodes = _extractAllBarcodes(response.result ?? [])
              .toList(growable: false);

          // print('response muelles: ${responseMuelles.length}');
          print('productsToInsert: ${productsIterable.length}');
          print('allBarcodes: ${allBarcodes.length}');
          print('originsIterable: ${originsIterable.length}');
          // Enviar la lista agrupada a insertBatchProducts
          await DataBaseSqlite()
              .insertBatchProducts(productsIterable, 'components');

          await DataBaseSqlite()
              .docOriginRepository
              .insertAllDocsOrigins(originsIterable, 'components');
          if (allBarcodes.isNotEmpty) {
            // Enviar la lista agrupada a insertBarcodesPackageProduct
            await DataBaseSqlite()
                .barcodesPackagesRepository
                .insertOrUpdateBarcodes(allBarcodes, 'components');
          }

          // //* Carga los batches desde la base de datos
          add(FilterBatchesBStatusEvent(
            '',
            'components',
          ));
        }

        
        emit(LoadBatchsSuccesState(listOfBatchs: listOfBatchsByComponents));
      } else {
        print('Error resBatchs: response is null');
      }
    } catch (e, s) {
      print('Error LoadAllBatchsEvent: $e, $s');
      emit(BatchsPickingErrorState(e.toString()));
    }
  }

  Iterable<Barcodes> _extractAllBarcodes(List<BatchsModel> batches) sync* {
    for (final batch in batches) {
      if (batch.listItems == null) continue;

      for (final product in batch.listItems!) {
        if (product.productPacking != null) {
          yield* product.productPacking!;
        }
        if (product.otherBarcode != null) {
          yield* product.otherBarcode!;
        }
      }
    }
  }

  Iterable<Origin> _extractAllOrigins(List<BatchsModel> batches) {
    return batches.expand((batch) {
      final origins = batch.origin ?? [];
      return origins.where((p) => p.id != null && p.name != null).map((p) {
        return Origin(id: p.id!, name: p.name!, idBatch: batch.id);
      });
    });
  }

  Iterable<ProductsBatch> _extractAllProducts(List<BatchsModel> batches) sync* {
    for (final batch in batches) {
      if (batch.listItems != null) {
        yield* batch.listItems!;
      }
    }
  }

  void _onLoadHistoryBatchsEvent(
      LoadHistoryBatchsEvent event, Emitter<PickingState> emit) async {
    try {
      print('date: ${event.date}');
      emit(BatchsPickingLoadingState());

      final response = await wmsPickingRepository.resBatchsHistory(
        event.isLoadinDialog,
        event.date,
      );

      if (response != null && response is List) {
        historyBatchs.clear();
        filtersHistoryBatchs.clear();
        historyBatchs.addAll(response);
        filtersHistoryBatchs.addAll(response);

        emit(LoadHistoryBatchState(listOfBatchs: filtersHistoryBatchs));
      } else {
        print('Error resHistoryBatchs: response is null');
      }
    } catch (e, s) {
      print('Error LoadHistoryBatchsEvent: $e, $s');
      emit(BatchsPickingErrorState(e.toString()));
    }
  }

  void _onLoadHistoryBatchIdEvent(
      LoadHistoryBatchIdEvent event, Emitter<PickingState> emit) async {
    try {
      emit(BatchHistoryLoadingState());

      final response = await wmsPickingRepository.getBatchById(
        event.isLoadinDialog,
        event.batchId,
      );

      if (response != null && response is HistoryBatchId) {
        historyBatchId = HistoryBatchId();
        historyBatchId = response;
        emit(BatchHistoryLoadedState(historyBatchId));
      } else {
        print('Error resHistoryBatchs: response is null');
      }
    } catch (e, s) {
      print('Error LoadHistoryBatchsEvent: $e, $s');
      emit(BatchsPickingErrorState(e.toString()));
    }
  }

  void _onSearchBacthHistoryEvent(
      SearchBatchHistoryEvent event, Emitter<PickingState> emit) async {
    final query = event.query.toLowerCase();

    if (query.isEmpty) {
      filtersHistoryBatchs = historyBatchs;
    } else {
      filtersHistoryBatchs = historyBatchs.where((batch) {
        return batch.name?.toLowerCase().contains(query) ?? false;
      }).toList();
    }

    emit(LoadHistoryBatchState(listOfBatchs: filtersHistoryBatchs));
  }
}
