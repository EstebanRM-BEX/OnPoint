import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/info_rapida/data/services/info_rapida_ws_listener.dart';
import 'package:wms_app/features/info_rapida/domain/entities/config_info_rapida_usuario.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/catalog/catalog_search_bloc.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/scan/info_rapida_scan_bloc.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/cards/product_list_tile.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/empty_list_message.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_consulta_listener.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_header.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/propietario_filter_sheet.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

/// Búsqueda manual de productos en el catálogo local (páginas consultadas en
/// SQLite). Al seleccionar uno se consulta por id y se abre su detalle.
class ListProductsPage extends StatelessWidget {
  final ConfigInfoRapidaUsuario config;

  const ListProductsPage({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<CatalogSearchBloc>()
                ..add(const CargarCatalogoProductosEvent()),
        ),
        BlocProvider(create: (_) => getIt<InfoRapidaScanBloc>()),
      ],
      child: InfoRapidaConsultaListener(
        config: config,
        child: const _ListProductsView(),
      ),
    );
  }
}

class _ListProductsView extends StatefulWidget {
  const _ListProductsView();

  @override
  State<_ListProductsView> createState() => _ListProductsViewState();
}

class _ListProductsViewState extends State<_ListProductsView> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedId;

  // Debounce del buscador: no filtra toda la lista en cada tecla.
  Timer? _searchDebounce;

  // Productos actualizados por WebSocket: se vuelve a consultar la página
  // abierta para que muestre el cambio.
  StreamSubscription<int>? _wsSubscription;
  Timer? _wsDebounce;

  @override
  void initState() {
    super.initState();
    _wsSubscription =
        getIt<InfoRapidaWsListener>().productosActualizados.listen((_) {
      _wsDebounce?.cancel();
      _wsDebounce = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          context
              .read<CatalogSearchBloc>()
              .add(const CargarCatalogoProductosEvent());
        }
      });
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _wsDebounce?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _filtrarPropietario(CatalogSearchState state) async {
    final seleccion = await showPropietarioFilterSheet(
      context,
      propietarios: state.propietarios,
      seleccionado: state.propietarioProducto,
    );
    if (seleccion == null || !mounted) return;
    setState(() => _selectedId = null);
    context.read<CatalogSearchBloc>().add(
      FiltrarProductosPorPropietarioEvent(seleccion.propietario),
    );
  }

  void _seleccionar() {
    final id = _selectedId;
    if (id == null) return;
    FocusScope.of(context).unfocus();
    context.read<InfoRapidaScanBloc>().add(
      ConsultarPorIdEvent(id: id, isProduct: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogSearchBloc, CatalogSearchState>(
      builder: (context, state) {
        final filtrados = state.productosFiltrados;
        final hayMas = state.hayMasProductos;

        return Stack(
          children: [
            Scaffold(
              backgroundColor: white,
              body: Column(
                children: [
                  InfoRapidaHeader(
                    title: 'PRODUCTOS',
                    onBack: () => Navigator.pop(context),
                    trailing: HeaderFilterButton(
                      icon: Icons.person_search_outlined,
                      active: state.propietarioProducto != null,
                      onTap: () => _filtrarPropietario(state),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DynamicSearchBar(
                    controller: _searchController,
                    hintText: 'Buscar producto',
                    // watchdog: reabre el teclado si el IME del PDA lo
                    // cierra solo.
                    persistentKeyboard: true,
                    onSearchChanged: (value) {
                      _searchDebounce?.cancel();
                      _searchDebounce = Timer(
                        const Duration(milliseconds: 200),
                        () {
                          if (!mounted) return;
                          setState(() => _selectedId = null);
                          context.read<CatalogSearchBloc>().add(
                            BuscarProductosCatalogoEvent(value),
                          );
                        },
                      );
                    },
                    onSearchCleared: () {
                      // Cancela la búsqueda pendiente para que no pise el
                      // "limpiar".
                      _searchDebounce?.cancel();
                      _searchController.clear();
                      setState(() => _selectedId = null);
                      context.read<CatalogSearchBloc>().add(
                        const BuscarProductosCatalogoEvent(''),
                      );
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  Expanded(
                    child: filtrados.isEmpty
                        // Antes del primer resultado no se muestra "No hay
                        // productos": el "Cargando…" aparece si tarda.
                        ? state.statusProductos == CatalogStatus.initial
                              ? const SizedBox.shrink()
                              : const EmptyListMessage(
                                  title: 'No hay productos',
                                  subtitle:
                                      'No tiene productos en la base de datos',
                                )
                        : ListView.builder(
                            itemCount: filtrados.length + (hayMas ? 1 : 0),
                            itemBuilder: (_, index) {
                              // Cerca del final se pide la siguiente página
                              // (el bloc descarta pedidos repetidos).
                              if (hayMas && index >= filtrados.length - 10) {
                                context.read<CatalogSearchBloc>().add(
                                  const CargarMasProductosCatalogoEvent(),
                                );
                              }
                              if (index == filtrados.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final product = filtrados[index];
                              return ProductListTile(
                                product: product,
                                isSelected: _selectedId == product.id,
                                onSelect: () =>
                                    setState(() => _selectedId = product.id),
                              );
                            },
                          ),
                  ),
                  if (_selectedId != null)
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: ElevatedButton(
                          onPressed: _seleccionar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColorApp,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: Size(
                              MediaQuery.sizeOf(context).width * 0.9,
                              40,
                            ),
                          ),
                          child: const Text(
                            'Seleccionar',
                            style: TextStyle(color: white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (state.isLoadingProductos && filtrados.isEmpty)
              const Positioned.fill(
                child: AbsorbPointer(
                  child: DialogLoading(message: 'Cargando productos…'),
                ),
              ),
          ],
        );
      },
    );
  }
}
