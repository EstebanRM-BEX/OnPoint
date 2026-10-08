import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/transfer/transfer_info_bloc.dart';
import 'package:wms_app/features/info_rapida/presentation/pages/location_dest_page.dart';
import 'package:wms_app/features/info_rapida/presentation/utils/info_rapida_format.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/cards/transfer_step_card.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/cantidad_transfer_bar.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_header.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_snackbar.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/utils/keyboard_watchdog.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/shared/widgets/loading_dialog_mixin.dart';

/// Transferencia individual de un producto desde una de sus ubicaciones.
///
/// Devuelve el `TransferenciaIndividualResult` con `Navigator.pop` cuando se
/// crea; el detalle de producto lo usa para refrescar existencias.
class TransferInfoPage extends StatelessWidget {
  final ProductoInfo producto;
  final UbicacionProducto ubicacion;

  const TransferInfoPage({
    super.key,
    required this.producto,
    required this.ubicacion,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransferInfoBloc>()
        ..add(
          TransferInfoInicializado(
            idAlmacen: ubicacion.idAlmacen ?? 0,
            idMove: ubicacion.idMove ?? 0,
            idProducto: producto.id,
            nombreProducto: producto.nombre,
            idLote: ubicacion.loteId ?? 0,
            nombreLote: ubicacion.lote ?? '',
            idUbicacionOrigen: ubicacion.idUbicacion,
            nombreUbicacionOrigen: ubicacion.ubicacion,
            // Igual que el legacy: el tope es la cantidad a la mano.
            cantidadDisponible: ubicacion.cantidadMano,
            idPropietario: ubicacion.idPropietario,
            propietario: ubicacion.propietario,
            manejoPropietario: ubicacion.manejoPropietario,
          ),
        ),
      child: _TransferInfoView(producto: producto, ubicacion: ubicacion),
    );
  }
}

class _TransferInfoView extends StatefulWidget {
  final ProductoInfo producto;
  final UbicacionProducto ubicacion;

  const _TransferInfoView({required this.producto, required this.ubicacion});

  @override
  State<_TransferInfoView> createState() => _TransferInfoViewState();
}

