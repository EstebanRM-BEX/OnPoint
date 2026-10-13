import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/picking_cluster/widgets/cluster_search_dock.dart';
import 'package:wms_app/features/printing/presentation/widgets/modal_printers_list.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/features/print_labels/presentation/bloc/print_labels_bloc.dart';
import 'package:wms_app/features/print_labels/presentation/widgets/rango_ubicaciones_inputs.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';

class PrintLabelsLocationsScreen extends StatefulWidget {
  const PrintLabelsLocationsScreen({super.key});

  @override
  State<PrintLabelsLocationsScreen> createState() =>
      _PrintLabelsLocationsScreenState();
}

class _PrintLabelsLocationsScreenState
    extends State<PrintLabelsLocationsScreen> {
  ResultUbicaciones? selectedLocation;
  bool _isSearching = false;
  final FocusNode _searchFocusNode = FocusNode();
  // Lector PDA (campo invisible detrás del buscador, como en Cluster).
  final FocusNode _scannerFocusNode = FocusNode();
  final TextEditingController _scannerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _scannerFocusNode.dispose();
    _scannerController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Pide la página siguiente al acercarse al final de la lista.
  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      final bloc = context.read<PrintLabelsBloc>();
      if (bloc.hayMasUbicaciones) bloc.add(LoadMoreLocationsEvent());
    }
  }

  /// Entra con el lector activo: escanear agrega la ubicación; tocar el
  /// buscador pasa a búsqueda manual (el botón del lector se apaga).
  void _enterSearchMode() {
    setState(() => _isSearching = true);
    Future.microtask(() => _scannerFocusNode.requestFocus());
  }

  void _clearSearch(PrintLabelsBloc bloc) {
    bloc.searchControllerLocation.clear();
    bloc.add(SearchLocationEvent(''));
    _scannerFocusNode.requestFocus();
  }

  void _exitSearchMode(PrintLabelsBloc bloc) {
    bloc.searchControllerLocation.clear();
    bloc.add(SearchLocationEvent(''));
    FocusScope.of(context).unfocus();
    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PrintLabelsBloc, PrintLabelsState>(
      listener: (context, state) {
        if (state is ScanLocationAdded) {
          Get.snackbar(
            'Ubicación agregada',
            state.location.name ?? '',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.check_circle, color: Colors.green),
            duration: const Duration(seconds: 2),
          );
        } else if (state is ScanLocationNotFound) {
          Get.snackbar(
            'Ubicación no encontrada',
            'Código: ${state.barcode}',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.error, color: Colors.red),
            duration: const Duration(seconds: 2),
          );
        }
      },
      builder: (context, state) {
        final size = MediaQuery.sizeOf(context);
        final bloc = context.read<PrintLabelsBloc>();
        return WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            backgroundColor: primaryColorApp,
            body: SafeArea(
              child: Container(
                color: Colors.white,
                width: size.width,
                height: size.height,
                child: Column(
                  children: [
                    _AppBarInfo(size: size, isSearching: _isSearching),
                    if (_isSearching) ...[
                      // ── Modo búsqueda ──
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => _exitSearchMode(bloc),
                              icon: const Icon(Icons.arrow_back,
                                  color: primaryColorApp, size: 18),
                              label: const Text('Atrás',
                                  style: TextStyle(
                                      color: primaryColorApp, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      ClusterSearchDock(
                        controller: bloc.searchControllerLocation,
                        searchFocusNode: _searchFocusNode,
                        scannerFocusNode: _scannerFocusNode,
                        hintText: 'Escanear o buscar ubicación...',
                        scanner: BarcodeScannerField(
                          controller: _scannerController,
                          focusNode: _scannerFocusNode,
                          clearOnScan: true,
                          refocusOnScan: true,
                          onBarcodeScanned: (value, _) =>
                              bloc.add(ScanLocationLabelEvent(value)),
                        ),
                        onChanged: (value) =>
                            bloc.add(SearchLocationEvent(value)),
                        onCleared: () => _clearSearch(bloc),
                        onActivateScanner: () =>
                            _scannerFocusNode.requestFocus(),
                      ),
                      Expanded(
                        child: Builder(builder: (context) {
                          // Ya viene ordenada por nombre desde SQLite.
                          final sorted = bloc.ubicacionesFilters;
                          return ListView.builder(
                            controller: _scrollController,
                            itemCount: sorted.length +
                                (bloc.hayMasUbicaciones ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= sorted.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final location = sorted[index];
                              final alreadyAdded = bloc.ubicacionesRange
                                  .any((l) => l.id == location.id);
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 2),
                                child: Card(
                                  elevation: 2,
                                  child: ListTile(
                                    dense: true,
                                    title: Row(
                                      children: [
                                        Text(
                                          'Nombre: ',
                                          style: TextStyle(
                                              color: black, fontSize: 12),
                                        ),
                                        Expanded(
                                          // Nombre completo: envuelve en varias
                                          // líneas en vez de cortar con "…".
                                          child: Text(location.name ?? '',
                                              softWrap: true,
                                              style: const TextStyle(
                                                color: primaryColorApp,
                                                fontSize: 12,
                                              )),
                                        ),
                                      ],
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Text(
                                          'Barcode: ',
                                          style: TextStyle(
                                              color: black, fontSize: 12),
                                        ),
                                        Expanded(
                                          child: Text(
                                              location.barcode?.toString() ??
                                                  'Sin barcode',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: primaryColorApp)),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: Icon(
                                            alreadyAdded
                                                ? Icons.check_circle
                                                : Icons.add_circle_outline,
                                            color: alreadyAdded
                                                ? Colors.green
                                                : primaryColorApp,
                                            size: 20,
                                          ),
                                          onPressed: alreadyAdded
                                              ? () {
                                                  if (selectedLocation?.id ==
                                                      location.id) {
                                                    setState(() {
                                                      selectedLocation = null;
                                                    });
                                                  }
                                                  bloc.add(
                                                      RemoveRangeLocationEvent(
                                                          location.id!));
                                                }
                                              : () => bloc.add(
                                                  AddRangeLocationEvent(
                                                      location)),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    ] else ...[
                      // ── Modo normal ──
                      Expanded(
                        child: SingleChildScrollView(
                          child: _RangeSearchSection(
                            onLocationSelected: (location) {
                              setState(() {
                                selectedLocation =
                                    (selectedLocation?.id == location.id)
                                        ? null
                                        : location;
                              });
                            },
                            selectedLocationId: selectedLocation?.id,
                            onAddLocations: _enterSearchMode,
                          ),
                        ),
                      ),
                      if (bloc.ubicacionesRange.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              //validamso que tengamos ubicaciones encontradas
                              if (bloc.ubicacionesRange.isEmpty) {
                                Get.snackbar(
                                  'Aviso',
                                  'No se encontraron ubicaciones',
                                  backgroundColor: white,
                                  colorText: primaryColorApp,
                                );
                              } else {
                                ModalPrintersList.show(context,
                                    // ids expandidos según la cantidad de cada
                                    // ubicación (se repite el id N veces)
                                    resIds: bloc.expandedLocationResIds,
                                    companyId: 1,
                                    onPrintSuccess: () =>
                                        bloc.add(ClearRangeLocationsEvent()));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColorApp,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              minimumSize: Size(size.width * 0.9, 40),
                            ),
                            child: const Text('Imprimir Etiqueta',
                                style: TextStyle(color: white)),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AppBarInfo extends StatelessWidget {
  const _AppBarInfo({required this.size, this.isSearching = false});

  final Size size;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: primaryColorApp,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      width: double.infinity,
      child: BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
        builder: (context, status) {
          return Column(
            children: [
              const WarningWidgetCubit(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!isSearching)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: white),
                      onPressed: () {
                        final bloc = context.read<PrintLabelsBloc>();
                        bloc.searchControllerLocation.clear();
                        Navigator.pushReplacementNamed(context, 'print-labels',
                            arguments: [bloc]);
                      },
                    )
                  else
                    const SizedBox(width: 48),
                  Padding(
                    padding: EdgeInsets.only(left: size.width * 0.2),
                    child: const Text(
                      'UBICACIONES',
                      style: TextStyle(color: white, fontSize: 18),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RangeSearchSection extends StatelessWidget {
  final Function(ResultUbicaciones) onLocationSelected;
  final int? selectedLocationId;
  final VoidCallback onAddLocations;

  const _RangeSearchSection({
    required this.onLocationSelected,
    required this.onAddLocations,
    this.selectedLocationId,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bloc = context.watch<PrintLabelsBloc>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Column(
        children: [
          Text("Rango de ubicaciones a imprimir",
              style: TextStyle(fontSize: 14)),
          const SizedBox(height: 5),
          const RangoUbicacionesInputs(),
          const SizedBox(height: 5),
          ElevatedButton(
            onPressed: () {
              // "Limpiar búsqueda": vacía la lista y los campos inicio/fin.
              if (bloc.ubicacionesRange.isNotEmpty) {
                bloc.add(ClearRangeLocationsEvent());
                return;
              }

              //valdiar que tengamos una ubicacion en inicio
              if (bloc.rangeStartController.text.isEmpty) {
                Get.snackbar(
                  '360 Software Informa',
                  "Ingrese una ubicación de inicio",
                  backgroundColor: white,
                  colorText: primaryColorApp,
                  icon: const Icon(Icons.error, color: Colors.red),
                );
                return;
              }
              // if (bloc.rangeEndController.text.isEmpty) {
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     SnackBar(
              //       content: Text("Ingrese una ubicación final"),
              //       backgroundColor: Colors.red,
              //     ),
              //   );
              //   return;
              // }

              FocusScope.of(context).unfocus();
              bloc.add(SearchRangeLocationEvent(
                bloc.rangeStartController.text,
                bloc.rangeEndController.text,
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  bloc.ubicacionesRange.isNotEmpty ? grey : primaryColorApp,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: Size(size.width * 1, 40),
            ),
            child: Text(
                bloc.ubicacionesRange.isNotEmpty
                    ? "Limpiar busqueda"
                    : "Buscar Rango ",
                style: TextStyle(color: white)),
          ),
          Row(
            children: [
              const SizedBox(width: 10),
            ],
          ),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: () {},
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddLocations,
                icon: const Icon(Icons.add_location_alt_outlined,
                    size: 16, color: primaryColorApp),
                label: const Text(
                  'Agregar ubicaciones',
                  style: TextStyle(color: primaryColorApp, fontSize: 11),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryColorApp),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          if (bloc.ubicacionesRange.isNotEmpty) ...[
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ubicaciones encontradas: ${bloc.ubicacionesRange.length}',
                style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                    color: primaryColorApp),
              ),
            ),
            if (bloc.rangoEnTope)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Se muestran las primeras ${PrintLabelsBloc.topeRango}: '
                  'acote el rango para ver el resto',
                  style: TextStyle(fontSize: 10, color: Colors.orange),
                ),
              ),
            const SizedBox(height: 5),
            Container(
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListView.builder(
                itemCount: bloc.ubicacionesRange.length,
                itemBuilder: (context, index) {
                  final location = bloc.ubicacionesRange[index];

                  return Card(
                    elevation: 1,
                    color: const Color.fromARGB(255, 138, 200, 238),
                    child: ListTile(
                      minTileHeight: 40,
                      dense: true,
                      title: Text(location.name ?? '',
                          style: const TextStyle(
                              color: primaryColorApp,
                              fontWeight: FontWeight.bold,
                              fontSize: 10)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Stepper de cantidad de etiquetas de la ubicación.
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => bloc.add(
                                DecrementLocationQtyEvent(location.id!)),
                            icon: const Icon(Icons.remove_circle_outline,
                                color: primaryColorApp, size: 20),
                          ),
                          SizedBox(
                            width: 22,
                            child: Text(
                              '${bloc.locationQuantities[location.id] ?? 1}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: primaryColorApp,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => bloc.add(
                                IncrementLocationQtyEvent(location.id!)),
                            icon: const Icon(Icons.add_circle,
                                color: primaryColorApp, size: 20),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                        onTap: () {
                          //mostramos un dialog para confirmar la seleciona
                          Get.dialog(
                            AlertDialog(
                              title: const Text(
                                'Confirmar selección',
                                style: TextStyle(
                                  color: primaryColorApp,
                                  fontSize: 14,
                                ),
                              ),
                              content: const Text(
                                '¿Está seguro de que desea remover esta ubicación?',
                                style: TextStyle(
                                  color: black,
                                  fontSize: 14,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Get.back();
                                  },
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      color: primaryColorApp,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Get.back();
                                    if (selectedLocationId == location.id) {
                                      onLocationSelected(location);
                                    }
                                    bloc.add(
                                      RemoveRangeLocationEvent(
                                        location.id!,
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Aceptar',
                                    style: TextStyle(
                                      color: primaryColorApp,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Icon(Icons.close, color: red, size: 16),
                          ),
                        ],
                      ),
                      onTap: () => onLocationSelected(location),
                    ),
                  );
                },
              ),
            ),
          ] else if (bloc.rangoBuscado)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('No se encontraron ubicaciones en este rango',
                  style: TextStyle(color: grey, fontSize: 12)),
            )
        ],
      ),
    );
  }
}
