import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_claim.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/usecases/fetch_my_claims_usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/usecases/release_claim_usecase.dart';

part 'recepcion_multiusuario_my_claims_event.dart';
part 'recepcion_multiusuario_my_claims_state.dart';

/// Bloc del tab "Mis asignados": productos que el usuario actual ya
/// reclamó y sigue trabajando en la sesión (POST
/// /api/receipt/session/{id}/my_claims), y la acción de liberar una
/// asignación (POST /api/receipt/claim/{id}/release). Sin persistencia
/// local — se lee en vivo, igual que el pool.
@injectable
class RecepcionMultiusuarioMyClaimsBloc
    extends
        Bloc<
          RecepcionMultiusuarioMyClaimsEvent,
          RecepcionMultiusuarioMyClaimsState
        > {
  final FetchMyClaimsUseCase fetchMyClaimsUseCase;
  final ReleaseClaimUseCase releaseClaimUseCase;

  /// Último listado cargado con éxito. Permite a la UI seguir mostrando la
  /// lista mientras se procesa un release (loading/success/error de esa
  /// acción no traen su propio listado).
  List<RecepcionClaim> currentClaims = [];

  RecepcionMultiusuarioMyClaimsBloc({
    required this.fetchMyClaimsUseCase,
    required this.releaseClaimUseCase,
  }) : super(const RecepcionMultiusuarioMyClaimsInitial()) {
    on<FetchMyClaimsEvent>(_onFetchMyClaims);
    on<ReleaseClaimEvent>(_onReleaseClaim);
  }

  Future<void> _onFetchMyClaims(
    FetchMyClaimsEvent event,
    Emitter<RecepcionMultiusuarioMyClaimsState> emit,
  ) async {
    emit(const RecepcionMultiusuarioMyClaimsLoading());

    final result = await fetchMyClaimsUseCase(
      FetchMyClaimsParams(
        sessionId: event.sessionId,
        isLoadinDialog: event.isLoadinDialog,
      ),
    );

    result.fold(
      (failure) =>
          emit(RecepcionMultiusuarioMyClaimsError(_mapFailureMessage(failure))),
      (claims) {
        currentClaims = claims;
        emit(RecepcionMyClaimsLoaded(claims));
      },
    );
  }

  Future<void> _onReleaseClaim(
    ReleaseClaimEvent event,
    Emitter<RecepcionMultiusuarioMyClaimsState> emit,
  ) async {
    emit(const ClaimReleaseLoading());

    final result = await releaseClaimUseCase(
      ReleaseClaimParams(claimId: event.claimId),
    );

    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(ClaimReleaseError(_mapFailureMessage(failure)));
      return;
    }

    emit(const ClaimReleaseSuccess());

    // Refresca "Mis asignados": el producto liberado ya no debe aparecer.
    final refreshed = await fetchMyClaimsUseCase(
      FetchMyClaimsParams(sessionId: event.sessionId),
    );
    refreshed.fold(
      (f) => emit(RecepcionMultiusuarioMyClaimsError(_mapFailureMessage(f))),
      (claims) {
        currentClaims = claims;
        emit(RecepcionMyClaimsLoaded(claims));
      },
    );
  }

  String _mapFailureMessage(Failure failure) {
    return switch (failure) {
      NetworkFailure() => 'Sin conexión a Internet',
      ServerFailure() => failure.message,
      _ => 'Error inesperado',
    };
  }
}
