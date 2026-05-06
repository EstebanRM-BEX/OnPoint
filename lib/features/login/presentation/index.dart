// ignore_for_file: use_build_context_synchronously, unused_element, unnecessary_null_comparison, avoid_print, must_be_immutable, prefer_final_fields

import 'dart:io';

import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_bloc.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_event.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/core/utils/validator_utils.dart';
import 'package:wms_app/core/utils/widgets/dialog_loading_widget.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/features/login/presentation/bloc/login_bloc.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';
import 'package:wms_app/src/presentation/views/inventario/screens/bloc/inventario_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/bloc/wms_picking_bloc.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // LoginBloc is now provided in main.dart via getIt
    // 1. Primer Listener: LoginBloc
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginLoading) {
          Get.dialog(
            DialogLoadingNetwork(
              titel: 'Login',
            ),
            barrierDismissible:
                false, // No permitir cerrar tocando fuera del diálogo
          );
        }
        if (state is LoginSuccess) {
          context.read<UserBloc>().add(RegisterDeviceEvent(
                user: state.user,
                password: state.password,
              ));
          context.read<PackagingTypeBloc>().add(SyncPackagingTypesEvent());
        }

        if (state is LoginFailure) {
          Get.back();
          showScrollableErrorDialog(state.message);
        }
      },
      // 2. Segundo Listener (Hijo del primero): UserBloc
      child: BlocListener<UserBloc, UserState>(
        listener: (context, state) async {
          if (state is DeviceRegistrationFailure) {
            Get.back();
            showScrollableErrorDialog(state.message);
          }

          if (state is UserLoaded) {
            final swTotal = Stopwatch()..start();
            final swDev = Stopwatch();
            final swNovedades = Stopwatch();
            final swInventario = Stopwatch();

            // Suscribimos ANTES de disparar los eventos para evitar race condition
            final devFuture = context
                .read<DevolucionesBloc>()
                .stream
                .firstWhere((s) =>
                    s is DownloadAllTercerosSuccess ||
                    s is DownloadAllTercerosFailure)
                .timeout(const Duration(seconds: 30))
                .then((s) {
              swDev.stop();
              debugPrint(
                  '📦 [Métricas] Terceros: ${swDev.elapsedMilliseconds}ms — ${s.runtimeType}');
              return s;
            });

            final novedadesFuture = context
                .read<WMSPickingBloc>()
                .stream
                .firstWhere((s) =>
                    s is LoadSuccessNovedadesState ||
                    s is LoadFailureNovedadesState)
                .timeout(const Duration(seconds: 30))
                .then((s) {
              swNovedades.stop();
              debugPrint(
                  '📋 [Métricas] Novedades: ${swNovedades.elapsedMilliseconds}ms — ${s.runtimeType}');
              return s;
            });

            final inventarioFuture = context
                .read<InventarioBloc>()
                .stream
                .firstWhere((s) =>
                    s is GetProductsSuccess || s is GetProductsFailureInventory)
                .timeout(const Duration(seconds: 30))
                .then((s) {
              swInventario.stop();
              debugPrint(
                  '🏪 [Métricas] Inventario: ${swInventario.elapsedMilliseconds}ms — ${s.runtimeType}');
              return s;
            });

            // Disparamos los eventos después de tener las suscripciones listas
            swDev.start();
            context.read<DevolucionesBloc>().add(DownloadAllTercerosEvent());
            swNovedades.start();
            context.read<WMSPickingBloc>().add(LoadAllNovedades(context));
            swInventario.start();
            context
                .read<InventarioBloc>()
                .add(GetProductsEvent(isDialogLoading: false));

            try {
              await Future.wait([devFuture, novedadesFuture, inventarioFuture]);
            } catch (_) {
              // Si alguna carga falla o expira el timeout, continuamos igual
            }

            swTotal.stop();
            debugPrint(
                '⏱️ [Métricas] Total paralelo: ${swTotal.elapsedMilliseconds}ms');
            debugPrint(
                '⏱️ [Métricas] Total secuencial estimado: ${swDev.elapsedMilliseconds + swNovedades.elapsedMilliseconds + swInventario.elapsedMilliseconds}ms');
            debugPrint(
                '⚡ [Métricas] Ahorro estimado: ${(swDev.elapsedMilliseconds + swNovedades.elapsedMilliseconds + swInventario.elapsedMilliseconds) - swTotal.elapsedMilliseconds}ms');

            if (!context.mounted) return;
            Get.back();
            Navigator.pushReplacementNamed(context, '/home');
          }

          if (state is UserError) {
            Get.back();
            showScrollableErrorDialog(state.message);
          }
        },
        // 3. UI Visual (Hijo del segundo): El BlocBuilder y el Scaffold
        child: BlocBuilder<LoginBloc, LoginState>(
          builder: (context, state) {
            return WillPopScope(
              onWillPop: () async {
                return false;
              },
              child: Scaffold(
                body: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          colors: [
                        primaryColorApp,
                        secondary,
                        primaryColorApp
                      ])),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const WarningWidgetCubit(),
                      const SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 15, left: 20, right: 20, bottom: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                                child: Text(
                              "Bienvenido a OnPoint",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 22),
                            )),
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
                                        color: Colors.white, fontSize: 10),
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
                                  topRight: Radius.circular(40))),
                          child: SingleChildScrollView(
                            child: BlocBuilder<LoginBloc, LoginState>(
                              builder: (context, state) {
                                return const _LoginForm();
                              },
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({super.key});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  // TextEditingControllers now in UI layer (not in BLoC)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  FocusNode _focusNodeEmail = FocusNode();
  FocusNode _focusNodePassword = FocusNode();
  GlobalKey<FormState> formkey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _focusNodeEmail.addListener(_onFocusChanged);
    _focusNodePassword.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _focusNodeEmail.removeListener(_onFocusChanged);
    _focusNodePassword.removeListener(_onFocusChanged);
    _focusNodeEmail.dispose();
    _focusNodePassword.dispose();
    super.dispose();
  }

  TextEditingController _getActiveController(BuildContext context) {
    if (_focusNodeEmail.hasFocus) return _emailController;
    if (_focusNodePassword.hasFocus) return _passwordController;
    return _emailController;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
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
                      onTap:
                          !context.read<UserBloc>().fabricante.contains("Zebra")
                              ? null
                              : () {
                                  setState(() {
                                    FocusScope.of(context)
                                        .requestFocus(_focusNodeEmail);
                                  });
                                },
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        disabledBorder: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.email,
                          size: 15,
                          color: primaryColorApp,
                        ),
                        hintText: "Correo electrónico",
                        hintStyle:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(10),
                        errorStyle:
                            const TextStyle(color: Colors.red, fontSize: 10),
                      ),
                      validator: (value) => Validator.email(value, context),
                    ),
                    TextFormField(
                      controller: _passwordController,
                      autocorrect: false,
                      obscureText: !context.read<LoginBloc>().isPasswordVisible,
                      focusNode: _focusNodePassword,
                      style: const TextStyle(fontSize: 13),
                      onTap:
                          !context.read<UserBloc>().fabricante.contains("Zebra")
                              ? null
                              : () {
                                  setState(() {
                                    FocusScope.of(context)
                                        .requestFocus(_focusNodePassword);
                                  });
                                },
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
                            context
                                .read<LoginBloc>()
                                .add(TogglePasswordVisibility());
                          },
                          icon: Icon(
                            context.read<LoginBloc>().isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 15,
                            color: primaryColorApp,
                          ),
                        ),
                        hintText: "Contraseña",
                        errorStyle:
                            const TextStyle(color: Colors.red, fontSize: 10),
                        hintStyle:
                            const TextStyle(color: Colors.grey, fontSize: 12),
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
                  onPressed: () async {
                    if (!context
                        .read<UserBloc>()
                        .fabricante
                        .contains("Zebra")) {
                      FocusScope.of(context).unfocus();
                    }

                    // ⚡️ CORRECCIÓN 1: Validación segura (evita el crash si currentState es null)
                    if (formkey.currentState?.validate() != true) return;

                    try {
                      final result =
                          await InternetAddress.lookup('example.com');
                      if (result.isNotEmpty &&
                          result[0].rawAddress.isNotEmpty) {
                        // Aquí inicia el proceso. El Dialog se mostrará en el Listener, no aquí.
                        // Get database from Preferences
                        final database = getIt<IStorageService>().nameDatabase;

                        context.read<LoginBloc>().add(
                              LoginButtonPressed(
                                email: _emailController.text,
                                password: _passwordController.text,
                                database: database,
                              ),
                            );
                      }
                    } catch (e) {
                      // ⚡️ CORRECCIÓN 2: Eliminado Navigator.pop().
                      // No debemos cerrar nada aquí porque el diálogo de carga NUNCA se mostró.
                      // (El diálogo solo se muestra si el evento LoginButtonPressed se dispara y el Bloc emite Loading)

                      Get.defaultDialog(
                        title: '360 Software Informa',
                        titleStyle: TextStyle(color: Colors.red, fontSize: 18),
                        middleText: 'No tiene conexión a internet',
                        middleTextStyle: TextStyle(color: black, fontSize: 14),
                        backgroundColor: Colors.white,
                        radius: 10,
                        actions: [
                          ElevatedButton(
                            onPressed: () => Get.back(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColorApp,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child:
                                Text('Aceptar', style: TextStyle(color: white)),
                          ),
                        ],
                      );
                    }
                  },
                  child: Container(
                    width: size.width * 0.9,
                    alignment: Alignment.center,
                    child: state is LoginLoading
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
      },
    );
  }
}
