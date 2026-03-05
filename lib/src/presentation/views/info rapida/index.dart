import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/injection_container.dart';
// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/bloc/info_rapida_bloc.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/widgets/dialog_info_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import '../../providers/network/cubit/warning_widget_cubit.dart';

class InfoRapidaScreen extends StatefulWidget {
  const InfoRapidaScreen({super.key});

  @override
  State<InfoRapidaScreen> createState() => _InfoRapidaScreenState();
}

class _InfoRapidaScreenState extends State<InfoRapidaScreen> {
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();

  final TextEditingController _controllerSearch = TextEditingController();
  final FocusNode focusNode1 = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    focusNode1.dispose();
    _controllerSearch.dispose();
    super.dispose();
  }

  void validateBarcode(String value) {
    final bloc = context.read<InfoRapidaBloc>();

    String scan = value.trim();

    if (bloc.scannedValue1.trim().isNotEmpty) {
      scan = bloc.scannedValue1.trim();
    }

    if (scan.isEmpty) {
      _controllerSearch.text = '';
      Future.microtask(() => focusNode1.requestFocus());
      return;
    }

    _controllerSearch.text = '';
    bloc.add(GetInfoRapida(scan.toUpperCase(), false, false, false));
    Future.microtask(() => focusNode1.requestFocus());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InfoRapidaBloc, InfoRapidaState>(
      listenWhen: (previous, current) => current is! InfoRapidaInitial,
      buildWhen: (previous, current) =>
          current is InfoRapidaInitial || current is InfoRapidaLoaded,
      listener: (context, state) async {
        debugPrint('Estado actual: $state');
        if (state is DeviceNotAuthorized) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // Cierra el loader si hubo error
          }
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
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // Cierra el loader si hubo error
          }
          Get.snackbar(
            '360 Software Informa',
            'Información no encontrada',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.error, color: Colors.red),
            showProgressIndicator: true,
            duration: Duration(seconds: 5),
          );
          _vibrationService.vibrate();
          _audioService.playErrorSound();
        } else if (state is InfoRapidaLoading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const DialogLoading(message: "Buscando información..."),
          );
        } else if (state is InfoRapidaLoaded) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // Cierra el loader
          }

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
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => DialogInfoQuick(
                  contextScreen: context,
                ),
              );
            },
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
                    BarcodeScannerField(
                      controller: _controllerSearch,
                      focusNode: focusNode1,
                      onBarcodeScanned: (value, context) {
                        return validateBarcode(value);
                      },
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
