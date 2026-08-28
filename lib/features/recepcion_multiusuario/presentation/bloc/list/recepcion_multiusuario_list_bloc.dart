import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/usecases/fetch_recepcion_sessions_usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/usecases/get_recepcion_sessions_from_db_usecase.dart';

part 'recepcion_multiusuario_list_event.dart';
part 'recepcion_multiusuario_list_state.dart';

/// Bloc de la lista de recepción multiusuario (solo lectura/búsqueda). Fase 1
/// del módulo: no maneja asignación de responsable ni tiempos — a diferencia
/// del módulo de recepción individual, aquí una sesión puede tener 1 o más
/// usuarios trabajándola a la vez.
@injectable
class RecepcionMultiusuarioListBloc
    extends
        Bloc<RecepcionMultiusuarioListEvent, RecepcionMultiusuarioListState> {
  final FetchRecepcionSessionsUseCase fetchRecepcionSessionsUseCase;
  final GetRecepcionSessionsFromDbUseCase getRecepcionSessionsFromDbUseCase;

  List<RecepcionSession> _todasLasSesiones = [];
  List<RecepcionSession> _sesionesFiltradas = [];

  RecepcionMultiusuarioListBloc({
    required this.fetchRecepcionSessionsUseCase,
    required this.getRecepcionSessionsFromDbUseCase,
  }) : super(const RecepcionMultiusuarioListInitial()) {
    on<FetchRecepcionSessionsEvent>(_onFetchSessions);
    on<FetchRecepcionSessionsFromDbEvent>(_onFetchSessionsFromDb);
    on<SearchRecepcionSessionEvent>(_onSearchSession);
  }

  Future<void> _onFetchSessions(
    FetchRecepcionSessionsEvent event,
    Emitter<RecepcionMultiusuarioListState> emit,
  ) async {
    emit(const RecepcionMultiusuarioListLoading());

    final result = await fetchRecepcionSessionsUseCase(
      FetchRecepcionSessionsParams(isLoadinDialog: event.isLoadinDialog),
    );

    result.fold(
      (failure) =>
          emit(RecepcionMultiusuarioListError(_mapFailureMessage(failure))),
      (sessions) {
        _todasLasSesiones = sessions;
        _sesionesFiltradas = List.from(_todasLasSesiones);
        emit(RecepcionSessionsLoaded(_sesionesFiltradas));
      },
    );
  }

  Future<void> _onFetchSessionsFromDb(
    FetchRecepcionSessionsFromDbEvent event,
    Emitter<RecepcionMultiusuarioListState> emit,
  ) async {
    emit(const RecepcionMultiusuarioListDbLoading());

    final result = await getRecepcionSessionsFromDbUseCase(NoParams());

    result.fold(
      (failure) =>
          emit(RecepcionMultiusuarioListError(_mapFailureMessage(failure))),
      (sessions) {
        _todasLasSesiones = sessions;
        _sesionesFiltradas = List.from(_todasLasSesiones);
        emit(RecepcionSessionsLoaded(_sesionesFiltradas));
      },
    );
  }

  void _onSearchSession(
    SearchRecepcionSessionEvent event,
    Emitter<RecepcionMultiusuarioListState> emit,
  ) {
    final query = event.query.trim();

    if (query.isEmpty) {
      _sesionesFiltradas = List.from(_todasLasSesiones);
    } else {
      final normalizedQuery = _normalizeText(query);
      _sesionesFiltradas = _todasLasSesiones.where((session) {
        final name = _normalizeText(session.name ?? '');
        final pickingName = _normalizeText(session.pickingName ?? '');
        return name.contains(normalizedQuery) ||
            pickingName.contains(normalizedQuery);
      }).toList();
    }

    emit(RecepcionSessionsLoaded(_sesionesFiltradas));
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
