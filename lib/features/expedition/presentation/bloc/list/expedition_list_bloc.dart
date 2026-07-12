import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_pedido.dart';
import 'package:wms_app/features/expedition/domain/usecases/fetch_expediciones_usecase.dart';
import 'package:wms_app/features/expedition/domain/usecases/get_expediciones_from_db_usecase.dart';

part 'expedition_list_event.dart';
part 'expedition_list_state.dart';

/// Bloc de lista de expediciones (solo lectura/búsqueda/orden). No maneja
/// certificación de productos ni acciones de detalle — eso es
/// responsabilidad de blocs separados que se agregarán cuando se construya
/// esa parte del módulo.
@injectable
class ExpedicionListBloc extends Bloc<ExpedicionListEvent, ExpedicionListState> {
  final FetchExpedicionesUseCase fetchExpedicionesUseCase;
  final GetExpedicionesFromDbUseCase getExpedicionesFromDbUseCase;

  List<ExpedicionPedido> _todasLasExpediciones = [];
  List<ExpedicionPedido> _expedicionesFiltradas = [];
  String currentFilterKey = 'fecha_desc';

  ExpedicionListBloc({
    required this.fetchExpedicionesUseCase,
    required this.getExpedicionesFromDbUseCase,
  }) : super(const ExpedicionListInitial()) {
    on<FetchExpedicionesEvent>(_onFetchExpediciones);
    on<FetchExpedicionesFromDbEvent>(_onFetchExpedicionesFromDb);
    on<SearchExpedicionEvent>(_onSearchExpedicion);
    on<SortExpedicionListEvent>(_onSortExpedicionList);
  }

  Future<void> _onFetchExpediciones(
    FetchExpedicionesEvent event,
    Emitter<ExpedicionListState> emit,
  ) async {
    emit(const ExpedicionListLoading());

    final result = await fetchExpedicionesUseCase(
      FetchExpedicionesParams(isLoadinDialog: event.isLoadinDialog),
    );

    result.fold(
      (failure) => emit(ExpedicionListError(_mapFailureMessage(failure))),
      (fetchResult) {
        _todasLasExpediciones = fetchResult.expediciones;
        _expedicionesFiltradas = List.from(_todasLasExpediciones);
        if (fetchResult.needsUpdate) {
          emit(const NeedUpdateVersionExpedicionState());
        }
        emit(ExpedicionesLoaded(_expedicionesFiltradas));
      },
    );
  }

  Future<void> _onFetchExpedicionesFromDb(
    FetchExpedicionesFromDbEvent event,
    Emitter<ExpedicionListState> emit,
  ) async {
    emit(const ExpedicionListDbLoading());

    final result = await getExpedicionesFromDbUseCase(NoParams());

    result.fold(
      (failure) => emit(ExpedicionListError(_mapFailureMessage(failure))),
      (expediciones) {
        _todasLasExpediciones = expediciones;
        _expedicionesFiltradas = List.from(_todasLasExpediciones);
        emit(ExpedicionesLoaded(_expedicionesFiltradas));
      },
    );
  }

  void _onSearchExpedicion(
    SearchExpedicionEvent event,
    Emitter<ExpedicionListState> emit,
  ) {
    final query = event.query.trim();

    if (query.isEmpty) {
      _expedicionesFiltradas = List.from(_todasLasExpediciones);
    } else {
      final normalizedQuery = _normalizeText(query);
      _expedicionesFiltradas = _todasLasExpediciones.where((expedicion) {
        final nombre = _normalizeText(expedicion.nombre ?? '');
        final cliente = _normalizeText(expedicion.cliente ?? '');
        final documentoOrigen = _normalizeText(expedicion.documentoOrigen ?? '');
        return nombre.contains(normalizedQuery) ||
            cliente.contains(normalizedQuery) ||
            documentoOrigen.contains(normalizedQuery);
      }).toList();
    }

    emit(ExpedicionesLoaded(_expedicionesFiltradas));
  }

  void _onSortExpedicionList(
    SortExpedicionListEvent event,
    Emitter<ExpedicionListState> emit,
  ) {
    switch (event.field) {
      case 'fecha':
        currentFilterKey = event.ascending ? 'fecha_asc' : 'fecha_desc';
        break;
      case 'nombre':
        currentFilterKey = event.ascending ? 'nombre_asc' : 'nombre_desc';
        break;
      case 'cliente':
        currentFilterKey = event.ascending ? 'cliente_asc' : 'cliente_desc';
        break;
    }

    final sortedList = List<ExpedicionPedido>.from(_expedicionesFiltradas);
    sortedList.sort((a, b) {
      switch (event.field) {
        case 'fecha':
          final fechaA = a.fecha ?? DateTime(1900);
          final fechaB = b.fecha ?? DateTime(1900);
          final resultFecha = fechaA.compareTo(fechaB);
          return event.ascending ? resultFecha : -resultFecha;
        case 'nombre':
          final nombreA = a.nombre ?? '';
          final nombreB = b.nombre ?? '';
          final resultNombre =
              nombreA.toLowerCase().compareTo(nombreB.toLowerCase());
          return event.ascending ? resultNombre : -resultNombre;
        case 'cliente':
          final clienteA = a.cliente ?? '';
          final clienteB = b.cliente ?? '';
          final resultCliente =
              clienteA.toLowerCase().compareTo(clienteB.toLowerCase());
          return event.ascending ? resultCliente : -resultCliente;
        default:
          return 0;
      }
    });

    _expedicionesFiltradas = sortedList;
    emit(ExpedicionesLoaded(_expedicionesFiltradas));
  }

  String _mapFailureMessage(Failure failure) {
    return switch (failure) {
      NetworkFailure() => 'Sin conexión a Internet',
      ServerFailure() => failure.message,
      CacheFailure() => 'Error al leer datos locales',
      _ => 'Error inesperado',
    };
  }

  static String _normalizeText(String input) {
    const Map<String, String> accentMap = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    return input
        .trim()
        .toLowerCase()
        .split('')
        .map((char) => accentMap[char] ?? char)
        .join();
  }
}