class _TransferInfoViewState extends State<_TransferInfoView>
    with WidgetsBindingObserver, LoadingDialogMixin {
  final _destController = TextEditingController();
  final _destFocusNode = FocusNode();
  final _cantidadController = TextEditingController();
  final _cantidadFocusNode = FocusNode();
  late final KeyboardWatchdog _kbWatchdog = KeyboardWatchdog(
    state: this,
    focusNode: _cantidadFocusNode,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() => _kbWatchdog.onMetricsChanged();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _kbWatchdog.dispose();
    _destController.dispose();
    _destFocusNode.dispose();
    _cantidadController.dispose();
    _cantidadFocusNode.dispose();
    super.dispose();
  }

  void _error(String mensaje) {
    getIt<IAudioService>().playErrorSound();
    getIt<IVibrationService>().vibrate();
    InfoRapidaSnackbar.error(mensaje);
  }

  void _reenfocarEscaner() {
    _destController.clear();
    Future.microtask(() {
      if (mounted) _destFocusNode.requestFocus();
    });
  }

  void _onScanDestino(String value) {
    final state = context.read<TransferInfoBloc>().state;
    // Igual que el legacy: con un destino válido ya elegido se ignoran
    // nuevos escaneos.
    if (state.ubicacionDestinoValida) {
      _reenfocarEscaner();
      return;
    }
    if (state.ubicacionesDestino.isEmpty) {
      _error('Las ubicaciones aún no han cargado. Intente nuevamente.');
      _reenfocarEscaner();
      return;
    }
    context.read<TransferInfoBloc>().add(EscanearUbicacionDestinoEvent(value));
    _reenfocarEscaner();
  }

  Future<void> _elegirDestino() async {
    final destino = await Navigator.of(context).push<UbicacionCatalogo>(
      MaterialPageRoute(
        builder: (_) =>
            LocationDestPage(idUbicacionOrigen: widget.ubicacion.idUbicacion),
      ),
    );
    if (!mounted) return;
    if (destino != null) {
      context.read<TransferInfoBloc>().add(
        SeleccionarUbicacionDestinoEvent(destino),
      );
    }
    _reenfocarEscaner();
  }

  void _aplicarCantidad() {
    final state = context.read<TransferInfoBloc>().state;
    final input = _cantidadController.text.trim().replaceAll(',', '.');

    if (input.isEmpty || !RegExp(r'^\d+(\.\d+)?$').hasMatch(input)) {
      _error('Cantidad inválida');
      return;
    }
    final cantidad = double.parse(input);
    if (cantidad > state.cantidadDisponible) {
      _error('Cantidad superior a la cantidad en ubicacion');
      return;
    }
    if (!state.ubicacionDestinoValida || state.ubicacionDestino == null) {
      _error('Ubicacion de destino no valida');
      return;
    }
    if (cantidad == 0) {
      _error('Cantidad no valida');
      return;
    }

    FocusScope.of(context).unfocus();
    context.read<TransferInfoBloc>()
      ..add(CambiarCantidadTransferEvent(cantidad))
      ..add(const ConfirmarTransferenciaIndividualEvent());
  }

  void _onState(BuildContext context, TransferInfoState state) {
    if (state.isLoading) {
      showLoadingDialog('Enviando transferencia...');
      return;
    }
    hideLoadingDialog();

    if (state.isSuccess) {
      InfoRapidaSnackbar.success('Transferencia realizada');
      Navigator.pop(context, state.resultadoTransferencia);
      return;
    }

    final mensaje = state.mensajeError;
    if (mensaje != null) {
      _error(
        mensaje.isEmpty
            ? 'No se pudo realizar la transferencia. Intente nuevamente.'
            : mensaje,
      );
      context.read<TransferInfoBloc>().add(const LimpiarMensajeTransferEvent());
      _reenfocarEscaner();
    }
  }

  @override
  Widget build(BuildContext context) {
    final producto = widget.producto;
    final ubicacion = widget.ubicacion;
    final propietario = ubicacion.propietario ?? '';
    final lote = ubicacion.lote ?? '';

    return BlocConsumer<TransferInfoBloc, TransferInfoState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.mensajeError != current.mensajeError,
      listener: _onState,
      builder: (context, state) {
        final destino = state.ubicacionDestino;
        return Scaffold(
          backgroundColor: white,
          body: Column(
            children: [
              InfoRapidaHeader(
                title: 'TRANSFERENCIA',
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: [
                      TransferStepCard(
                        title: 'Ubicación de origen',
                        icon: const TransferStepPngIcon(
                          'assets/icons/ubicacion.png',
                        ),
                        children: [
                          Text(
                            orDefault(ubicacion.ubicacion, 'Sin nombre'),
                            style: const TextStyle(fontSize: 14, color: black),
                          ),
                        ],
                      ),
                      TransferStepCard(
                        title: 'Producto',
                        icon: const TransferStepPngIcon(
                          'assets/icons/producto.png',
                        ),
                        children: [
                          Text(
                            orDefault(producto.nombre, 'Sin nombre'),
                            style: const TextStyle(fontSize: 14, color: black),
                          ),
                          Row(
                            children: [
                              const TransferStepSvgIcon(
                                'assets/icons/barcode.svg',
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  orDefault(
                                    producto.codigoBarras,
                                    'Sin codigo de barras',
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: producto.codigoBarras.isEmpty
                                        ? red
                                        : black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text(
                                'Propietario:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: primaryColorApp,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  orDefault(propietario, 'Sin propietario'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: propietario.isEmpty ? red : black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (lote.isNotEmpty)
                            Row(
                              children: [
                                const Text(
                                  'Lote/serie:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: primaryColorApp,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    lote,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      TransferStepCard(
                        title: 'Ubicación de destino',
                        icon: const TransferStepSvgIcon(
                          'assets/icons/packing.svg',
                        ),
                        dotColor: state.ubicacionDestinoValida ? green : yellow,
                        cardColor: state.ubicacionDestinoValida
                            ? Colors.green[100]
                            : Colors.grey[300],
                        onTitleTap: _elegirDestino,
                        children: [
                          BarcodeScannerField(
                            controller: _destController,
                            focusNode: _destFocusNode,
                            clearOnScan: true,
                            onBarcodeScanned: (value, _) =>
                                _onScanDestino(value),
                          ),
                          Text(
                            destino == null
                                ? 'Esperando escaneo'
                                : orDefault(destino.name, 'Sin nombre'),
                            style: const TextStyle(fontSize: 14, color: black),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              CantidadTransferBar(
                disponible: formatCantidad(ubicacion.cantidadMano),
                controller: _cantidadController,
                focusNode: _cantidadFocusNode,
                onApply: _aplicarCantidad,
              ),
            ],
          ),
        );
      },
    );
  }
}
