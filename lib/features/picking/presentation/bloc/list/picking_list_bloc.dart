// ignore_for_file: prefer_is_empty

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/transferencias/data/transferencias_repository.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/data/picking_pick_repository.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/PickhWithProducts_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_model.dart';

part 'picking_list_event.dart';
part 'picking_list_state.dart';

class PickingListBloc extends Bloc<PickingListEvent, PickingListState> {
  final PickingPickRepository _pickingRepository = PickingPickRepository();
  final TransferenciasRepository _transferRepository = TransferenciasRepository();
  final DataBaseSqlite _db = DataBaseSqlite();

  //*valores de scanvalue ──────────────────────────────────────────────────────
  String scannedValue1 = '';
 

  // ── Estado en memoria ──────────────────────────────────────────────────────
  List<ResultPick> listOfPick = [];
  List<ResultPick> listOfPickFiltered = [];
  List<ResultPick> historyPicks = [];
  List<ResultPick> filtersHistoryPicks = [];



  PickWithProducts pickWithProducts = PickWithProducts();
  UserConfigurationModel configurations = UserConfigurationModel();

  TextEditingController searchPickController = TextEditingController();

  String currentFilterKey = 'priority_high';

  // ──────────────────────────────────────────────────────────────────────────

  PickingListBloc() : super(const PickingListInitial()) {
    on<FetchPicksEvent>(_onFetchPicks);
    on<FetchPicksFromDbEvent>(_onFetchPicksFromDb);
    on<SearchPickListEvent>(_onSearchPickList);
    on<SortPicksEvent>(_onSortPicks);
    on<AssignUserToPickEvent>(_onAssignUserToPick);
    on<StartStopTimePickEvent>(_onStartStopTimePick);
    on<LoadPickWithProductsEvent>(_onLoadPickWithProducts);
    on<LoadPickConfigurationsEvent>(_onLoadPickConfigurations);
    on<LoadPickHistoryEvent>(_onLoadPickHistory);
  }

  // ── FetchPicksEvent ────────────────────────────────────────────────────────
  Future<void> _onFetchPicks(
      FetchPicksEvent event, Emitter<PickingListState> emit) async {
    emit(const PickingListLoading());
    try {
      await DataBaseSqlite().delePick('pick');

      final result =
          await _pickingRepository.resPicks(event.isLoadingDialog);

      if ((result.updateVersion ?? false) == true) {
        emit(const NeedUpdateVersionPickState());
      }

      if (result.result?.isNotEmpty == true) {
        await _db.pickRepository
            .insertAllPickingPicks(result.result!, 'pick');

        final products = _extractAllProducts(result.result!).toList();
        final sentProducts = _getAllSentProducts(result.result!).toList();
        final barcodes = _extractAllBarcodes(result.result!).toList();

        await _db.pickProductsRepository
            .insertPickProducts(products, 'pick');
        await _db.pickProductsRepository
            .insertPickProducts(sentProducts, 'pick');

        if (barcodes.isNotEmpty) {
          await DataBaseSqlite()
              .barcodesPackagesRepository
              .insertOrUpdateBarcodes(barcodes, 'pick');
        }

        add(const FetchPicksFromDbEvent());
        emit(PicksLoaded(result.result ?? []));
      } else {
        listOfPick = [];
        listOfPickFiltered = [];
        emit(PicksLoaded(result.result ?? []));
      }
    } catch (e) {
      emit(PickingListError(e.toString()));
    }
  }

  // ── FetchPicksFromDbEvent ─────────────────────────────────────────────────
  Future<void> _onFetchPicksFromDb(
      FetchPicksFromDbEvent event, Emitter<PickingListState> emit) async {
    emit(const PickingListDbLoading());
    try {
      final result =
          await _db.pickRepository.getAllPickingPicks('pick');
      listOfPick.clear();
      listOfPickFiltered.clear();

      if (result.isNotEmpty) {
        listOfPick = result;
        listOfPickFiltered = List.from(result)
          ..sort((a, b) {
            final pA = a.priority ?? '0';
            final pB = b.priority ?? '0';
            return pB.compareTo(pA); // Alta primero por defecto
          });
        emit(PicksLoadedFromDb(listOfPickFiltered));
        return;
      }
      emit(const PicksLoadedFromDb([]));
    } catch (e) {
      emit(PickingListError(e.toString()));
    }
  }

