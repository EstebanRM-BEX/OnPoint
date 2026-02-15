// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/core/utils/sounds_utils.dart';
import 'package:wms_app/src/core/utils/vibrate_utils.dart';
import 'package:wms_app/src/presentation/providers/network/check_internet_connection.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/bloc/info_rapida_bloc.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/widgets/dialog_info_widget.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import '../../providers/network/cubit/warning_widget_cubit.dart';

class InfoRapidaScreen extends StatefulWidget {
  const InfoRapidaScreen({super.key});

  @override
  State<InfoRapidaScreen> createState() => _InfoRapidaScreenState();
}

class _InfoRapidaScreenState extends State<InfoRapidaScreen> {
  final AudioService _audioService = AudioService();
  final VibrationService _vibrationService = VibrationService();

  final TextEditingController _controllerSearch = TextEditingController();
  final FocusNode focusNode1 = FocusNode();

  @override
  void dispose() {
    focusNode1.dispose();
    _controllerSearch.dispose();
    super.dispose();
  }

  void validateBarcode(String value) {
    final bloc = context.read<InfoRapidaBloc>();

    // ✅ CORRECCIÓN 1: Manejo seguro del texto escaneado
    // Aseguramos que no se procesen espacios en blanco vacíos
    String scan = value.trim();

    // Si el valor viene vacío, intentamos usar el del BLoC, pero también lo limpiamos
    if (bloc.scannedValue1.trim().isNotEmpty) {
      scan = bloc.scannedValue1.trim();
    }

    // ✅ CORRECCIÓN CRÍTICA: Si después de limpiar, el texto está vacío, NO hacemos nada.
    // Esto evita buscar "" en la base de datos, lo cual causa el error 'No element'.
    if (scan.isEmpty) return;

    _controllerSearch.text = '';
    print('Valor escaneado para validar: "$scan"');
    bloc.add(GetInfoRapida(scan.toUpperCase(), false, false, false));

  }
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InfoRapidaBloc, InfoRapidaState>(
      listenWhen: (previous, current) => current is! InfoRapidaInitial,
      buildWhen: (previous, current) =>
          current is InfoRapidaInitial || current is InfoRapidaLoaded,
      listener: (context, state) async {
        print('Estado actual: $state');
        if (state is DeviceNotAuthorized) {
          Navigator.pop(context);
          Get.defaultDialog(
            title: 'Dispositivo no autorizado',
            titleStyle: TextStyle(
                color: primaryColorApp,
                fontWeight: FontWeight.bold,
                fontSize: 16),
            middleText:
                'Este dispositivo no está autorizado para usar la aplicación. su suscripción ha expirado o no está activa, por favor contacte con el administrador.',
            middleTextStyle: TextStyle(color: black, fontSize: 14),
            backgroundColor: Colors.white,
            radius: 10,
            barrierDismissible: false,
            onWillPop: () async => false,
          );
        } else if (state is NeedUpdateVersionState) {
          Get.snackbar(
            '360 Software Informa',
            'Hay una nueva versión disponible. Actualiza desde la configuración de la app, pulsando el nombre de usuario en el Home',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: Icon(Icons.error, color: Colors.amber),
            showProgressIndicator: true,
            duration: Duration(seconds: 5),
          );
        } else if (state is InfoRapidaError) {
          _vibrationService.vibrate();
          _audioService.playErrorSound();
          Navigator.pop(context); // Cierra el loader si hubo error
          Get.snackbar(
            '360 Software Informa',
            state.error ??
                'No se encontró producto, lote, paquete ni ubicación con ese código de barras',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.error, color: Colors.red),
          );
        } else if (state is InfoRapidaLoading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const DialogLoading(message: "Buscando información..."),
          );
        } else if (state is InfoRapidaLoaded) {
          Navigator.pop(context); // Cierra el loader

          // ✅ CORRECCIÓN 2: Validación de Nulidad
          // Si el resultado es nulo, detenemos la ejecución para evitar el crash.
          if (state.infoRapidaResult == null) {
            return;
          }

          Future.microtask(() {
            // Verificamos si el widget sigue montado antes de mostrar UI
            if (!mounted) return;

            Get.snackbar(
              '360 Software Informa',
              'Información encontrada',
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: const Icon(Icons.check_circle, color: Colors.green),
            );

            // Guardamos el resultado en una variable local segura
            final result = state.infoRapidaResult;

            // Navegación segura (asumiendo que result no es nulo gracias al chequeo anterior)
            if (result!.type == 'product') {
              Navigator.pushReplacementNamed(context, 'product-info');
            } else if (result.type == 'ubicacion') {
              Navigator.pushReplacementNamed(
                context,
                'location-info',
                arguments: [result],
              );
            } else if (result.type == 'paquete') {
              Navigator.pushReplacementNamed(
                context,
                'paquete-info',
                arguments: [result],
              );
            }
          });
        }
      },
      builder: (context, state) {
        final size = MediaQuery.sizeOf(context);
        return Scaffold(
          backgroundColor: white,
          floatingActionButton: FloatingActionButton(
            backgroundColor: primaryColorApp,
            onPressed: () => showDialog(
              context: context,
              builder: (_) => DialogInfoQuick(
                contextScreen: context,
              ),
            ),
            child: const Icon(Icons.search, color: white),
          ),
          body: Column(
            children: [
              const CustomAppBar(),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.13),
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: SvgPicture.asset(
                        color: black,
                        "assets/icons/barcode.svg",
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Este es el módulo de información rápida de 360 software para OnPoint. Escanee un código de barras de PRODUCTO, PAQUETE, LOTE/SERIE o una UBICACIÓN para obtener toda su información.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: black),
                      ),
                    ),
                    const SizedBox(height: 20),
                    context
                            .select((UserBloc b) => b.fabricante)
                            .contains("Zebra")
                        ? TextFormField(
                            controller: _controllerSearch,
                            focusNode: focusNode1,
                            autofocus: true,
                            showCursor: false,
                            onChanged: validateBarcode,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintStyle: TextStyle(fontSize: 14, color: black),
                            ),
                          )
                        : Focus(
                            focusNode: focusNode1,
                            autofocus: true,
                            onKey: (node, event) {
                              if (event is RawKeyDownEvent) {
                                if (event.logicalKey ==
                                    LogicalKeyboardKey.enter) {
                                  // ✅ CORRECCIÓN 3: Evitar disparar validación si el escáner está vacío
                                  // Esto previene que al presionar Enter accidentalmente crashee la app.
                                  if (context
                                      .read<InfoRapidaBloc>()
                                      .scannedValue1
                                      .trim()
                                      .isNotEmpty) {
                                    validateBarcode(context
                                        .read<InfoRapidaBloc>()
                                        .scannedValue1);
                                  }

                                  return KeyEventResult.handled;
                                } else {
                                  context.read<InfoRapidaBloc>().add(
                                      UpdateScannedValueEvent(
                                          event.data.keyLabel, 'info'));
                                  return KeyEventResult.handled;
                                }
                              }
                              return KeyEventResult.ignored;
                            },
                            child: const SizedBox(),
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
      builder: (context, status) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: primaryColorApp,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              const WarningWidgetCubit(),
              Padding(
                padding: EdgeInsets.only(
                  top: status != ConnectionStatus.online ? 0 : 25,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: white),
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/home'),
                    ),
                    const Spacer(),
                    const Text(
                      "INFORMACIÓN RÁPIDA",
                      style: TextStyle(color: white, fontSize: 18),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
