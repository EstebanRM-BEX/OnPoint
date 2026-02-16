// ignore_for_file: unrelated_type_equality_checks, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-consolidade/bloc/packing_consolidade_bloc.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

class Tab4Screen extends StatelessWidget {
  const Tab4Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BlocConsumer<PackingConsolidateBloc, PackingConsolidateState>(
      listener: (context, state) {
        if (state is ViewProductImageSuccess) {
          showImageDialog(context, state.imageUrl);
        } else if (state is ViewProductImageFailure) {
          showScrollableErrorDialog(state.error);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 5, bottom: 10),
                  // width: double.infinity,
                  // height: size.height * 0.7,
                  child: (context
                          .read<PackingConsolidateBloc>()
                          .productsDonePacking
                          .isEmpty)
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('No hay productos listos',
                                  style: TextStyle(fontSize: 14, color: grey)),
                              Text('Intente con otro pedido o batch',
                                  style: TextStyle(fontSize: 12, color: grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: context
                              .read<PackingConsolidateBloc>()
                              .productsDonePacking
                              .length,
                          itemBuilder: (context, index) {
                            final product = context
                                .read<PackingConsolidateBloc>()
                                .productsDonePacking[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: GestureDetector(
                                onTap: () {
                                  print("Producto: ${product.toJson()}");
                                },
                                child: Card(
                                    color: product.isSeparate == 1
                                        ? Colors.green[100]
                                        : Colors.white,
                                    elevation: 5,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      child: Column(
                                        children: [
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                " ${product.productId}",
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: black)),
                                          ),
                                          Card(
                                            elevation: 3,
                                            color: white,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "Certificado: ",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp,
                                                        ),
                                                      ),
                                                      Text(
                                                          product.isCertificate ==
                                                                  0
                                                              ? "No"
                                                              : "Si",
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      black)),
                                                      const Spacer(),
                                                      Text(
                                                        "Unidades: ",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp,
                                                        ),
                                                      ),
                                                      Text(
                                                          "${product.unidades}",
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      black)),
                                                    ],
                                                  ),
                                                  Visibility(
                                                    visible: product
                                                            .manejaTemperatura ==
                                                        1,
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .thermostat_outlined,
                                                          color:
                                                              primaryColorApp,
                                                          size: 16,
                                                        ),
                                                        Text(
                                                          "Temperatura: ",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                primaryColorApp,
                                                          ),
                                                        ),
                                                        Text(
                                                            "${product.temperatura}",
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        black)),
                                                        const Spacer(),
                                                        Visibility(
                                                          visible:
                                                              product.image !=
                                                                  "",
                                                          child:
                                                              GestureDetector(
                                                            onTap: () {
                                                              showImageDialog(
                                                                context,
                                                                product.image ??
                                                                    '', // URL o path de la imagen
                                                              );
                                                            },
                                                            child: Icon(
                                                              Icons.image,
                                                              color:
                                                                  primaryColorApp,
                                                              size: 23,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "Cantidad empacada: ",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp,
                                                        ),
                                                      ),
                                                      Text(
                                                          product.isCertificate ==
                                                                  0
                                                              ? "${product.quantity}"
                                                              : "${product.quantitySeparate}",
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      black)),
                                                      const Spacer(),
                                                      GestureDetector(
                                                        onTap: () {
                                                          context
                                                              .read<
                                                                  PackingConsolidateBloc>()
                                                              .add(ViewProductImageEvent(
                                                                  product.idProduct ??
                                                                      0));
                                                        },
                                                        child: Card(
                                                          //borde
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        5),
                                                          ),
                                                          elevation: 2,
                                                          color: white,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(2.0),
                                                            child: Icon(
                                                              Icons.image,
                                                              color:
                                                                  primaryColorApp,
                                                              size: 15,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "Paquete: ",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp,
                                                        ),
                                                      ),
                                                      Text(
                                                          "${product.packageName}",
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      black)),
                                                    ],
                                                  ),
                                                  if (product.observation !=
                                                      null)
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "Novedad: ",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                primaryColorApp,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width:
                                                              size.width * 0.55,
                                                          child: Text(
                                                              "${product.observation}",
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color:
                                                                          black)),
                                                        ),
                                                        const Spacer(),
                                                        Visibility(
                                                          visible: product
                                                                  .imageNovedad !=
                                                              "",
                                                          child:
                                                              GestureDetector(
                                                            onTap: () {
                                                              showImageDialog(
                                                                context,
                                                                product.imageNovedad ??
                                                                    '', // URL o path de la imagen
                                                              );
                                                            },
                                                            child: Icon(
                                                              Icons.image,
                                                              color:
                                                                  primaryColorApp,
                                                              size: 23,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  if (product.isProductSplit ==
                                                      1)
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "Novedad: ",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                primaryColorApp,
                                                          ),
                                                        ),
                                                        const Text(
                                                          "Producto en diferentes paquetes",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: black,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (product.tracking == 'lot')
                                            Row(
                                              children: [
                                                Text(
                                                  "Numero de serie/lote: ",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: primaryColorApp,
                                                  ),
                                                ),
                                                Text(" ${product.lotId}",
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black)),
                                              ],
                                            ),
                                          Row(
                                            children: [
                                              Text(
                                                "Peso: ",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: primaryColorApp,
                                                ),
                                              ),
                                              Text("${product.weight}",
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: black)),
                                            ],
                                          ),
                                          Row(
                                            children: [
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
                                                              PackingConsolidateBloc>()
                                                          .formatSecondsToHHMMSS(
                                                              (product.timeSeparate ??
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
                                        ],
                                      ),
                                    )),
                              ),
                            );
                          }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