  // ── SearchPickListEvent ───────────────────────────────────────────────────
  void _onSearchPickList(
      SearchPickListEvent event, Emitter<PickingListState> emit) {
    try {
      final query = event.query.toLowerCase();

      // La búsqueda de componentes la maneja PickingComponentsBloc
      if (event.isComponentes) return;

      if (query.isEmpty) {
        listOfPickFiltered = List.from(listOfPick);
        filtersHistoryPicks = List.from(historyPicks);
      } else {
        listOfPickFiltered = listOfPick.where((pick) {
          final name = pick.name?.toLowerCase() ?? '';
          final origin = pick.origin?.toLowerCase() ?? '';
          final proveedor = pick.proveedor?.toLowerCase() ?? '';
          final backorder = pick.backorderName?.toLowerCase() ?? '';
          final zona = pick.zonaEntrega?.toLowerCase() ?? '';
          return name.contains(query) ||
              origin.contains(query) ||
              proveedor.contains(query) ||
              backorder.contains(query) ||
              zona.contains(query);
        }).toList();

        filtersHistoryPicks = historyPicks.where((pick) {
          final name = pick.name?.toLowerCase() ?? '';
          final origin = pick.referencia?.toLowerCase() ?? '';
          final proveedor = pick.proveedor?.toLowerCase() ?? '';
          final backorder = pick.backorderName?.toLowerCase() ?? '';
          final zona = pick.zonaEntrega?.toLowerCase() ?? '';
          return name.contains(query) ||
              origin.contains(query) ||
              proveedor.contains(query) ||
              backorder.contains(query) ||
              zona.contains(query);
        }).toList();
      }

      emit(const PickListSearched());
    } catch (e, s) {
      debugPrint('❌ Error en _onSearchPickList: $e, $s');
    }
  }

  // ── SortPicksEvent ────────────────────────────────────────────────────────
  void _onSortPicks(SortPicksEvent event, Emitter<PickingListState> emit) {
    final sorted = List<ResultPick>.from(listOfPickFiltered);

    sorted.sort((a, b) {
      switch (event.field) {
        case 'priority':
          final pA = a.priority ?? '0';
          final pB = b.priority ?? '0';
          currentFilterKey =
              event.ascending ? 'priority_normal' : 'priority_high';
          return event.ascending ? pA.compareTo(pB) : pB.compareTo(pA);

        case 'backorder':
          final hasA = (a.backorderName?.isNotEmpty ?? false) ? 1 : 0;
          final hasB = (b.backorderName?.isNotEmpty ?? false) ? 1 : 0;
          currentFilterKey =
              event.ascending ? 'backorder_asc' : 'backorder_desc';
          return event.ascending
              ? hasA.compareTo(hasB)
              : hasB.compareTo(hasA);

        case 'date':
          final dateA =
              DateTime.tryParse(a.fechaCreacion ?? '') ?? DateTime(1900);
          final dateB =
              DateTime.tryParse(b.fechaCreacion ?? '') ?? DateTime(1900);
          final diff = dateA.compareTo(dateB);
          currentFilterKey = event.ascending ? 'date_asc' : 'date_desc';
          return event.ascending ? diff : -diff;

        case 'name':
          final nameA = a.name ?? '';
          final nameB = b.name ?? '';
          final diff = nameA.toLowerCase().compareTo(nameB.toLowerCase());
          currentFilterKey = event.ascending ? 'name_asc' : 'name_desc';
          return event.ascending ? diff : -diff;

        default:
          return 0;
      }
    });

    listOfPickFiltered = sorted;
    emit(PicksSorted(sorted));
  }

  // ── AssignUserToPickEvent ─────────────────────────────────────────────────
  Future<void> _onAssignUserToPick(
      AssignUserToPickEvent event, Emitter<PickingListState> emit) async {
    try {
      final userId = await PrefUtils.getUserId();
      final userName = await PrefUtils.getUserName();

      emit(const AssignUserToPickLoading());

      final ok = await _transferRepository.assignUserToTransfer(
        false,
        userId,
        event.id,
      );

      if (ok) {
        await _db.pickRepository
            .setFieldTablePick(event.id, 'responsable_id', userId);
        await _db.pickRepository
            .setFieldTablePick(event.id, 'responsable', userName);
        await _db.pickRepository
            .setFieldTablePick(event.id, 'is_selected', 1);

        add(StartStopTimePickEvent(event.id, 'start_time_transfer'));
        emit(AssignUserToPickSuccess(event.id));
      } else {
        emit(const AssignUserToPickError(
            'La recepción ya tiene un responsable asignado'));
      }
    } catch (e, s) {
      emit(const AssignUserToPickError('Error al asignar el usuario'));
      debugPrint('❌ Error en _onAssignUserToPick: $e, $s');
    }
  }

