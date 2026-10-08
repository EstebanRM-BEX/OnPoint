import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
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

/// Búsqueda manual de productos en el catálogo local. Al seleccionar uno se
/// consulta por id y se abre su detalle.
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
  String? _selectedPropietario;

  // Debounce del buscador: no filtra toda la lista en cada tecla.
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<String> _propietarios(List<ProductoCatalogo> productos) {
    return productos
        .where((p) => p.manejoPropietario && (p.propietario ?? '').isNotEmpty)
        .map((p) => p.propietario!)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> _filtrarPropietario(List<ProductoCatalogo> productos) async {
    final seleccion = await showPropietarioFilterSheet(
      context,
      propietarios: _propietarios(productos),
      seleccionado: _selectedPropietario,
    );
    if (seleccion == null || !mounted) return;
    setState(() {
      _selectedPropietario = seleccion.propietario;
      _selectedId = null;
    });
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
        final filtrados = _selectedPropietario == null
            ? state.productosFiltrados
            : state.productosFiltrados
                  .where((p) => p.propietario == _selectedPropietario)
                  .toList();

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
                      active: _selectedPropietario != null,
                      onTap: () => _filtrarPropietario(state.productos),
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
                        ? const EmptyListMessage(
                            title: 'No hay productos',
                            subtitle: 'No tiene productos en la base de datos',
                          )
                        : ListView.builder(
                            itemCount: filtrados.length,
                            itemBuilder: (_, index) {
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
            if (state.isLoadingProductos)
              const Positioned.fill(
                child: AbsorbPointer(
                  child: DialogLoading(message: 'Cargando productos...'),
                ),
              ),
          ],
        );
      },
    );
  }
}
