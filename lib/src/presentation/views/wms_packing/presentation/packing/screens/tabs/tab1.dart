// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/un_pack_request.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/screens/widgets/dialog_unPacking.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/bloc/packing_pedido_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/screens/widgets/others/dialog_backorder_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

class Tab1PedidoScreen extends StatelessWidget {
  const Tab1PedidoScreen({
    super.key,
  });

  void _showQRDialog(BuildContext context, String data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          title: Center(
              child: Text(
            "Información del paquete",
            style: TextStyle(
              color: primaryColorApp,
              fontSize: 16,
            ),
          )),
          content: SizedBox(
            height: 200, // Establecemos el tamaño del dialogo
            width: 200,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Esto hace que el contenido sea flexible
              children: [
                QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cerrar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocBuilder<PackingPedidoBloc, PackingPedidoState>(
        builder: (context, state) {
          final totalEnviadas = context
              .read<PackingPedidoBloc>()
              .productsDonePacking
              .map((e) => e.quantity ?? 0)
              .fold<double>(0, (a, b) => a + b);

          final pedidoCurrent =
              context.read<PackingPedidoBloc>().currentPedidoPack;
          return BlocListener<PackingPedidoBloc, PackingPedidoState>(
            listener: (context, state) {
              print('STATE : $state');
              if (state is UnPackignSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  duration: const Duration(milliseconds: 1000),
                  content: Text(state.message),
                  backgroundColor: Colors.green[200],
                ));
              }

              if (state is CreateBackOrderOrNotSuccess) {
                if (state.isBackorder) {
                  Get.snackbar("360 Software Informa", state.msg,
                      backgroundColor: white,
                      colorText: primaryColorApp,
                      icon: Icon(Icons.error, color: Colors.green));
                } else {
                  Get.snackbar("360 Software Informa", state.msg,
                      backgroundColor: white,
                      colorText: primaryColorApp,
                      icon: Icon(Icons.error, color: Colors.green));
                }
                Navigator.pushReplacementNamed(
                  context,
                  'list-packing',
                );
              }

              if (state is CreateBackOrderOrNotLoading) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return const DialogLoading(
                      message: "Validando informacion...",
                    );
                  },
                );
              }

              if (state is ValidateConfirmLoading) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return const DialogLoading(
                      message: "Validando informacion...",
                    );
                  },
                );
              }

              if (state is ValidateConfirmSuccess) {
                //volvemos a llamar las entradas que tenemos guardadas en la bd
                if (state.isBackorder) {
                  Get.snackbar("360 Software Informa", state.msg,
                      backgroundColor: white,
                      colorText: primaryColorApp,
                      icon: Icon(Icons.error, color: Colors.green));
                } else {
                  Get.snackbar("360 Software Informa", state.msg,
                      backgroundColor: white,
                      colorText: primaryColorApp,
                      icon: Icon(Icons.error, color: Colors.green));
                }

                Navigator.pushReplacementNamed(
                  context,
                  'list-packing',
                );
              }

              if (state is ValidateConfirmFailure) {
                Navigator.pop(context);

                showScrollableErrorDialog(state.error);
              }

              if (state is CreateBackOrderOrNotFailure) {
                Navigator.pop(context);

                if (state.error.contains('expiry.picking.confirmation')) {
                  Get.defaultDialog(
                    title: '360 Software Informa',
                    titleStyle: TextStyle(color: Colors.red, fontSize: 18),
                    middleText:
                        'Algunos productos tienen fecha de caducidad alcanzada.\n¿Desea continuar con la confirmacion aceptando los productos vencidos?',
                    middleTextStyle: TextStyle(color: black, fontSize: 14),
                    backgroundColor: Colors.white,
                    radius: 10,
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          context.read<PackingPedidoBloc>().add(
                              ValidateConfirmEvent(
                                  context
                                          .read<PackingPedidoBloc>()
                                          .currentPedidoPack
                                          .id ??
                                      0,
                                  state.isBackorder,
                                  false));

                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColorApp,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child:
                            Text('Continuar', style: TextStyle(color: white)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child:
                            Text('Descartar', style: TextStyle(color: white)),
                      ),
                    ],
                  );
                } else {
                  showScrollableErrorDialog(state.error);
                }
              }
            },
            child: Scaffold(
              backgroundColor: white,
              body: Column(
                children: [
                  Container(
                    height: context.read<PackingPedidoBloc>().viewDetail
                        ? size.height * 0.64
                        : size.height * 0.15,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    width: double.infinity,
                    child: Card(
                      color: Colors.white,
                      elevation: 5,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // Header con título y botón
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    pedidoCurrent.name ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: primaryColorApp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      context
                                              .read<PackingPedidoBloc>()
                                              .viewDetail
                                          ? Icons.arrow_drop_up
                                          : Icons.arrow_drop_down,
                                      color: primaryColorApp,
                                    ),
                                    onPressed: () {
                                      context.read<PackingPedidoBloc>().add(
                                          ShowDetailvent(context
                                              .read<PackingPedidoBloc>()
                                              .viewDetail));
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    iconSize: 24,
                                  ),
                                ],
                              ),

                              // Contenido colapsable
                              AnimatedSize(
                                duration: Duration(milliseconds: 300),
                                child: context
                                        .read<PackingPedidoBloc>()
                                        .viewDetail
                                    ? SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Row(
                                                children: [
                                                  Text('Prioridad: ',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp)),
                                                  Text(
                                                    pedidoCurrent.priority ==
                                                            '0'
                                                        ? 'Normal'
                                                        : 'Alta'
                                                            "",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: pedidoCurrent
                                                                  .priority ==
                                                              '0'
                                                          ? black
                                                          : red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  'Operacion: ',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: primaryColorApp),
                                                ),
                                                Text(
                                                  pedidoCurrent.pickingType ??
                                                      "",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: black),
                                                ),
                                              ],
                                            ),
                                            if (pedidoCurrent.observacion !=
                                                    null &&
                                                pedidoCurrent.observacion!
                                                    .isNotEmpty) ...[
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text("Observación: ",
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            primaryColorApp)),
                                              ),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  pedidoCurrent.observacion
                                                      .toString(),
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: black),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                            Row(
                                              children: [
                                                Text(
                                                  'Referencia: ',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: primaryColorApp),
                                                ),
                                                Text(
                                                  pedidoCurrent.referencia ??
                                                      '',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: black),
                                                ),
                                              ],
                                            ),
                                            Divider(
                                              color: black,
                                              thickness: 1,
                                              height: 5,
                                            ),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.calendar_month_sharp,
                                                    color: primaryColorApp,
                                                    size: 15,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    pedidoCurrent
                                                                .fechaCreacion !=
                                                            null
                                                        ? DateFormat(
                                                                'dd/MM/yyyy hh:mm ')
                                                            .format(DateTime.parse(
                                                                pedidoCurrent
                                                                    .fechaCreacion
                                                                    .toString()))
                                                        : "Sin fecha",
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                pedidoCurrent.proveedor == "" ||
                                                        pedidoCurrent
                                                                .proveedor ==
                                                            null
                                                    ? 'Sin proveedor'
                                                    : pedidoCurrent.proveedor ??
                                                        "",
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: pedidoCurrent
                                                                    .proveedor ==
                                                                "" ||
                                                            pedidoCurrent
                                                                    .proveedor ==
                                                                null
                                                        ? red
                                                        : primaryColorApp),
                                              ),
                                            ),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'Contacto: ',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: primaryColorApp),
                                              ),
                                            ),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                pedidoCurrent.contactoName ==
                                                            "" ||
                                                        pedidoCurrent
                                                                .contactoName ==
                                                            null
                                                    ? 'Sin contacto'
                                                    : pedidoCurrent
                                                            .contactoName ??
                                                        "",
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: pedidoCurrent
                                                                    .contactoName ==
                                                                "" ||
                                                            pedidoCurrent
                                                                    .contactoName ==
                                                                null
                                                        ? red
                                                        : black),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      'Total productos : ',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp),
                                                    )),
                                                Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      pedidoCurrent.numeroLineas
                                                          .toString(),
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: black),
                                                    )),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      'Total de unidades: ',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp),
                                                    )),
                                                Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      pedidoCurrent.numeroItems
                                                          .toString(),
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: black),
                                                    )),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  'Total productos empacados: ',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: primaryColorApp),
                                                ),
                                                Text(
                                                  context
                                                      .read<PackingPedidoBloc>()
                                                      .listOfProductos
                                                      .where((element) =>
                                                          element.isPackage ==
                                                          1)
                                                      .length
                                                      .toString(),
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: black),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  'Numero de paquetes: ',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: primaryColorApp),
                                                ),
                                                Text(
                                                  context
                                                      .read<PackingPedidoBloc>()
                                                      .packages
                                                      .length
                                                      .toString(),
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: black),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    'Destino: ',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: primaryColorApp),
                                                  ),
                                                ),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    pedidoCurrent
                                                            .locationDestName ??
                                                        '',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.person_rounded,
                                                    color: primaryColorApp,
                                                    size: 15,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    pedidoCurrent.responsable ==
                                                            false
                                                        ? 'Sin responsable'
                                                        : pedidoCurrent
                                                                .responsable ??
                                                            '',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.timer,
                                                    color: primaryColorApp,
                                                    size: 15,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    'Tiempo de inicio : ',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: primaryColorApp),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    pedidoCurrent
                                                            .startTimeTransfer ??
                                                        "",
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Visibility(
                                              visible: pedidoCurrent
                                                          .isTerminate !=
                                                      1 &&
                                                  (context
                                                              .read<
                                                                  PackingPedidoBloc>()
                                                              .configurations
                                                              .result // Asumo que .configurations existe
                                                              ?.result
                                                              ?.hideValidatePacking ??
                                                          false) ==
                                                      false,
                                              child: ElevatedButton(
                                                  onPressed: () {
                                                    if (context
                                                        .read<
                                                            PackingPedidoBloc>()
                                                        .productsDone
                                                        .isNotEmpty) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: const Text(
                                                            'No se puede confirmar un pedido con productos en proceso o listos para empaquetar',
                                                            style: TextStyle(
                                                                color: white),
                                                          ),
                                                          backgroundColor:
                                                              Colors.red[200],
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                    if (context
                                                        .read<
                                                            PackingPedidoBloc>()
                                                        .packages
                                                        .isEmpty) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: const Text(
                                                            'No se puede confirmar un pedido sin empaques',
                                                            style: TextStyle(
                                                                color: white),
                                                          ),
                                                          backgroundColor:
                                                              Colors.red[200],
                                                        ),
                                                      );
                                                      return;
                                                    }

                                                    final progress = (totalEnviadas /
                                                                context
                                                                    .read<
                                                                        PackingPedidoBloc>()
                                                                    .currentPedidoPack
                                                                    .numeroItems ??
                                                            0) *
                                                        100;

                                                    showDialog(
                                                        context: Navigator.of(
                                                                context,
                                                                rootNavigator:
                                                                    true)
                                                            .context,
                                                        builder: (context) {
                                                          return DialogBackorderPack(
                                                            totalEnviadas:
                                                                progress,
                                                            createBackorder: context
                                                                    .read<
                                                                        PackingPedidoBloc>()
                                                                    .currentPedidoPack
                                                                    .createBackorder ??
                                                                "ask",
                                                          );
                                                        });
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    minimumSize: Size(
                                                      size.width * 0.9,
                                                      30, // Alto
                                                    ),
                                                    backgroundColor:
                                                        primaryColorApp,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Confirmar pedido',
                                                    style: TextStyle(
                                                        color: white,
                                                        fontSize: 12),
                                                  )),
                                            ),
                                          ],
                                        ),
                                      )
                                    : SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!context.read<PackingPedidoBloc>().viewDetail) ...[
                    Text("Listado de empaques",
                        style: TextStyle(
                            fontSize: 14,
                            color: primaryColorApp,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(
                            left: 10, right: 2, bottom: 10, top: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child:
                            (context.read<PackingPedidoBloc>().packages.isEmpty)
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('No hay empaques',
                                            style: TextStyle(
                                                fontSize: 14, color: grey)),
                                        Text('Realiza el proceso de empaque',
                                            style: TextStyle(
                                                fontSize: 12, color: grey)),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.only(bottom: 55),
                                    itemCount: context
                                        .read<PackingPedidoBloc>()
                                        .packages
                                        .length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      final package = context
                                          .read<PackingPedidoBloc>()
                                          .packages[index];

                                      // Filtrar los productos de acuerdo al id_package del paquete actual
                                      final filteredProducts = context
                                          .read<PackingPedidoBloc>()
                                          .listOfProductos
                                          .where((product) =>
                                              product.idPackage == package.id)
                                          .toList();

                                      return Card(
                                        color: Colors.white,
                                        child: ExpansionTile(
                                          childrenPadding:
                                              const EdgeInsets.all(5),
                                          title: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${package.name}",
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: primaryColorApp),
                                              ),
                                              Text(
                                                "${package.consecutivo}",
                                                style: TextStyle(
                                                    fontSize: 10, color: black),
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    "Cantidad de productos: ${package.cantidadProductos}",
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black),
                                                  ),
                                                  const Spacer(),
                                                  GestureDetector(
                                                    onTap: () async {
                                                      var url = await PrefUtils
                                                          .getEnterprise();

                                                      url =
                                                          '$url/package/info/${package.name}';

                                                      _showQRDialog(
                                                          context, url);
                                                    },
                                                    child: Icon(
                                                      Icons.qr_code,
                                                      color: primaryColorApp,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                ],
                                              ),
                                            ],
                                          ),
                                          children: [
                                            // Aquí generamos la lista de productos filtrados
                                            SizedBox(
                                              height: 200,
                                              child: ListView.builder(
                                                itemCount: filteredProducts
                                                    .length, // La cantidad de productos filtrados
                                                itemBuilder: (context, index) {
                                                  final product =
                                                      filteredProducts[index];
                                                  return GestureDetector(
                                                    onTap: () {
                                                      print(
                                                          "info paquete: ${package.toMap()}");
                                                      print(
                                                          "--------------------");
                                                      print(
                                                          "Producto seleccionado: ${product.toMap()}");
                                                    },
                                                    child: Card(
                                                      color: white,
                                                      elevation: 2,
                                                      child: ListTile(
                                                        title: Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                  product.productId ??
                                                                      "",
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color:
                                                                          black)),
                                                            ),
                                                            if (product
                                                                    .barcode !=
                                                                null)
                                                              GestureDetector(
                                                                onTap: () {
                                                                  //validar si el producto  actual se encuentra  la lista de por hacer

                                                                  bool isInProgress = context
                                                                      .read<
                                                                          PackingPedidoBloc>()
                                                                      .listOfProductosProgress
                                                                      .any((p) =>
                                                                          p.productId ==
                                                                          product
                                                                              .productId);
                                                                  if (isInProgress) {
                                                                    Get.defaultDialog(
                                                                      title:
                                                                          '360 Software Informa',
                                                                      titleStyle: TextStyle(
                                                                          color: Colors
                                                                              .red,
                                                                          fontSize:
                                                                              18),
                                                                      middleText:
                                                                          "Este producto se encuentra en estado por hacer, por favor seleccione otro para desempacar",
                                                                      middleTextStyle: TextStyle(
                                                                          color:
                                                                              black,
                                                                          fontSize:
                                                                              14),
                                                                      backgroundColor:
                                                                          Colors
                                                                              .white,
                                                                      radius:
                                                                          10,
                                                                      actions: [
                                                                        ElevatedButton(
                                                                          onPressed:
                                                                              () {
                                                                            Get.back();
                                                                          },
                                                                          style:
                                                                              ElevatedButton.styleFrom(
                                                                            backgroundColor:
                                                                                primaryColorApp,
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(10),
                                                                            ),
                                                                          ),
                                                                          child: Text(
                                                                              'Aceptar',
                                                                              style: TextStyle(color: white)),
                                                                        ),
                                                                      ],
                                                                    );
                                                                    return;
                                                                  }
                                                                  //mensaje de confirmacion de desempacar el
                                                                  showDialog(
                                                                    context:
                                                                        context,
                                                                    builder: (_) =>
                                                                        DialogUnPacking(
                                                                      product:
                                                                          product,
                                                                      package:
                                                                          package,
                                                                      onConfirm:
                                                                          () async {
                                                                        final idOperario =
                                                                            await PrefUtils.getUserId();

                                                                        context
                                                                            .read<PackingPedidoBloc>()
                                                                            .add(UnPackingEvent(
                                                                              UnPackRequest(
                                                                                idTransferencia: package.batchId ?? 0,
                                                                                idPaquete: package.id ?? 0,
                                                                                listItems: [
                                                                                  ListItemUnpack(
                                                                                    idMove: product.idMove ?? 0,
                                                                                    observacion: "Desempacado",
                                                                                    idOperario: idOperario,
                                                                                  )
                                                                                ],
                                                                              ),
                                                                              product.pedidoId ?? 0,
                                                                              product.idProduct ?? 0,
                                                                              package.consecutivo,
                                                                            ));
                                                                      },
                                                                    ),
                                                                  );
                                                                },
                                                                child:
                                                                    const Icon(
                                                                  Icons.delete,
                                                                  color: Colors
                                                                      .red,
                                                                  size: 20,
                                                                ),
                                                              ),
                                                          ],
                                                        ), // Muestra el nombre del producto
                                                        subtitle: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                if (product
                                                                        .isCertificate !=
                                                                    0)
                                                                  RichText(
                                                                    text:
                                                                        TextSpan(
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        color: Colors
                                                                            .black,
                                                                      ),
                                                                      children: <TextSpan>[
                                                                        const TextSpan(
                                                                          text:
                                                                              "Cantidad empacada: ",
                                                                          style: TextStyle(
                                                                              fontSize: 12,
                                                                              color: black),
                                                                        ),
                                                                        TextSpan(
                                                                          text:
                                                                              (product.quantitySeparate ?? 0.0).toString(),
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                primaryColorApp,
                                                                            fontSize:
                                                                                12,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),

                                                                if (product
                                                                        .isCertificate ==
                                                                    0)
                                                                  RichText(
                                                                    text:
                                                                        const TextSpan(
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            14, // Tamaño del texto
                                                                        color: Colors
                                                                            .black, // Color del texto por defecto (puedes cambiarlo aquí)
                                                                      ),
                                                                      children: <TextSpan>[
                                                                        TextSpan(
                                                                            text:
                                                                                "Cantidad: ",
                                                                            style:
                                                                                TextStyle(fontSize: 12, color: black)), // Parte del texto en color negro (o el color que prefieras)

                                                                        TextSpan(
                                                                          text:
                                                                              "No certificado", // La cantidad en color rojo
                                                                          style: TextStyle(
                                                                              color: Colors.red,
                                                                              fontSize: 12), // Estilo solo para la cantidad
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                const SizedBox(
                                                                  width: 5,
                                                                ),
                                                                //icono de check

                                                                Visibility(
                                                                  visible: product
                                                                          .isCertificate ==
                                                                      0,
                                                                  child: const Icon(
                                                                      Icons
                                                                          .warning,
                                                                      color: Colors
                                                                          .amber,
                                                                      size: 15),
                                                                ),
                                                                //icono de check
                                                                Visibility(
                                                                  visible: product
                                                                          .isCertificate ==
                                                                      1,
                                                                  child: const Icon(
                                                                      Icons
                                                                          .check,
                                                                      color:
                                                                          green,
                                                                      size: 15),
                                                                ),
                                                                const Spacer(),
                                                                RichText(
                                                                  text:
                                                                      TextSpan(
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          14, // Tamaño del texto
                                                                      color: Colors
                                                                          .black, // Color del texto por defecto (puedes cambiarlo aquí)
                                                                    ),
                                                                    children: <TextSpan>[
                                                                      const TextSpan(
                                                                          text:
                                                                              "Unidades: ",
                                                                          style: TextStyle(
                                                                              fontSize: 12,
                                                                              color: black)), // Parte del texto en color negro (o el color que prefieras)
                                                                      TextSpan(
                                                                        text:
                                                                            "${product.unidades}", // La cantidad en color rojo
                                                                        style: TextStyle(
                                                                            color:
                                                                                primaryColorApp,
                                                                            fontSize:
                                                                                12), // Estilo solo para la cantidad
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Visibility(
                                                              visible: product
                                                                      .isCertificate ==
                                                                  0,
                                                              child: Row(
                                                                children: [
                                                                  RichText(
                                                                    text:
                                                                        TextSpan(
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            14, // Tamaño del texto
                                                                        color: Colors
                                                                            .black, // Color del texto por defecto (puedes cambiarlo aquí)
                                                                      ),
                                                                      children: <TextSpan>[
                                                                        const TextSpan(
                                                                            text:
                                                                                "Cantidad empacada: ",
                                                                            style:
                                                                                TextStyle(fontSize: 12, color: black)), // Parte del texto en color negro (o el color que prefieras)

                                                                        TextSpan(
                                                                          text: (product.quantity ?? 0.0).toString(), // La cantidad en color rojo
                                                                          style: TextStyle(
                                                                              color: primaryColorApp,
                                                                              fontSize: 12), // Estilo solo para la cantidad
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Visibility(
                                                              visible: product
                                                                      .isCertificate ==
                                                                  1,
                                                              child: Row(
                                                                children: [
                                                                  RichText(
                                                                    text:
                                                                        TextSpan(
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            14, // Tamaño del texto
                                                                        color: Colors
                                                                            .black, // Color del texto por defecto (puedes cambiarlo aquí)
                                                                      ),
                                                                      children: <TextSpan>[
                                                                        const TextSpan(
                                                                            text:
                                                                                "Novedad: ",
                                                                            style:
                                                                                TextStyle(fontSize: 12, color: black)), // Parte del texto en color negro (o el color que prefieras)

                                                                        TextSpan(
                                                                          text: product.observation == null
                                                                              ? "Sin novedad"
                                                                              : "${product.observation}", // La cantidad en color rojo
                                                                          style: TextStyle(
                                                                              color: primaryColorApp,
                                                                              fontSize: 12), // Estilo solo para la cantidad
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Visibility(
                                                              visible: product
                                                                      .manejaTemperatura ==
                                                                  1,
                                                              child: Row(
                                                                children: [
                                                                  RichText(
                                                                    text:
                                                                        TextSpan(
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            14, // Tamaño del texto
                                                                        color: Colors
                                                                            .black, // Color del texto por defecto (puedes cambiarlo aquí)
                                                                      ),
                                                                      children: <TextSpan>[
                                                                        const TextSpan(
                                                                            text:
                                                                                "Temperatura: ",
                                                                            style:
                                                                                TextStyle(fontSize: 12, color: black)), // Parte del texto en color negro (o el color que prefieras)
                                                                        TextSpan(
                                                                          text: product.temperatura == null
                                                                              ? "Sin temperatura"
                                                                              : "${product.temperatura}", // La cantidad en color rojo
                                                                          style: TextStyle(
                                                                              color: primaryColorApp,
                                                                              fontSize: 12), // Estilo solo para la cantidad
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  const Spacer(),
                                                                  Visibility(
                                                                    visible:
                                                                        product.image !=
                                                                            "",
                                                                    child:
                                                                        GestureDetector(
                                                                      onTap:
                                                                          () {
                                                                        showImageDialog(
                                                                          context,
                                                                          product.image ??
                                                                              '', // URL o path de la imagen
                                                                        );
                                                                      },
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .image,
                                                                        color:
                                                                            primaryColorApp,
                                                                        size:
                                                                            23,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ), // Muestra la cantidad
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    )
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
