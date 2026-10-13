import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/catalog/catalog_search_bloc.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/cards/location_list_tile.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/almacen_filter_menu.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/empty_list_message.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_header.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

/// Selección manual de la ubicación destino, para la transferencia
/// individual y la masiva (en el legacy eran dos pantallas iguales:
/// `locations_dest_widget` y `location_search_widget`).
///
/// Devuelve la [UbicacionCatalogo] elegida con `Navigator.pop`.
class LocationDestPage extends StatelessWidget {
  /// Ubicación origen: no se ofrece como destino.
  final int idUbicacionOrigen;

  const LocationDestPage({super.key, required this.idUbicacionOrigen});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<CatalogSearchBloc>()
            ..add(const CargarCatalogoUbicacionesEvent()),
      child: _LocationDestView(idUbicacionOrigen: idUbicacionOrigen),
    );
  }
}

class _LocationDestView extends StatefulWidget {
  final int idUbicacionOrigen;

  const _LocationDestView({required this.idUbicacionOrigen});

  @override
  State<_LocationDestView> createState() => _LocationDestViewState();
}

class _LocationDestViewState extends State<_LocationDestView> {
  final TextEditingController _searchController = TextEditingController();
  UbicacionCatalogo? _selected;
  Timer? _searchDebounce;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  /// Pide la página siguiente al acercarse al final de la lista.
  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300 &&
        context.read<CatalogSearchBloc>().state.hayMasUbicaciones) {
      context.read<CatalogSearchBloc>().add(
        const CargarMasUbicacionesCatalogoEvent(),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogSearchBloc, CatalogSearchState>(
      builder: (context, state) {
        final almacen = state.almacenUbicacionesFiltro;
        final ubicaciones = state.ubicacionesFiltradas
            .where((u) => u.id != widget.idUbicacionOrigen)
            .toList();

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
                        setState(() => _selected = null);
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
                          context.read<CatalogSearchBloc>().add(
                            BuscarUbicacionesCatalogoEvent(value),
                          );
                        },
                      );
                    },
                    onSearchCleared: () {
                      _searchDebounce?.cancel();
                      _searchController.clear();
                      context.read<CatalogSearchBloc>().add(
                        const BuscarUbicacionesCatalogoEvent(''),
                      );
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  Expanded(
                    child: ubicaciones.isEmpty
                        // Antes del primer resultado no se muestra "No hay
                        // ubicaciones": el "Cargando…" aparece si tarda.
                        ? state.statusUbicaciones == CatalogStatus.initial
                              ? const SizedBox.shrink()
                              : const EmptyListMessage(
                                  title: 'No hay ubicaciones',
                                  subtitle:
                                      'No tiene ubicaciones en la base de datos',
                                )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: ubicaciones.length +
                                (state.hayMasUbicaciones ? 1 : 0),
                            itemBuilder: (_, index) {
                              if (index >= ubicaciones.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              final ubicacion = ubicaciones[index];
                              final isSelected = _selected?.id == ubicacion.id;
                              return LocationListTile(
                                ubicacion: ubicacion,
                                isSelected: isSelected,
                                onTap: () => setState(
                                  () =>
                                      _selected = isSelected ? null : ubicacion,
                                ),
                              );
                            },
                          ),
                  ),
                  if (_selected != null)
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, _selected),
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
                  child: DialogLoading(message: 'Cargando ubicaciones…'),
                ),
              ),
          ],
        );
      },
    );
  }
}
