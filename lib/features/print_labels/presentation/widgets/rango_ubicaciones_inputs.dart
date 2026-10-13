import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/picking_cluster/widgets/cluster_search_dock.dart';
import 'package:wms_app/features/print_labels/presentation/bloc/print_labels_bloc.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';

/// Inicio y fin del rango de etiquetas con el buscador de Cluster: cada
/// campo tiene su lector (campo invisible) y su botón.
///
/// Flujo: entra con el lector de Inicio activo; al escanear Inicio, el
/// lector pasa a Fin. Con Fin escaneado se espera "Buscar rango". Tocar un
/// campo es escritura manual (el botón de su lector se apaga); tocar el
/// botón reactiva ese lector.
class RangoUbicacionesInputs extends StatefulWidget {
  const RangoUbicacionesInputs({super.key});

  @override
  State<RangoUbicacionesInputs> createState() => _RangoUbicacionesInputsState();
}

class _RangoUbicacionesInputsState extends State<RangoUbicacionesInputs> {
  final _inicioFocus = FocusNode();
  final _finFocus = FocusNode();
  final _lectorInicioFocus = FocusNode();
  final _lectorFinFocus = FocusNode();
  final _lectorInicio = TextEditingController();
  final _lectorFin = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Al volver de "Agregar ubicaciones": el lector del campo que falta.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<PrintLabelsBloc>();
      (bloc.rangeStartController.text.isEmpty
              ? _lectorInicioFocus
              : _lectorFinFocus)
          .requestFocus();
    });
  }

  @override
  void dispose() {
    _inicioFocus.dispose();
    _finFocus.dispose();
    _lectorInicioFocus.dispose();
    _lectorFinFocus.dispose();
    _lectorInicio.dispose();
    _lectorFin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PrintLabelsBloc>();
    return BlocListener<PrintLabelsBloc, PrintLabelsState>(
      // "Limpiar búsqueda" o impresión exitosa vacían los campos: se vuelve
      // a escanear desde Inicio.
      listenWhen: (_, state) =>
          state is SearchRangeLocationSuccess &&
          bloc.rangeStartController.text.isEmpty &&
          bloc.rangeEndController.text.isEmpty,
      listener: (_, __) => _lectorInicioFocus.requestFocus(),
      child: Column(
        children: [
          ClusterSearchDock(
            controller: bloc.rangeStartController,
            searchFocusNode: _inicioFocus,
            scannerFocusNode: _lectorInicioFocus,
            hintText: 'Inicio: escanear o escribir código...',
            scanner: BarcodeScannerField(
              controller: _lectorInicio,
              focusNode: _lectorInicioFocus,
              autofocus: false,
              clearOnScan: true,
              onBarcodeScanned: (value, _) {
                bloc.rangeStartController.text = value;
                _lectorFinFocus.requestFocus();
              },
            ),
            onChanged: (_) {},
            onCleared: () {
              bloc.rangeStartController.clear();
              _lectorInicioFocus.requestFocus();
            },
            onActivateScanner: () => _lectorInicioFocus.requestFocus(),
          ),
          ClusterSearchDock(
            controller: bloc.rangeEndController,
            searchFocusNode: _finFocus,
            scannerFocusNode: _lectorFinFocus,
            hintText: 'Fin (opcional): escanear o escribir...',
            scanner: BarcodeScannerField(
              controller: _lectorFin,
              focusNode: _lectorFinFocus,
              autofocus: false,
              clearOnScan: true,
              // Se queda en Fin: un nuevo escaneo lo reemplaza.
              refocusOnScan: true,
              onBarcodeScanned: (value, _) =>
                  bloc.rangeEndController.text = value,
            ),
            onChanged: (_) {},
            onCleared: () {
              bloc.rangeEndController.clear();
              _lectorFinFocus.requestFocus();
            },
            onActivateScanner: () => _lectorFinFocus.requestFocus(),
          ),
        ],
      ),
    );
  }
}
