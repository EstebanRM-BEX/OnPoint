import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/cluster_picking/cluster_picking_bloc.dart';
import 'package:wms_app/features/user/presentation/widgets/dialog_info_widget.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/widgets/expiredate_widget.dart';
import 'package:wms_app/shared/widgets/dialog_confirm_product_load_widget.dart';

class DetailClusterScreen extends StatelessWidget {
  const DetailClusterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox(
          width: size.width,
          height: size.height * 1,
          child: Column(
            children: [
              //*appbar
              Container(
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
                            bottom: 5,
                            top: status != ConnectionStatus.online ? 20 : 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: white),
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                    context, 'scan-product-cluster');
                              },
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: size.width * 0.25),
                              child: Text(
                                  "${context.read<ClusterPickingBloc>().currentBatch?.name}",
                                  style: const TextStyle(
                                      color: white, fontSize: 12)),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),

              //lista de productos

              Expanded(
                child: context
                        .read<ClusterPickingBloc>()
                        .filteredProducts
                        .isNotEmpty
                    ? ListView.builder(
                        itemCount: context
                            .read<ClusterPickingBloc>()
                            .filteredProducts
                            .length,
                        itemBuilder: (context, index) {
                          final productsBatch = context
                              .read<ClusterPickingBloc>()
                              .filteredProducts[index];
                          return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              child: Card(
                                elevation: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: productsBatch.quantity ==
                                            productsBatch.quantitySeparate
                                        ? Colors.green[100]
                                        : productsBatch.isSelected == 1
                                            ? primaryColorApp.withOpacity(0.3)
                                            : productsBatch.isSeparate == 1
                                                ? Colors.green[100]
                                                : Colors.white,
                                  ),
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                productsBatch.productId ?? '',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: black,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            //  if (!context
                                            //                 .read<ClusterPickingBloc>()
                                            //                 .isSearch &&
                                            //             (productsBatch
                                            //                     .quantitySeparate <
                                            //                 productsBatch
                                            //                     .quantity))
                                            SizedBox(
                                              width: 50,
                                              height: 50,
                                              child: Card(
                                                elevation: 2,
                                                color: white,
                                                child: IconButton(
                                                    onPressed: () {
                                                      // showDialog(
                                                      //     context:
                                                      //         context,
                                                      //     builder:
                                                      //         (context) {
                                                      //       context
                                                      //           .read<
                                                      //               ClusterPickingBloc>()
                                                      //           .editProductController
                                                      //           .text = '';
                                                      //       return DialogEditProductWidget(
                                                      //         productsBatch:
                                                      //             productsBatch,
                                                      //       );
                                                      //     });
                                                    },
                                                    icon: Icon(Icons.edit,
                                                        size: 20,
                                                        color:
                                                            primaryColorApp)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 5),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: SvgPicture.asset(
                                                color: primaryColorApp,
                                                "assets/icons/barcode.svg",
                                                height: 20,
                                                width: 20,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(productsBatch.barcode,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: black,
                                                )),
                                            if (productsBatch.isSendOdoo != 1 &&
                                                productsBatch.isSeparate !=
                                                    1) ...[
                                              //icono de play
                                              const Spacer(),
                                              GestureDetector(
                                                onTap: () {
                                                  showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        return DialogConfirmProductLoadWidget(
                                                          productsBatch:
                                                              productsBatch,
                                                          onAccept: () {
                                                            context
                                                                .read<
                                                                    ClusterPickingBloc>()
                                                                .add(
                                                                    LoadSelectedProductEvent(
                                                                  productsBatch,
                                                                  "cluster",
                                                                ));
                                                            Navigator
                                                                .pushReplacementNamed(
                                                                    context,
                                                                    'scan-product-cluster');
                                                          },
                                                        );
                                                      });
                                                },
                                                child: Icon(
                                                  Icons.play_circle,
                                                  color: green,
                                                  size: 20,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 5),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            //icono de imagen
                                            Icon(
                                              Icons.image,
                                              color: primaryColorApp,
                                              size: 15,
                                            ),

                                            const SizedBox(width: 5),
                                            Text('Imagen del producto: ',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: black,
                                                )),
                                            GestureDetector(
                                              onTap: () {
                                                context
                                                    .read<ClusterPickingBloc>()
                                                    .add(ViewProductImageEvent(
                                                        productsBatch
                                                                .idProduct ??
                                                            0));
                                              },
                                              child: Card(
                                                //borde
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                elevation: 2,
                                                color: white,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(2.0),
                                                  child: Icon(
                                                    Icons.image,
                                                    color: primaryColorApp,
                                                    size: 15,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Visibility(
                                        visible: context
                                                .read<ClusterPickingBloc>()
                                                .configurations
                                                .result
                                                ?.result
                                                ?.showNextLocationsInDetails ==
                                            true,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                color: primaryColorApp,
                                                size: 15,
                                              ),
                                              const SizedBox(width: 5),
                                              const Text("Desde: ",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: black)),
                                              SizedBox(
                                                width: size.width * 0.57,
                                                child: Text(
                                                    productsBatch.locationId
                                                            ?.toString() ??
                                                        '',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            primaryColorApp)),
                                              ),
                                              if (productsBatch.isPending == 1)
                                                Container(
                                                  width: 30,
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                    color: Colors.amber[100],
                                                  ),
                                                  padding:
                                                      const EdgeInsets.all(3),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) {
                                                            return const DialogInfo(
                                                              title:
                                                                  "Producto pendiente",
                                                              body:
                                                                  "Este producto fue enviado al final de la lista de picking. ",
                                                            );
                                                          });
                                                    },
                                                    child: SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child: SvgPicture.asset(
                                                        color: primaryColorApp,
                                                        "assets/icons/list_final.svg",
                                                        height: 20,
                                                        width: 20,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.arrow_forward,
                                              color: primaryColorApp,
                                              size: 15,
                                            ),
                                            const SizedBox(width: 5),
                                            const Text("A:",
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: black)),
                                            const SizedBox(width: 5),
                                            SizedBox(
                                              width: size.width * 0.7,
                                              child: Text(
                                                  productsBatch.locationDestId
                                                      .toString(),
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: primaryColorApp)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Visibility(
                                        visible: productsBatch.origin != "" &&
                                            productsBatch.origin != null,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.file_open_sharp,
                                                color: primaryColorApp,
                                                size: 15,
                                              ),
                                              const SizedBox(width: 5),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text("Doc. origen: ",
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: grey)),
                                              ),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                    productsBatch.origin ?? "",
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            primaryColorApp)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.priority_high,
                                              color: primaryColorApp,
                                              size: 15,
                                            ),
                                            const SizedBox(width: 5),
                                            const Text("Priority:",
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: black)),
                                            const SizedBox(width: 5),
                                            SizedBox(
                                              width: size.width * 0.5,
                                              child: Text(
                                                  productsBatch.removalPriority
                                                      .toString(),
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: primaryColorApp)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ExpiryDateWidget(
                                          expireDate:
                                              productsBatch.expireDate == "" ||
                                                      productsBatch
                                                              .expireDate ==
                                                          null
                                                  ? DateTime.now()
                                                  : DateTime.parse(
                                                      productsBatch.expireDate),
                                          size: size,
                                          isDetaild: true,
                                          isNoExpireDate:
                                              productsBatch.expireDate == ""
                                                  ? true
                                                  : false),
                                      if (productsBatch.lotId != null &&
                                          productsBatch.lotId != "")
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.bookmarks_sharp,
                                                color: primaryColorApp,
                                                size: 15,
                                              ),
                                              const SizedBox(width: 5),
                                              const Text("Lote:",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: black)),
                                              const SizedBox(width: 5),
                                              SizedBox(
                                                width: size.width * 0.55,
                                                child: Text(
                                                    productsBatch.lotId
                                                        .toString(),
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            primaryColorApp)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      Card(
                                        elevation: 0,
                                        color: white,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 3),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.send_to_mobile_outlined,
                                                color: primaryColorApp,
                                                size: 15,
                                              ),
                                              const SizedBox(width: 5),
                                              const Text("Subido a WMS:",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: black)),
                                              const SizedBox(width: 5),
                                              SizedBox(
                                                width: size.width * 0.25,
                                                child: Text(
                                                    productsBatch.isSendOdoo ==
                                                            null
                                                        ? 'Sin enviar'
                                                        : productsBatch
                                                                    .isSendOdoo ==
                                                                1
                                                            ? 'Enviado'
                                                            : 'No enviado',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: productsBatch
                                                                    .isSendOdoo ==
                                                                null
                                                            ? primaryColorApp
                                                            : productsBatch
                                                                        .isSendOdoo ==
                                                                    1
                                                                ? green
                                                                : red)),
                                              ),
                                              if (productsBatch.isSendOdoo == 0)
                                                ElevatedButton(
                                                    onPressed: () async {
                                                      // context
                                                      //     .read<BatchBloc>()
                                                      //     .add(
                                                      //         SendProductOdooEvent(
                                                      //       productsBatch,
                                                      //       context
                                                      //           .read<
                                                      //               BatchBloc>()
                                                      //           .typePicking,
                                                      //     ));
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          primaryColorApp,
                                                      maximumSize:
                                                          const Size(80, 20),
                                                      minimumSize:
                                                          const Size(80, 20),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      elevation: 3,
                                                    ),
                                                    child: const Text(
                                                      'Enviar',
                                                      style: TextStyle(
                                                          color: white,
                                                          fontSize: 10),
                                                    )),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (productsBatch.isSeparate == 1)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: Row(
                                            children: [
                                              Icon(Icons.timer,
                                                  color: primaryColorApp,
                                                  size: 15),
                                              const SizedBox(width: 5),
                                              RichText(
                                                text: TextSpan(
                                                  children: [
                                                    const TextSpan(
                                                      text: "Tiempo total: ",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            black, // color del texto antes de tiempoTotal
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: context
                                                          .read<
                                                              ClusterPickingBloc>()
                                                          .formatSecondsToHHMMSS(
                                                              (productsBatch.timeSeparate ??
                                                                          0)
                                                                      .toDouble() ??
                                                                  0.0),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            primaryColorApp, // color rojo para tiempoTotal
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      const SizedBox(height: 5),
                                      Card(
                                        color: productsBatch.quantity ==
                                                productsBatch.quantitySeparate
                                            ? Colors.green[100]
                                            : productsBatch.quantitySeparate ==
                                                    null
                                                ? Colors.red[100]
                                                : Colors.amber[100],
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.add,
                                                    color: primaryColorApp,
                                                    size: 15,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  const Text("Unidades:",
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: black)),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                      productsBatch.quantity
                                                          .toString(),
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp)),
                                                  const Spacer(),
                                                  Icon(
                                                    Icons.check,
                                                    color: primaryColorApp,
                                                    size: 15,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  const Text("Separadas:",
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: black)),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                      productsBatch
                                                                  .quantitySeparate ==
                                                              null
                                                          ? "0"
                                                          : (productsBatch
                                                                      .quantitySeparate ??
                                                                  0.0)
                                                              .toString(),
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp)),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.assessment_outlined,
                                                    color: primaryColorApp,
                                                    size: 15,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                      "Unidad de medida: ${productsBatch.unidades ?? ''}",
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: black)),
                                                ],
                                              ),
                                              if (productsBatch.quantity !=
                                                  productsBatch
                                                      .quantitySeparate)
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.assignment_late,
                                                        color: primaryColorApp,
                                                        size: 15,
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                          "Novedad: ${productsBatch.observation ?? ''}",
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      black)),
                                                    ],
                                                  ),
                                                ),
                                              const SizedBox(height: 5),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ));
                        },
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('No hay productos en la lista',
                                style: TextStyle(
                                    fontSize: 12, color: primaryColorApp)),
                            Text('Intenta con otra búsqueda',
                                style:
                                    const TextStyle(fontSize: 12, color: grey)),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
