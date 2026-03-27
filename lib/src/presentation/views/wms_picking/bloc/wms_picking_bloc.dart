// ignore_for_file: unnecessary_type_check, unnecessary_null_comparison, avoid_print, unnecessary_import, unrelated_type_equality_checks, use_build_context_synchronously

import 'dart:math';

import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/user/domain/entities/user_novelty.dart';
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
    //evento para obtener todas las novedades desde odoo
    on<LoadAllNovedades>(_onLoadAllNovedadesEvent);

    on<LoadDocOriginsEvent>(_onLoadDocOriginsEvent);
  }

  void _onLoadDocOriginsEvent(
      LoadDocOriginsEvent event, Emitter<PickingState> emit) async {
    try {
      final batchsFromDB = await _databas.docOriginRepository
          .getAllOriginsByIdBatch(event.idBatch, 'picking');

      listOfOrigins.clear();

      listOfOrigins = batchsFromDB;
      debugPrint('listOfOrigins: ${listOfOrigins.length}');

      emit(LoadDocOriginsState(listOfOrigins: listOfOrigins));
    } catch (e, s) {
      debugPrint('Error LoadDocOriginsEvent: $e, $s');
    }
  }

  //*metodo para cargar todas las novedades

  void _onLoadAllNovedadesEvent(
      LoadAllNovedades event, Emitter<PickingState> emit) async {
    try {
      emit(LoadLoadingNovedadesState());
      final response = await _databas.novedadesRepository.getAllNovedades();
      if (response != null) {
        listOfNovedades.clear();
        listOfNovedades = response;
        debugPrint("novedades: ${listOfNovedades.length}");
        emit(LoadSuccessNovedadesState(listOfNovedades: listOfNovedades));
      } else {
        emit(LoadFailureNovedadesState(message: 'No se encontraron novedades'));
      }
    } catch (e, s) {
      debugPrint("Error en __onLoadAllNovedadesEvent: $e, $s");
      emit(LoadFailureNovedadesState(message: 'Error al cargar novedades'));
    }
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

      await DataBaseSqlite().delePicking('batch');

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
          //LIMPIAMOS LA BD

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

          // debugPrint('response muelles: ${responseMuelles.length}');
          debugPrint('productsToInsert: ${productsIterable.length}');
          debugPrint('allBarcodes: ${allBarcodes.length}');
          debugPrint('originsIterable: ${originsIterable.length}');
          // Enviar la lista agrupada a insertBatchProducts
          await DataBaseSqlite()
              .insertBatchProducts(productsIterable, event.type);

          await DataBaseSqlite()
              .docOriginRepository
              .insertAllDocsOrigins(originsIterable, 'batch');

          if (allBarcodes.isNotEmpty) {
            // Enviar la lista agrupada a insertBarcodesPackageProduct
            await DataBaseSqlite()
                .barcodesPackagesRepository
                .insertOrUpdateBarcodes(allBarcodes, 'batch');
          }

          // //* Carga los batches desde la base de datos
          add(FilterBatchesBStatusEvent(
            '',
            'batch',
          ));
        }

        emit(LoadBatchsSuccesState(listOfBatchs: listOfBatchs));
      } else {
        debugPrint('Error resBatchs: response is null');
      }
    } catch (e, s) {
      debugPrint('Error LoadAllBatchsEvent: $e, $s');
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

          // debugPrint('response muelles: ${responseMuelles.length}');
          debugPrint('productsToInsert: ${productsIterable.length}');
          debugPrint('allBarcodes: ${allBarcodes.length}');
          debugPrint('originsIterable: ${originsIterable.length}');
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
        debugPrint('Error resBatchs: response is null');
      }
    } catch (e, s) {
      debugPrint('Error LoadAllBatchsEvent: $e, $s');
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
      debugPrint('date: ${event.date}');
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
        debugPrint('Error resHistoryBatchs: response is null');
      }
    } catch (e, s) {
      debugPrint('Error LoadHistoryBatchsEvent: $e, $s');
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
        debugPrint('Error resHistoryBatchs: response is null');
      }
    } catch (e, s) {
      debugPrint('Error LoadHistoryBatchsEvent: $e, $s');
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
