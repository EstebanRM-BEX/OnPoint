import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/utils/widgets/dialog_dispositivo_no_autorizado_widget.dart';
import 'package:wms_app/injection_container.dart';
// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/quick%20info/bloc/info_rapida_bloc.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/quick%20info/widgets/dialog_info_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/quick%20info/widgets/info_rapida_header.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/quick%20info/widgets/recent_queries_card.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/quick%20info/widgets/scan_hero_card.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/quick%20info/widgets/scanner_status_pill.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<InfoRapidaBloc>();

      if (bloc.isInitialized) return;

      // El diálogo de "Cargando interfaz..." ya NO se abre con
      // showDialog+Navigator.pop (dependía de que el listener siguiera
      // vivo cuando terminara el fetch de ~7000 productos, y a veces se
      // quedaba pegado) — ahora es el overlay declarativo que arma
      // build(), basado en el estado actual del bloc.
      bloc.add(InitInfoRapidaEvent());
    });
  }

  void validateBarcode(String value) {
    final bloc = context.read<InfoRapidaBloc>();

    String scan = value.trim();
    print('scan:::::: $scan');
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
    return Stack(
      children: [
        _buildContent(context),
        // Overlay declarativo de "Cargando interfaz..." — reemplaza al
        // showDialog()+Navigator.pop() de antes, que dependía de que este
        // widget siguiera vivo y suscripto cuando terminara el fetch
        // (~7000 productos, 1-2s) para poder cerrarlo; a veces se quedaba
        // pegado. Esto solo depende del estado actual del bloc, sin
        // Navigator de por medio.
        BlocBuilder<InfoRapidaBloc, InfoRapidaState>(
          buildWhen: (previous, current) =>
              current is InfoRapidaInitial ||
              current is InitInfoRapidaLoading ||
              current is InitInfoRapidaSuccess ||
              current is InitInfoRapidaFailure ||
              // El "Buscando información..." también es overlay: con
              // showDialog+Navigator.pop se quedaba pegado para siempre si el
              // estado final no llegaba a este listener (bloc recreado en un
              // rebuild de la ruta), y no había forma de cerrarlo a mano
              // (barrierDismissible: false + PopScope(canPop: false)).
              current is InfoRapidaLoading ||
              current is InfoRapidaLoaded ||
              current is InfoRapidaError ||
              current is DeviceNotAuthorized,
          builder: (context, state) {
            if (state is InfoRapidaLoading) {
              return const Positioned.fill(
                child: AbsorbPointer(
                  child: DialogLoading(message: 'Buscando información...'),
                ),
              );
            }
            // InfoRapidaInitial (el estado de arranque del bloc, antes de
            // que initState() alcance a disparar InitInfoRapidaEvent en el
            // siguiente frame) también cuenta como "todavía cargando" — si
            // no, hay una ventana de 1 frame donde el FAB/botones ya son
            // tocables pero productos/ubicaciones siguen vacíos, y navegar
            // ahí mismo a una pantalla que lee esos campos los ve en [].
            final stillLoading =
                state is InfoRapidaInitial || state is InitInfoRapidaLoading;
            if (!stillLoading) return const SizedBox.shrink();
            // AbsorbPointer: bloquea toques al contenido de abajo mientras
            // carga (lo que antes hacía la barrera modal de showDialog).
            return const Positioned.fill(
              child: AbsorbPointer(
                child: DialogLoading(message: 'Cargando interfaz...'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocConsumer<InfoRapidaBloc, InfoRapidaState>(
      listenWhen: (previous, current) => current is! InfoRapidaInitial,
      buildWhen: (previous, current) =>
          current is InfoRapidaInitial || current is InfoRapidaLoaded,
      listener: (context, state) async {
        debugPrint('Estado actual: $state');

        // El overlay de "Cargando interfaz..." ya no depende de este
        // listener (ver _InitLoadingOverlay en build()) — acá solo queda
        // el aviso de error si la carga inicial falla.
        if (state is InitInfoRapidaFailure) {
          Get.snackbar(
            '360 Software Informa',
            'Error al cargar la interfaz. Intenta de nuevo.',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.error, color: Colors.red),
          );
        }

        if (state is DeviceNotAuthorized) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const DialogUnauthorizedDevice(),
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
        } else if (state is InfoRapidaLoaded) {
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
            final bloc = context.read<InfoRapidaBloc>();
            if (result.type == 'product') {
              Navigator.pushReplacementNamed(
                context,
                'product-info',
                arguments: [bloc],
              );
            } else if (result.type == 'ubicacion') {
              Navigator.pushReplacementNamed(
                context,
                'location-info',
                arguments: [result, bloc],
              );
            } else if (result.type == 'paquete') {
              Navigator.pushReplacementNamed(
                context,
                'paquete-info',
                arguments: [result, bloc],
              );
            }
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: primaryColorApp,
            foregroundColor: white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => DialogInfoQuick(contextScreen: context),
              );
            },
            icon: const Icon(Icons.search),
            label: const Text(
              'Buscar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: Column(
            children: [
              InfoRapidaHeader(
                onBack: () => Navigator.pushReplacementNamed(context, '/home'),
              ),
              Expanded(
                // SingleChildScrollView (no ListView): el campo invisible del
                // escáner debe seguir montado aunque quede fuera de pantalla,
                // o perdería el foco y el lector dejaría de responder.
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ScannerStatusPill(
                        focusNode: focusNode1,
                        onActivate: focusNode1.requestFocus,
                      ),
                      const SizedBox(height: 16),
                      const ScanHeroCard(),
                      RecentQueriesCard(
                        onSelect: (q) => context.read<InfoRapidaBloc>().add(
                          GetInfoRapida(
                            q.query,
                            q.isManual,
                            q.isProduct,
                            false,
                          ),
                        ),
                      ),
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
              ),
            ],
          ),
        );
      },
    );
  }
}
