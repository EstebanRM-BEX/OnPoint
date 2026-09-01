import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
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

    final sessionId = widget.session.sessionId;
    if (sessionId != null) {
      // El pool es en vivo y no se persiste local (ver
      // RecepcionMultiusuarioRepositoryImpl.fetchPool) — siempre se muestra
      // lo que devuelva esta petición, nada de una vez anterior.
      //
      // Dos fetches porque "Por hacer" y "Terminados" necesitan datos
      // DISTINTOS del mismo endpoint (verification: false vs true — ver
      // RecepcionMultiusuarioPoolBloc) y sus dos globitos de conteo están
      // visibles a la vez en este AppBar (por eso se piden los 3 juntos acá,
      // sin importar con qué tab se entra — _onTabChanged de abajo se
      // encarga de refrescar cada uno de nuevo cuando el operario vuelve a
      // entrar a su tab).
      context.read<RecepcionMultiusuarioPoolBloc>().add(
        FetchRecepcionPoolEvent(sessionId, verification: false),
      );
      context.read<RecepcionMultiusuarioPoolBloc>().add(
        FetchRecepcionPoolEvent(sessionId, verification: true),
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

  /// Refresca la data del tab al que el operario acaba de entrar — "Por
  /// hacer"/"Terminados"/"Mis asignados" son datos en vivo, pueden haber
  /// cambiado desde la última vez (otro operario tomó/terminó un producto)
  /// mientras se estaba en otro tab. "Detalle" (índice 0) ya se refresca
  /// solo, ver RecepcionMultiusuarioDetailTabDetalle.
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
        context.read<RecepcionMultiusuarioPoolBloc>().add(
          FetchRecepcionPoolEvent(sessionId, verification: false),
        );
        break;
      case 2: // Mis asignados
        context.read<RecepcionMultiusuarioMyClaimsBloc>().add(
          FetchMyClaimsEvent(sessionId),
        );
        break;
      case 3: // Terminados
        context.read<RecepcionMultiusuarioPoolBloc>().add(
          FetchRecepcionPoolEvent(sessionId, verification: true),
        );
        break;
    }
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
                final items = context
                    .read<RecepcionMultiusuarioPoolBloc>()
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
                final items = context
                    .read<RecepcionMultiusuarioPoolBloc>()
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
