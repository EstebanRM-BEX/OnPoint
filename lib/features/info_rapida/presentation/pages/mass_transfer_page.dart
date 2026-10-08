import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/domain/entities/transfer_results.dart';
import 'package:wms_app/features/info_rapida/domain/failures/info_rapida_failures.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/mass_transfer/mass_transfer_bloc.dart';
import 'package:wms_app/features/info_rapida/presentation/pages/location_dest_page.dart';
import 'package:wms_app/features/info_rapida/presentation/utils/info_rapida_format.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/cards/mass_transfer_item_card.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/cards/transfer_step_card.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/empty_list_message.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_header.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_snackbar.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/shared/widgets/confirm_delete_dialog.dart';
import 'package:wms_app/shared/widgets/loading_dialog_mixin.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

/// Transferencia masiva desde una ubicación: destino (escaneo o lista) y
/// productos seleccionados, a los que se pueden sumar otros escaneando.
///
/// Devuelve el [TransferenciaMasivaResult] con `Navigator.pop` al crearla.
/// El detalle de ubicación abre entonces la ubicación destino (igual que el
/// legacy).
class MassTransferPage extends StatelessWidget {
  final UbicacionInfo ubicacionOrigen;
  final List<ProductoUbicacion> productos;

  const MassTransferPage({
    super.key,
    required this.ubicacionOrigen,
    required this.productos,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MassTransferBloc>()
        ..add(
          MassTransferInicializado(
            // El almacén que se envía es el del destino (lo resuelve el bloc).
            idAlmacen: 0,
            idUbicacionOrigen: ubicacionOrigen.id,
            nombreUbicacionOrigen: ubicacionOrigen.nombre,
            productosSeleccionados: productos,
          ),
        ),
      child: _MassTransferView(ubicacionOrigen: ubicacionOrigen),
    );
  }
}

class _MassTransferView extends StatefulWidget {
  final UbicacionInfo ubicacionOrigen;

  const _MassTransferView({required this.ubicacionOrigen});

  @override
  State<_MassTransferView> createState() => _MassTransferViewState();
}

