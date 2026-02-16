// CustomAppBar permanece igual
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
      builder: (context, status) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: primaryColorApp,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              const WarningWidgetCubit(),
              Padding(
                padding: EdgeInsets.only(
                  top: status != ConnectionStatus.online ? 0 : 30,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: white),
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/home'),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: size.width * 0.15),
                      child: const Text(
                        "NUEVA DEVOLUCION",
                        style: TextStyle(color: white, fontSize: 18),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete, color: white),
                      onPressed: () {
                        //mostramos un dialogo de confirmación
                        showDialog(
                          context: context,
                          builder: (context) {
                            return BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: AlertDialog(
                                actionsAlignment:
                                    MainAxisAlignment.spaceBetween,
                                title: Center(
                                    child: Text(
                                  'Confirmar eliminación',
                                  style: TextStyle(
                                      color: primaryColorApp, fontSize: 16),
                                )),
                                content: const Text(
                                    '¿Estás seguro de que deseas eliminar todos los datos de la devolución y comenzar de nuevo?',
                                    style:
                                        TextStyle(fontSize: 14, color: black)),
                                actions: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: grey,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancelar',
                                        style: TextStyle(color: white)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColorApp,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      // Aquí puedes agregar la lógica para mostrar ayuda
                                      context
                                          .read<DevolucionesBloc>()
                                          .add(ClearValueEvent());
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Eliminar',
                                        style: TextStyle(color: white)),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
