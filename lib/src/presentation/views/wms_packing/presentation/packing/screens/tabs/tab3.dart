// ignore_for_file: unrelated_type_equality_checks, avoid_print

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packaging_types/domain/entities/packaging_type.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/screens/widgets/dialog_confirmated_packing_widget.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/bloc/packing_pedido_bloc.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

class Tab3PedidoScreen extends StatelessWidget {
  const Tab3PedidoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BlocConsumer<PackingPedidoBloc, PackingPedidoState>(
      listener: (context, state) {
        if (state is DeleteProductFromTemporaryPackageError) {
          showScrollableErrorDialog(state.message);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          floatingActionButton:
              context.read<PackingPedidoBloc>().productsDone.isEmpty
                  ? null
                  : Stack(
                      children: [
                        Positioned(
                          bottom:
                              0.0, // Ajusta según sea necesario para colocar en la parte inferior
                          right:
                              0.0, // Ajusta según sea necesario para colocar en la parte derecha
                          child: FloatingActionButton(
                            onPressed: context
                                    .read<PackingPedidoBloc>()
                                    .productsDone
                                    .isEmpty
                                ? null
                                : () {
                                    showDialog(
                                      context: context,
                                      builder: (_) {
                                        final bloc =
                                            context.read<PackingPedidoBloc>();
                                        return DialogConfirmatedPacking(
                                          manejaPeso: context
                                                  .read<PackingPedidoBloc>()
                                                  .currentPedidoPack
                                                  .configPacking ==
                                              "cluster",
                                          manejaTipoEmpaque: context
                                                  .read<PackingPedidoBloc>()
                                                  .currentPedidoPack
                                                  .configPacking ==
                                              "cluster",
                                          productos: context
                                              .read<PackingPedidoBloc>()
                                              .productsDone,
                                          isCertificate: true,
                                          isSticker: bloc.isSticker,
                                          onToggleSticker: (value) {
                                            bloc.add(ChangeStickerEvent(value));
                                          },
                                          onConfirm: (PackagingType? pedidoType,
                                              String weight) {
                                            bloc.add(SetPackingsEvent(
                                              context
                                                  .read<PackingPedidoBloc>()
                                                  .productsDone,
                                              bloc.isSticker,
                                              context
                                                  .read<PackingPedidoBloc>()
                                                  .currentPedidoPack
                                                  .configPacking,
                                              true,
                                              weight == "" || weight == null
                                                  ? 0.0
                                                  : double.parse(weight),
                                              pedidoType ?? PackagingType(),
                                            ));
                                          },
                                        );
                                      },
                                    );
                                  },
                            backgroundColor: primaryColorApp,
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: SvgPicture.asset(
                                color: white,
                                "assets/icons/packing.svg",
                                height: 20,
                                width: 20,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 40.0, // Posición hacia arriba
                          right: 0.0, // Posición hacia la derecha
                          child: context
                                  .read<PackingPedidoBloc>()
                                  .productsDone
                                  .isNotEmpty
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    context
                                        .read<PackingPedidoBloc>()
                                        .productsDone
                                        .length
                                        .toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : const SizedBox
                                  .shrink(), // No mostrar el número si no hay productos seleccionados
                        ),
                      ],
                    ),
          body: Column(
            children: [
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(top: 5, bottom: 10),
                  // width: double.infinity,
                  // height: size.height * 0.7,
                  child: (context
                          .read<PackingPedidoBloc>()
                          .productsDone
                          .isEmpty)
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('No hay productos preparados',
                                  style: TextStyle(fontSize: 14, color: grey)),
                              Text('Intente con otro pedido o batch',
                                  style: TextStyle(fontSize: 12, color: grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: context
                              .read<PackingPedidoBloc>()
                              .productsDone
                              .length,
                          itemBuilder: (context, index) {
                            final product = context
                                .read<PackingPedidoBloc>()
                                .productsDone[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: GestureDetector(
                                onTap: () {
                                  debugPrint("Producto: ${product.toJson()}");
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
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      "${product.productId}",
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: black)),
                                                ),
                                              ),
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    //dialogo de confirmacion
                                                    showDialog(
                                                        context: context,
                                                        builder:
                                                            (_) =>
                                                                BackdropFilter(
                                                                  filter: ImageFilter
                                                                      .blur(
                                                                          sigmaX:
                                                                              5,
                                                                          sigmaY:
                                                                              5),
                                                                  child:
                                                                      AlertDialog(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .white,
                                                                    actionsAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    title:
                                                                        Center(
                                                                      child:
                                                                          Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          SizedBox(
                                                                            height:
                                                                                100,
                                                                            width:
                                                                                200,
                                                                            child:
                                                                                SvgPicture.asset(
                                                                              "assets/images/icono.svg",
                                                                              height: 150,
                                                                              width: 50,
                                                                              fit: BoxFit.cover,
                                                                            ),
                                                                          ),
                                                                          Align(
                                                                            alignment:
                                                                                Alignment.center,
                                                                            child:
                                                                                RichText(
                                                                              textAlign: TextAlign.center,
                                                                              text: TextSpan(
                                                                                children: [
                                                                                  TextSpan(
                                                                                    text: '¿Está seguro de eliminar el producto del paquete temporal: ',
                                                                                    style: TextStyle(
                                                                                      color: primaryColorApp,
                                                                                      fontSize: 16,
                                                                                    ),
                                                                                  ),
                                                                                  TextSpan(
                                                                                    text: '${product.productId}?',
                                                                                    style: const TextStyle(
                                                                                      color: red,
                                                                                      fontSize: 16,
                                                                                      fontWeight: FontWeight.bold,
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    content:
                                                                        const Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        Align(
                                                                          alignment:
                                                                              Alignment.center,
                                                                          child:
                                                                              Text(
                                                                            "El producto será eliminado y volverá al listado de por hacer.",
                                                                            style:
                                                                                TextStyle(color: black, fontSize: 12),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    actions: [
                                                                      ElevatedButton(
                                                                        onPressed:
                                                                            () =>
                                                                                Navigator.pop(context),
                                                                        style: ElevatedButton
                                                                            .styleFrom(
                                                                          backgroundColor:
                                                                              grey,
                                                                          shape:
                                                                              RoundedRectangleBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(10),
                                                                          ),
                                                                        ),
                                                                        child:
                                                                            const Text(
                                                                          'Cancelar',
                                                                          style:
                                                                              TextStyle(color: Colors.white),
                                                                        ),
                                                                      ),
                                                                      ElevatedButton(
                                                                        onPressed:
                                                                            () {
                                                                          context
                                                                              .read<PackingPedidoBloc>()
                                                                              .add(DeleteProductFromTemporaryPackageEvent(product: product));
                                                                          Navigator.pop(
                                                                              context);
                                                                        },
                                                                        style: ElevatedButton
                                                                            .styleFrom(
                                                                          backgroundColor:
                                                                              primaryColorApp,
                                                                          shape:
                                                                              RoundedRectangleBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(10),
                                                                          ),
                                                                        ),
                                                                        child:
                                                                            const Text(
                                                                          'Aceptar',
                                                                          style:
                                                                              TextStyle(color: Colors.white),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ));
                                                  },
                                                  child: Icon(
                                                    Icons.delete,
                                                    color: red,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          Card(
                                            elevation: 3,
                                            color: product.quantity ==
                                                    product.quantitySeparate
                                                ? white
                                                : Colors.amber[100],
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    children: [
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
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "Cantidad a empacar: ",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp,
                                                        ),
                                                      ),
                                                      Text(
                                                          "${product.quantitySeparate}",
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
                                                            1 ||
                                                        product.manejaTemperatura ==
                                                            true,
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          "Temperatura: ",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                primaryColorApp,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width:
                                                              size.width * 0.15,
                                                          child: Text(
                                                              "${product.temperatura}",
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
                                                            product.observation ==
                                                                    null
                                                                ? "Sin novedad"
                                                                : "${product.observation}", //
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
                                                        child: GestureDetector(
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
                                                Text(
                                                    "${product.tracking} / ${product.lotId}",
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
                                                              PackingPedidoBloc>()
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
                                          // if (product.expirationDate != false)
                                          //   Row(
                                          //     children: [
                                          //       const Text(
                                          //         "Fecha de caducidad: ",
                                          //         style: TextStyle(
                                          //           fontSize: 16,
                                          //           color: primaryColorApp,
                                          //         ),
                                          //       ),
                                          //       Text("${product.expirationDate}",
                                          //           style: const TextStyle(
                                          //               fontSize: 16, color: black)),
                                          //     ],
                                          //   )
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
