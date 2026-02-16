// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/sounds_utils.dart';
import 'package:wms_app/core/utils/vibrate_utils.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/bloc/picking_pick_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/widgets/others/dialog_backorder_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/widgets/others/dialog_picking_incompleted_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

class MuellePickDropdownWidget extends StatefulWidget {
  final String? selectedMuelle;
  final ProductsBatch currentProduct;
  final bool isPda;

  const MuellePickDropdownWidget({
    super.key,
    required this.selectedMuelle,
    required this.currentProduct,
    required this.isPda,
  });

  @override
  State<MuellePickDropdownWidget> createState() => _MuelleDropdownWidgetState();
}

class _MuelleDropdownWidgetState extends State<MuellePickDropdownWidget> {
  final AudioService _audioService = AudioService();
  final VibrationService _vibrationService = VibrationService();

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
              DropdownMenuItem(
                value: context
                            .read<PickingPickBloc>()
                            .configurations
                            .result
                            ?.result
                            ?.muelleOption ==
                        "multiple"
                    ? context
                        .read<PickingPickBloc>()
                        .currentProduct
                        .barcodeLocationDest
                    : context
                        .read<PickingPickBloc>()
                        .pickWithProducts
                        .pick
                        ?.barcodeMuelle,
                child: Text(
                  context
                              .read<PickingPickBloc>()
                              .configurations
                              .result
                              ?.result
                              ?.muelleOption ==
                          "multiple"
                      ? context
                              .read<PickingPickBloc>()
                              .currentProduct
                              .locationDestId ??
                          ""
                      : context
                              .read<PickingPickBloc>()
                              .pickWithProducts
                              .pick
                              ?.muelle ??
                          "",
                  style: const TextStyle(fontSize: 14, color: black),
                ),
              ),
            ],
            onChanged: context
                        .read<PickingPickBloc>()
                        .configurations
                        .result
                        ?.result
                        ?.manualSpringSelection ==
                    false
                ? null
                : !context.read<PickingPickBloc>().quantityIsOk &&
                        !context.read<PickingPickBloc>().locationDestIsOk &&
                        context.read<PickingPickBloc>().productIsOk
                    ? (String? newValue) {
                        print("Muelle seleccionado: $newValue");
                        if (context
                                    .read<PickingPickBloc>()
                                    .configurations
                                    .result
                                    ?.result
                                    ?.muelleOption ==
                                "multiple"
                            ? newValue ==
                                context
                                    .read<PickingPickBloc>()
                                    .currentProduct
                                    .barcodeLocationDest
                            : newValue ==
                                context
                                    .read<PickingPickBloc>()
                                    .pickWithProducts
                                    .pick
                                    ?.barcodeMuelle) {
                          print('Muelle correcto');
                          // Validación correcta
                          validatePicking(
                            context.read<PickingPickBloc>(),
                            context,
                            widget.currentProduct,
                          );
                        } else {
                          _audioService.playErrorSound();
                          _vibrationService.vibrate();
                          // Si la validación falla
                          context.read<PickingPickBloc>().add(
                              ValidateFieldsEvent(
                                  field: "locationDest", isOk: false));
                          // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          //   duration: const Duration(milliseconds: 1000),
                          //   content: const Text('Muelle erróneo'),
                          //   backgroundColor: Colors.red[200],
                          // ));
                        }
                      }
                    : null,
          ),

          Visibility(
            visible: widget.isPda,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context
                            .read<PickingPickBloc>()
                            .configurations
                            .result
                            ?.result
                            ?.muelleOption ==
                        "multiple"
                    ? context
                            .read<PickingPickBloc>()
                            .currentProduct
                            .locationDestId ??
                        ""
                    : context
                            .read<PickingPickBloc>()
                            .pickWithProducts
                            .pick
                            ?.muelle ??
                        "",
                style: const TextStyle(fontSize: 14, color: black),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Visibility(
              visible: context
                          .read<PickingPickBloc>()
                          .configurations
                          .result
                          ?.result
                          ?.muelleOption ==
                      "multiple"
                  ? context
                              .read<PickingPickBloc>()
                              .currentProduct
                              .barcodeLocationDest ==
                          false ||
                      context
                              .read<PickingPickBloc>()
                              .currentProduct
                              .barcodeLocationDest ==
                          null ||
                      context
                              .read<PickingPickBloc>()
                              .currentProduct
                              .barcodeLocationDest ==
                          ""
                  : context
                              .read<PickingPickBloc>()
                              .pickWithProducts
                              .pick
                              ?.barcodeMuelle ==
                          false ||
                      context
                              .read<PickingPickBloc>()
                              .pickWithProducts
                              .pick
                              ?.barcodeMuelle ==
                          null ||
                      context
                              .read<PickingPickBloc>()
                              .pickWithProducts
                              .pick
                              ?.barcodeMuelle ==
                          "",
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

  void validatePicking(PickingPickBloc batchBloc, BuildContext context,
      ProductsBatch currentProduct) {
    batchBloc.add(
        FetchPickWithProductsEvent(batchBloc.pickWithProducts.pick?.id ?? 0));

    //validamos que la cantidad de productos separados sea igual a la cantidad de productos pedidos
//validamos el 100 de las unidades separadas
    final double unidadesSeparadas =
        double.parse(batchBloc.calcularUnidadesSeparadas());
//*validamos is tenemos productos que no se han enviado
    if (unidadesSeparadas == "100.0" || unidadesSeparadas >= 100.0) {
      var productsToSend = batchBloc.filteredProducts
          .where((element) => element.isSendOdoo == 0)
          .toList();

      // Si hay productos pendientes de enviar a Odoo, mostramos un modal
      if (productsToSend.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Center(
              child: Text("360 Software Informa",
                  style: TextStyle(color: yellow, fontSize: 16)),
            ),
            content: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    "Tienes productos que no han sido enviados al WMS. revisa la lista de productos y envíalos antes de continuar.",
                    style: TextStyle(color: black, fontSize: 14)),
                const SizedBox(height: 15),
                ElevatedButton(
                    onPressed: () {
                      // Navigator.pop(context);
                      if (batchBloc.configurations.result?.result
                              ?.showDetallesPicking ==
                          true) {
                        //cerramos el focus
                        batchBloc.isSearch = false;
                        batchBloc.add(LoadProductEditEvent());
                        Navigator.pushReplacementNamed(
                          context,
                          'pick-detail',
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            duration: Duration(milliseconds: 1000),
                            content:
                                Text('No tienes permisos para ver detalles'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                    ),
                    child: Text('Ver productos',
                        style: TextStyle(color: primaryColorApp, fontSize: 12)))
              ],
            ),
          ),
        );
        return;
      } else {
        if (batchBloc.configurations.result?.result?.hideValidatePicking ==
            false) {
          showDialog(
              context: Navigator.of(context, rootNavigator: true).context,
              builder: (context) {
                return DialogBackorderPick(
                  isHistory: false,
                  idPick: context
                          .read<PickingPickBloc>()
                          .pickWithProducts
                          .pick
                          ?.id ??
                      0,
                  unidadesSeparadas: unidadesSeparadas,
                  createBackorder: context
                          .read<PickingPickBloc>()
                          .pickWithProducts
                          .pick
                          ?.createBackorder ??
                      "ask",
                  isExternalProduct: false,
                );
              });
        } else {
          batchBloc.add(PickOkEvent(batchBloc.pickWithProducts.pick?.id ?? 0));
        }
      }
    } else {
      showDialog(
          context: context,
          builder: (context) {
            return DialogPickIncompleted(
              currentProduct: batchBloc.currentProduct,
              cantidad: unidadesSeparadas,
              onAccepted: () {
                if (batchBloc
                        .configurations.result?.result?.showDetallesPicking ==
                    true) {
                  //cerramos el focus
                  batchBloc.isSearch = false;
                  batchBloc.add(ShowKeyboard(false));
                  batchBloc.add(LoadProductEditEvent());
                  Navigator.pushReplacementNamed(
                    context,
                    'pick-detail',
                  ).then((_) {});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      duration: Duration(milliseconds: 1000),
                      content: Text('No tienes permisos para ver detalles'),
                    ),
                  );
                }
              },
              onClose: () {
                if (batchBloc
                        .configurations.result?.result?.hideValidatePicking ==
                    false) {
                  Navigator.pop(context);

                  Future.delayed(Duration.zero, () {
                    showDialog(
                        context:
                            Navigator.of(context, rootNavigator: true).context,
                        builder: (context) {
                          return DialogBackorderPick(
                            isHistory: false,
                            idPick: batchBloc.pickWithProducts.pick?.id ?? 0,
                            unidadesSeparadas: unidadesSeparadas,
                            createBackorder: batchBloc
                                    .pickWithProducts.pick?.createBackorder ??
                                "ask",
                            isExternalProduct: false,
                          );
                        });
                  });
                } else {
                  batchBloc.add(
                      PickOkEvent(batchBloc.pickWithProducts.pick?.id ?? 0));
                }
              },
            );
          });
    }
  }
}
