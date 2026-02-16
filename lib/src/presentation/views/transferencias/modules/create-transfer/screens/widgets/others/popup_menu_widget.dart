import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/bloc/crate_transfer_bloc.dart';

class PopupMenuCreateTransferWidget extends StatelessWidget {
  const PopupMenuCreateTransferWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateTransferBloc, CreateTransferState>(
      builder: (context, state) {
        return PopupMenuButton<String>(
          shadowColor: Colors.white,
          color: Colors.white,
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          onSelected: (String value) {
            // Manejar la selección de opciones aquí
            if (value == '1') {
              //verficamos si tenemos permisos
              Navigator.pushReplacementNamed(
                context,
                'detail-create-transfer',
              );

              // Acción para opción 1
            } else if (value == '2') {
              context
                  .read<CreateTransferBloc>()
                  .add(ClearDataCreateTransferEvent(
                      isClearProduct: false
                  ));
            } else if (value == '3') {
              context
                  .read<CreateTransferBloc>()
                  .add(ClearDataCreateTransferEvent(
                      isClearProduct: true
                  ));
              // Acción para opción 3
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem<String>(
                value: '1',
                child: Row(
                  children: [
                    Icon(Icons.info, color: primaryColorApp, size: 20),
                    const SizedBox(width: 10),
                    const Text('Ver detalles',
                        style: TextStyle(color: black, fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: '2',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: red, size: 20),
                    const SizedBox(width: 10),
                    const Text('Todo',
                        style: TextStyle(color: black, fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: '3',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: red, size: 20),
                    const SizedBox(width: 10),
                    const Text('Producto',
                        style: TextStyle(color: black, fontSize: 14)),
                  ],
                ),
              ),
            ];
          },
        );
      },
    );
  }
}
