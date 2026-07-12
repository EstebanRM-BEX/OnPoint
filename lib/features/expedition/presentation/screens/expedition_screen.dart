import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/expedition/presentation/bloc/detail/expedicion_detail_bloc.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context
        .read<ExpedicionDetailBloc>()
        .add(LoadExpedicionDetailEvent(widget.expeditionId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            tabs: const [
              Tab(text: 'Detalles', icon: Icon(Icons.info_outline, size: 18)),
              Tab(
                  text: 'Por hacer',
                  icon: Icon(Icons.pending_actions_outlined, size: 18)),
              Tab(
                  text: 'Listo',
                  icon: Icon(Icons.check_circle_outline, size: 18)),
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
                  child: BlocBuilder<ExpedicionDetailBloc, ExpedicionDetailState>(
                    builder: (context, state) {
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

                      final detail = (state as ExpedicionDetailLoaded).detail;

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          ExpedicionDetailTabDetalles(detail: detail),
                          ExpedicionDetailTabPorHacer(detail: detail),
                          ExpedicionDetailTabListo(detail: detail),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
