// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';

class Terceroscreen extends StatefulWidget {
  const Terceroscreen({super.key});

  @override
  State<Terceroscreen> createState() => _TerceroscreenState();
}

class _TerceroscreenState extends State<Terceroscreen> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return BlocBuilder<DevolucionesBloc, DevolucionesState>(
      builder: (context, state) {
        final bloc = context.read<DevolucionesBloc>();
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
                            return BlocBuilder<DevolucionesBloc,
                                DevolucionesState>(
                              builder: (context, state) {
                                return Column(
                                  children: [
                                    const WarningWidgetCubit(),
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: connectionStatus !=
                                                ConnectionStatus.online
                                            ? 0
                                            : 35,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.arrow_back,
                                                color: white),
                                            onPressed: () {
                                              Navigator.pushReplacementNamed(
                                                context,
                                                'devoluciones-create',
                                              );
                                            },
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(
                                                left: size.width * 0.25),
                                            child: const Text(
                                              'CONTACTO',
                                              style: TextStyle(
                                                  color: white, fontSize: 18),
                                            ),
                                          ),
                                          const Spacer()
                                        ],
                                      ),
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
                                      controller: bloc.searchControllerTerceros,
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(
                                          Icons.search,
                                          color: grey,
                                          size: 20,
                                        ),
                                        suffixIcon: IconButton(
                                            onPressed: () {
                                              bloc.searchControllerTerceros
                                                  .clear();
                                              bloc.add(SearchTerceroEvent(
                                                '',
                                              ));
                                              FocusScope.of(context).unfocus();
                                            },
                                            icon: const Icon(
                                              Icons.close,
                                              color: grey,
                                              size: 20,
                                            )),
                                        disabledBorder:
                                            const OutlineInputBorder(),
                                        hintText: "Buscar proveedor",
                                        hintStyle: const TextStyle(
                                            color: Colors.grey, fontSize: 14),
                                        border: InputBorder.none,
                                      ),
                                      onChanged: (value) {
                                        bloc.add(SearchTerceroEvent(
                                          value,
                                        ));
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      Expanded(
                          child: ListView.builder(
                              itemCount: bloc.tercerosFilters.length,
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
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    bloc.tercerosFilters[index]
                                                            .name ??
                                                        '',
                                                    style: TextStyle(
                                                      color: primaryColorApp,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Documento: ',
                                                      style: TextStyle(
                                                        color: black,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      bloc
                                                                  .tercerosFilters[
                                                                      index]
                                                                  .document ==
                                                              false
                                                          ? 'Sin barcode'
                                                          : bloc
                                                                  .tercerosFilters[
                                                                      index]
                                                                  .document ??
                                                              '',
                                                      style: TextStyle(
                                                        color: bloc
                                                                    .tercerosFilters[
                                                                        index]
                                                                    .document ==
                                                                false
                                                            ? red
                                                            : primaryColorApp,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
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
                              // seleccionamos el tercero
                              final selectedTercero =
                                  bloc.tercerosFilters[selectedIndex!];
                              bloc.add(SelectTerceroEvent(selectedTercero));
                              FocusScope.of(context).unfocus();

                              setState(() {
                                selectedIndex == null;
                              });

                              Navigator.pushReplacementNamed(
                                context,
                                'devoluciones-create',
                              );
                            }
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
