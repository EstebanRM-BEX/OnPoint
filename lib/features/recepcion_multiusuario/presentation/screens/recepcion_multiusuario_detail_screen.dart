import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_pool_item.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/detail/recepcion_multiusuario_my_claims_bloc.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/detail/recepcion_multiusuario_pool_bloc.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/recepcion_multiusuario_detail_tab_detalle.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/recepcion_multiusuario_detail_tab_mis_asignados.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/recepcion_multiusuario_detail_tab_por_hacer.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/recepcion_multiusuario_detail_tab_terminados.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';

/// Detalle de una sesión de recepción multiusuario: 4 tabs — Detalle, Por
/// hacer (pool en vivo), Mis asignados (mis claims en progreso) y
/// Terminados. Detalle/Por hacer/Mis asignados ya muestran datos reales;
/// Terminados sigue en blanco.
class RecepcionMultiusuarioDetailScreen extends StatefulWidget {
  const RecepcionMultiusuarioDetailScreen({
    super.key,
    required this.session,
    this.initialTabIndex = 0,
  });

  final RecepcionSession session;
  final int initialTabIndex;

  @override
  State<RecepcionMultiusuarioDetailScreen> createState() =>
      _RecepcionMultiusuarioDetailScreenState();
}

class _RecepcionMultiusuarioDetailScreenState
    extends State<RecepcionMultiusuarioDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    final sessionId = widget.session.sessionId;
    if (sessionId != null) {
      // Offline-first: mostramos lo que ya haya en SQLite mientras llega la
      // respuesta en vivo del backend (el pool cambia todo el tiempo — cada
      // producto que otro operario toma desaparece de la próxima respuesta).
      context.read<RecepcionMultiusuarioPoolBloc>().add(
        FetchRecepcionPoolFromDbEvent(sessionId),
      );
      context.read<RecepcionMultiusuarioPoolBloc>().add(
        FetchRecepcionPoolEvent(sessionId),
      );
      context.read<RecepcionMultiusuarioMyClaimsBloc>().add(
        FetchMyClaimsEvent(sessionId),
      );
    }

    // Las novedades las necesita el selector de "cantidad menor a lo
    // pendiente" y el de "deshacer" (scan_product_screen.dart / tab
    // Terminados) — las precargamos acá para que ya estén listas cuando el
    // operario llegue a esas pantallas. Los permisos (tbl_configurations)
    // no hace falta recargarlos: UserBloc ya los carga en el login.
    context.read<UserBloc>().add(LoadUserNoveltiesEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColorApp,
      appBar: AppBar(
        backgroundColor: primaryColorApp,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.session.name ?? 'RECEPCIÓN',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          tabs: [
            const Tab(
              text: 'Detalle',
              icon: Icon(Icons.info_outline, size: 16),
            ),
            BlocBuilder<
              RecepcionMultiusuarioPoolBloc,
              RecepcionMultiusuarioPoolState
            >(
              builder: (context, poolState) {
                final items = poolState is RecepcionPoolLoaded
                    ? poolState.items
                    : const <RecepcionPoolItem>[];
                return _TabConBadge(
                  tab: const Tab(
                    text: 'Por hacer',
                    icon: Icon(Icons.pending_actions_outlined, size: 16),
                  ),
                  count: items.length,
                  color: red,
                );
              },
            ),
            BlocBuilder<
              RecepcionMultiusuarioMyClaimsBloc,
              RecepcionMultiusuarioMyClaimsState
            >(
              builder: (context, state) {
                // Estados transitorios (release loading/success/error) no
                // traen su propia lista: seguimos contando la última
                // cargada, mismo criterio que el propio tab.
                final claims = state is RecepcionMyClaimsLoaded
                    ? state.claims
                    : context
                          .read<RecepcionMultiusuarioMyClaimsBloc>()
                          .currentClaims;
                return _TabConBadge(
                  tab: const Tab(
                    text: 'Asignados',
                    icon: Icon(Icons.assignment_ind_outlined, size: 16),
                  ),
                  count: claims.length,
                  color: Colors.orange,
                );
              },
            ),
            BlocBuilder<
              RecepcionMultiusuarioPoolBloc,
              RecepcionMultiusuarioPoolState
            >(
              builder: (context, poolState) {
                final items = poolState is RecepcionPoolLoaded
                    ? poolState.items
                    : const <RecepcionPoolItem>[];
                final terminadas = items.fold<int>(
                  0,
                  (total, item) =>
                      total + item.observaciones.where((o) => o.isDone).length,
                );
                return _TabConBadge(
                  tab: const Tab(
                    text: 'Terminados',
                    icon: Icon(Icons.done_all, size: 16),
                  ),
                  count: terminadas,
                  color: green,
                );
              },
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
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    RecepcionMultiusuarioDetailTabDetalle(
                      session: widget.session,
                    ),
                    RecepcionMultiusuarioDetailTabPorHacer(
                      session: widget.session,
                    ),
                    RecepcionMultiusuarioDetailTabMisAsignados(
                      session: widget.session,
                    ),
                    RecepcionMultiusuarioDetailTabTerminados(
                      session: widget.session,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tab con contador (globito) arriba a la derecha — réplica del patrón de
/// recepción individual (recepcion_screen.dart) para "Por hacer"/"Listo".
/// No se muestra el globito si el contador es 0.
class _TabConBadge extends StatelessWidget {
  const _TabConBadge({
    required this.tab,
    required this.count,
    required this.color,
  });

  final Tab tab;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        tab,
        if (count > 0)
          Positioned(
            right: 0,
            child: CircleAvatar(
              radius: 8,
              backgroundColor: color,
              child: Text(
                count.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ),
      ],
    );
  }
}
