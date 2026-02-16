// ignore_for_file: file_names

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/lista_product_packing.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/bloc/packing_pedido_bloc.dart';

class DialogConfirmatedPack extends StatelessWidget {
  const DialogConfirmatedPack({
    super.key,
    required this.productos,
    required this.isCertificate,
  });

  final List<ProductoPedido> productos;
  final bool isCertificate;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white,
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 100,
              width: 200,
              child: SvgPicture.asset(
                "assets/images/icono.svg",
                height: 150,
                width: 50,
                fit: BoxFit.cover,
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                'Esta seguro de empacar los productos seleccionados?',
                style: TextStyle(color: primaryColorApp, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                'Total de productos: ${productos.length}',
                style: const TextStyle(color: black, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlocBuilder<PackingPedidoBloc, PackingPedidoState>(
              builder: (context, state) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //icono de sticker
                    const Text(
                      'Incluir sticker de certificación',
                      style: TextStyle(color: black, fontSize: 14),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: context.read<PackingPedidoBloc>().isSticker,
                          onChanged: (value) {
                            context
                                .read<PackingPedidoBloc>()
                                .add(ChangeStickerEvent(
                                  !context.read<PackingPedidoBloc>().isSticker,
                                ));
                          },
                        ),
                        Icon(Icons.print, color: primaryColorApp),
                      ],
                    ),
                  ],
                );
              },
            )
            // : const Text("Esta rsealizando una separación sin certificado, tampoco se incluira el sticker de certificación", style: TextStyle(color: black, fontSize: 14), textAlign: TextAlign.center,),
          ],
        ),
        actions: [
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
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<PackingPedidoBloc>().add(SetPackingsEvent(
                    productos,
                    context.read<PackingPedidoBloc>().isSticker,
                    isCertificate,
                  ));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColorApp,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Aceptar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
