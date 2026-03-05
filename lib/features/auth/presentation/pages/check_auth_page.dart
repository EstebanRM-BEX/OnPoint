import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wms_app/injection_container.dart';

/// Página de verificación de autenticación
///
/// Esta página valida la sesión del usuario al iniciar la aplicación
/// y redirige a la pantalla correspondiente según el estado de la sesión.
class CheckAuthPage extends StatelessWidget {
  const CheckAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>()..add(ValidateSessionEvent()),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthValid) {
            // Sesión válida - ir al home
            Navigator.pushReplacementNamed(context, '/home');
          } else if (state is AuthNotLoggedIn || state is AuthExpired) {
            // Sin sesión o expirada - ir al login
            Navigator.pushReplacementNamed(context, 'enterprice');
          } else if (state is AuthError) {
            // Error - ir al login por seguridad
            Navigator.pushReplacementNamed(context, 'enterprice');
          }
        },
        child: const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
