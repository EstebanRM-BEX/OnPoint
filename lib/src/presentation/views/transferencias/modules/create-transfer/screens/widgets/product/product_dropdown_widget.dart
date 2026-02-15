import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/bloc/crate_transfer_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_barcodes_widget.dart';

class ProductDropdownCreateTransferWidget extends StatelessWidget {
  const ProductDropdownCreateTransferWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: (context.read<CreateTransferBloc>().locationIsOk &&
                  !context.read<CreateTransferBloc>().productIsOk &&
                  !context.read<CreateTransferBloc>().quantityIsOk)
              ? () {
                  context
                      .read<CreateTransferBloc>()
                      .add(GetProductsFromDBEvent());
                  Navigator.pushReplacementNamed(
                    context,
                    'search-product-create-transfer',
                  );
                }
              : null,
          child: Card(
            color: white,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Row(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Producto',
                        style: TextStyle(fontSize: 14, color: primaryColorApp)),
                  ),
                  const Spacer(),
                  Image.asset(
                    "assets/icons/producto.png",
                    color: primaryColorApp,
                    width: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!context.read<UserBloc>().fabricante.contains("Zebra"))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.read<CreateTransferBloc>().currentProduct?.name ??
                    "Esperando escaneo",
                style: const TextStyle(color: black, fontSize: 14),
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
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
              const SizedBox(width: 10),
              Text(
                context
                            .read<CreateTransferBloc>()
                            .currentProduct
                            ?.barcode
                            ?.isNotEmpty ??
                        false
                    ? context
                            .read<CreateTransferBloc>()
                            .currentProduct
                            ?.barcode ??
                        ""
                    : "Sin codigo de barras",
                textAlign: TextAlign.start,
                style: TextStyle(
                    fontSize: 12,
                    color: context
                                .read<CreateTransferBloc>()
                                .currentProduct
                                ?.barcode
                                ?.isNotEmpty ??
                            false
                        ? black
                        : red),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return DialogBarcodes(
                        listOfBarcodes:
                            context.read<CreateTransferBloc>().listOfBarcodes,
                      );
                    },
                  );
                },
                child: Visibility(
                  visible: context
                      .read<CreateTransferBloc>()
                      .listOfBarcodes
                      .isNotEmpty,
                  child: SizedBox(
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
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Text('codigo: ', style: TextStyle(fontSize: 14, color: black)),
              Text(
                context
                            .read<CreateTransferBloc>()
                            .currentProduct
                            ?.code
                            ?.isNotEmpty ??
                        true
                    ? context.read<CreateTransferBloc>().currentProduct?.code ??
                        "Sin codigo "
                    : "Sin codigo ",
                textAlign: TextAlign.start,
                style: TextStyle(
                    fontSize: 12,
                    color: context
                                .read<CreateTransferBloc>()
                                .currentProduct
                                ?.code
                                ?.isNotEmpty ??
                            false
                        ? primaryColorApp
                        : red),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
