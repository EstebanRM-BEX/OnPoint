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

  /// Sale del gate hacia 'enterprice' quitando todo el stack.
  ///
  /// Antes se hacía `showScrollableErrorDialog` + `pushReplacementNamed`: el
  /// replace sustituía al DIÁLOGO (la ruta de arriba), no a esta página, así
  /// que `CheckAuthPage` quedaba viva debajo con sus listeners, y el diálogo
  /// se cruzaba con la transición de la página (parpadeo blanco ↔ diálogo).
  /// Ahora se navega primero y el error se muestra ya sobre 'enterprice'.
  void _irAEnterprise([String? error]) {
    if (_yaNavego) return;
    _yaNavego = true;
    Navigator.pushNamedAndRemoveUntil(context, 'enterprice', (_) => false);
    if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => showScrollableErrorDialog(error),
      );
    }
  }

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
            _irAEnterprise();
          }
        },
        child: BlocListener<UserBloc, UserState>(
          listener: (context, state) {
            if (_yaNavego) return;
            // El registro no respondió (red lenta, timeout, servidor caído):
            // la sesión guardada sigue siendo válida. Antes esto mandaba a
            // 'enterprice' y, tras un cierre de la app, el operario "perdía la
            // sesión" solo porque Odoo tardó en contestar al relanzar.
            if (state is DeviceRegistrationFailure && state.isTransient) {
              context.read<UserBloc>().add(LoadUserInfoEvent());
              return;
            }
            if (state is UserError) {
              _irAEnterprise(state.message);
              return;
            }
            if (state is DeviceRegistrationFailure) {
              _irAEnterprise(state.message);
              return;
            }
            if (state is UserLoaded) {
              _yaNavego = true;
              // Remove-all, no replace: si hay un diálogo arriba, el replace
              // lo sustituye a él y este gate queda vivo debajo de Home.
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (_) => false,
              );
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