  // ── StartStopTimePickEvent ────────────────────────────────────────────────
  Future<void> _onStartStopTimePick(
      StartStopTimePickEvent event, Emitter<PickingListState> emit) async {
    try {
      final time =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      if (event.value == 'start_time_transfer') {
        await _db.pickRepository
            .setFieldTablePick(event.id, 'start_time_transfer', time);
        await _db.pickRepository
            .setFieldTablePick(event.id, 'is_selected', 1);
      } else if (event.value == 'end_time_transfer') {
        await _db.pickRepository
            .setFieldTablePick(event.id, 'end_time_transfer', time);
      }

      final ok = await _transferRepository.sendTime(
        event.id,
        event.value,
        time,
        false,
      );

      if (ok) {
        emit(StartStopTimeSuccess(event.value));
      } else {
        emit(const StartStopTimeFailure('Error al enviar el tiempo'));
      }
    } catch (e, s) {
      debugPrint('❌ Error en _onStartStopTimePick: $e, $s');
    }
  }

  // ── LoadPickWithProductsEvent ─────────────────────────────────────────────
  Future<void> _onLoadPickWithProducts(
      LoadPickWithProductsEvent event, Emitter<PickingListState> emit) async {
    try {
      pickWithProducts = PickWithProducts();

      final response = await _db.pickProductsRepository
          .getPickWithProducts(event.pickId);

      if (response != null && response.products?.isNotEmpty == true) {
        pickWithProducts = response;
        emit(PickWithProductsLoaded(response));
      } else {
        emit(const PickWithProductsEmpty());
      }
    } catch (e, s) {
      debugPrint('❌ Error en _onLoadPickWithProducts: $e, $s');
    }
  }

  // ── LoadPickConfigurationsEvent ───────────────────────────────────────────
  Future<void> _onLoadPickConfigurations(
      LoadPickConfigurationsEvent event,
      Emitter<PickingListState> emit) async {
    try {
      emit(const PickConfigurationsLoading());
      final userId = await PrefUtils.getUserId();
      final response =
          await _db.configurationsRepository.getConfiguration(userId);

      if (response != null) {
        configurations = response;
        emit(PickConfigurationsLoaded(response));
      } else {
        emit(const PickConfigurationsError(
            'Error al cargar las configuraciones'));
      }
    } catch (e, s) {
      debugPrint('❌ Error en _onLoadPickConfigurations: $e, $s');
    }
  }

  // ── LoadPickHistoryEvent ──────────────────────────────────────────────────
  Future<void> _onLoadPickHistory(
      LoadPickHistoryEvent event, Emitter<PickingListState> emit) async {
    try {
      emit(const PickHistoryLoading());

      final response = await _pickingRepository.resPicksDone(
        event.isLoadingDialog,
        event.date,
      );

      if (response != null && response.isNotEmpty) {
        historyPicks = List<ResultPick>.from(response);
        filtersHistoryPicks = List<ResultPick>.from(response);
        emit(PickHistoryLoaded(filtersHistoryPicks));
      } else {
        emit(const PickHistoryError('No se encontraron resultados'));
      }
    } catch (e, s) {
      emit(PickHistoryError(e.toString()));
      debugPrint('❌ Error en _onLoadPickHistory: $e, $s');
    }
  }

  // ── Helpers privados (misma lógica que PickingPickBloc) ───────────────────

  Iterable<ProductsBatch> _extractAllProducts(
      List<ResultPick> picks) sync* {
    for (final pick in picks) {
      if (pick.lineasTransferencia != null) {
        yield* pick.lineasTransferencia!;
      }
    }
  }

  Iterable<ProductsBatch> _getAllSentProducts(
      List<ResultPick> picks) sync* {
    for (final pick in picks) {
      if (pick.lineasTransferenciaEnviadas != null) {
        yield* pick.lineasTransferenciaEnviadas!;
      }
    }
  }

  Iterable<Barcodes> _extractAllBarcodes(List<ResultPick> picks) sync* {
    for (final pick in picks) {
      if (pick.lineasTransferencia == null) continue;
      for (final product in pick.lineasTransferencia!) {
        if (product.productPacking != null) yield* product.productPacking!;
        if (product.otherBarcode != null) yield* product.otherBarcode!;
      }
    }
  }

  @override
  Future<void> close() {
    searchPickController.dispose();
    return super.close();
  }
}
