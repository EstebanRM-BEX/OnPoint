part of 'recepcion_multiusuario_my_claims_bloc.dart';

sealed class RecepcionMultiusuarioMyClaimsState extends Equatable {
  const RecepcionMultiusuarioMyClaimsState();

  @override
  List<Object> get props => [];
}

final class RecepcionMultiusuarioMyClaimsInitial
    extends RecepcionMultiusuarioMyClaimsState {
  const RecepcionMultiusuarioMyClaimsInitial();
}

final class RecepcionMultiusuarioMyClaimsLoading
    extends RecepcionMultiusuarioMyClaimsState {
  const RecepcionMultiusuarioMyClaimsLoading();
}

final class RecepcionMyClaimsLoaded extends RecepcionMultiusuarioMyClaimsState {
  final List<RecepcionClaim> claims;
  const RecepcionMyClaimsLoaded(this.claims);

  @override
  List<Object> get props => [claims, Object()];
}

final class RecepcionMultiusuarioMyClaimsError
    extends RecepcionMultiusuarioMyClaimsState {
  final String message;
  const RecepcionMultiusuarioMyClaimsError(this.message);

  @override
  List<Object> get props => [message];
}

final class ClaimReleaseLoading extends RecepcionMultiusuarioMyClaimsState {
  const ClaimReleaseLoading();
}

final class ClaimReleaseSuccess extends RecepcionMultiusuarioMyClaimsState {
  const ClaimReleaseSuccess();
}

final class ClaimReleaseError extends RecepcionMultiusuarioMyClaimsState {
  final String message;
  const ClaimReleaseError(this.message);

  @override
  List<Object> get props => [message];
}
