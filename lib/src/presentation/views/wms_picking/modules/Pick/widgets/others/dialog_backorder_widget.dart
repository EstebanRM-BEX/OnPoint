// ignore_for_file: unrelated_type_equality_checks

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/bloc/picking_pick_bloc.dart';

class DialogBackorderPick extends StatelessWidget {
  const DialogBackorderPick(
      {super.key,
      required this.unidadesSeparadas,
      required this.createBackorder,
      required this.idPick,
      required this.isExternalProduct,
      required this.isHistory});

  final double unidadesSeparadas;
  final String createBackorder;
  final int idPick;
  final bool isExternalProduct;
  final bool isHistory;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white,
        actionsAlignment: MainAxisAlignment.center,
        title: Text(
          'Confirmar Picking',
          style: TextStyle(color: primaryColorApp, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        content: Column(
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
                (unidadesSeparadas == "100.0" || unidadesSeparadas >= 100.0)
                    ? '¿Estás seguro de confirmar el picking para ser enviado?'
                    : createBackorder == "never"
                        ? '¿Estás seguro de confirmar picking para ser enviado?'
                        : "Usted ha procesado cantidades de productos menores que los requeridos en el movimiento orignal.",
                style: TextStyle(color: black, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          Visibility(
            visible:
                (unidadesSeparadas == "100.0" || unidadesSeparadas >= 100.0)
                    ? false
                    : createBackorder == "never" || createBackorder == "always"
                        ? false
                        : true,
            child: ElevatedButton(
              onPressed: () {
                context.read<PickingPickBloc>().add(ShowKeyboard(false));
                context.read<PickingPickBloc>().add(CreateBackOrderOrNot(
                    context.read<PickingPickBloc>().pickWithProducts.pick?.id ??
                        0,
                    true,
                    isExternalProduct));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColorApp,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: Size(size.width * 0.9, 40),
              ),
              child: const Text(
                'Confirmar y Crear un Backorder',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              context.read<PickingPickBloc>().add(ShowKeyboard(false));
              context.read<PickingPickBloc>().add(CreateBackOrderOrNot(
                  isHistory
                      ? idPick
                      : context
                              .read<PickingPickBloc>()
                              .pickWithProducts
                              .pick
                              ?.id ??
                          0,
                  createBackorder == "never"
                      ? false
                      : createBackorder == "always"
                          ? true
                          : false,
                  isExternalProduct));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColorApp,
              minimumSize: Size(size.width * 0.9, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Confirmar Picking',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: Size(size.width * 0.9, 40),
              backgroundColor: grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
