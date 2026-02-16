import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/auth/domain/usecases/validate_session.dart';
import 'package:wms_app/core/services/websocket_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC para gestionar la autenticación y validación de sesión
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ValidateSession validateSession;

  AuthBloc({required this.validateSession}) : super(AuthInitial()) {
    on<ValidateSessionEvent>(_onValidateSession);
  }

  Future<void> _onValidateSession(
    ValidateSessionEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthValidating());

    final result = await validateSession(NoParams());

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (validationResult) {
        if (validationResult.isValid) {
          // Reconectar WebSocket cuando la sesión es válida
          WebSocketService().connect();
          emit(AuthValid());
        } else if (validationResult.isExpired) {
          emit(AuthExpired());
        } else {
          emit(AuthNotLoggedIn());
        }
      },
    );
  }
}
