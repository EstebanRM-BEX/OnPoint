import 'package:wms_app/core/utils/prefs/secure_storage_utils.dart';
import 'package:wms_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_bloc.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_event.dart';
import 'package:wms_app/shared/widgets/loading_dialog_mixin.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/features/login/presentation/bloc/login_bloc.dart';
import 'package:wms_app/features/login/presentation/coordinator/post_login_coordinator.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';
import 'package:wms_app/features/inventario/presentation/bloc/inventario_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/bloc/wms_picking_bloc.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/login/presentation/widgets/login_footer.dart';
import 'package:wms_app/features/login/presentation/widgets/login_form_card.dart';
import 'package:wms_app/shared/widgets/auth/auth_brand_gradient.dart';
import 'package:wms_app/shared/widgets/auth/onpoint_brand_header.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with LoadingDialogMixin {
  @override
  Widget build(BuildContext context) {
    // LoginBloc is now provided in main.dart via getIt
    // 1. Primer Listener: LoginBloc
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) async {
        if (state is LoginLoading) {
          showLoadingDialog('Iniciando sesión...');
        }
        if (state is LoginSuccess) {
          // El password fue guardado en SecureStorage por el BLoC antes del emit
          final password = await SecureStorage.getUserPass();
          if (!context.mounted) return;
          context.read<UserBloc>().add(
            RegisterDeviceEvent(user: state.user, password: password),
          );
          context.read<PackagingTypeBloc>().add(SyncPackagingTypesEvent());
        }

        if (state is LoginFailure) {
          hideLoadingDialog();
          showScrollableErrorDialog(state.message);
        }
      },
      // 2. Segundo Listener (Hijo del primero): UserBloc
      child: BlocListener<UserBloc, UserState>(
        listener: (context, state) async {
          if (state is DeviceRegistrationFailure) {
            hideLoadingDialog();
            showScrollableErrorDialog(state.message);
          }

          if (state is UserLoaded) {
            if (!context.mounted) return;

            final result = await PostLoginCoordinator(
              homeBloc: context.read<HomeBloc>(),
              devolucionesBloc: context.read<DevolucionesBloc>(),
              pickingBloc: context.read<WMSPickingBloc>(),
              inventarioBloc: context.read<InventarioBloc>(),
              userBloc: context.read<UserBloc>(),
            ).run();

            if (!context.mounted) return;

            hideLoadingDialog();

            if (result.destination == PostLoginDestination.updateRequired) {
              Navigator.pushReplacementNamed(
                context,
                'update-required',
                arguments: result.appVersion,
              );
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          }

          if (state is UserError) {
            hideLoadingDialog();
            showScrollableErrorDialog(state.message);
          }
        },
        // 3. UI Visual (Hijo del segundo): El Scaffold
        child: const PopScope(canPop: false, child: _LoginView()),
      ),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  static const double _bandHeight = 280;

  // URL elegida en la pantalla de servidor (la guarda el repositorio de
  // enterprise con PrefUtils.setEnterprise). Se lee una sola vez: la vista se
  // reconstruye con cada apertura/cierre del teclado.
  late final Future<String> _serverUrl = PrefUtils.getEnterprise();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Banda de marca detrás de la cabecera; la tarjeta la solapa.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _bandHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: authBrandGradient),
            ),
          ),
          // Todo en un único scroll: con el teclado abierto el contenido se
          // desplaza y el campo activo queda visible sin re-layouts bruscos.
          SafeArea(
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              slivers: [
                const SliverToBoxAdapter(child: WarningWidgetCubit()),
                const SliverToBoxAdapter(child: OnPointBrandHeader()),
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(child: LoginFormCard()),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: FutureBuilder<String>(
                        future: _serverUrl,
                        builder: (_, snapshot) =>
                            LoginFooter(serverUrl: snapshot.data ?? ''),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
