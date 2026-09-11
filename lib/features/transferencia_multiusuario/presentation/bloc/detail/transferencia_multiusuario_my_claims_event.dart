part of 'transferencia_multiusuario_my_claims_bloc.dart';

sealed class TransferenciaMultiusuarioMyClaimsEvent extends Equatable {
  const TransferenciaMultiusuarioMyClaimsEvent();

  @override
  List<Object> get props => [];
}

/// Trae los productos que el usuario actual ya reclamó en [sessionId]
/// (POST /api/transfer/session/{sessionId}/my_claims).
class FetchMyClaimsEvent extends TransferenciaMultiusuarioMyClaimsEvent {
  final int sessionId;
  final bool isLoadinDialog;
  const FetchMyClaimsEvent(this.sessionId, {this.isLoadinDialog = false});

  @override
  List<Object> get props => [sessionId, isLoadinDialog];
}

/// Libera la asignación [claimId] (POST /api/transfer/claim/{claimId}/release)
/// y refresca "Mis asignados" de [sessionId] al terminar.
class ReleaseClaimEvent extends TransferenciaMultiusuarioMyClaimsEvent {
  final int claimId;
  final int sessionId;
  const ReleaseClaimEvent({required this.claimId, required this.sessionId});

  @override
  List<Object> get props => [claimId, sessionId];
}

/// Siembra [currentClaims] con el `my_claims` que ya trajo
/// /transfer/session/{id}/snapshot en la carga inicial, sin llamar de nuevo
/// a /my_claims.
class SeedTransferenciaMyClaimsEvent
    extends TransferenciaMultiusuarioMyClaimsEvent {
  final List<TransferenciaClaim> claims;
  const SeedTransferenciaMyClaimsEvent(this.claims);

  @override
  List<Object> get props => [claims, Object()];
}
