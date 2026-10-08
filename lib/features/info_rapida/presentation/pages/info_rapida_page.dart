import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/scan/info_rapida_scan_bloc.dart';
import 'package:wms_app/features/info_rapida/presentation/pages/list_locations_page.dart';
import 'package:wms_app/features/info_rapida/presentation/pages/list_products_page.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/cards/recent_queries_card.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/cards/scan_hero_card.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/cards/scanner_status_pill.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_consulta_listener.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_header.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/dialogs/busqueda_manual_dialog.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/dialogs/search_package_dialog.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';

/// Pantalla principal de Información Rápida: escaneo continuo, búsqueda
/// manual (productos, ubicaciones, paquetes) y últimas consultas.
class InfoRapidaPage extends StatelessWidget {
  const InfoRapidaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<InfoRapidaScanBloc>()..add(const InfoRapidaScanIniciado()),
      child: const _InfoRapidaView(),
    );
  }
}

class _InfoRapidaView extends StatefulWidget {
  const _InfoRapidaView();

  @override
  State<_InfoRapidaView> createState() => _InfoRapidaViewState();
}

class _InfoRapidaViewState extends State<_InfoRapidaView> {
  final TextEditingController _scanController = TextEditingController();
  final FocusNode _scanFocusNode = FocusNode();

  @override
  void dispose() {
    _scanFocusNode.dispose();
    _scanController.dispose();
    super.dispose();
  }

  void _onScan(String value) {
    final scan = value.trim();
    if (scan.isNotEmpty) {
      context.read<InfoRapidaScanBloc>().add(
        ConsultarPorBarcodeEvent(scan.toUpperCase()),
      );
    }
    _reenfocarEscaner();
  }

  void _reenfocarEscaner() {
    _scanController.clear();
    Future.microtask(() {
      if (mounted) _scanFocusNode.requestFocus();
    });
  }

  void _volverAlHome() => Navigator.pushReplacementNamed(context, '/home');

  Future<void> _busquedaManual() async {
    final opcion = await showDialog<BusquedaManualOpcion>(
      context: context,
      builder: (_) => const BusquedaManualDialog(),
    );
    if (!mounted || opcion == null) return;

    final config = context.read<InfoRapidaScanBloc>().state.configuracion;
    switch (opcion) {
      case BusquedaManualOpcion.productos:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ListProductsPage(config: config)),
        );
      case BusquedaManualOpcion.ubicaciones:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ListLocationsPage(config: config)),
        );
      case BusquedaManualOpcion.paquetes:
        final nombre = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const SearchPackageDialog(),
        );
        if (!mounted || nombre == null) return;
        context.read<InfoRapidaScanBloc>().add(
          ConsultarPorBarcodeEvent(nombre),
        );
    }
    _reenfocarEscaner();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _volverAlHome();
      },
      child: InfoRapidaConsultaListener(
        onRetorno: _reenfocarEscaner,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: primaryColorApp,
            foregroundColor: white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onPressed: _busquedaManual,
            icon: const Icon(Icons.search),
            label: const Text(
              'Buscar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: Column(
            children: [
              InfoRapidaHeader(onBack: _volverAlHome),
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
                        focusNode: _scanFocusNode,
                        onActivate: _scanFocusNode.requestFocus,
                      ),
                      const SizedBox(height: 16),
                      const ScanHeroCard(),
                      BlocBuilder<InfoRapidaScanBloc, InfoRapidaScanState>(
                        buildWhen: (previous, current) =>
                            previous.consultasRecientes !=
                            current.consultasRecientes,
                        builder: (context, state) => RecentQueriesCard(
                          items: state.consultasRecientes,
                          onSelect: (q) => context
                              .read<InfoRapidaScanBloc>()
                              .add(ConsultaRecienteSeleccionada(q)),
                          onClear: () => context.read<InfoRapidaScanBloc>().add(
                            const BorrarHistorialConsultasEvent(),
                          ),
                        ),
                      ),
                      BarcodeScannerField(
                        controller: _scanController,
                        focusNode: _scanFocusNode,
                        clearOnScan: true,
                        onBarcodeScanned: (value, _) => _onScan(value),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
