import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/bloc/safe_bloc_mixin.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/asignar_responsable_pack_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/get_config_packing_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/get_pedidos_pack_local_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/registrar_tiempo_pack_usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/usecases/sync_pedidos_pack_usecase.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/common/packing_operacion.dart';

part 'packing_pedido_list_event.dart';
part 'packing_pedido_list_state.dart';

/// Lista de pedidos de packing: sincronización, búsqueda, orden y
/// asignación de responsable.
@injectable
class PackingPedidoListBloc
    extends Bloc<PackingPedidoListEvent, PackingPedidoListState>
    with SafeBlocMixin<PackingPedidoListEvent, PackingPedidoListState> {
  final SyncPedidosPackUseCase syncPedidos;
  final GetPedidosPackLocalUseCase getPedidosLocal;
  final AsignarResponsablePackUseCase asignarResponsable;
  final GetConfigPackingUseCase getConfig;
  final RegistrarTiempoPackUseCase registrarTiempo;

  PackingPedidoListBloc(
    this.syncPedidos,
    this.getPedidosLocal,
    this.asignarResponsable,
    this.getConfig,
    this.registrarTiempo,
  ) : super(const PackingPedidoListState()) {
    on<ListaPackIniciada>(_onIniciada, transformer: droppable());
    on<ListaPackSincronizada>(_onSincronizada, transformer: droppable());
    on<BusquedaPedidoPackCambiada>(_onBusqueda);
    on<OrdenPedidosPackCambiado>(_onOrden);
    on<PropietarioPackFiltrado>(
      (e, emit) => emit(
        state.copyWith(
          propietario: e.propietario,
          limpiarPropietario: e.propietario == null,
        ),
      ),
    );
    on<SoloMisPedidosPackCambiado>(
      (e, emit) => emit(state.copyWith(soloMios: e.soloMios)),
    );
    on<ResponsablePackAsignado>(_onAsignar, transformer: droppable());
    on<InicioPedidoPackRegistrado>(_onInicio, transformer: droppable());
  }

  Future<void> _onIniciada(
    ListaPackIniciada event,
    Emitter<PackingPedidoListState> emit,
  ) async {
    emit(state.copyWith(status: ListaPackStatus.cargando));

    final config = await getConfig(NoParams());
    final local = await getPedidosLocal(NoParams());
    local.fold(
      (f) => emit(
        state.copyWith(
          status: ListaPackStatus.error,
          operacion: state.operacion.fallo('cargar', f),
        ),
      ),
      (pedidos) => emit(
        state.copyWith(
          status: ListaPackStatus.listo,
          pedidos: pedidos,
          config: config.getOrElse((_) => state.config),
        ),
      ),
    );

    // Primera vez sin datos locales: se trae de Odoo. Si el operario salió
    // de la pantalla mientras se leía SQLite, el bloc ya está cerrado y el
    // add() tiraba "Cannot add new events after calling close".
    if (!isClosing && (event.sincronizar || state.pedidos.isEmpty)) {
      add(const ListaPackSincronizada());
    }
  }

  Future<void> _onSincronizada(
    ListaPackSincronizada event,
    Emitter<PackingPedidoListState> emit,
  ) async {
    emit(
      state.copyWith(
        sincronizando: true,
        operacion: state.operacion.procesar(
          'sincronizar',
          'Actualizando pedidos...',
        ),
      ),
    );
    final r = await syncPedidos(
      const SyncPedidosPackParams(isLoadingDialog: false),
    );
    r.fold(
      (f) => emit(
        state.copyWith(
          sincronizando: false,
          status: state.pedidos.isEmpty
              ? ListaPackStatus.error
              : ListaPackStatus.listo,
          operacion: state.operacion.fallo('sincronizar', f),
        ),
      ),
      (res) => emit(
        state.copyWith(
          sincronizando: false,
          status: ListaPackStatus.listo,
          pedidos: res.pedidos,
          needUpdateVersion: res.needUpdateVersion,
          operacion: state.operacion.exito('sincronizar'),
        ),
      ),
    );
  }

  void _onBusqueda(
    BusquedaPedidoPackCambiada event,
    Emitter<PackingPedidoListState> emit,
  ) => emit(state.copyWith(query: event.query));

  void _onOrden(
    OrdenPedidosPackCambiado event,
    Emitter<PackingPedidoListState> emit,
  ) => emit(state.copyWith(orden: event.orden, ascendente: event.ascendente));

  Future<void> _onAsignar(
    ResponsablePackAsignado event,
    Emitter<PackingPedidoListState> emit,
  ) async {
    emit(
      state.copyWith(
        operacion: state.operacion.procesar('asignar', 'Asignando pedido...'),
      ),
    );
    final r = await asignarResponsable(
      AsignarResponsablePackParams(pedidoId: event.pedidoId),
    );
    r.fold(
      (f) =>
          emit(state.copyWith(operacion: state.operacion.fallo('asignar', f))),
      (pedido) => emit(
        state.copyWith(
          pedidos: [
            for (final p in state.pedidos) p.id == pedido.id ? pedido : p,
          ],
          pedidoAbierto: pedido,
          operacion: state.operacion.exito('abrir'),
        ),
      ),
    );
  }

  Future<void> _onInicio(
    InicioPedidoPackRegistrado event,
    Emitter<PackingPedidoListState> emit,
  ) async {
    emit(
      state.copyWith(
        operacion: state.operacion.procesar('inicio', 'Iniciando pedido...'),
      ),
    );
    // El tiempo es informativo: si no se puede enviar, el pedido igual se abre.
    await registrarTiempo(
      RegistrarTiempoPackParams(
        pedidoId: event.pedido.id,
        marca: MarcaTiempoPack.inicio,
      ),
    );
    final local = await getPedidosLocal(NoParams());
    final pedidos = local.getOrElse((_) => state.pedidos);
    final abierto =
        pedidos.where((p) => p.id == event.pedido.id).firstOrNull ??
        event.pedido;
    emit(
      state.copyWith(
        pedidos: pedidos,
        pedidoAbierto: abierto,
        operacion: state.operacion.exito('abrir'),
      ),
    );
  }
}
