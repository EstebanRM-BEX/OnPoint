import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_claim.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/usecases/fetch_transferencia_my_claims_usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/usecases/release_transferencia_claim_usecase.dart';

part 'transferencia_multiusuario_my_claims_event.dart';
part 'transferencia_multiusuario_my_claims_state.dart';

/// Bloc del tab "Asignados": productos que el usuario actual ya reclamó y
/// sigue trabajando en la sesión (POST /api/transfer/session/{id}/my_claims),
/// y la acción de liberar una asignación
/// (POST /api/transfer/claim/{id}/release). Espejo de
/// RecepcionMultiusuarioMyClaimsBloc. Sin persistencia local — se lee en
/// vivo, igual que el pool.
@injectable
class TransferenciaMultiusuarioMyClaimsBloc
    extends
        Bloc<
          TransferenciaMultiusuarioMyClaimsEvent,
          TransferenciaMultiusuarioMyClaimsState
        > {
  final FetchTransferenciaMyClaimsUseCase fetchTransferenciaMyClaimsUseCase;
  final ReleaseTransferenciaClaimUseCase releaseTransferenciaClaimUseCase;

  /// Último listado cargado con éxito. Permite a la UI seguir mostrando la
  /// lista mientras se procesa un release (loading/success/error de esa
  /// acción no traen su propio listado).
  List<TransferenciaClaim> currentClaims = [];

  TransferenciaMultiusuarioMyClaimsBloc({
    required this.fetchTransferenciaMyClaimsUseCase,
    required this.releaseTransferenciaClaimUseCase,
  }) : super(const TransferenciaMultiusuarioMyClaimsInitial()) {
    on<FetchMyClaimsEvent>(_onFetchMyClaims);
    on<ReleaseClaimEvent>(_onReleaseClaim);
    on<SeedTransferenciaMyClaimsEvent>(_onSeedMyClaims);
  }

  Future<void> _onFetchMyClaims(
    FetchMyClaimsEvent event,
    Emitter<TransferenciaMultiusuarioMyClaimsState> emit,
  ) async {
    emit(const TransferenciaMultiusuarioMyClaimsLoading());

    final result = await fetchTransferenciaMyClaimsUseCase(
      FetchTransferenciaMyClaimsParams(
        sessionId: event.sessionId,
        isLoadinDialog: event.isLoadinDialog,
      ),
    );

    result.fold(
      (failure) => emit(
        TransferenciaMultiusuarioMyClaimsError(_mapFailureMessage(failure)),
      ),
      (claims) {
        currentClaims = claims;
        emit(TransferenciaMyClaimsLoaded(claims));
      },
    );
  }

  Future<void> _onReleaseClaim(
    ReleaseClaimEvent event,
    Emitter<TransferenciaMultiusuarioMyClaimsState> emit,
  ) async {
    emit(const ClaimReleaseLoading());

    final result = await releaseTransferenciaClaimUseCase(
      ReleaseTransferenciaClaimParams(claimId: event.claimId),
    );

    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(ClaimReleaseError(_mapFailureMessage(failure)));
      return;
    }

    emit(const ClaimReleaseSuccess());

    // Refresca "Asignados": el producto liberado ya no debe aparecer.
    final refreshed = await fetchTransferenciaMyClaimsUseCase(
      FetchTransferenciaMyClaimsParams(sessionId: event.sessionId),
    );
    refreshed.fold(
      (f) =>
          emit(TransferenciaMultiusuarioMyClaimsError(_mapFailureMessage(f))),
      (claims) {
        currentClaims = claims;
        emit(TransferenciaMyClaimsLoaded(claims));
      },
    );
  }

  void _onSeedMyClaims(
    SeedTransferenciaMyClaimsEvent event,
    Emitter<TransferenciaMultiusuarioMyClaimsState> emit,
  ) {
    currentClaims = event.claims;
    emit(TransferenciaMyClaimsLoaded(event.claims));
  }

  String _mapFailureMessage(Failure failure) {
    return switch (failure) {
      NetworkFailure() => 'Sin conexión a Internet',
      ServerFailure() => failure.message,
      _ => 'Error inesperado',
    };
  }
}
