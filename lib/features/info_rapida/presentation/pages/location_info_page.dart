import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/info_rapida/domain/entities/config_info_rapida_usuario.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/domain/entities/transfer_results.dart';
import 'package:wms_app/features/info_rapida/domain/failures/info_rapida_failures.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/location/location_info_bloc.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/scan/info_rapida_scan_bloc.dart';
import 'package:wms_app/features/info_rapida/presentation/pages/mass_transfer_page.dart';
import 'package:wms_app/features/info_rapida/presentation/pages/product_info_page.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/cards/location_detail_card.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/cards/mass_transfer_product_card.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_consulta_listener.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_header.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_snackbar.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/location_info_menu.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/mass_transfer_bar.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/pill_button.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/propietario_filter_sheet.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/loading_dialog_mixin.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

/// Detalle de una ubicación: datos editables, productos que contiene y
/// selección para transferencia masiva.
class LocationInfoPage extends StatelessWidget {
  final UbicacionInfo ubicacion;
  final ConfigInfoRapidaUsuario config;

  const LocationInfoPage({
    super.key,
    required this.ubicacion,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<LocationInfoBloc>()
                ..add(LocationInfoInicializado(ubicacion)),
        ),
        BlocProvider(create: (_) => getIt<InfoRapidaScanBloc>()),
      ],
      child: _LocationInfoView(ubicacion: ubicacion, config: config),
    );
  }
}

class _LocationInfoView extends StatefulWidget {
  final UbicacionInfo ubicacion;
  final ConfigInfoRapidaUsuario config;

  const _LocationInfoView({required this.ubicacion, required this.config});

  @override
  State<_LocationInfoView> createState() => _LocationInfoViewState();
}

