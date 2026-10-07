import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/packages/packing_packages_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/barra_lector_pack.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/lista_vacia_pack.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/packages/paquete_pack_card.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';

/// Pestaña "Paquetes". El lector reconoce cajas (las selecciona) y
/// ubicaciones de muelle (se asignan a las seleccionadas o a la abierta).
class PaquetesTab extends StatefulWidget {
  final bool activo;
  final bool editable;

  /// Pedidos cluster muestran el botón de asignar ubicación.
  final bool esCluster;
  final ValueChanged<List<int>> onImprimir;
  final ValueChanged<PaquetePacking> onEliminar;
  final void Function(PaquetePacking paquete, ProductoPacking producto)
  onDesempacar;
  final ValueChanged<UbicacionMuelle?> onAsignarUbicacion;

  const PaquetesTab({
    super.key,
    required this.activo,
    required this.editable,
    required this.esCluster,
    required this.onImprimir,
    required this.onEliminar,
    required this.onDesempacar,
    required this.onAsignarUbicacion,
  });

  @override
  State<PaquetesTab> createState() => _PaquetesTabState();
}

class _PaquetesTabState extends State<PaquetesTab> {
  final _scanController = TextEditingController();
  final _scanFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<PackingPackagesBloc>().add(
      const UbicacionesMuellePackCargadas(),
    );
    if (widget.activo) _enfocarLector();
  }

  @override
  void didUpdateWidget(covariant PaquetesTab old) {
    super.didUpdateWidget(old);
    if (widget.activo && !old.activo) _enfocarLector();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _scanFocus.dispose();
    super.dispose();
  }

  void _enfocarLector() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) _scanFocus.requestFocus();
  });

  void _onEscaneo(String valor) {
    final bloc = context.read<PackingPackagesBloc>();
    final s = bloc.state;
    if (s.paquetes.any((p) => p.coincideCon(valor))) {
      bloc.add(PaquetePackEscaneado(valor));
      return;
    }
    final v = valor.trim().toLowerCase();
    final ubicacion = s.ubicaciones
        .where((u) => u.barcode.toLowerCase() == v || u.name.toLowerCase() == v)
        .firstOrNull;
    if (ubicacion != null && widget.editable) {
      widget.onAsignarUbicacion(ubicacion);
      return;
    }
    getIt<IAudioService>().playErrorSound();
    getIt<IVibrationService>().vibrate();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Paquete o ubicación no encontrado')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PackingPackagesBloc, PackingPackagesState>(
      builder: (context, state) {
        final bloc = context.read<PackingPackagesBloc>();
        final paquetes = state.paquetes;
        final seleccion = state.seleccionados;
        final todos =
            paquetes.isNotEmpty && seleccion.length == paquetes.length;
        final hayDestino = state.paquetesDestino.isNotEmpty;

        return Scaffold(
          backgroundColor: white,
          floatingActionButton: seleccion.length > 1
              ? FloatingActionButton.extended(
                  heroTag: 'fab-pack-paquetes',
                  backgroundColor: primaryColorApp,
                  onPressed: () => widget.onImprimir(seleccion.toList()),
                  icon: const Icon(Icons.print, color: white),
                  label: Text(
                    '(${seleccion.length})',
                    style: const TextStyle(color: white),
                  ),
                )
              : null,
          body: Column(
            children: [
              BarraLectorPack(
                lector: BarcodeScannerField(
                  controller: _scanController,
                  focusNode: _scanFocus,
                  autofocus: false,
                  clearOnScan: true,
                  refocusOnScan: true,
                  onBarcodeScanned: (v, _) => _onEscaneo(v),
                ),
                texto: 'Escanee una caja o ubicación',
                seleccionTodos: paquetes.isEmpty
                    ? null
                    : () => bloc.add(
                        SeleccionPaquetesPackReemplazada(
                          todos ? const [] : paquetes.map((p) => p.id),
                        ),
                      ),
                todosSeleccionados: todos,
                acciones: [
                  if (widget.esCluster && widget.editable)
                    IconButton(
                      tooltip: 'Asignar ubicación de destino',
                      icon: Icon(
                        Icons.add_location_alt,
                        color: hayDestino ? primaryColorApp : grey,
                      ),
                      onPressed: hayDestino
                          ? () => widget.onAsignarUbicacion(null)
                          : null,
                    ),
                ],
              ),
              Expanded(
                child: paquetes.isEmpty
                    ? const ListaVaciaPack(
                        titulo: 'No hay paquetes',
                        subtitulo: 'Empaque productos para crear cajas',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 90),
                        itemCount: paquetes.length,
                        itemBuilder: (_, i) {
                          final p = paquetes[i];
                          return PaquetePackCard(
                            paquete: p,
                            seleccionado: seleccion.contains(p.id),
                            expandido: state.expandido == p.id,
                            editable: widget.editable,
                            onSeleccionar: (v) => bloc.add(
                              PaquetePackSeleccionado(p.id, seleccionado: v),
                            ),
                            onExpandir: () =>
                                bloc.add(PaquetePackExpandido(p.id)),
                            onImprimir: () => widget.onImprimir([p.id]),
                            onEliminar: () => widget.onEliminar(p),
                            onDesempacar: (prod) =>
                                widget.onDesempacar(p, prod),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
