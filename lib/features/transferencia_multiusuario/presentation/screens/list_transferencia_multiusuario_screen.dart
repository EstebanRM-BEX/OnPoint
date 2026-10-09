import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/routes/app_router.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_list_header_widget.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/picking_cluster/widgets/cluster_search_dock.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_session.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/bloc/list/transferencia_multiusuario_list_bloc.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/widgets/transferencia_session_card_widget.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/shared/widgets/loading_dialog_mixin.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/shared/utils/app_navigation.dart';

/// Listado de sesiones de transferencia multiusuario (fase 1: solo lectura).
/// Espejo de ListRecepcionMultiusuarioScreen: una sesión puede ser trabajada
/// por 1 o más usuarios a la vez.
class ListTransferenciaMultiusuarioScreen extends StatefulWidget {
  const ListTransferenciaMultiusuarioScreen({super.key});

  @override
  State<ListTransferenciaMultiusuarioScreen> createState() =>
      _ListTransferenciaMultiusuarioScreenState();
}

class _ListTransferenciaMultiusuarioScreenState
    extends State<ListTransferenciaMultiusuarioScreen>
    with LoadingDialogMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  // Campo invisible del lector PDA (keyboard-wedge), igual que Pick Cluster.
  final TextEditingController _scanController = TextEditingController();
  final FocusNode _scanFocusNode = FocusNode();
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();

  @override
  void initState() {
    super.initState();
    // Offline-first: primero lo que ya hay en SQLite, el refresh manual trae
    // lo nuevo del backend.
    context.read<TransferenciaMultiusuarioListBloc>().add(
      const FetchTransferenciaSessionsFromDbEvent(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scanController.dispose();
    _scanFocusNode.dispose();
    super.dispose();
  }

  void _handleSessionTap(TransferenciaSession session) {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.transferenciaMultiusuarioDetail,
      arguments: [session],
    );
  }

  /// Escanear el nombre de la sesión, del picking o del documento origen
  /// entra directo al detalle. Matchea contra la lista completa, no la
  /// filtrada por el buscador.
  void _handleScan(String value) {
    final scan = value.trim().toLowerCase();
    if (scan.isEmpty) return;

    final sessions =
        context.read<TransferenciaMultiusuarioListBloc>().todasLasSesiones;
    for (final session in sessions) {
      final codes = [
        session.name,
        session.pickingName,
        session.origin,
        session.originPickingName,
      ].map((c) => (c ?? '').trim().toLowerCase());
      if (codes.contains(scan)) {
        _handleSessionTap(session);
        return;
      }
    }

    _audioService.playErrorSound();
    _vibrationService.vibrate();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transferencia no encontrada en la lista')),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<TransferenciaMultiusuarioListBloc>().add(
      const SearchTransferenciaSessionEvent(''),
    );
    // Al limpiar, el foco vuelve al lector para seguir escaneando.
    _scanFocusNode.requestFocus();
  }

  void _refresh() {
    final bloc = context.read<TransferenciaMultiusuarioListBloc>();
    if (bloc.state is TransferenciaMultiusuarioListLoading) return;
    _searchController.clear();
    bloc.add(const SearchTransferenciaSessionEvent(''));
    bloc.add(const FetchTransferenciaSessionsEvent(isLoadinDialog: false));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: ClusterPalette.surface,
        body: Column(
          children: [
            ExpedicionListHeaderWidget(
              title: 'TRASLADO MULTIUSUARIO',
              onBack: () => goHome(context),
              onRefresh: _refresh,
            ),
            ClusterSearchDock(
              controller: _searchController,
              searchFocusNode: _searchFocusNode,
              scannerFocusNode: _scanFocusNode,
              hintText: 'Escanear o buscar transferencia...',
              scanner: BarcodeScannerField(
                controller: _scanController,
                focusNode: _scanFocusNode,
                clearOnScan: true,
                refocusOnScan: true,
                onBarcodeScanned: (value, _) => _handleScan(value),
              ),
              onChanged: (value) => context
                  .read<TransferenciaMultiusuarioListBloc>()
                  .add(SearchTransferenciaSessionEvent(value)),
              onCleared: _clearSearch,
              onActivateScanner: () => _scanFocusNode.requestFocus(),
            ),
            Expanded(
              child:
                  BlocConsumer<
                    TransferenciaMultiusuarioListBloc,
                    TransferenciaMultiusuarioListState
                  >(
                    listener: (context, state) {
                      if (state is TransferenciaMultiusuarioListLoading) {
                        showLoadingDialog('Cargando transferencias...');
                      } else {
                        hideLoadingDialog();
                      }
                      if (state is TransferenciaMultiusuarioListError) {
                        showScrollableErrorDialog(state.message);
                      }
                    },
                    builder: (context, state) {
                      if (state is TransferenciaMultiusuarioListDbLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final sessions = state is TransferenciaSessionsLoaded
                          ? state.sessions
                          : const <TransferenciaSession>[];

                      if (sessions.isEmpty) {
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              'No hay transferencias',
                              style: TextStyle(fontSize: 14, color: grey),
                            ),
                            Text(
                              'Intente buscar otra transferencia',
                              style: TextStyle(fontSize: 12, color: grey),
                            ),
                          ],
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 2),
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          return InkWell(
                            onTap: () => _handleSessionTap(session),
                            child: TransferenciaSessionCardWidget(
                              session: session,
                            ),
                          );
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
