import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';

class DialogAlmacenes extends StatelessWidget {
  const DialogAlmacenes({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: white,
        title: Center(
          child: Column(
            children: [
              Text("Almacenes",
                  style: TextStyle(fontSize: 14, color: primaryColorApp)),
              const SizedBox(
                height: 10,
              ),
              Text(
                "Su usuario tiene multiples alamcenes, seleccione el alamcen en el que desea realizar el inventario rapido.",
                style: TextStyle(fontSize: 12, color: black),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        content: SizedBox(
          height: 300,
          width: size.width * 0.9,
          child: ListView.builder(
            itemCount: context.read<UserBloc>().almacenes.length,
            itemBuilder: (contextList, index) {
              return Card(
                color: white,
                elevation: 2,
                child: ListTile(
                  title: Text(context.read<UserBloc>().almacenes[index].name ?? 'Sin nombre',
                      style: const TextStyle(fontSize: 12, color: black)),
                  leading:
                      Icon(Icons.warehouse, color: primaryColorApp, size: 20),
                  trailing: Icon(Icons.arrow_forward_ios,
                      color: primaryColorApp, size: 20),
                  onTap: () {
                    Navigator.pop(
                        context, context.read<UserBloc>().almacenes[index].id); // Devuelve el ID
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                  context, null); // Retorna null si se cierra sin selección
            },
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 30),
                backgroundColor: primaryColorApp),
            child: const Text("Cerrar", style: TextStyle(color: white)),
          ),
        ],
      ),
    );
  }
}
