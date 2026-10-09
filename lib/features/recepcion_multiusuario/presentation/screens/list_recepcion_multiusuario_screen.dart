import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/routes/app_router.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_list_header_widget.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/picking_cluster/widgets/cluster_search_dock.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/list/recepcion_multiusuario_list_bloc.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/recepcion_session_card_widget.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/shared/widgets/loading_dialog_mixin.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/shared/utils/app_navigation.dart';

/// Listado de sesiones de recepción multiusuario (fase 1: solo lectura).
/// A diferencia de recepción individual, no maneja asignación de responsable
/// ni tiempos de inicio — una sesión puede ser trabajada por 1 o más usuarios
/// a la vez.
class ListRecepcionMultiusuarioScreen extends StatefulWidget {
  const ListRecepcionMultiusuarioScreen({super.key});

  @override
  State<ListRecepcionMultiusuarioScreen> createState() =>
      _ListRecepcionMultiusuarioScreenState();
}

class _ListRecepcionMultiusuarioScreenState
    extends State<ListRecepcionMultiusuarioScreen>
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
    context.read<RecepcionMultiusuarioListBloc>().add(
      const FetchRecepcionSessionsFromDbEvent(),
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

  void _handleSessionTap(RecepcionSession session) {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.recepcionMultiusuarioDetail,
      arguments: [session],
    );
  }

  /// Escanear el nombre de la sesión, de la recepción o del documento origen
  /// entra directo al detalle. Matchea contra la lista completa, no la
  /// filtrada por el buscador.
  void _handleScan(String value) {
    final scan = value.trim().toLowerCase();
    if (scan.isEmpty) return;

    final sessions =
        context.read<RecepcionMultiusuarioListBloc>().todasLasSesiones;
    for (final session in sessions) {
      final codes = [
        session.name,
        session.pickingName,
        session.origin,
      ].map((c) => (c ?? '').trim().toLowerCase());
      if (codes.contains(scan)) {
        _handleSessionTap(session);
        return;
      }
    }

    _audioService.playErrorSound();
    _vibrationService.vibrate();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recepción no encontrada en la lista')),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<RecepcionMultiusuarioListBloc>().add(
      const SearchRecepcionSessionEvent(''),
    );
    // Al limpiar, el foco vuelve al lector para seguir escaneando.
    _scanFocusNode.requestFocus();
  }

  void _refresh() {
    final bloc = context.read<RecepcionMultiusuarioListBloc>();
    if (bloc.state is RecepcionMultiusuarioListLoading) return;
    _searchController.clear();
    bloc.add(const SearchRecepcionSessionEvent(''));
    bloc.add(const FetchRecepcionSessionsEvent(isLoadinDialog: false));
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
              title: 'RECEPCIÓN MULTIUSUARIO',
              onBack: () => goHome(context),
              onRefresh: _refresh,
            ),
            ClusterSearchDock(
              controller: _searchController,
              searchFocusNode: _searchFocusNode,
              scannerFocusNode: _scanFocusNode,
              hintText: 'Escanear o buscar recepción...',
              scanner: BarcodeScannerField(
                controller: _scanController,
                focusNode: _scanFocusNode,
                clearOnScan: true,
                refocusOnScan: true,
                onBarcodeScanned: (value, _) => _handleScan(value),
              ),
              onChanged: (value) => context
                  .read<RecepcionMultiusuarioListBloc>()
                  .add(SearchRecepcionSessionEvent(value)),
              onCleared: _clearSearch,
              onActivateScanner: () => _scanFocusNode.requestFocus(),
            ),
            Expanded(
              child:
                  BlocConsumer<
                    RecepcionMultiusuarioListBloc,
                    RecepcionMultiusuarioListState
                  >(
                    listener: (context, state) {
                      if (state is RecepcionMultiusuarioListLoading) {
                        showLoadingDialog('Cargando recepciones...');
                      } else {
                        hideLoadingDialog();
                      }
                      if (state is RecepcionMultiusuarioListError) {
                        showScrollableErrorDialog(state.message);
                      }
                    },
                    builder: (context, state) {
                      if (state is RecepcionMultiusuarioListDbLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final sessions = state is RecepcionSessionsLoaded
                          ? state.sessions
                          : const <RecepcionSession>[];

                      if (sessions.isEmpty) {
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              'No hay recepciones',
                              style: TextStyle(fontSize: 14, color: grey),
                            ),
                            Text(
                              'Intente buscar otra recepción',
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
                            child: RecepcionSessionCardWidget(
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
