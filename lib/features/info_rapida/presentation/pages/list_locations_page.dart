import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/info_rapida/domain/entities/config_info_rapida_usuario.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/catalog/catalog_search_bloc.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/scan/info_rapida_scan_bloc.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/cards/location_list_tile.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/almacen_filter_menu.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/empty_list_message.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_consulta_listener.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_header.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

/// Búsqueda manual de ubicaciones en el catálogo local, con filtro por
/// almacén. Al seleccionar una se consulta por id y se abre su detalle.
class ListLocationsPage extends StatelessWidget {
  final ConfigInfoRapidaUsuario config;

  const ListLocationsPage({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<CatalogSearchBloc>()
                ..add(const CargarCatalogoUbicacionesEvent()),
        ),
        BlocProvider(create: (_) => getIt<InfoRapidaScanBloc>()),
      ],
      child: InfoRapidaConsultaListener(
        config: config,
        child: const _ListLocationsView(),
      ),
    );
  }
}

class _ListLocationsView extends StatefulWidget {
  const _ListLocationsView();

  @override
  State<_ListLocationsView> createState() => _ListLocationsViewState();
}

class _ListLocationsViewState extends State<_ListLocationsView> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedId;
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _seleccionar() {
    final id = _selectedId;
    if (id == null) return;
    FocusScope.of(context).unfocus();
    context.read<InfoRapidaScanBloc>().add(
      ConsultarPorIdEvent(id: id, isProduct: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogSearchBloc, CatalogSearchState>(
      builder: (context, state) {
        final almacen = state.almacenUbicacionesFiltro;
        final ubicaciones = state.ubicacionesFiltradas;

        return Stack(
          children: [
            Scaffold(
              backgroundColor: white,
              body: Column(
                children: [
                  InfoRapidaHeader(
                    title: 'UBICACIONES',
                    onBack: () => Navigator.pop(context),
                    trailing: AlmacenFilterMenu(
                      almacenes: state.almacenesDisponibles,
                      seleccionado: almacen,
                      onSelected: (value) {
                        setState(() => _selectedId = null);
                        context.read<CatalogSearchBloc>().add(
                          FiltrarUbicacionesPorAlmacenEvent(value),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    almacen == null
                        ? 'Ubicaciones de todos los almacenes'
                        : 'Ubicaciones del almacen: $almacen',
                    style: const TextStyle(
                      color: black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  DynamicSearchBar(
                    controller: _searchController,
                    hintText: 'Buscar ubicación',
                    persistentKeyboard: true,
                    onSearchChanged: (value) {
                      _searchDebounce?.cancel();
                      _searchDebounce = Timer(
                        const Duration(milliseconds: 200),
                        () {
                          if (!mounted) return;
                          setState(() => _selectedId = null);
                          context.read<CatalogSearchBloc>().add(
                            BuscarUbicacionesCatalogoEvent(value),
                          );
                        },
                      );
                    },
                    onSearchCleared: () {
                      _searchDebounce?.cancel();
                      _searchController.clear();
                      setState(() => _selectedId = null);
                      context.read<CatalogSearchBloc>().add(
                        const BuscarUbicacionesCatalogoEvent(''),
                      );
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  Expanded(
                    child: ubicaciones.isEmpty
                        ? const EmptyListMessage(
                            title: 'No hay ubicaciones',
                            subtitle:
                                'No tiene ubicaciones en la base de datos',
                          )
                        : ListView.builder(
                            itemCount: ubicaciones.length,
                            itemBuilder: (_, index) {
                              final ubicacion = ubicaciones[index];
                              final isSelected = _selectedId == ubicacion.id;
                              return LocationListTile(
                                ubicacion: ubicacion,
                                isSelected: isSelected,
                                onTap: () => setState(
                                  () => _selectedId = isSelected
                                      ? null
                                      : ubicacion.id,
                                ),
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
            if (state.isLoadingUbicaciones)
              const Positioned.fill(
                child: AbsorbPointer(
                  child: DialogLoading(message: 'Cargando ubicaciones...'),
                ),
              ),
          ],
        );
      },
    );
  }
}
