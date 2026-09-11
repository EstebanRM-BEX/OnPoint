import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_session.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/usecases/fetch_transferencia_sessions_usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/usecases/get_transferencia_sessions_from_db_usecase.dart';

part 'transferencia_multiusuario_list_event.dart';
part 'transferencia_multiusuario_list_state.dart';

/// Bloc de la lista de transferencia multiusuario (solo lectura/búsqueda).
/// Espejo de RecepcionMultiusuarioListBloc. Fase 1 del módulo: no maneja
/// asignación de responsable ni tiempos — una sesión puede tener 1 o más
/// usuarios trabajándola a la vez.
@injectable
class TransferenciaMultiusuarioListBloc
    extends
        Bloc<
          TransferenciaMultiusuarioListEvent,
          TransferenciaMultiusuarioListState
        > {
  final FetchTransferenciaSessionsUseCase fetchTransferenciaSessionsUseCase;
  final GetTransferenciaSessionsFromDbUseCase
  getTransferenciaSessionsFromDbUseCase;

  List<TransferenciaSession> _todasLasSesiones = [];
  List<TransferenciaSession> _sesionesFiltradas = [];

  TransferenciaMultiusuarioListBloc({
    required this.fetchTransferenciaSessionsUseCase,
    required this.getTransferenciaSessionsFromDbUseCase,
  }) : super(const TransferenciaMultiusuarioListInitial()) {
    on<FetchTransferenciaSessionsEvent>(_onFetchSessions);
    on<FetchTransferenciaSessionsFromDbEvent>(_onFetchSessionsFromDb);
    on<SearchTransferenciaSessionEvent>(_onSearchSession);
  }

  Future<void> _onFetchSessions(
    FetchTransferenciaSessionsEvent event,
    Emitter<TransferenciaMultiusuarioListState> emit,
  ) async {
    emit(const TransferenciaMultiusuarioListLoading());

    final result = await fetchTransferenciaSessionsUseCase(
      FetchTransferenciaSessionsParams(isLoadinDialog: event.isLoadinDialog),
    );

    result.fold(
      (failure) =>
          emit(TransferenciaMultiusuarioListError(_mapFailureMessage(failure))),
      (sessions) {
        _todasLasSesiones = sessions;
        _sesionesFiltradas = List.from(_todasLasSesiones);
        emit(TransferenciaSessionsLoaded(_sesionesFiltradas));
      },
    );
  }

  Future<void> _onFetchSessionsFromDb(
    FetchTransferenciaSessionsFromDbEvent event,
    Emitter<TransferenciaMultiusuarioListState> emit,
  ) async {
    emit(const TransferenciaMultiusuarioListDbLoading());

    final result = await getTransferenciaSessionsFromDbUseCase(NoParams());

    result.fold(
      (failure) =>
          emit(TransferenciaMultiusuarioListError(_mapFailureMessage(failure))),
      (sessions) {
        _todasLasSesiones = sessions;
        _sesionesFiltradas = List.from(_todasLasSesiones);
        emit(TransferenciaSessionsLoaded(_sesionesFiltradas));
      },
    );
  }

  void _onSearchSession(
    SearchTransferenciaSessionEvent event,
    Emitter<TransferenciaMultiusuarioListState> emit,
  ) {
    final query = event.query.trim();

    if (query.isEmpty) {
      _sesionesFiltradas = List.from(_todasLasSesiones);
    } else {
      final normalizedQuery = _normalizeText(query);
      _sesionesFiltradas = _todasLasSesiones.where((session) {
        final name = _normalizeText(session.name ?? '');
        final pickingName = _normalizeText(session.pickingName ?? '');
        final origin = _normalizeText(session.origin ?? '');
        final proveedor = _normalizeText(session.proveedor ?? '');
        return name.contains(normalizedQuery) ||
            pickingName.contains(normalizedQuery) ||
            origin.contains(normalizedQuery) ||
            proveedor.contains(normalizedQuery);
      }).toList();
    }

    emit(TransferenciaSessionsLoaded(_sesionesFiltradas));
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
