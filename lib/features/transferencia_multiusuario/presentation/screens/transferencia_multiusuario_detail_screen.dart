import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/routes/app_router.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_session.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/usecases/fetch_transferencia_snapshot_usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/bloc/detail/transferencia_multiusuario_my_claims_bloc.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/bloc/detail/transferencia_multiusuario_pool_bloc.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/widgets/transferencia_multiusuario_detail_tab_detalle.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/widgets/transferencia_multiusuario_detail_tab_mis_asignados.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/widgets/transferencia_multiusuario_detail_tab_por_hacer.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/widgets/transferencia_multiusuario_detail_tab_terminados.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';

/// Detalle de una sesión de transferencia multiusuario: 4 tabs — Detalle,
/// Por hacer, Asignados y Terminados. Espejo de
/// RecepcionMultiusuarioDetailScreen. "Por hacer" ya muestra el pool real;
/// Detalle/Asignados/Terminados siguen en placeholder — se van llenando una
/// a una en los siguientes pasos.
class TransferenciaMultiusuarioDetailScreen extends StatefulWidget {
  const TransferenciaMultiusuarioDetailScreen({
    super.key,
    required this.session,
    this.initialTabIndex = 0,
  });

  final TransferenciaSession session;
  final int initialTabIndex;

  @override
  State<TransferenciaMultiusuarioDetailScreen> createState() =>
      _TransferenciaMultiusuarioDetailScreenState();
}

class _TransferenciaMultiusuarioDetailScreenState
    extends State<TransferenciaMultiusuarioDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Evita refetchear de más mientras el TabController todavía está
  // resolviendo a qué índice se asienta (ver _onTabChanged).
  int? _lastFetchedTabIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(_onTabChanged);
    _lastFetchedTabIndex = widget.initialTabIndex;

    _cargarSnapshotInicial();

    // Las novedades las necesita el selector de "cantidad menor a lo
    // pendiente" y el de "deshacer" (scan_product_screen.dart / tab
    // Terminados) — las precargamos acá para que ya estén listas cuando el
    // operario llegue a esas pantallas. Los permisos (tbl_configurations)
    // no hace falta recargarlos: UserBloc ya los carga en el login.
    context.read<UserBloc>().add(LoadUserNoveltiesEvent());
  }

  /// Refresca la data del tab al que el operario acaba de entrar — "Por
  /// hacer"/"Asignados"/"Terminados" son datos en vivo, pueden haber
  /// cambiado desde la última vez (otro operario tomó/terminó un producto)
  /// mientras se estaba en otro tab. "Detalle" (índice 0) ya se refresca
  /// solo, ver TransferenciaMultiusuarioDetailTabDetalle.
  void _onTabChanged() {
    // Se dispara varias veces durante la animación/el swipe — solo importa
    // el índice en el que se asienta.
    if (_tabController.indexIsChanging) return;
    final index = _tabController.index;
    if (index == _lastFetchedTabIndex) return;
    _lastFetchedTabIndex = index;

    final sessionId = widget.session.sessionId;
    if (sessionId == null) return;

    switch (index) {
      case 1: // Por hacer
        context.read<TransferenciaMultiusuarioPoolBloc>().add(
          FetchTransferenciaPoolEvent(sessionId, verification: false),
        );
        break;
      case 2: // Asignados
        context.read<TransferenciaMultiusuarioMyClaimsBloc>().add(
          FetchMyClaimsEvent(sessionId),
        );
        break;
      case 3: // Terminados
        context.read<TransferenciaMultiusuarioPoolBloc>().add(
          FetchTransferenciaPoolEvent(sessionId, verification: true),
        );
        break;
    }
  }

  /// Carga inicial de la pantalla: una sola llamada a
  /// /api/transfer/session/{id}/snapshot en vez de las 2 llamadas separadas
  /// (pool + my_claims) que se hacían antes. "Por hacer" siempre pide su
  /// propio pool en vivo aparte — el pool del snapshot no viene filtrado
  /// por disponibilidad (ver TransferenciaSnapshotModel.fromJson), así que
  /// solo se usa para sembrar "Terminados". Si el snapshot falla, cada tab
  /// cae en su fetch individual de siempre.
  Future<void> _cargarSnapshotInicial() async {
    final sessionId = widget.session.sessionId;
    if (sessionId == null) return;

    context.read<TransferenciaMultiusuarioPoolBloc>().add(
      FetchTransferenciaPoolEvent(sessionId, verification: false),
    );

    final result = await getIt<FetchTransferenciaSnapshotUseCase>()(
      FetchTransferenciaSnapshotParams(sessionId: sessionId),
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        context.read<TransferenciaMultiusuarioMyClaimsBloc>().add(
          FetchMyClaimsEvent(sessionId),
        );
      },
      (snapshot) {
        context.read<TransferenciaMultiusuarioMyClaimsBloc>().add(
          SeedTransferenciaMyClaimsEvent(snapshot.myClaims),
        );
        context.read<TransferenciaMultiusuarioPoolBloc>().add(
          SeedTransferenciaTerminadosEvent(snapshot.pool),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
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
          onPressed: () => Navigator.pushReplacementNamed(
            context,
            AppRoutes.listTransferenciaMultiusuario,
          ),
        ),
        title: Text(
          widget.session.name ?? 'TRANSFERENCIA',
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
              TransferenciaMultiusuarioPoolBloc,
              TransferenciaMultiusuarioPoolState
            >(
              builder: (context, poolState) {
                final items = context
                    .read<TransferenciaMultiusuarioPoolBloc>()
                    .poolItems;
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
              TransferenciaMultiusuarioMyClaimsBloc,
              TransferenciaMultiusuarioMyClaimsState
            >(
              builder: (context, state) {
                final claims = state is TransferenciaMyClaimsLoaded
                    ? state.claims
                    : context
                          .read<TransferenciaMultiusuarioMyClaimsBloc>()
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
              TransferenciaMultiusuarioPoolBloc,
              TransferenciaMultiusuarioPoolState
            >(
              builder: (context, poolState) {
                final items = context
                    .read<TransferenciaMultiusuarioPoolBloc>()
                    .terminadosItems;
                // Cuenta PRODUCTOS con al menos una asignación terminada,
                // no observaciones sueltas — un producto con 2 entregas
                // parciales cuenta 1, no 2 (mismo criterio que el tab
                // Terminados, incluyendo el dedupe por asignacion_id/
                // claim_id porque el pool a veces repite la misma
                // asignación).
                final vistos = <int>{};
                var productosTerminados = 0;
                for (final item in items) {
                  final tieneTerminada = item.observaciones.any(
                    (o) =>
                        o.isDone &&
                        vistos.add(o.asignacionId ?? o.claimId ?? o.hashCode),
                  );
                  if (tieneTerminada) productosTerminados++;
                }
                return _TabConBadge(
                  tab: const Tab(
                    text: 'Terminados',
                    icon: Icon(Icons.done_all, size: 16),
                  ),
                  count: productosTerminados,
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
                    TransferenciaMultiusuarioDetailTabDetalle(
                      session: widget.session,
                    ),
                    TransferenciaMultiusuarioDetailTabPorHacer(
                      session: widget.session,
                    ),
                    TransferenciaMultiusuarioDetailTabMisAsignados(
                      session: widget.session,
                    ),
                    TransferenciaMultiusuarioDetailTabTerminados(
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
/// recepción multiusuario. No se muestra el globito si el contador es 0.
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
