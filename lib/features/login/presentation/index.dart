import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/prefs/secure_storage_utils.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_bloc.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_event.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/core/utils/validator_utils.dart';
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
        child: PopScope(
          canPop: false,
          child: Scaffold(
            body: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  colors: [primaryColorApp, secondary, primaryColorApp],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const WarningWidgetCubit(),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 15,
                      left: 20,
                      right: 20,
                      bottom: 5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            "Bienvenido a OnPoint",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        Center(
                          child: BlocBuilder<UserBloc, UserState>(
                            builder: (context, state) {
                              String version = '';
                              if (state is DeviceInfoLoaded) {
                                version = state.deviceInfo.appVersion;
                              }
                              return Text(
                                "Version: $version",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(top: 15),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: const SingleChildScrollView(child: _LoginForm()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  // TextEditingControllers now in UI layer (not in BLoC)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _focusNodeEmail = FocusNode();
  final FocusNode _focusNodePassword = FocusNode();
  final GlobalKey<FormState> formkey = GlobalKey<FormState>();

  // Estado puramente visual: no necesita pasar por el BLoC
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _focusNodeEmail.dispose();
    _focusNodePassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Form(
      key: formkey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.only(left: 30, right: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: primaryColorApp.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                TextFormField(
                  focusNode: _focusNodeEmail,
                  controller: _emailController,
                  onTap: !context.read<UserBloc>().fabricante.contains("Zebra")
                      ? null
                      : () => FocusScope.of(
                          context,
                        ).requestFocus(_focusNodeEmail),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    disabledBorder: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.email,
                      size: 15,
                      color: primaryColorApp,
                    ),
                    hintText: "Correo electrónico",
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(10),
                    errorStyle: const TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                    ),
                  ),
                  validator: (value) => Validator.email(value, context),
                ),
                TextFormField(
                  controller: _passwordController,
                  autocorrect: false,
                  obscureText: !_isPasswordVisible,
                  focusNode: _focusNodePassword,
                  style: const TextStyle(fontSize: 13),
                  onTap: !context.read<UserBloc>().fabricante.contains("Zebra")
                      ? null
                      : () => FocusScope.of(
                          context,
                        ).requestFocus(_focusNodePassword),
                  decoration: InputDecoration(
                    disabledBorder: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.all(10),
                    prefixIcon: Icon(
                      Icons.lock,
                      size: 15,
                      color: primaryColorApp,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 15,
                        color: primaryColorApp,
                      ),
                    ),
                    hintText: "Contraseña",
                    errorStyle: const TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                    ),
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                  ),
                  validator: (value) => Validator.password(value, context),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30, right: 30, top: 10),
            child: MaterialButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              disabledColor: Colors.grey,
              elevation: 0,
              color: primaryColorApp,
              onPressed: () {
                if (!context.read<UserBloc>().fabricante.contains("Zebra")) {
                  FocusScope.of(context).unfocus();
                }

                // Validación segura (evita el crash si currentState es null)
                if (formkey.currentState?.validate() != true) return;

                // La conectividad la valida el repositorio (NetworkInfo);
                // si no hay red llega un LoginFailure al listener.
                final database = getIt<IStorageService>().nameDatabase;

                context.read<LoginBloc>().add(
                  LoginButtonPressed(
                    email: _emailController.text,
                    password: _passwordController.text,
                    database: database,
                  ),
                );
              },
              child: Container(
                width: size.width * 0.9,
                alignment: Alignment.center,
                child: BlocBuilder<LoginBloc, LoginState>(
                  builder: (context, state) => state is LoginLoading
                      ? const Center(
                          child: Text(
                            "Cargando...",
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : const Text(
                          "Iniciar Sesión",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30, right: 30),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                minimumSize: Size(size.width * 0.9, 20),
              ),
              onPressed: () {
                _passwordController.clear();
                Navigator.pushReplacementNamed(context, 'enterprice');
              },
              child: Container(
                width: 220,
                height: 30,
                alignment: Alignment.center,
                child: const Text(
                  "Atras",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
