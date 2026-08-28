part of 'recepcion_multiusuario_my_claims_bloc.dart';

sealed class RecepcionMultiusuarioMyClaimsEvent extends Equatable {
  const RecepcionMultiusuarioMyClaimsEvent();

  @override
  List<Object> get props => [];
}

/// Trae los productos que el usuario actual ya reclamó en [sessionId]
/// (POST /api/receipt/session/{sessionId}/my_claims).
class FetchMyClaimsEvent extends RecepcionMultiusuarioMyClaimsEvent {
  final int sessionId;
  final bool isLoadinDialog;
  const FetchMyClaimsEvent(this.sessionId, {this.isLoadinDialog = false});

  @override
  List<Object> get props => [sessionId, isLoadinDialog];
}

/// Libera la asignación [claimId] (POST /api/receipt/claim/{claimId}/release)
/// y refresca "Mis asignados" de [sessionId] al terminar.
class ReleaseClaimEvent extends RecepcionMultiusuarioMyClaimsEvent {
  final int claimId;
  final int sessionId;
  const ReleaseClaimEvent({required this.claimId, required this.sessionId});

  @override
  List<Object> get props => [claimId, sessionId];
}
