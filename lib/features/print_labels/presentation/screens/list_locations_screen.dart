import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/features/printing/presentation/widgets/modal_printers_list.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/features/print_labels/presentation/bloc/print_labels_bloc.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/new_lote_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';
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

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _enterSearchMode() {
    setState(() => _isSearching = true);
    Future.microtask(() => _searchFocusNode.requestFocus());
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
      listener: (context, state) {},
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
                      DynamicSearchBar(
                        controller: bloc.searchControllerLocation,
                        focusNode: _searchFocusNode,
                        hintText: "Buscar ubicación",
                        onSearchChanged: (value) =>
                            bloc.add(SearchLocationEvent(value)),
                        onSearchCleared: () {
                          bloc.searchControllerLocation.clear();
                          bloc.add(SearchLocationEvent(''));
                          FocusScope.of(context).unfocus();
                        },
                        onTap: () {},
                      ),
                      Expanded(
                        child: Builder(builder: (context) {
                          final sorted = [...bloc.ubicacionesFilters]..sort(
                              (a, b) => (a.name ?? '').compareTo(b.name ?? ''));
                          return ListView.builder(
                            itemCount: sorted.length,
                            itemBuilder: (context, index) {
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
                                        Text(location.name ?? '',
                                            style: const TextStyle(
                                              color: primaryColorApp,
                                              fontSize: 12,
                                            )),
                                      ],
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Text(
                                          'Barcode: ',
                                          style: TextStyle(
                                              color: black, fontSize: 12),
                                        ),
                                        Text(
                                            location.barcode?.toString() ??
                                                'Sin barcode',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: primaryColorApp)),
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
                                    resIds:
                                        //todos los ids de las ubicaciones encontradas
                                        bloc.ubicacionesRange
                                            .map((e) => e.id)
                                            .toList(),
                                    companyId: 1);
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
  const _AppBarInfo({super.key, required this.size, this.isSearching = false});

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
                        context
                            .read<PrintLabelsBloc>()
                            .searchControllerLocation
                            .clear();
                        Navigator.pushReplacementNamed(context, 'print-labels');
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
          SizedBox(
            height: 40,
            child: TextField(
              controller: bloc.rangeStartController,
              inputFormatters: [
                UpperCaseTextFormatter(),
              ],
              style: TextStyle(
                color: black,
                fontSize: 10,
              ),
              decoration: InputDecoration(
                disabledBorder: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {
                    bloc.rangeStartController.clear();
                  },
                  icon: const Icon(Icons.close, color: grey),
                ),
                hintText: "Inicio",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(10),
                errorStyle: const TextStyle(color: Colors.red, fontSize: 10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: TextField(
              controller: bloc.rangeEndController,
              inputFormatters: [
                UpperCaseTextFormatter(),
              ],
              style: TextStyle(
                color: black,
                fontSize: 10,
              ),
              decoration: InputDecoration(
                disabledBorder: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {
                    bloc.rangeStartController.clear();
                  },
                  icon: const Icon(Icons.close, color: grey),
                ),
                hintText: "Inicio",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(10),
                errorStyle: const TextStyle(color: Colors.red, fontSize: 10),
              ),
            ),
          ),
          const SizedBox(height: 5),
          ElevatedButton(
            onPressed: () {
              if (bloc.ubicacionesRange.isNotEmpty) {
                bloc.ubicacionesRange = [];
                bloc.add(SearchRangeLocationEvent('', ''));
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

              if (bloc.ubicacionesRange.isNotEmpty) {
                bloc.rangeStartController.clear();
                bloc.rangeEndController.clear();
                bloc.add(SearchRangeLocationEvent('', ''));
              } else {
                FocusScope.of(context).unfocus();
                bloc.add(SearchRangeLocationEvent(
                  bloc.rangeStartController.text,
                  bloc.rangeEndController.text,
                ));
              }
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
                      trailing: GestureDetector(
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
                      onTap: () => onLocationSelected(location),
                    ),
                  );
                },
              ),
            ),
          ] else if (bloc.rangeStartController.text.isNotEmpty &&
              bloc.rangeEndController.text.isNotEmpty)
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
