// ignore_for_file: unrelated_type_equality_checks, avoid_print, use_build_context_synchronously

import 'dart:ui';

import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/core/utils/get_colors_utils.dart';
import 'package:wms_app/features/printing/presentation/widgets/modal_printers_list.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/shared/widgets/dialog_confirm_product_load_widget.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';
import 'package:wms_app/features/user/presentation/widgets/dialog_info_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/bloc/wms_picking_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/blocs/batch_bloc/batch_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_edit_product_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/expiredate_widget.dart';

class BatchDetailScreen extends StatelessWidget {
  const BatchDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BlocConsumer<BatchBloc, BatchState>(
      listener: (context, state) {
        if (state is ProductEditOk) {
          Navigator.pop(context);
          Get.snackbar(
            '360 Software Informa',
            'Producto ajustado correctamente',
            backgroundColor: white,
            colorText: primaryColorApp,
            duration: const Duration(milliseconds: 1000),
            icon: Icon(Icons.error, color: Colors.green),
            snackPosition: SnackPosition.TOP,
          );
        }

        if (state is SendProductOdooLoading) {
          showDialog(
              context: context,
              builder: (context) {
                return const DialogLoading(message: "Enviando producto...");
              });
        }
        if (state is SendProductOdooError) {
          Navigator.pop(context);
          showScrollableErrorDialog(state.error);
        }
        if (state is LoadingSendProductEdit) {
          showDialog(
              context: context,
              builder: (context) {
                return const DialogLoading(message: "Enviando producto...");
              });
        }

        if (state is ProductEditError) {
          Navigator.pop(context);
          showScrollableErrorDialog(state.error);
        }

        if (state is SendProductOdooSuccess) {
          Navigator.pop(context);
          Get.snackbar(
            '360 Software Informa',
            'Producto enviado correctamente',
            backgroundColor: white,
            colorText: primaryColorApp,
            duration: const Duration(milliseconds: 1000),
            icon: Icon(Icons.error, color: Colors.green),
            snackPosition: SnackPosition.TOP,
          );
        }

        if (state is ViewProductImageSuccess) {
          showImageDialog(context, state.imageUrl);
        } else if (state is ViewProductImageFailure) {
          showScrollableErrorDialog(state.error);
        }
      },
      builder: (context, state) {
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Scaffold(
              backgroundColor: primaryColorApp,
              // appBar: AppBarGlobal(
              //     tittle: 'Picking Detail', actions: const SizedBox()),
              body: SafeArea(
                child: Container(
                  color: Colors.white,
                  width: size.width,
                  height: size.height * 1,
                  child: Column(
                    ///apbar

                    children: [
                      //*appbar
                      Container(
                        decoration: BoxDecoration(
                          color: context
                                      .read<BatchBloc>()
                                      .batchWithProducts
                                      .batch
                                      ?.isSeparate ==
                                  1
                              ? green
                              : primaryColorApp,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        width: double.infinity,
                        child: BlocBuilder<ConnectionStatusCubit,
                            ConnectionStatus>(builder: (context, status) {
                          return Column(
                            children: [
                              const WarningWidgetCubit(),
                              Padding(
                                padding: EdgeInsets.only(bottom: 5),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back,
                                          color: white),
                                      onPressed: () {
                                        if (context
                                                .read<BatchBloc>()
                                                .batchWithProducts
                                                .batch
                                                ?.isSeparate ==
                                            1) {
                                          context.read<WMSPickingBloc>().add(
                                              FilterBatchesBStatusEvent(
                                                  '',
                                                  context
                                                      .read<BatchBloc>()
                                                      .typePicking));
                                          Navigator.pushReplacementNamed(
                                            context,
                                            'wms-picking',
                                          );
                                        } else {
                                          context.read<BatchBloc>().add(
                                              ClearSearchProudctsBatchEvent(
                                                  context
                                                      .read<BatchBloc>()
                                                      .typePicking));

                                          Navigator.pushReplacementNamed(
                                              context, 'batch');
                                        }
                                      },
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                          left: size.width * 0.25),
                                      child: Text(
                                          "${context.read<BatchBloc>().batchWithProducts.batch?.name}",
                                          style: const TextStyle(
                                              color: white, fontSize: 12)),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.print,
                                          color: white, size: 25),
                                      onPressed: () {
                                        ModalPrintersList.show(context,
                                            resId: context
                                                .read<BatchBloc>()
                                                .batchWithProducts
                                                .batch
                                                ?.id,
                                            companyId: 1);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),

                      const SizedBox(height: 5),
                      SizedBox(
                        width: size.width,
                        height: context
                                    .read<BatchBloc>()
                                    .batchWithProducts
                                    .batch
                                    ?.isSeparate ==
                                1
                            ? 140
                            : context.read<BatchBloc>().isSearch == false
                                ? 70
                                : 100,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Card(
                                color: white,
                                elevation: 2,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: size.width * 0.6,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      child: Center(
                                        child: Row(
                                          children: [
                                            Text(
                                              "Unidades separadas: ${(context.read<BatchBloc>().calcularProgresoReal())}%",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: getColorForPercentage(
                                                    double.tryParse(context
                                                            .read<BatchBloc>()
                                                            .calcularProgresoReal()) ??
                                                        0.0), // Convertir a double
                                              ),
                                            ),
                                            const Spacer(),
                                            //icono de ayuda
                                            GestureDetector(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return BackdropFilter(
                                                        filter:
                                                            ImageFilter.blur(
                                                                sigmaX: 5,
                                                                sigmaY: 5),
                                                        child: AlertDialog(
                                                          actionsAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          title: Center(
                                                            child: Text(
                                                                "Información",
                                                                style: TextStyle(
                                                                    color:
                                                                        primaryColorApp,
                                                                    fontSize:
                                                                        20)),
                                                          ),
                                                          content: const Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Text(
                                                                  "El porcentaje de unidades separadas se calcula de la siguiente manera:"),
                                                              SizedBox(
                                                                  height: 5),
                                                              Text(
                                                                  "Porcentaje de unidades separadas = (Unidades separadas / Unidades totales) * 100"),
                                                            ],
                                                          ),
                                                          actions: [
                                                            ElevatedButton(
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                  backgroundColor:
                                                                      grey,
                                                                  shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              10)),
                                                                ),
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                },
                                                                child: const Text(
                                                                    "Cerrar",
                                                                    style: TextStyle(
                                                                        color:
                                                                            white))),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                                child: Icon(Icons.help,
                                                    color: primaryColorApp,
                                                    size: 15)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // //*widget de busqueda

                              Visibility(
                                visible: context.read<BatchBloc>().isSearch,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Card(
                                    color: Colors.white,
                                    elevation: 2,
                                    child: TextFormField(
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      onChanged: (value) {
                                        context.read<BatchBloc>().add(
                                            SearchProductsBatchEvent(
                                                value,
                                                context
                                                    .read<BatchBloc>()
                                                    .typePicking));
                                      },
                                      controller: context
                                          .read<BatchBloc>()
                                          .searchController,
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(Icons.search,
                                            color: grey),
                                        suffixIcon: IconButton(
                                            onPressed: () {
                                              context.read<BatchBloc>().add(
                                                  ClearSearchProudctsBatchEvent(
                                                      context
                                                          .read<BatchBloc>()
                                                          .typePicking));
                                              //cerramo el teclado
                                              FocusScope.of(context).unfocus();
                                            },
                                            icon: const Icon(Icons.close,
                                                color: grey)),
                                        disabledBorder:
                                            const OutlineInputBorder(),
                                        hintText: "Buscar productos",
                                        hintStyle: const TextStyle(
                                            color: Colors.grey, fontSize: 12),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // *Lista de productos
                      Expanded(
                        // height: size.height * 0.75,
                        child: context
                                .read<BatchBloc>()
                                .filteredProducts
                                .isNotEmpty
                            ? ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: context
                                    .read<BatchBloc>()
                                    .filteredProducts
                                    .length,
                                itemBuilder: (context, index) {
                                  final productsBatch = context
                                      .read<BatchBloc>()
                                      .filteredProducts[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    child: GestureDetector(
                                      onTap: () async {
                                        debugPrint("----------------");
                                        debugPrint(
                                            "product detail info: ${productsBatch.toMap()}");
                                        debugPrint("----------------");
                                      },
                                      child: Card(
                                          elevation: 4,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: productsBatch.quantity ==
                                                      productsBatch
                                                          .quantitySeparate
                                                  ? Colors.green[100]
                                                  : productsBatch.isSelected ==
                                                          1
                                                      ? primaryColorApp
                                                          .withOpacity(0.3)
                                                      : productsBatch
                                                                  .isSeparate ==
                                                              1
                                                          ? Colors.green[100]
                                                          : Colors.white,
                                            ),
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              children: [
                                                Center(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          productsBatch
                                                                  .productId ??
                                                              '',
                                                          style: const TextStyle(
                                                              fontSize: 12,
                                                              color: black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                      if (!context
                                                              .read<BatchBloc>()
                                                              .isSearch &&
                                                          (productsBatch
                                                                  .quantitySeparate <
                                                              productsBatch
                                                                  .quantity))
                                                        SizedBox(
                                                          width: 50,
                                                          height: 50,
                                                          child: Card(
                                                            elevation: 2,
                                                            color: white,
                                                            child: IconButton(
                                                                onPressed: () {
                                                                  showDialog(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (context) {
                                                                        context
                                                                            .read<BatchBloc>()
                                                                            .editProductController
                                                                            .text = '';
                                                                        return DialogEditProductWidget(
                                                                          productsBatch:
                                                                              productsBatch,
                                                                        );
                                                                      });
                                                                },
                                                                icon: Icon(
                                                                    Icons.edit,
                                                                    size: 20,
                                                                    color:
                                                                        primaryColorApp)),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 5),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child: SvgPicture.asset(
                                                          color:
                                                              primaryColorApp,
                                                          "assets/icons/barcode.svg",
                                                          height: 20,
                                                          width: 20,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                          productsBatch.barcode,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                            color: black,
                                                          )),
                                                      if (productsBatch
                                                                  .isSendOdoo !=
                                                              1 &&
                                                          productsBatch
                                                                  .isSeparate !=
                                                              1) ...[
                                                        //icono de play
                                                        const Spacer(),
                                                        GestureDetector(
                                                          onTap: () {
                                                            ///dialogo de confirmacion
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return DialogConfirmProductLoadWidget(
                                                                    productsBatch:
                                                                        productsBatch,
                                                                    onAccept:
                                                                        () {
                                                                      context.read<BatchBloc>().add(LoadSelectedProductEvent(
                                                                          productsBatch,
                                                                          context
                                                                              .read<BatchBloc>()
                                                                              .typePicking));
                                                                      Navigator.pushReplacementNamed(
                                                                          context,
                                                                          'batch');
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
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 5),
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
                                                      Text(
                                                          'Imagen del producto: ',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                            color: black,
                                                          )),
                                                      GestureDetector(
                                                        onTap: () {
                                                          context
                                                              .read<BatchBloc>()
                                                              .add(ViewProductImageEvent(
                                                                  productsBatch
                                                                          .idProduct ??
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
                                                ),
                                                Visibility(
                                                  visible: context
                                                          .read<BatchBloc>()
                                                          .configurations
                                                          .result
                                                          ?.result
                                                          ?.showNextLocationsInDetails ==
                                                      true,
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.location_on,
                                                          color:
                                                              primaryColorApp,
                                                          size: 15,
                                                        ),
                                                        const SizedBox(
                                                            width: 5),
                                                        const Text("Desde: ",
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: black)),
                                                        SizedBox(
                                                          width:
                                                              size.width * 0.57,
                                                          child: Text(
                                                              productsBatch
                                                                      .locationId
                                                                      ?.toString() ??
                                                                  '',
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      primaryColorApp)),
                                                        ),
                                                        if (productsBatch
                                                                .isPending ==
                                                            1)
                                                          Container(
                                                            width: 30,
                                                            height: 30,
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5),
                                                              color: Colors
                                                                  .amber[100],
                                                            ),
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(3),
                                                            child:
                                                                GestureDetector(
                                                              onTap: () {
                                                                showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (context) {
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
                                                                child:
                                                                    SvgPicture
                                                                        .asset(
                                                                  color:
                                                                      primaryColorApp,
                                                                  "assets/icons/list_final.svg",
                                                                  height: 20,
                                                                  width: 20,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 8),
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
                                                            productsBatch
                                                                .locationDestId
                                                                .toString(),
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    primaryColorApp)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Visibility(
                                                  visible: productsBatch
                                                              .origin !=
                                                          "" &&
                                                      productsBatch.origin !=
                                                          null,
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.file_open_sharp,
                                                          color:
                                                              primaryColorApp,
                                                          size: 15,
                                                        ),
                                                        const SizedBox(
                                                            width: 5),
                                                        Align(
                                                          alignment: Alignment
                                                              .centerLeft,
                                                          child: Text(
                                                              "Doc. origen: ",
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: grey)),
                                                        ),
                                                        Align(
                                                          alignment: Alignment
                                                              .centerLeft,
                                                          child: Text(
                                                              productsBatch
                                                                      .origin ??
                                                                  "",
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
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 8),
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
                                                            productsBatch
                                                                .rimovalPriority
                                                                .toString(),
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    primaryColorApp)),
                                                      ),
                                                      const Spacer(),
                                                      GestureDetector(
                                                        onTap: () {
                                                          ModalPrintersList.show(
                                                              context,
                                                              resId:
                                                                  productsBatch
                                                                      .idMove,
                                                              companyId: 1);
                                                        },
                                                        child: Icon(
                                                          Icons.print,
                                                          color:
                                                              primaryColorApp,
                                                          size: 25,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                ExpiryDateWidget(
                                                    expireDate: productsBatch
                                                                .expireDate ==
                                                            ""
                                                        ? DateTime.now()
                                                        : DateTime.parse(
                                                            productsBatch
                                                                .expireDate),
                                                    size: size,
                                                    isDetaild: true,
                                                    isNoExpireDate: productsBatch
                                                                .expireDate ==
                                                            ""
                                                        ? true
                                                        : false),
                                                if (productsBatch.lotId !=
                                                        null &&
                                                    productsBatch.lotId != "")
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.bookmarks_sharp,
                                                          color:
                                                              primaryColorApp,
                                                          size: 15,
                                                        ),
                                                        const SizedBox(
                                                            width: 5),
                                                        const Text("Lote:",
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: black)),
                                                        const SizedBox(
                                                            width: 5),
                                                        SizedBox(
                                                          width:
                                                              size.width * 0.55,
                                                          child: Text(
                                                              productsBatch
                                                                  .lotId
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
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 3),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .send_to_mobile_outlined,
                                                          color:
                                                              primaryColorApp,
                                                          size: 15,
                                                        ),
                                                        const SizedBox(
                                                            width: 5),
                                                        const Text(
                                                            "Subido a WMS:",
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: black)),
                                                        const SizedBox(
                                                            width: 5),
                                                        SizedBox(
                                                          width:
                                                              size.width * 0.25,
                                                          child: Text(
                                                              productsBatch
                                                                          .isSendOdoo ==
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
                                                                      : productsBatch.isSendOdoo ==
                                                                              1
                                                                          ? green
                                                                          : red)),
                                                        ),
                                                        if (productsBatch
                                                                .isSendOdoo ==
                                                            0)
                                                          ElevatedButton(
                                                              onPressed:
                                                                  () async {
                                                                context
                                                                    .read<
                                                                        BatchBloc>()
                                                                    .add(
                                                                        SendProductOdooEvent(
                                                                      productsBatch,
                                                                      context
                                                                          .read<
                                                                              BatchBloc>()
                                                                          .typePicking,
                                                                    ));
                                                              },
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                backgroundColor:
                                                                    primaryColorApp,
                                                                maximumSize:
                                                                    const Size(
                                                                        80, 20),
                                                                minimumSize:
                                                                    const Size(
                                                                        80, 20),
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10),
                                                                ),
                                                                elevation: 3,
                                                              ),
                                                              child: const Text(
                                                                'Enviar',
                                                                style: TextStyle(
                                                                    color:
                                                                        white,
                                                                    fontSize:
                                                                        10),
                                                              ))
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                if (productsBatch.isSeparate ==
                                                    1)
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8),
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.timer,
                                                            color:
                                                                primaryColorApp,
                                                            size: 15),
                                                        const SizedBox(
                                                            width: 5),
                                                        RichText(
                                                          text: TextSpan(
                                                            children: [
                                                              const TextSpan(
                                                                text:
                                                                    "Tiempo total: ",
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      black, // color del texto antes de tiempoTotal
                                                                ),
                                                              ),
                                                              TextSpan(
                                                                text: context
                                                                    .read<
                                                                        BatchBloc>()
                                                                    .formatSecondsToHHMMSS(
                                                                        (productsBatch.timeSeparate ?? 0).toDouble() ??
                                                                            0.0),
                                                                style:
                                                                    TextStyle(
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
                                                  color: productsBatch
                                                              .quantity ==
                                                          productsBatch
                                                              .quantitySeparate
                                                      ? Colors.green[100]
                                                      : productsBatch
                                                                  .quantitySeparate ==
                                                              null
                                                          ? Colors.red[100]
                                                          : Colors.amber[100],
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                    child: Column(
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.add,
                                                              color:
                                                                  primaryColorApp,
                                                              size: 15,
                                                            ),
                                                            const SizedBox(
                                                                width: 5),
                                                            const Text(
                                                                "Unidades:",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        black)),
                                                            const SizedBox(
                                                                width: 5),
                                                            Text(
                                                                productsBatch
                                                                    .quantity
                                                                    .toString(),
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        primaryColorApp)),
                                                            const Spacer(),
                                                            Icon(
                                                              Icons.check,
                                                              color:
                                                                  primaryColorApp,
                                                              size: 15,
                                                            ),
                                                            const SizedBox(
                                                                width: 5),
                                                            const Text(
                                                                "Separadas:",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        black)),
                                                            const SizedBox(
                                                                width: 5),
                                                            Text(
                                                                productsBatch.quantitySeparate ==
                                                                        null
                                                                    ? "0"
                                                                    : (productsBatch.quantitySeparate ??
                                                                            0.0)
                                                                        .toString(),
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        primaryColorApp)),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .assessment_outlined,
                                                              color:
                                                                  primaryColorApp,
                                                              size: 15,
                                                            ),
                                                            const SizedBox(
                                                                width: 5),
                                                            Text(
                                                                "Unidad de medida: ${productsBatch.unidades ?? ''}",
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        black)),
                                                          ],
                                                        ),
                                                        if (productsBatch
                                                                .quantity !=
                                                            productsBatch
                                                                .quantitySeparate)
                                                          Align(
                                                            alignment: Alignment
                                                                .centerLeft,
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .assignment_late,
                                                                  color:
                                                                      primaryColorApp,
                                                                  size: 15,
                                                                ),
                                                                const SizedBox(
                                                                    width: 5),
                                                                Text(
                                                                    "Novedad: ${productsBatch.observation ?? ''}",
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color:
                                                                            black)),
                                                              ],
                                                            ),
                                                          ),
                                                        const SizedBox(
                                                            height: 5),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        context.read<BatchBloc>().isSearch
                                            ? 'No se encontraron resultados'
                                            : 'No hay productos en la lista',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: primaryColorApp)),
                                    Text(
                                        context.read<BatchBloc>().isSearch
                                            ? 'Intenta con otra búsqueda'
                                            : 'Todos los productos han sido completados',
                                        style: const TextStyle(
                                            fontSize: 12, color: grey)),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              )),
        );
      },
    );
  }
}
