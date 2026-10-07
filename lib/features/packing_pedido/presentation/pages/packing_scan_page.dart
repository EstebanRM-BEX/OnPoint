import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/scan/packing_scan_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/info_linea_pack.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/packing_operacion_listener.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/dialogs/decision_parcial_dialog.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/dialogs/temperatura_pack_dialog.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/scan/cantidad_scan_card.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/scan/paso_scan_card.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/scan/scan_pack_header.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';

/// Escaneo de una línea: ubicación → producto → cantidad. Al terminar vuelve
/// al detalle (o pide la temperatura antes, si el producto la maneja).
class PackingScanPage extends StatelessWidget {
  final ProductoPacking producto;

  /// Viene de escanear el producto en "Por hacer": arranca en la cantidad.
  final bool productoEscaneado;

  const PackingScanPage({
    super.key,
    required this.producto,
    this.productoEscaneado = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PackingScanBloc>()
        ..add(ScanPackIniciado(producto, productoEscaneado: productoEscaneado)),
      child: const _ScanView(),
    );
  }
}

class _ScanView extends StatefulWidget {
  const _ScanView();

  @override
  State<_ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<_ScanView> {
  final _scanController = TextEditingController();
  final _scanFocus = FocusNode();
  final _cantidadController = TextEditingController();
  final _cantidadFocus = FocusNode();

  PackingScanBloc get _bloc => context.read<PackingScanBloc>();

  @override
  void dispose() {
    _scanController.dispose();
    _scanFocus.dispose();
    _cantidadController.dispose();
    _cantidadFocus.dispose();
    super.dispose();
  }

  void _enfocarLector() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && !_bloc.state.editandoCantidad) _scanFocus.requestFocus();
  });

  void _aplicar() {
    final s = _bloc.state;
    if (s.editandoCantidad) {
      final v = double.tryParse(
        _cantidadController.text.trim().replaceAll(',', '.'),
      );
      if (v == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cantidad inválida')));
        return;
      }
      _bloc.add(CantidadPackAplicada(v));
    } else {
      _bloc.add(const CantidadPackAplicada());
    }
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PackingScanBloc, PackingScanState>(
          listenWhen: (a, b) =>
              a.cantidadEnDecision == null && b.cantidadEnDecision != null,
          listener: (context, _) async {
            await showDecisionParcialDialog(context, _bloc);
            _enfocarLector();
          },
        ),
        BlocListener<PackingScanBloc, PackingScanState>(
          listenWhen: (a, b) => !a.requiereTemperatura && b.requiereTemperatura,
          listener: (context, _) => showTemperaturaPackDialog(context, _bloc),
        ),
        BlocListener<PackingScanBloc, PackingScanState>(
          listenWhen: (a, b) => !a.finalizado && b.finalizado,
          listener: (context, _) => Navigator.of(context).pop(true),
        ),
        BlocListener<PackingScanBloc, PackingScanState>(
          listenWhen: (a, b) =>
              a.paso != b.paso || a.editandoCantidad != b.editandoCantidad,
          listener: (_, s) {
            if (s.editandoCantidad) {
              _cantidadController.text = s.cantidad > 0
                  ? s.cantidad.toString()
                  : '';
            } else {
              _enfocarLector();
            }
          },
        ),
      ],
      child: PackingOperacionListener<PackingScanBloc, PackingScanState>(
        operacion: (s) => s.operacion,
        exitosSilenciosos: const {
          'separar',
          'imagenNovedad',
          'leerTemperatura',
        },
        child: BlocBuilder<PackingScanBloc, PackingScanState>(
          builder: (context, s) {
            final p = s.producto;
            if (p == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return Scaffold(
              backgroundColor: white,
              body: Column(
                children: [
                  ScanPackHeader(
                    producto: p,
                    onBack: () => Navigator.of(context).pop(false),
                  ),
                  // Campo invisible del lector: siempre presente, toma el foco
                  // salvo mientras se digita la cantidad.
                  BarcodeScannerField(
                    controller: _scanController,
                    focusNode: _scanFocus,
                    clearOnScan: true,
                    refocusOnScan: true,
                    onBarcodeScanned: (v, _) => _bloc.add(ScanPackLeido(v)),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        PasoScanCard(
                          titulo: 'Ubicación',
                          icono: Icons.location_on,
                          estado: _estado(s.paso, PasoScanPack.ubicacion),
                          onManual: s.config.locationPackManual
                              ? () => _bloc.add(
                                  const UbicacionPackConfirmadaManual(),
                                )
                              : null,
                          contenido: [
                            InfoLineaPack(
                              valor: p.locationName,
                              vacio: 'Sin ubicación',
                              negrita: true,
                            ),
                            InfoLineaPack(
                              etiqueta: 'Barcode',
                              valor: p.barcodeLocation,
                            ),
                          ],
                        ),
                        PasoScanCard(
                          titulo: 'Producto',
                          icono: Icons.inventory_2_outlined,
                          estado: _estado(s.paso, PasoScanPack.producto),
                          onManual: s.config.manualProductSelectionPack
                              ? () => _bloc.add(
                                  const ProductoPackConfirmadoManual(),
                                )
                              : null,
                          contenido: [
                            InfoLineaPack(valor: p.productName, negrita: true),
                            InfoLineaPack(
                              etiqueta: 'Código',
                              valor: p.productCode,
                            ),
                            InfoLineaPack(
                              etiqueta: 'Barcode',
                              valor: p.barcode,
                              vacio: 'Sin barcode',
                            ),
                            if (p.loteName.isNotEmpty)
                              InfoLineaPack(
                                etiqueta: 'Lote',
                                valor: p.loteName,
                              ),
                            if (s.barcodes.isNotEmpty)
                              InfoLineaPack(
                                etiqueta: 'Otros códigos',
                                valor: s.barcodes
                                    .map(
                                      (b) => b.cantidad > 1
                                          ? '${b.barcode} (x${b.cantidad.toStringAsFixed(0)})'
                                          : b.barcode,
                                    )
                                    .join(', '),
                              ),
                          ],
                        ),
                        CantidadScanCard(
                          activo: s.paso == PasoScanPack.cantidad,
                          cantidad: s.cantidad,
                          total: p.quantity,
                          unidades: p.unidades,
                          editando: s.editandoCantidad,
                          puedeEditar: s.config.manualQuantityPack,
                          ocupado: s.ocupado,
                          controller: _cantidadController,
                          focusNode: _cantidadFocus,
                          onAlternarEdicion: () =>
                              _bloc.add(const EdicionCantidadPackAlternada()),
                          onAplicar: _aplicar,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static EstadoPasoScan _estado(PasoScanPack actual, PasoScanPack paso) {
    if (actual == paso) return EstadoPasoScan.activo;
    return actual.index > paso.index
        ? EstadoPasoScan.hecho
        : EstadoPasoScan.pendiente;
  }
}
