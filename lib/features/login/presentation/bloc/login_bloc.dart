import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/utils/prefs/secure_storage_utils.dart';
import 'package:wms_app/features/login/domain/entities/user.dart';
import 'package:wms_app/features/login/domain/usecases/authenticate_user.dart';

part 'login_event.dart';
part 'login_state.dart';

/// LoginBloc with Clean Architecture and Dependency Injection.
///
/// Note: UI-only state (TextEditingControllers, password visibility)
/// lives in the UI layer, not here.
@injectable
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthenticateUser authenticateUser;

  LoginBloc({
    required this.authenticateUser,
  }) : super(LoginInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
  }

  /// Handle login button pressed event
  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());

    // Authenticate user
    final authResult = await authenticateUser(
      AuthenticateParams(
        email: event.email,
        password: event.password,
        database: event.database,
      ),
    );

    await authResult.fold(
      // Authentication failed
      (failure) async {
        debugPrint('❌ Login failed: ${failure.message}');
        emit(LoginFailure(failure.message));
      },
      // Authentication successful
      (user) async {
        debugPrint('✅ Login successful: ${user.name}');
        // Guardar el password en secure storage antes del emit para no exponerlo en el estado
        await SecureStorage.setUserPass(event.password);
        emit(LoginSuccess(user));
      },
    );
  }

}
