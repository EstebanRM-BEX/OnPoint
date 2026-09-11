part of 'transferencia_multiusuario_my_claims_bloc.dart';

sealed class TransferenciaMultiusuarioMyClaimsState extends Equatable {
  const TransferenciaMultiusuarioMyClaimsState();

  @override
  List<Object> get props => [];
}

final class TransferenciaMultiusuarioMyClaimsInitial
    extends TransferenciaMultiusuarioMyClaimsState {
  const TransferenciaMultiusuarioMyClaimsInitial();
}

final class TransferenciaMultiusuarioMyClaimsLoading
    extends TransferenciaMultiusuarioMyClaimsState {
  const TransferenciaMultiusuarioMyClaimsLoading();
}

final class TransferenciaMyClaimsLoaded
    extends TransferenciaMultiusuarioMyClaimsState {
  final List<TransferenciaClaim> claims;
  const TransferenciaMyClaimsLoaded(this.claims);

  @override
  List<Object> get props => [claims, Object()];
}

final class TransferenciaMultiusuarioMyClaimsError
    extends TransferenciaMultiusuarioMyClaimsState {
  final String message;
  const TransferenciaMultiusuarioMyClaimsError(this.message);

  @override
  List<Object> get props => [message];
}

final class ClaimReleaseLoading extends TransferenciaMultiusuarioMyClaimsState {
  const ClaimReleaseLoading();
}

final class ClaimReleaseSuccess extends TransferenciaMultiusuarioMyClaimsState {
  const ClaimReleaseSuccess();
}

final class ClaimReleaseError extends TransferenciaMultiusuarioMyClaimsState {
  final String message;
  const ClaimReleaseError(this.message);

  @override
  List<Object> get props => [message];
}
