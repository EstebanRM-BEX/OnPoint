import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/routes/app_router.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_detail.dart';
import 'package:wms_app/features/expedition/domain/entities/item_suelto_expedicion.dart';
import 'package:wms_app/features/expedition/domain/entities/paquete_expedicion.dart';
import 'package:wms_app/features/expedition/presentation/bloc/detail/expedicion_detail_bloc.dart';
import 'package:wms_app/features/expedition/presentation/bloc/scan/expedicion_scan_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/features/expedition/presentation/widgets/dialog_validar_expedicion_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_item_suelto_row_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_paquete_row_widget.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

/// Tab "Por hacer": paquetes e items sueltos aún no validados. Tocar uno
/// navega a scan_product_screen para validarlo de a uno.
///
/// Con el permiso `allow_validate_multiple` además aparece un checkbox por
/// fila (y un "seleccionar todos"): al marcar 2 o más, un FAB valida toda la
/// selección de una sola vez, sin pasar por scan_product_screen.
///
/// Incluye buscador (por nombre/código/barcode) y escaneo (por
/// packing_barcode en paquetes, barcode en productos sueltos) que hacen lo
/// mismo que un tap — misma funcionalidad que tab2.dart de packing.
class ExpedicionDetailTabPorHacer extends StatefulWidget {
  final ExpedicionDetail detail;

  const ExpedicionDetailTabPorHacer({super.key, required this.detail});

  @override
  State<ExpedicionDetailTabPorHacer> createState() =>
      _ExpedicionDetailTabPorHacerState();
}

