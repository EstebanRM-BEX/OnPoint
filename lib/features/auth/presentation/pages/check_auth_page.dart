import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

/// Página de verificación de autenticación
///
/// Esta página valida la sesión del usuario al iniciar la aplicación
/// y redirige a la pantalla correspondiente según el estado de la sesión.
class CheckAuthPage extends StatefulWidget {
  const CheckAuthPage({super.key});

  @override
  State<CheckAuthPage> createState() => _CheckAuthPageState();
}

class _CheckAuthPageState extends State<CheckAuthPage> {
  /// El gate solo debe navegar una vez. `UserBloc` es global y otras pantallas
  /// (p.ej. Expedición) re-disparan `LoadUserInfoEvent`, emitiendo `UserLoaded`
  /// de nuevo; sin esta bandera, este listener robaba la navegación y rebotaba
  /// al usuario a /home. Con ella, solo reacciona al primer `UserLoaded` (el
  /// del arranque) e ignora los posteriores.
  bool _yaNavego = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>()..add(ValidateSessionEvent()),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthValid) {
            // Sesión válida - registrar dispositivo para verificar autorización
            context.read<UserBloc>().add(RegisterDeviceEvent());
          } else if (state is AuthNotLoggedIn || state is AuthExpired || state is AuthError) {
            Navigator.pushReplacementNamed(context, 'enterprice');
          }
        },
        child: BlocListener<UserBloc, UserState>(
          listener: (context, state) {
            if (_yaNavego) return;
            if (state is DeviceRegistrationFailure) {
              _yaNavego = true;
              showScrollableErrorDialog(state.message);
              Navigator.pushReplacementNamed(context, 'enterprice');
            }
            if (state is UserLoaded) {
              _yaNavego = true;
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
          child: const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }
}
