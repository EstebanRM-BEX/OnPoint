// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/presentation/providers/network/check_internet_connection.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/bloc/info_rapida_bloc.dart';
import 'package:wms_app/src/presentation/views/user/screens/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/widgets/keyboard_widget.dart';

class SearchLocationCreateMassTransfercreen extends StatefulWidget {
  const SearchLocationCreateMassTransfercreen(
      {super.key, required this.isLocationDest});
  final bool isLocationDest;

  @override
  State<SearchLocationCreateMassTransfercreen> createState() =>
      _SearchLocationScreenState();
}

class _SearchLocationScreenState
    extends State<SearchLocationCreateMassTransfercreen> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return BlocBuilder<InfoRapidaBloc, InfoRapidaState>(
      builder: (context, state) {
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
                    _AppBarInfo(size: size),
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
                                    readOnly: context
                                            .read<UserBloc>()
                                            .fabricante
                                            .contains("Zebra")
                                        ? true
                                        : false,
                                    textAlignVertical: TextAlignVertical.center,
                                    controller: bloc.searchControllerLocation,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: grey,
                                        size: 20,
                                      ),
                                      suffixIcon: IconButton(
                                          onPressed: () {
                                            // bloc.searchControllerLocation
                                            //     .clear();
                                            // bloc.add(SearchLocationEvent(
                                            //   '',
                                            // ));
                                            // bloc.add(
                                            //     ShowKeyboardCreateTransferEvent(
                                            //         false));
                                            // FocusScope.of(context).unfocus();
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
                                      bloc.add(SearchLocationEvent(
                                        value,
                                      ));
                                    },
                                    onTap: !context
                                            .read<UserBloc>()
                                            .fabricante
                                            .contains("Zebra")
                                        ? null
                                        : () {
                                            // bloc.add(
                                            //     ShowKeyboardCreateTransferEvent(
                                            //         true));
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
                            // // seleccionamos la ubicacion
                            // final selectedLocation =
                            //     bloc.ubicacionesFilters[selectedIndex!];

                            // //seleccionamos la ubicacion
                            // bloc.add(ValidateFieldsEvent(
                            //     field: widget.isLocationDest
                            //         ? "locationDest"
                            //         : "location",
                            //     isOk: true));
                            // bloc.add(ChangeLocationIsOkEvent(
                            //     selectedLocation, widget.isLocationDest));

                            // bloc.add(ShowKeyboardCreateTransferEvent(false));
                            // FocusScope.of(context).unfocus();

                            // setState(() {
                            //   selectedIndex == null;
                            // });

                            // Navigator.pushReplacementNamed(
                            //   context,
                            //   'create-transfer',
                            // );
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
                    Visibility(
                      visible: bloc.isKeyboardVisible &&
                          context.read<UserBloc>().fabricante.contains("Zebra"),
                      child: CustomKeyboard(
                        isLogin: false,
                        controller: bloc.searchControllerLocation,
                        onchanged: () {
                          bloc.add(SearchLocationEvent(
                            bloc.searchControllerLocation.text,
                          ));
                        },
                      ),
                    )
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
    required this.size,
  });

  final Size size;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
      builder: (context, connectionStatus) {
        return BlocBuilder<InfoRapidaBloc, InfoRapidaState>(
          builder: (context, state) {
            return Container(
              // padding: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                color: primaryColorApp,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              width: double.infinity,
              child: Column(
                children: [
                  const WarningWidgetCubit(), // Usa cubit global
                  Padding(
                    padding: EdgeInsets.only(
                      top: connectionStatus != ConnectionStatus.online ? 0 : 15,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: white),
                          onPressed: () {
                            // context.read<CreateTransferBloc>().add(
                            //       ShowKeyboardCreateTransferEvent(false),
                            //     );
                            Navigator.pushReplacementNamed(
                                context, 'create-mass-transfer', arguments: [
                              context.read<InfoRapidaBloc>().infoRapidaResult
                            ]);
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: size.width * 0.2),
                          child: const Text(
                            'UBICACIONES',
                            style: TextStyle(color: white, fontSize: 18),
                          ),
                        ),
                        const Spacer()
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
