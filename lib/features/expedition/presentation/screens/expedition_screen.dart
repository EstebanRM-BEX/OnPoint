import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/expedition/data/services/expedition_sync_coordinator.dart';
import 'package:wms_app/features/expedition/presentation/bloc/detail/expedicion_detail_bloc.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_detail_tab_detalles.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_detail_tab_listo.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_detail_tab_por_hacer.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';

class ExpedicionDetailScreen extends StatefulWidget {
  final int expeditionId;

  const ExpedicionDetailScreen({super.key, required this.expeditionId});

  @override
  State<ExpedicionDetailScreen> createState() =>
      _ExpedicionDetailScreenState();
}

class _ExpedicionDetailScreenState extends State<ExpedicionDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  StreamSubscription<void>? _syncedSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context
        .read<ExpedicionDetailBloc>()
        .add(LoadExpedicionDetailEvent(widget.expeditionId));

    // Cuando el coordinator sincroniza validaciones offline, relee el detalle
    // desde SQLite para que los badges pasen de "pendiente" a "enviado".
    _syncedSub = getIt<ExpeditionSyncCoordinator>().onSynced.listen((_) {
      if (!mounted) return;
      context
          .read<ExpedicionDetailBloc>()
          .add(LoadExpedicionDetailEvent(widget.expeditionId));
    });
  }

  @override
  void dispose() {
    _syncedSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpedicionDetailBloc, ExpedicionDetailState>(
      builder: (context, state) {
        final detail =
            state is ExpedicionDetailLoaded ? state.detail : null;
        final porHacerCount = (detail?.paquetesPendientes.length ?? 0) +
            (detail?.itemsSueltosPendientes.length ?? 0);
        final listoCount = (detail?.paquetesListos.length ?? 0) +
            (detail?.itemsSueltosListos.length ?? 0);

        return WillPopScope(
          onWillPop: () async => true,
          child: Scaffold(
            backgroundColor: primaryColorApp,
            appBar: AppBar(
              backgroundColor: primaryColorApp,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              title: const Text('EXPEDICIÓN',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              centerTitle: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  const Tab(
                      text: 'Detalles', icon: Icon(Icons.info_outline, size: 18)),
                  Stack(
                    children: [
                      const Tab(
                          text: 'Por hacer',
                          icon: Icon(Icons.pending_actions_outlined, size: 18)),
                      Positioned(
                        right: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: red,
                          child: Text(
                            '$porHacerCount',
                            style:
                                const TextStyle(color: Colors.white, fontSize: 9),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      const Tab(
                          text: 'Listo',
                          icon: Icon(Icons.check_circle_outline, size: 18)),
                      Positioned(
                        right: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: green,
                          child: Text(
                            '$listoCount',
                            style:
                                const TextStyle(color: Colors.white, fontSize: 9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            body: SafeArea(
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    const WarningWidgetCubit(isTop: false),
                    Expanded(
                      child: Builder(builder: (context) {
                        if (state is ExpedicionDetailLoading ||
                            state is ExpedicionDetailInitial) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (state is ExpedicionDetailError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(state.message,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: red)),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () => context
                                        .read<ExpedicionDetailBloc>()
                                        .add(LoadExpedicionDetailEvent(
                                            widget.expeditionId)),
                                    child: const Text('Reintentar'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return TabBarView(
                          controller: _tabController,
                          children: [
                            ExpedicionDetailTabDetalles(detail: detail!),
                            ExpedicionDetailTabPorHacer(detail: detail),
                            ExpedicionDetailTabListo(detail: detail),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
