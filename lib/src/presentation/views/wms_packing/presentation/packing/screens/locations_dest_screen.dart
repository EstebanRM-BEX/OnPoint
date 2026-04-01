// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';

import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/bloc/packing_pedido_bloc.dart';

class LocationDestPackingScreen extends StatefulWidget {
  const LocationDestPackingScreen({super.key});

  @override
  State<LocationDestPackingScreen> createState() => _LocationDestScreenState();
}

class _LocationDestScreenState extends State<LocationDestPackingScreen> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return BlocBuilder<PackingPedidoBloc, PackingPedidoState>(
      builder: (context, state) {
        final bloc = context.read<PackingPedidoBloc>();
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Scaffold(
            backgroundColor: primaryColorApp,
            body: SafeArea(
              child: Container(
                  color: Colors.white,
                  width: size.width * 1,
                  height: size.height * 1,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: primaryColorApp,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        width: double.infinity,
                        child: BlocBuilder<ConnectionStatusCubit,
                            ConnectionStatus>(
                          builder: (context, connectionStatus) {
                            return BlocBuilder<PackingPedidoBloc,
                                PackingPedidoState>(
                              builder: (context, state) {
                                return Column(
                                  children: [
                                    const WarningWidgetCubit(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.arrow_back,
                                              color: white),
                                          onPressed: () {
                                            Navigator.pushReplacementNamed(
                                                context,
                                                'detail-packing-pedido',
                                                arguments: [4]);
                                          },
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(
                                              left: size.width * 0.2),
                                          child: const Text(
                                            'UBICACIONES',
                                            style: TextStyle(
                                                color: white, fontSize: 18),
                                          ),
                                        ),
                                        const Spacer(),
                                        PopupMenuButton<String>(
                                          color: white,
                                          icon: const Icon(
                                            Icons.more_vert,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onSelected: (value) {
                                            context
                                                .read<PackingPedidoBloc>()
                                                .add(
                                                  FilterUbicacionesEvent(value),
                                                );
                                          },
                                          itemBuilder: (BuildContext context) {
                                            final tipos = context
                                                .read<UserBloc>()
                                                .almacenes;
                                            return tipos.map((tipo) {
                                              return PopupMenuItem<String>(
                                                value: tipo.name,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .file_upload_outlined,
                                                      color: primaryColorApp,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      tipo.name ?? "",
                                                      style: const TextStyle(
                                                        color: black,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList();
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                          bloc.selectedAlmacen == null ||
                                  bloc.selectedAlmacen == ''
                              ? 'Ubicaciones de todos los almacenes'
                              : 'Ubicaciones del almacen: ${bloc.selectedAlmacen}',
                          style: TextStyle(
                              color: black,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      SizedBox(
                          height: 55,
                          width: size.width * 1,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 10,
                              right: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: size.width * 0.9,
                                  child: Card(
                                    color: Colors.white,
                                    elevation: 3,
                                    child: TextFormField(
                                      showCursor: true,
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      controller:
                                          bloc.searchControllerLocationDest,
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(
                                          Icons.search,
                                          color: grey,
                                          size: 20,
                                        ),
                                        suffixIcon: IconButton(
                                            onPressed: () {
                                              bloc.searchControllerLocationDest
                                                  .clear();
                                              // bloc.add(SearchLocationEvent(
                                              //   '',
                                              // ));
                                              FocusScope.of(context).unfocus();
                                            },
                                            icon: const Icon(
                                              Icons.close,
                                              color: grey,
                                              size: 20,
                                            )),
                                        disabledBorder:
                                            const OutlineInputBorder(),
                                        hintText: "Buscar ubicación",
                                        hintStyle: const TextStyle(
                                            color: Colors.grey, fontSize: 14),
                                        border: InputBorder.none,
                                      ),
                                      onChanged: (value) {
                                        // bloc.add(SearchLocationEvent(
                                        //   value,
                                        // ));
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      Expanded(
                          child: ListView.builder(
                              itemCount: bloc.ubicacionesFilters.length,
                              itemBuilder: (context, index) {
                                bool isSelected = selectedIndex == index;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 0),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedIndex =
                                            isSelected ? null : index;
                                      });
                                    },
                                    child: Card(
                                      elevation: 3,
                                      color: isSelected
                                          ? Colors.green[100]
                                          : white,
                                      child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          child: SizedBox(
                                            // height: 30,
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Nombre: ',
                                                      style: TextStyle(
                                                        color: black,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    Text(
                                                      bloc
                                                              .ubicacionesFilters[
                                                                  index]
                                                              .name ??
                                                          '',
                                                      style: TextStyle(
                                                        color: primaryColorApp,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Barcode: ',
                                                      style: TextStyle(
                                                        color: black,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      bloc
                                                                  .ubicacionesFilters[
                                                                      index]
                                                                  .barcode ==
                                                              false
                                                          ? 'Sin barcode'
                                                          : bloc
                                                                  .ubicacionesFilters[
                                                                      index]
                                                                  .barcode ??
                                                              '',
                                                      style: TextStyle(
                                                        color: bloc
                                                                    .ubicacionesFilters[
                                                                        index]
                                                                    .barcode ==
                                                                false
                                                            ? red
                                                            : primaryColorApp,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Almacen: ',
                                                      style: TextStyle(
                                                        color: black,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      bloc
                                                                  .ubicacionesFilters[
                                                                      index]
                                                                  .warehouseName ==
                                                              false
                                                          ? 'Sin almacen'
                                                          : bloc
                                                                  .ubicacionesFilters[
                                                                      index]
                                                                  .warehouseName ??
                                                              '',
                                                      style: TextStyle(
                                                        color: bloc
                                                                    .ubicacionesFilters[
                                                                        index]
                                                                    .warehouseName ==
                                                                false
                                                            ? red
                                                            : primaryColorApp,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              ],
                                            ),
                                          )),
                                    ),
                                  ),
                                );
                              })),
                      const SizedBox(
                        height: 20,
                      ),
                      Visibility(
                        visible: selectedIndex != null,
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedIndex != null) {
                              // seleccionamos la ubicacion
                              final selectedLocation =
                                  bloc.ubicacionesFilters[selectedIndex!];

                              // seleccionamos la ubicacion
                              // bloc.add(SelectLocationEvent(selectedLocation));

                              FocusScope.of(context).unfocus();

                              setState(() {
                                selectedIndex == null;
                              });

                              // Navigator.pushReplacementNamed(
                              //   context,
                              //   'devoluciones-create',
                              // );
                            }
                            debugPrint(
                                "selectedUbication: ${bloc.ubicacionesFilters[selectedIndex!].toMap()}");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColorApp,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: Size(size.width * 0.9, 40),
                          ),
                          child: Text("Seleccionar",
                              style: TextStyle(
                                color: white,
                              )),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  )),
            ),
          ),
        );
      },
    );
  }
}
