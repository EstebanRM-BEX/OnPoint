// ignore_for_file: use_build_context_synchronously, use_super_parameters, unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/presentation/providers/network/check_internet_connection.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/models/info_rapida_model.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/bloc/info_rapida_bloc.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/widgets/info_widget.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/widgets/keyboard_numbers_widget.dart';
import 'package:wms_app/src/presentation/widgets/keyboard_widget.dart';

class PaqueteInfoScreen extends StatelessWidget {
  final InfoRapidaResult? infoRapidaResult;

  const PaqueteInfoScreen({Key? key, this.infoRapidaResult}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // barcodeController

    final size = MediaQuery.sizeOf(context);
    return BlocConsumer<InfoRapidaBloc, InfoRapidaState>(
      listener: (context, state) {},
      builder: (context, state) {
        final bloc = context.read<InfoRapidaBloc>();
        final paquete = bloc.infoRapidaResult.result;

        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Scaffold(
            backgroundColor: white,
            bottomNavigationBar: bloc.isKeyboardVisible &&
                    context.read<UserBloc>().fabricante.contains("Zebra")
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: bloc.isNumericKeyboardType
                        ? CustomKeyboardNumber(
                            controller: bloc.controllerActivo!,
                            onchanged: () {},
                          )
                        : CustomKeyboard(
                            isLogin: false,
                            controller: bloc.controllerActivo!,
                            onchanged: () {},
                          ))
                : null,
            body: SizedBox(
              width: size.width * 1,
              height: size.height * 1,
              child: Column(
                children: [
                  AppBar(size: size),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: SizedBox(
                      width: size.width * 1,
                      child: Card(
                        elevation: 3,
                        color: white,
                        child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                // ProductInfoRow(
                                //   title: 'Nombre: ',
                                //   value: '${paquete?.nombre}',
                                // ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    paquete?.nombre ?? 'Sin nombre',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        color: primaryColorApp,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Divider(
                                  color: black,
                                  thickness: 1,
                                  height: 5,
                                ),
                                Row(
                                  children: [
                                    //icono de codigo de barras
                                    Icon(
                                      Icons.qr_code,
                                      color: primaryColorApp,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 5),
                                    ProductInfoRow(
                                      title: 'Código de barras: ',
                                      value: '${paquete?.codigoBarras}',
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    //icono de mas
                                    Icon(
                                      Icons.add,
                                      color: primaryColorApp,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 5),
                                    ProductInfoRow(
                                      title: 'Total de productos: ',
                                      value: '${paquete?.numeroProductos}',
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    //icono de mas
                                    Icon(
                                      Icons.add,
                                      color: primaryColorApp,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 5),
                                    ProductInfoRow(
                                      title: 'Total de unidades: ',
                                      value: '${paquete?.totalProductos}',
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    //icono de certificado
                                    Icon(
                                      Icons.verified,
                                      color: primaryColorApp,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 5),
                                    ProductInfoRow(
                                      title: 'Paquete certificado: ',
                                      value: '${paquete?.isCertificate}',
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    //icono de almacen
                                    Icon(
                                      Icons.store,
                                      color: primaryColorApp,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 5),
                                    ProductInfoRow(
                                      title: 'Almacen: ',
                                      value: '${paquete?.nombreAlmacen}',
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    //icono de fecha
                                    Icon(
                                      Icons.calendar_month,
                                      color: primaryColorApp,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 5),

                                    ProductInfoRow(
                                      title: 'Fecha de empaquetado: ',
                                      value: '${paquete?.fechaEmpaquetado}',
                                    ),
                                  ],
                                ),
                              ],
                            )),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Productos",
                        style: TextStyle(
                            color: black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  //listado de ubicaciones
                  Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ListView.builder(
                            padding: const EdgeInsets.all(0),
                            itemCount: paquete?.productos?.length ?? 0,
                            itemBuilder: (context, index) {
                              final producto = paquete?.productos?[index];
                              return Card(
                                  color: white,
                                  elevation: 3,
                                  child: ListTile(
                                    title: Text(
                                      producto?.producto ?? 'Sin nombre',
                                      style: TextStyle(
                                          color: primaryColorApp,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      children: [
                                        Row(
                                          children: [
                                            //icono de mas
                                            Icon(
                                              Icons.add,
                                              color: primaryColorApp,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 5),
                                            ProductInfoRow(
                                              title: 'Cantidad: ',
                                              value: '${producto?.cantidad}',
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            //icono de unidad de medida
                                            Icon(
                                              Icons.straighten,
                                              color: primaryColorApp,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 5),
                                            ProductInfoRow(
                                              title: 'Unidad medida: ',
                                              value: producto?.unidadMedida ==
                                                      false
                                                  ? 'Sin unidad medida'
                                                  : '${producto?.unidadMedida}',
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            //icono de codigo de barras
                                            Icon(
                                              Icons.qr_code,
                                              color: primaryColorApp,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 5),
                                            ProductInfoRow(
                                              title: 'Barcode: ',
                                              value: producto?.codigoBarras ==
                                                      false
                                                  ? 'Sin barcode'
                                                  : '${producto?.codigoBarras}',
                                            ),
                                          ],
                                        ),
                                        Visibility(
                                          visible: producto?.lote != "" &&
                                              producto?.lote != null,
                                          child: Row(
                                            children: [
                                              //icono de lote
                                              Icon(
                                                Icons.inventory_2,
                                                color: primaryColorApp,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 5),
                                              ProductInfoRow(
                                                title: 'Lote: ',
                                                value: producto?.lote == false
                                                    ? 'Sin lote'
                                                    : '${producto?.lote}',
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            //icono de tercero
                                            Icon(
                                              Icons.person,
                                              color: primaryColorApp,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              'Contacto: ',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: primaryColorApp),
                                            ),
                                            Flexible(
                                              child: Text(
                                                producto?.tercero == false
                                                    ? 'Sin tercero'
                                                    : '${producto?.tercero}',
                                                style: TextStyle(
                                                    fontSize: 12, color: black),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.list_alt,
                                              color: primaryColorApp,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 5),
                                            ProductInfoRow(
                                              title: '',
                                              value: producto?.pedido == false
                                                  ? 'Sin pedido'
                                                  : '${producto?.pedido}',
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.receipt,
                                              color: primaryColorApp,
                                              size: 15,
                                            ),
                                            const SizedBox(width: 5),
                                            ProductInfoRow(
                                              title: 'Doc. origin: ',
                                              value: producto?.origin == false
                                                  ? 'Sin origen'
                                                  : '${producto?.origin}',
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.inventory,
                                              color: primaryColorApp,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 5),
                                            ProductInfoRow(
                                              title: 'Numero de caja: ',
                                              value: producto?.numeroCaja ==
                                                      false
                                                  ? 'Sin numero de caja'
                                                  : '${producto?.numeroCaja}',
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person,
                                              color: primaryColorApp,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 5),
                                            ProductInfoRow(
                                              title: 'Empaquetado por: ',
                                              value: producto?.operador == false
                                                  ? 'Sin operador'
                                                  : '${producto?.operador}',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ));
                            })),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void getInfoProduct(String id, BuildContext context) {
    context
        .read<InfoRapidaBloc>()
        .add(GetInfoRapida(id.toUpperCase(), true, true, false));
  }
}

class AppBar extends StatelessWidget {
  const AppBar({
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
      child: BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
          builder: (context, status) {
        return Column(
          children: [
            const WarningWidgetCubit(),
            Padding(
              padding: EdgeInsets.only(
                  left: size.width * 0.05,
                  right: size.width * 0.05,
                  bottom: 10,
                  top: status != ConnectionStatus.online ? 0 : 35),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      context.read<InfoRapidaBloc>().add(IsEditEvent(false));
                      context.read<InfoRapidaBloc>().add(ShowKeyboardInfoEvent(
                          false, TextEditingController()));
                      context
                          .read<InfoRapidaBloc>()
                          .add(GetListLocationsEvent());
                      Navigator.pushReplacementNamed(
                        context,
                        'info-rapida',
                      );
                    },
                    child: Icon(
                      Icons.arrow_back,
                      color: white,
                      size: 20,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: size.width * 0.1),
                    child: const Text("INFORMACIÓN RÁPIDA",
                        style: TextStyle(color: white, fontSize: 18)),
                  ),
                  const Spacer(),
                  Visibility(
                    visible: context
                            .read<InfoRapidaBloc>()
                            .configurations
                            .result
                            ?.result
                            ?.updateLocationInventory ==
                        true,
                    child: GestureDetector(
                      onTap: () {
                        context.read<InfoRapidaBloc>().add(IsEditEvent(
                            !context.read<InfoRapidaBloc>().isEdit));
                        context.read<InfoRapidaBloc>().add(
                            ShowKeyboardInfoEvent(
                                false, TextEditingController()));
                      },
                      child: Icon(
                        context.read<InfoRapidaBloc>().isEdit
                            ? Icons.close
                            : Icons.edit,
                        color: white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
