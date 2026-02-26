// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/bloc/info_rapida_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

class ListLocationsScreen extends StatefulWidget {
  const ListLocationsScreen({super.key});

  @override
  State<ListLocationsScreen> createState() => _ListLocationsScreenState();
}

class _ListLocationsScreenState extends State<ListLocationsScreen> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InfoRapidaBloc, InfoRapidaState>(
      listener: (context, state) {
        if (state is DeviceNotAuthorized) {
          Navigator.pop(context);
          Get.defaultDialog(
            title: 'Dispositivo no autorizado',
            titleStyle: TextStyle(
                color: primaryColorApp,
                fontWeight: FontWeight.bold,
                fontSize: 16),
            middleText:
                'Este dispositivo no está autorizado para usar la aplicación. su suscripción ha expirado o no está activa, por favor contacte con el administrador.',
            middleTextStyle: TextStyle(color: black, fontSize: 14),
            backgroundColor: Colors.white,
            radius: 10,
            barrierDismissible:
                false, // Evita que se cierre al tocar fuera del diálogo
            onWillPop: () async => false,
          );
        } else if (state is NeedUpdateVersionState) {
          Get.snackbar(
            '360 Software Informa',
            'Hay una nueva versión disponible. Actualiza desde la configuración de la app, pulsando el nombre de usuario en el Home',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: Icon(Icons.error, color: Colors.amber),
            showProgressIndicator: true,
            duration: Duration(seconds: 5),
          );
        } else if (state is InfoRapidaError) {
          Navigator.pop(context);
          Get.snackbar(
            '360 Software Informa',
            'No se encontró producto, lote, paquete ni ubicación con ese código de barras',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: Icon(Icons.error, color: Colors.red),
          );
        } else if (state is InfoRapidaLoading) {
          showDialog(
            context: context,
            builder: (context) {
              return const DialogLoading(
                message: "Buscando informacion...",
              );
            },
          );
        } else if (state is InfoRapidaLoaded) {
          Navigator.pop(context);
          Get.snackbar(
            '360 Software Informa',
            'Información encontrada',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: Icon(Icons.error, color: Colors.green),
          );

          if (state.infoRapidaResult.type == 'product') {
            Navigator.pushReplacementNamed(
              context,
              'product-info',
            );
          } else if (state.infoRapidaResult.type == "ubicacion") {
            Navigator.pushReplacementNamed(context, 'location-info',
                arguments: [state.infoRapidaResult]);
          }
        }
      },
      builder: (context, state) {
        final size = MediaQuery.sizeOf(context);
        final bloc = context.read<InfoRapidaBloc>();
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Scaffold(
            backgroundColor: white,
            body: SizedBox(
                width: size.width * 1,
                height: size.height * 1,
                child: Column(
                  children: [
                    _AppBarInfo(
                      size: size,
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
                    //*barra de buscar
                    DynamicSearchBar(
                      controller: bloc.searchControllerLocation,
                      hintText: "Buscar ubicación",
                      onSearchChanged: (value) {
                        bloc.add(SearchLocationEvent(value));
                      },
                      onSearchCleared: () {
                        bloc.searchControllerLocation.clear();
                        bloc.add(SearchLocationEvent(''));

                        Future.microtask(() {
                          if (mounted) {
                            FocusScope.of(context).unfocus();
                          }
                        });
                      },
                      onTap: () {},
                    ),

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
                                      selectedIndex = isSelected ? null : index;
                                    });
                                  },
                                  child: Card(
                                    elevation: 3,
                                    color:
                                        isSelected ? Colors.green[100] : white,
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

                            FocusScope.of(context).unfocus();

                            setState(() {
                              selectedIndex == null;
                            });

                            bloc.add(GetInfoRapida(
                                selectedLocation.id.toString(),
                                true,
                                false,
                                false));
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
        );
      },
    );
  }
}

class _AppBarInfo extends StatelessWidget {
  const _AppBarInfo({
    super.key,
    required this.size,
  });

  final Size size;

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

      // ✅ Ya NO usas BlocProvider aquí
      child: BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
        builder: (context, status) {
          return Column(
            children: [
              const WarningWidgetCubit(), // Este ya usa el mismo cubit global
              Padding(
                padding: EdgeInsets.only(
                  top: status != ConnectionStatus.online ? 0 : 25,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: white),
                      onPressed: () {
                        context
                            .read<InfoRapidaBloc>()
                            .searchControllerLocation
                            .clear();

                        Navigator.pushReplacementNamed(
                          context,
                          'info-rapida',
                        );
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: size.width * 0.2),
                      child: const Text(
                        'UBICACIONES',
                        style: TextStyle(color: white, fontSize: 18),
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
                            .read<InfoRapidaBloc>()
                            .add(FilterUbicacionesAlmacenEvent(value));
                      },
                      itemBuilder: (BuildContext context) {
                        final tipos = [
                          ...context.read<UserBloc>().almacenes,
                        ];

                        return tipos.map((tipo) {
                          return PopupMenuItem<String>(
                            value: tipo.name,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.file_upload_outlined,
                                  color: primaryColorApp,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  tipo.name ?? "",
                                  style: const TextStyle(
                                      color: black, fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