class _ExpedicionDetailTabPorHacerState
    extends State<ExpedicionDetailTabPorHacer> {
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _scanFocusNode = FocusNode();
  final TextEditingController _scanController = TextEditingController();

  bool _isSearchVisible = false;
  String _searchQuery = '';

  /// packing_id de lo seleccionado. Paquetes y sueltos van por separado
  /// porque, aunque el backend recibe todos los packing_id juntos, cada tipo
  /// se marca en su propia tabla de SQLite.
  final Set<int> _selectedPaquetes = {};
  final Set<int> _selectedItemsSueltos = {};

  int get _totalSeleccionados =>
      _selectedPaquetes.length + _selectedItemsSueltos.length;

  /// El FAB de validación masiva aparece recién con 2 o más seleccionados:
  /// para validar uno solo ya está el flujo normal de scan_product_screen.
  bool get _puedeValidarSeleccion => _totalSeleccionados >= 2;

  /// El permiso vive en SQLite (tbl_configurations), no en UserBloc — ese
  /// bloc solo se carga si el usuario entra manualmente a "información del
  /// usuario" en Home, así que leerlo de ahí lo dejaba siempre en null y los
  /// checkboxes nunca aparecían (mismo caso que tab_detalles). Por eso
  /// list_expedition_screen.dart dispara LoadUserInfoEvent al entrar a la
  /// lista, para que la tabla ya esté poblada al llegar acá — pero ese fetch
  /// es asíncrono y nada garantiza que termine antes de que el usuario
  /// navegue al detalle. Si _cargarPermiso corre antes de que ese fetch
  /// escriba en SQLite, lee el valor viejo y se queda así para siempre (el
  /// tab no vuelve a consultar). El BlocListener<UserBloc> de abajo cierra
  /// esa ventana: cuando el fetch efectivamente termina (UserLoaded), vuelve
  /// a evaluar el permiso con el dato fresco que ya trae en memoria.
  bool _allowValidateMultiple = false;

  @override
  void initState() {
    super.initState();
    _cargarPermiso();
  }

  Future<void> _cargarPermiso() async {
    final userId = await PrefUtils.getUserId();
    final config =
        await DataBaseSqlite().configurationsRepository.getConfiguration(userId);
    if (!mounted) return;
    setState(() {
      _allowValidateMultiple =
          config?.result?.result?.allowValidateMultiple == true;
    });
  }

  void _actualizarPermisoDesdeUserBloc(UserState state) {
    if (state is! UserLoaded) return;
    final permiso =
        state.configuration.result?.result?.allowValidateMultiple == true;
    if (permiso == _allowValidateMultiple) return;
    setState(() => _allowValidateMultiple = permiso);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No robar foco si hay un dialog o scan_product_screen encima de esta
    // pantalla (si no, su propio escáner recapturaba el mismo código y
    // navegaba de nuevo, acumulando screens en el árbol).
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;
    // Mientras el buscador está visible no le robamos el foco al campo de
    // escaneo (mismo guard que tab2.dart de packing).
    if (_isSearchVisible) return;
    FocusScope.of(context).requestFocus(_scanFocusNode);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scanController.dispose();
    _scanFocusNode.dispose();
    super.dispose();
  }

  /// Al salir de esta pantalla a otra se descarta lo seleccionado: al volver,
  /// la lista ya pudo cambiar (lo validado se fue al tab "Listo") y arrastrar
  /// la selección vieja llevaría a validar algo que ya no corresponde.
  void _limpiarSeleccion() {
    if (_totalSeleccionados == 0) return;
    setState(() {
      _selectedPaquetes.clear();
      _selectedItemsSueltos.clear();
    });
  }

  void _toggleSearch() {
    setState(() => _isSearchVisible = !_isSearchVisible);
    if (!_isSearchVisible) {
      _searchController.clear();
      setState(() => _searchQuery = '');
      Future.microtask(() => _scanFocusNode.requestFocus());
    }
  }

  Future<void> _navigateToPaquete(
      BuildContext context, PaqueteExpedicion paquete) async {
    _limpiarSeleccion();
    final result = await Navigator.pushNamed(
        context, AppRoutes.scanProductExpedition,
        arguments: [paquete]);
    if (result == true && context.mounted) _refreshDetail(context);
  }

  Future<void> _navigateToItemSuelto(
      BuildContext context, ItemSueltoExpedicion item) async {
    _limpiarSeleccion();
    final result = await Navigator.pushNamed(
        context, AppRoutes.scanProductExpedition,
        arguments: [null, item]);
    if (result == true && context.mounted) _refreshDetail(context);
  }

  void _refreshDetail(BuildContext context) {
    final expeditionId = widget.detail.pedido.expeditionId;
    if (expeditionId == null) return;
    context
        .read<ExpedicionDetailBloc>()
        .add(LoadExpedicionDetailEvent(expeditionId));
  }

  void _togglePaquete(int packingId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedPaquetes.add(packingId);
      } else {
        _selectedPaquetes.remove(packingId);
      }
    });
  }

  void _toggleItemSuelto(int packingId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedItemsSueltos.add(packingId);
      } else {
        _selectedItemsSueltos.remove(packingId);
      }
    });
  }

  /// Marca/desmarca todo lo que está a la vista (respeta el filtro del
  /// buscador: no selecciona lo que el usuario no está viendo).
  void _toggleSeleccionarTodos(
    List<PaqueteExpedicion> paquetes,
    List<ItemSueltoExpedicion> itemsSueltos,
  ) {
    final idsPaquetes = paquetes.map((p) => p.packingId).whereType<int>();
    final idsItems = itemsSueltos.map((i) => i.packingId).whereType<int>();
    final todosSeleccionados = _todosSeleccionados(paquetes, itemsSueltos);

    setState(() {
      if (todosSeleccionados) {
        _selectedPaquetes.removeAll(idsPaquetes);
        _selectedItemsSueltos.removeAll(idsItems);
      } else {
        _selectedPaquetes.addAll(idsPaquetes);
        _selectedItemsSueltos.addAll(idsItems);
      }
    });
  }

  bool _todosSeleccionados(
    List<PaqueteExpedicion> paquetes,
    List<ItemSueltoExpedicion> itemsSueltos,
  ) {
    final idsPaquetes = paquetes.map((p) => p.packingId).whereType<int>();
    final idsItems = itemsSueltos.map((i) => i.packingId).whereType<int>();
    if (idsPaquetes.isEmpty && idsItems.isEmpty) return false;
    return idsPaquetes.every(_selectedPaquetes.contains) &&
        idsItems.every(_selectedItemsSueltos.contains);
  }

  void _handleValidarSeleccion(BuildContext context) {
    final expeditionId = widget.detail.pedido.expeditionId;
    if (expeditionId == null) return;

    final paquetes = widget.detail.paquetesPendientes
        .where((p) => _selectedPaquetes.contains(p.packingId))
        .toList();
    final itemsSueltos = widget.detail.itemsSueltosPendientes
        .where((i) => _selectedItemsSueltos.contains(i.packingId))
        .toList();

    // El resumen solo nombra lo que realmente hay seleccionado: si no hay
    // sueltos, no se menciona "0 producto(s) suelto(s)".
    final resumen = [
      if (paquetes.isNotEmpty) '${paquetes.length} paquete(s)',
      if (itemsSueltos.isNotEmpty)
        '${itemsSueltos.length} producto(s) suelto(s)',
    ].join(' y ');

    final detalles = <String>[
      if (paquetes.isNotEmpty) ...[
        'Paquetes (${paquetes.length}):',
        ...paquetes.map((p) =>
            '  • ${p.packageName ?? "Paquete sin nombre"} — ${p.items.length} producto(s)'),
      ],
      if (paquetes.isNotEmpty && itemsSueltos.isNotEmpty) '',
      if (itemsSueltos.isNotEmpty) ...[
        'Productos sueltos (${itemsSueltos.length}):',
        ...itemsSueltos.map((i) =>
            '  • ${i.productName ?? "Producto sin nombre"} — ${i.quantity ?? 0} ${i.uom ?? ""}'.trimRight()),
      ],
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => DialogValidarExpedicionWidget(
        message: '¿Está seguro de validar $resumen?',
        details: detalles,
        onCancel: () => Navigator.pop(dialogContext),
        onAccepted: () {
          Navigator.pop(dialogContext);
          context.read<ExpedicionScanBloc>().add(
                ValidarMultipleExpedicionScanEvent(
                  expeditionId: expeditionId,
                  paquetes: paquetes,
                  itemsSueltos: itemsSueltos,
                ),
              );
        },
      ),
    );
  }

  void _handleScan(String value, BuildContext context) {
    final scan = value.trim().toLowerCase();
    _scanController.clear();
    if (scan.isEmpty) return;

    for (final paquete in widget.detail.paquetesPendientes) {
      if (paquete.packingBarcode?.toLowerCase() == scan) {
        _navigateToPaquete(context, paquete);
        Future.microtask(() => _scanFocusNode.requestFocus());
        return;
      }
    }

    for (final item in widget.detail.itemsSueltosPendientes) {
      if (item.barcode?.toLowerCase() == scan) {
        _navigateToItemSuelto(context, item);
        Future.microtask(() => _scanFocusNode.requestFocus());
        return;
      }
    }

    _showScanError();
  }

  void _showScanError() {
    _audioService.playErrorSound();
    _vibrationService.vibrate();
    Future.microtask(() => _scanFocusNode.requestFocus());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código no encontrado en la lista')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final permisoMultiple = _allowValidateMultiple;

    final paquetes = [...widget.detail.paquetesPendientes]
      ..sort((a, b) => (a.orderPacking ?? 0).compareTo(b.orderPacking ?? 0));
    final itemsSueltos = [...widget.detail.itemsSueltosPendientes]
      ..sort((a, b) => (a.orderPacking ?? 0).compareTo(b.orderPacking ?? 0));

    final paquetesFiltrados = query.isEmpty
        ? paquetes
        : paquetes
            .where((p) =>
                (p.packageName?.toLowerCase().contains(query) ?? false) ||
                (p.packingBarcode?.toLowerCase().contains(query) ?? false))
            .toList();

    final itemsFiltrados = query.isEmpty
        ? itemsSueltos
        : itemsSueltos
            .where((i) =>
                (i.productName?.toLowerCase().contains(query) ?? false) ||
                (i.productCode?.toLowerCase().contains(query) ?? false) ||
                (i.barcode?.toLowerCase().contains(query) ?? false))
            .toList();

    return MultiBlocListener(
      listeners: [
        BlocListener<UserBloc, UserState>(
          listener: (context, state) => _actualizarPermisoDesdeUserBloc(state),
        ),
        BlocListener<ExpedicionScanBloc, ExpedicionScanState>(
          listener: (context, state) {
            if (state is ExpedicionScanValidatingMultiple) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const DialogLoading(message: 'Validando selección...'),
              );
            }
            if (state is ExpedicionScanValidatedMultiple) {
              Navigator.pop(context); // cierra el diálogo de carga
              setState(() {
                _selectedPaquetes.clear();
                _selectedItemsSueltos.clear();
              });
              _refreshDetail(context);
              Get.snackbar(
                'Listo',
                'Se validaron ${state.cantidad} elemento(s)',
                backgroundColor: white,
                colorText: primaryColorApp,
                snackPosition: SnackPosition.TOP,
              );
            }
            if (state is ExpedicionScanErrorMultiple) {
              Navigator.pop(context); // cierra el diálogo de carga
              _audioService.playErrorSound();
              _vibrationService.vibrate();
              Get.snackbar(
                'Error',
                state.message,
                backgroundColor: white,
                colorText: red,
                snackPosition: SnackPosition.TOP,
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButton: (permisoMultiple && _puedeValidarSeleccion)
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  FloatingActionButton(
                    onPressed: () => _handleValidarSeleccion(context),
                    backgroundColor: primaryColorApp,
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_totalSeleccionados',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : null,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  // Seleccionar/deseleccionar todo lo visible. Se oculta
                  // mientras el buscador está activo (igual que tab2 de
                  // packing) para no pelear por el espacio.
                  if (permisoMultiple && !_isSearchVisible)
                    IconButton(
                      icon: Icon(
                        _todosSeleccionados(paquetesFiltrados, itemsFiltrados)
                            ? Icons.checklist_rtl
                            : Icons.checklist,
                        color: primaryColorApp,
                      ),
                      tooltip: 'Seleccionar todos',
                      onPressed: () => _toggleSeleccionarTodos(
                          paquetesFiltrados, itemsFiltrados),
                    ),
                  if (_isSearchVisible)
                    Expanded(
                      child: DynamicSearchBar(
                        controller: _searchController,
                        hintText: 'Buscar producto o paquete',
                        onSearchChanged: (value) =>
                            setState(() => _searchQuery = value),
                        onSearchCleared: () => setState(() => _searchQuery = ''),
                      ),
                    )
                  else
                    const Spacer(),
                  IconButton(
                    icon: Icon(_isSearchVisible ? Icons.close : Icons.search,
                        color: primaryColorApp),
                    onPressed: _toggleSearch,
                  ),
                ],
              ),
            ),
            BarcodeScannerField(
              controller: _scanController,
              focusNode: _scanFocusNode,
              onBarcodeScanned: (value, context) => _handleScan(value, context),
            ),
            Expanded(
              child: paquetesFiltrados.isEmpty && itemsFiltrados.isEmpty
                  ? Center(
                      child: Text(
                        query.isEmpty
                            ? 'No hay productos pendientes'
                            : 'No se encontraron resultados',
                        style: const TextStyle(color: grey, fontSize: 14),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        if (paquetesFiltrados.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            child: Text(
                              'Paquetes',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          ...paquetesFiltrados.map((p) => InkWell(
                                onTap: () => _navigateToPaquete(context, p),
                                child: ExpedicionPaqueteRowWidget(
                                  paquete: p,
                                  seleccionable: permisoMultiple,
                                  isSelected:
                                      _selectedPaquetes.contains(p.packingId),
                                  onSelectedChanged:
                                      (permisoMultiple && p.packingId != null)
                                          ? (value) =>
                                              _togglePaquete(p.packingId!, value)
                                          : null,
                                ),
                              )),
                        ],
                        if (itemsFiltrados.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            child: Text(
                              'Productos sueltos',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          ...itemsFiltrados.map((i) => InkWell(
                                onTap: () => _navigateToItemSuelto(context, i),
                                child: ExpedicionItemSueltoRowWidget(
                                  item: i,
                                  seleccionable: permisoMultiple,
                                  isSelected: _selectedItemsSueltos
                                      .contains(i.packingId),
                                  onSelectedChanged:
                                      (permisoMultiple && i.packingId != null)
                                          ? (value) => _toggleItemSuelto(
                                              i.packingId!, value)
                                          : null,
                                ),
                              )),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
