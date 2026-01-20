import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/presentation/providers/network/check_internet_connection.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/connection_status_cubit.dart';

class WarningWidgetCubit extends StatelessWidget {
  const WarningWidgetCubit({super.key, this.isTop = true});

  final bool isTop;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
      builder: (context, status) {
        return Visibility(
          visible: status != ConnectionStatus.online,
          child: Container(
            padding: EdgeInsets.only(top: isTop ? 20 : 5, left: 16, right: 16),
            height: 60,
            color: grey,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, color: primaryColorApp, size: 30),
                const SizedBox(width: 8),
                Flexible(
                  child: const Text(
                    'No hay conexión a internet',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign
                        .center, // Centramos por si se divide en 2 lineas
                    overflow: TextOverflow
                        .ellipsis, // Pone "..." si es demasiado largo
                    maxLines: 2, // Permite hasta 2 lineas si es necesario
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
