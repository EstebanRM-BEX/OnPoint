// ignore_for_file: avoid_print

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:wms_app/features/login/domain/entities/user.dart';
import 'package:wms_app/features/login/domain/usecases/authenticate_user.dart';
import 'package:wms_app/features/login/domain/usecases/save_user_session.dart';

part 'login_event.dart';
part 'login_state.dart';

/// LoginBloc with Clean Architecture and Dependency Injection.
///
/// Note: TextEditingController should be in the UI layer, not here.
/// Password visibility state is kept for backward compatibility.
@injectable
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthenticateUser authenticateUser;
  final SaveUserSession saveUserSession;

  // Password visibility state (UI concern, but kept for compatibility)
  bool isPasswordVisible = false;

  LoginBloc({
    required this.authenticateUser,
    required this.saveUserSession,
  }) : super(LoginInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
    on<TogglePasswordVisibility>(_onTogglePasswordVisibility);
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
        // Session is saved only after device authorization is confirmed
        emit(LoginSuccess(user, event.password));
      },
    );
  }

  /// Handle password visibility toggle
  void _onTogglePasswordVisibility(
    TogglePasswordVisibility event,
    Emitter<LoginState> emit,
  ) {
    isPasswordVisible = !isPasswordVisible;
    emit(PasswordVisibilityToggled(isPasswordVisible));
  }
}
