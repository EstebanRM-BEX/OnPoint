// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/cluster_picking/cluster_picking_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_picking_incompleted_widget.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/batch_product.dart';

class MuelleDropdownWidget extends StatefulWidget {
  final String? selectedMuelle;
  final ClusterPickingBloc batchBloc;
  final BatchProduct currentProduct;

  const MuelleDropdownWidget({
    super.key,
    required this.selectedMuelle,
    required this.batchBloc,
    required this.currentProduct,
  });

  @override
  State<MuelleDropdownWidget> createState() => _MuelleDropdownWidgetState();
}

class _MuelleDropdownWidgetState extends State<MuelleDropdownWidget> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // DropdownButton para seleccionar el Muelle
          DropdownButton<String>(
            underline: Container(height: 0),
            borderRadius: BorderRadius.circular(10),
            focusColor: Colors.white,
            isExpanded: true,
            hint: Text(
              'Ubicación de destino',
              style: TextStyle(
                fontSize: 14,
                color: primaryColorApp,
              ),
            ),
            icon: SizedBox(
              height: 20,
              width: 20,
              child: SvgPicture.asset(
                color: primaryColorApp,
                "assets/icons/packing.svg",
                height: 20,
                width: 20,
                fit: BoxFit.cover,
              ),
            ),
            value: widget.selectedMuelle,
            items: [
              DropdownMenuItem<String>(
                value: widget.batchBloc.configurations.result?.result
                            ?.muelleOption ==
                        "multiple"
                    ? widget.batchBloc.currentProduct?.barcodeLocationDest
                    : widget.batchBloc.currentBatch?.barcodeMuelle,
                child: Text(
                  widget.batchBloc.configurations.result?.result
                              ?.muelleOption ==
                          "multiple"
                      ? widget.batchBloc.currentProduct?.locationDestId ?? ""
                      : widget.batchBloc.currentBatch?.muelle ?? "",
                  style: const TextStyle(fontSize: 14, color: black),
                ),
              ),
            ],
            onChanged: widget.batchBloc.configurations.result?.result
                        ?.manualSpringSelection ==
                    false
                ? null
                : !widget.batchBloc.quantityIsOk &&
                        !widget.batchBloc.locationDestIsOk &&
                        widget.batchBloc.productIsOk
                    ? (String? newValue) {
                        debugPrint("Muelle seleccionado: $newValue");
                        if (widget.batchBloc.configurations.result?.result
                                    ?.muelleOption ==
                                "multiple"
                            ? newValue ==
                                widget.batchBloc.currentProduct
                                    ?.barcodeLocationDest
                            : newValue ==
                                widget.batchBloc.currentBatch?.barcodeMuelle) {
                          // Validación correcta
                          validatePicking(
                            widget.batchBloc,
                            context,
                            widget.currentProduct,
                          );
                        } else {
                          // Si la validación falla
                          widget.batchBloc.add(ValidateFieldsEvent(
                              field: "locationDest", isOk: false));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            duration: const Duration(milliseconds: 1000),
                            content: const Text('Muelle erróneo'),
                            backgroundColor: Colors.red[200],
                          ));
                        }
                      }
                    : null,
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: Visibility(
              visible: widget.batchBloc.configurations.result?.result
                          ?.muelleOption ==
                      "multiple"
                  ? widget.batchBloc.currentProduct?.barcodeLocationDest ==
                          false ||
                      widget.batchBloc.currentProduct?.barcodeLocationDest ==
                          null ||
                      widget.batchBloc.currentProduct?.barcodeLocationDest == ""
                  : widget.batchBloc.currentBatch?.barcodeMuelle == false ||
                      widget.batchBloc.currentBatch?.barcodeMuelle == null ||
                      widget.batchBloc.currentBatch?.barcodeMuelle == "",
              child: const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  "Sin código de barras",
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: 13, color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void validatePicking(
    ClusterPickingBloc batchBloc,
    BuildContext context,
    BatchProduct currentProduct,
  ) async {
    // batchBloc.add(FetchBatchWithProductsEvent(
    //     batchBloc.batchWithProducts.batch?.id ?? 0, batchBloc.typePicking));

    // // Validamos que la cantidad de productos separados sea igual a la cantidad de productos pedidos
    // final double unidadesSeparadas =
    //     double.parse(batchBloc.calcularProgresoReal());

    // if (unidadesSeparadas == "100.0" || unidadesSeparadas >= 100.0) {
    //   var productsToSend = batchBloc.filteredProducts
    //       .where((element) => element.isSendOdoo == 0)
    //       .toList();

    //   // Si hay productos pendientes de enviar a Odoo, mostramos un modal
    //   if (productsToSend.isNotEmpty) {
    //     showDialog(
    //       context: context,
    //       builder: (context) => AlertDialog(
    //         backgroundColor: Colors.white,
    //         title: const Center(
    //           child: Text("360 Software Informa",
    //               style: TextStyle(color: yellow, fontSize: 16)),
    //         ),
    //         content: Column(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           mainAxisSize: MainAxisSize.min,
    //           children: [
    //             const Text(
    //                 "Tienes productos que no han sido enviados al wms. revisa la lista de productos y envíalos antes de continuar.",
    //                 style: TextStyle(color: black, fontSize: 14)),
    //             const SizedBox(height: 15),
    //             ElevatedButton(
    //                 onPressed: () {
    //                   Navigator.pop(context);
    //                   if (batchBloc.configurations.result?.result
    //                           ?.showDetallesPicking ==
    //                       true) {
    //                     //cerramos el focus
    //                     batchBloc.isSearch = false;
    //                     batchBloc
    //                         .add(LoadProductEditEvent(batchBloc.typePicking));
    //                     Navigator.pushReplacementNamed(
    //                       context,
    //                       'batch-detail',
    //                     );
    //                   } else {
    //                     ScaffoldMessenger.of(context).showSnackBar(
    //                       const SnackBar(
    //                         duration: Duration(milliseconds: 1000),
    //                         content:
    //                             Text('No tienes permisos para ver detalles'),
    //                       ),
    //                     );
    //                   }
    //                 },
    //                 style: ElevatedButton.styleFrom(
    //                   backgroundColor: Colors.white,
    //                   shape: RoundedRectangleBorder(
    //                     borderRadius: BorderRadius.circular(10),
    //                   ),
    //                   elevation: 3,
    //                 ),
    //                 child: Text('Ver productos',
    //                     style: TextStyle(color: primaryColorApp, fontSize: 12)))
    //           ],
    //         ),
    //       ),
    //     );
    //   } else {
    //     batchBloc.add(ValidateFieldsEvent(field: "locationDest", isOk: true));
    //     batchBloc.add(ChangeLocationDestIsOkEvent(
    //         true,
    //         currentProduct.idProduct ?? 0,
    //         batchBloc.batchWithProducts.batch?.id ?? 0,
    //         currentProduct.idMove ?? 0,
    //         batchBloc.typePicking));

    //     batchBloc.add(EndTimePick(
    //         batchBloc.batchWithProducts.batch?.id ?? 0, DateTime.now()));

    //     batchBloc.add(PickingOkEvent(batchBloc.batchWithProducts.batch?.id ?? 0,
    //         currentProduct.idProduct ?? 0, batchBloc.typePicking));
    //     context
    //         .read<WMSPickingBloc>()
    //         .add(FilterBatchesBStatusEvent('', batchBloc.typePicking));
    //     context.read<BatchBloc>().index = 0;
    //     context.read<BatchBloc>().isSearch = true;

    //     //validamos que tipo de batch es
    //     if (batchBloc.typePicking == 'components') {
    //       Navigator.pushReplacementNamed(
    //         context,
    //         'picking-componentes-batch',
    //       );
    //     } else if (batchBloc.typePicking == 'batch') {
    //       Navigator.pushReplacementNamed(
    //         context,
    //         'wms-picking',
    //       );
    //     } else {
    //       Navigator.pushReplacementNamed(context, '/home');
    //     }
    //   }
    // } else {
    //   showDialog(
    //       context: context,
    //       builder: (context) {
    //         return DialogPickingIncompleted(
    //             currentProduct: batchBloc.currentProduct,
    //             cantidad: unidadesSeparadas,
    //             batchBloc: batchBloc,
    //             onAccepted: () {
    //               Navigator.pop(context);
    //               if (batchBloc
    //                       .configurations.result?.result?.showDetallesPicking ==
    //                   true) {
    //                 // Cerramos el foco
    //                 batchBloc.isSearch = false;
    //                 batchBloc.add(LoadProductEditEvent(batchBloc.typePicking));

    //                 Navigator.pushReplacementNamed(
    //                   context,
    //                   'batch-detail',
    //                 );
    //               } else {
    //                 ScaffoldMessenger.of(context).showSnackBar(
    //                   const SnackBar(
    //                     duration: Duration(milliseconds: 1000),
    //                     content: Text('No tienes permisos para ver detalles'),
    //                   ),
    //                 );
    //               }
    //             });
    //       });
    // }
  }
}