class _LocationInfoViewState extends State<_LocationInfoView>
    with LoadingDialogMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedPropietario;

  /// Tras una transferencia masiva se consulta la ubicación destino y se
  /// abre en lugar de esta (igual que el legacy).
  bool _abrirDestinoEnLugarDeEsta = false;

  @override
  void initState() {
    super.initState();
    _cargarCampos(widget.ubicacion);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _cargarCampos(UbicacionInfo u) {
    _nameController.text = u.nombre;
    _barcodeController.text = u.codigoBarras;
  }

  List<String> _propietarios(UbicacionInfo u) {
    return u.productos
        .where(
          (p) =>
              p.manejoPropietario == true && (p.propietario ?? '').isNotEmpty,
        )
        .map((p) => p.propietario!)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> _filtrarPropietario(UbicacionInfo u) async {
    final seleccion = await showPropietarioFilterSheet(
      context,
      propietarios: _propietarios(u),
      seleccionado: _selectedPropietario,
    );
    if (seleccion == null || !mounted) return;
    setState(() => _selectedPropietario = seleccion.propietario);
  }

  void _toggleEdicion(LocationInfoState state) {
    if (!widget.config.updateLocationInventory) {
      InfoRapidaSnackbar.error('No tiene permiso para editar la ubicación');
      return;
    }
    final editar = !state.isEditing;
    if (!editar && state.ubicacion != null) _cargarCampos(state.ubicacion!);
    context.read<LocationInfoBloc>().add(
      ToggleModoEdicionUbicacionEvent(editar),
    );
  }

  void _guardar() {
    if (_nameController.text.isEmpty || _barcodeController.text.isEmpty) {
      InfoRapidaSnackbar.error('Por favor, complete todos los campos');
      return;
    }
    context.read<LocationInfoBloc>().add(
      GuardarEdicionUbicacionEvent(
        nombre: _nameController.text,
        barcode: _barcodeController.text,
      ),
    );
  }

  Future<void> _crearTransferenciaMasiva(LocationInfoState state) async {
    final ubicacion = state.ubicacion;
    if (ubicacion == null) return;
    if (state.productosSeleccionados.isEmpty) {
      InfoRapidaSnackbar.error(
        'Debe seleccionar al menos un producto para realizar la '
        'transferencia masiva',
      );
      return;
    }

    final resultado = await Navigator.of(context)
        .push<TransferenciaMasivaResult>(
          MaterialPageRoute(
            builder: (_) => MassTransferPage(
              ubicacionOrigen: ubicacion,
              productos: state.productosSeleccionados,
            ),
          ),
        );
    if (!mounted || resultado == null) return;

    final destinoId = resultado.ubicacionDestinoId;
    if (destinoId == null) return;
    _abrirDestinoEnLugarDeEsta = true;
    context.read<InfoRapidaScanBloc>().add(
      ConsultarPorIdEvent(
        id: destinoId,
        isProduct: false,
        guardarEnRecientes: false,
      ),
    );
  }

  void _onResultadoConsulta(InfoRapida info) {
    if (_abrirDestinoEnLugarDeEsta && info is UbicacionInfo) {
      _abrirDestinoEnLugarDeEsta = false;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              LocationInfoPage(ubicacion: info, config: widget.config),
        ),
      );
      return;
    }
    _abrirDestinoEnLugarDeEsta = false;
    if (info is ProductoInfo) {
      InfoRapidaSnackbar.success('Información encontrada');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ProductInfoPage(producto: info, config: widget.config),
        ),
      );
    }
  }

  void _onLocationState(BuildContext context, LocationInfoState state) {
    if (state.isSaving) {
      showLoadingDialog('Actualizando ubicación...');
    } else {
      hideLoadingDialog();
    }

    final bloc = context.read<LocationInfoBloc>();
    if (state.mensajeExito != null) {
      InfoRapidaSnackbar.success(state.mensajeExito!);
      bloc.add(const LimpiarMensajeUbicacionEvent());
    } else if (state.mensajeError != null) {
      if (state.failure is PropietarioMismatchFailure) {
        InfoRapidaSnackbar.blocked(state.mensajeError!);
      } else {
        InfoRapidaSnackbar.error(state.mensajeError!);
      }
      bloc.add(const LimpiarMensajeUbicacionEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return InfoRapidaConsultaListener(
      config: widget.config,
      onResultado: _onResultadoConsulta,
      child: MultiBlocListener(
        listeners: [
          BlocListener<LocationInfoBloc, LocationInfoState>(
            listenWhen: (previous, current) =>
                previous.ubicacion != current.ubicacion &&
                current.ubicacion != null,
            listener: (_, state) => _cargarCampos(state.ubicacion!),
          ),
          BlocListener<LocationInfoBloc, LocationInfoState>(
            listenWhen: (previous, current) =>
                previous.isSaving != current.isSaving ||
                previous.mensajeExito != current.mensajeExito ||
                previous.mensajeError != current.mensajeError,
            listener: _onLocationState,
          ),
        ],
        child: BlocBuilder<LocationInfoBloc, LocationInfoState>(
          builder: (context, state) => _buildScaffold(context, state),
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, LocationInfoState state) {
    final bloc = context.read<LocationInfoBloc>();
    final ubicacion = state.ubicacion;
    final masiva = state.modoSeleccionMasiva;

    final lista = _selectedPropietario == null
        ? state.productosFiltrados
        : state.productosFiltrados
              .where((p) => p.propietario == _selectedPropietario)
              .toList();

    final disponibles = (ubicacion?.productos ?? const []).where(
      esDisponibleParaMasiva,
    );
    final todosSeleccionados =
        disponibles.isNotEmpty &&
        disponibles.every((p) => _estaSeleccionado(state, p));

    return Scaffold(
      // Mismo color que el cuerpo: evita la franja plana detrás del status
      // bar separada del header curvo.
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          InfoRapidaHeader(
            onBack: () => Navigator.pop(context),
            trailing: LocationInfoMenu(
              isEdit: state.isEditing,
              massTransferActive: masiva,
              onEdit: () => _toggleEdicion(state),
              onToggleMassTransfer: () =>
                  bloc.add(ToggleModoSeleccionMasivaEvent(!masiva)),
            ),
          ),
          // Detalle, buscador y título quedan fijos; solo la lista de
          // productos hace scroll.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                children: [
                  if (ubicacion != null)
                    // Tope de altura: en modo edición con el teclado abierto
                    // la card dejaría sin espacio a la lista.
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight * 0.45,
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                        child: LocationDetailCard(
                          ubicacion: ubicacion,
                          isEditMode: state.isEditing,
                          nameController: _nameController,
                          barcodeController: _barcodeController,
                          onSubmitUpdate: _guardar,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                    child: DynamicSearchBar(
                      controller: _searchController,
                      hintText: 'Buscar producto o código de barras...',
                      persistentKeyboard: true,
                      onSearchChanged: (value) =>
                          bloc.add(BuscarProductosUbicacionEvent(value)),
                      onSearchCleared: () {
                        _searchController.clear();
                        bloc.add(const BuscarProductosUbicacionEvent(''));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                    child: Row(
                      children: [
                        Text(
                          'Productos',
                          style: TextStyle(
                            color: Colors.grey.shade900,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        CountBadge(count: lista.length),
                        const Spacer(),
                        if (masiva)
                          PillButton(
                            icon: todosSeleccionados
                                ? Icons.deselect
                                : Icons.select_all,
                            label: todosSeleccionados
                                ? 'Deselec. todos'
                                : 'Selec. todos',
                            onTap: () => bloc.add(
                              todosSeleccionados
                                  ? const DeseleccionarTodosProductosEvent()
                                  : const SeleccionarTodosProductosDisponiblesEvent(),
                            ),
                          ),
                        const SizedBox(width: 8),
                        PillButton(
                          icon: state.ordenAscendente
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          label: 'Ordenar',
                          onTap: () => bloc.add(
                            OrdenarProductosUbicacionEvent(
                              criterio: state.criterioOrden,
                              ascendente: !state.ordenAscendente,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: ubicacion == null
                              ? null
                              : () => _filtrarPropietario(ubicacion),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.person_search_outlined,
                              color: _selectedPropietario != null
                                  ? Colors.amber.shade800
                                  : primaryColorApp,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: lista.length,
                      itemBuilder: (context, index) {
                        final producto = lista[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: MassTransferProductCard(
                            producto: producto,
                            massTransferActive: masiva,
                            isSelected: _estaSeleccionado(state, producto),
                            onToggleSelected: (selected) => bloc.add(
                              ToggleProductoSeleccionadoEvent(
                                producto,
                                selected,
                              ),
                            ),
                            onOpenDetail: () =>
                                context.read<InfoRapidaScanBloc>().add(
                                  ConsultarPorIdEvent(
                                    id: producto.id,
                                    isProduct: true,
                                  ),
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: masiva
          ? MassTransferBar(
              count: state.totalSeleccionados,
              onTap: () => _crearTransferenciaMasiva(state),
            )
          : null,
    );
  }

  bool _estaSeleccionado(LocationInfoState state, ProductoUbicacion p) => state
      .productosSeleccionados
      .any((s) => s.id == p.id && s.loteId == p.loteId);
}