class _MassTransferViewState extends State<_MassTransferView>
    with LoadingDialogMixin {
  final _destController = TextEditingController();
  final _destFocusNode = FocusNode();
  final _productController = TextEditingController();
  final _productFocusNode = FocusNode();

  @override
  void dispose() {
    _destController.dispose();
    _destFocusNode.dispose();
    _productController.dispose();
    _productFocusNode.dispose();
    super.dispose();
  }

  void _alertar() {
    getIt<IAudioService>().playErrorSound();
    getIt<IVibrationService>().vibrate();
  }

  /// Igual que el legacy: primero se escanea el destino y después productos.
  void _enfocarSiguiente(MassTransferState state) {
    Future.microtask(() {
      if (!mounted) return;
      (state.ubicacionDestinoValida ? _productFocusNode : _destFocusNode)
          .requestFocus();
    });
  }

  void _onScanDestino(String value) {
    _destController.clear();
    context.read<MassTransferBloc>().add(
      EscanearUbicacionDestinoMassEvent(value),
    );
  }

  void _onScanProducto(String value) {
    _productController.clear();
    final scan = value.trim().toLowerCase();
    final encontrado = widget.ubicacionOrigen.productos
        .cast<ProductoUbicacion?>()
        .firstWhere(
          (p) => p!.codigoBarras.toLowerCase() == scan,
          orElse: () => null,
        );
    if (encontrado == null) {
      _alertar();
      InfoRapidaSnackbar.error('Producto no encontrado en la ubicación');
      _enfocarSiguiente(context.read<MassTransferBloc>().state);
      return;
    }
    context.read<MassTransferBloc>().add(AgregarItemMassEvent(encontrado));
  }

  Future<void> _elegirDestino() async {
    final destino = await Navigator.of(context).push<UbicacionCatalogo>(
      MaterialPageRoute(
        builder: (_) =>
            LocationDestPage(idUbicacionOrigen: widget.ubicacionOrigen.id),
      ),
    );
    if (!mounted) return;
    if (destino != null) {
      context.read<MassTransferBloc>().add(
        SeleccionarUbicacionDestinoMassEvent(destino),
      );
    }
    _enfocarSiguiente(context.read<MassTransferBloc>().state);
  }

  Future<void> _quitar(ProductoUbicacion p) async {
    final bloc = context.read<MassTransferBloc>();
    final confirmado = await showConfirmDeleteDialog(
      context,
      title: 'Eliminar producto',
      message: '¿Está seguro de que desea eliminar este producto?',
    );
    if (confirmado) {
      bloc.add(RemoverItemMassEvent(productoId: p.id, loteId: p.loteId));
    }
  }

  void _crear(MassTransferState state) {
    if (state.items.isEmpty) {
      InfoRapidaSnackbar.error('No hay productos para crear la transferencia');
      return;
    }
    if (state.ubicacionDestino == null) {
      InfoRapidaSnackbar.error('Debe seleccionar una ubicación de destino');
      return;
    }
    context.read<MassTransferBloc>().add(
      const ConfirmarTransferenciaMasivaEvent(),
    );
  }

  void _onState(BuildContext context, MassTransferState state) {
    if (state.isLoading) {
      showLoadingDialog('Creando transferencia...');
      return;
    }
    hideLoadingDialog();

    if (state.isSuccess) {
      InfoRapidaSnackbar.success('Transferencia creada con éxito');
      final r = state.resultadoTransferencia;
      Navigator.pop(
        context,
        TransferenciaMasivaResult(
          transferenciaId: r?.transferenciaId,
          nombreTransferencia: r?.nombreTransferencia,
          totalItems: r?.totalItems,
          ubicacionOrigenId: r?.ubicacionOrigenId,
          ubicacionDestinoId:
              r?.ubicacionDestinoId ?? state.ubicacionDestino?.id,
          itemsProcesados: r?.itemsProcesados ?? const [],
        ),
      );
      return;
    }

    final mensaje = state.mensajeError;
    if (mensaje != null) {
      _alertar();
      if (state.status == MassTransferStatus.failure) {
        // Error del backend al crear: se muestra completo, como el legacy.
        showScrollableErrorDialog(mensaje);
      } else if (state.failure is PropietarioMismatchFailure) {
        InfoRapidaSnackbar.blocked(mensaje);
      } else {
        InfoRapidaSnackbar.error(mensaje);
      }
      context.read<MassTransferBloc>().add(
        const LimpiarMensajeMassTransferEvent(),
      );
    }
    _enfocarSiguiente(state);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MassTransferBloc, MassTransferState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.mensajeError != current.mensajeError ||
          previous.ubicacionDestinoValida != current.ubicacionDestinoValida,
      listener: _onState,
      builder: (context, state) {
        final destino = state.ubicacionDestino;
        return Scaffold(
          backgroundColor: white,
          body: Column(
            children: [
              InfoRapidaHeader(
                title: 'TRANSFERENCIA MASIVA',
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 6),
              TransferStepCard(
                title: 'Ubicación Origen',
                icon: const TransferStepPngIcon('assets/icons/ubicacion.png'),
                cardColor: white,
                children: [
                  Text(
                    orDefault(
                      widget.ubicacionOrigen.nombreCompleto,
                      widget.ubicacionOrigen.nombre,
                    ),
                    style: const TextStyle(color: black, fontSize: 14),
                  ),
                ],
              ),
              TransferStepCard(
                title: 'Ubicación Destino',
                icon: const TransferStepSvgIcon('assets/icons/packing.svg'),
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
                    onBarcodeScanned: (value, _) => _onScanDestino(value),
                  ),
                  Text(
                    destino == null
                        ? 'Esperando escaneo'
                        : orDefault(destino.name, 'Sin nombre'),
                    style: const TextStyle(fontSize: 14, color: black),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Productos a transferir (${state.totalItems})',
                  style: const TextStyle(fontSize: 15, color: primaryColorApp),
                ),
              ),
              BarcodeScannerField(
                controller: _productController,
                focusNode: _productFocusNode,
                autofocus: false,
                clearOnScan: true,
                onBarcodeScanned: (value, _) => _onScanProducto(value),
              ),
              Expanded(
                child: state.items.isEmpty
                    ? const EmptyListMessage(
                        title: 'No hay productos agregados',
                        subtitle:
                            'Intente agregar productos a la transferencia',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemCount: state.items.length,
                        itemBuilder: (_, index) {
                          final producto = state.items[index].producto;
                          return MassTransferItemCard(
                            producto: producto,
                            onDelete: () => _quitar(producto),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColorApp,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: state.isLoading ? null : () => _crear(state),
                    child: const Text(
                      'Crear transferencia',
                      style: TextStyle(color: white),
                    ),
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
