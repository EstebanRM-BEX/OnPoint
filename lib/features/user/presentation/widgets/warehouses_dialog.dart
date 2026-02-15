import 'package:flutter/material.dart';
import 'package:wms_app/features/user/domain/entities/user_configuration.dart';
import 'package:wms_app/src/core/constans/colors.dart';

class WarehousesDialog extends StatelessWidget {
  final List<AllowedWarehouse>
      warehouses; // Using legacy type for checks or we create domain entity for it

  const WarehousesDialog({super.key, required this.warehouses});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AlertDialog(
      backgroundColor: white,
      title: Center(
        child: Text("Almacenes",
            style: TextStyle(fontSize: 14, color: primaryColorApp)),
      ),
      content: SizedBox(
        height: 300,
        width: size.width * 0.9,
        child: ListView.builder(
          itemCount: warehouses.length,
          itemBuilder: (context, index) {
            return Card(
              color: white,
              elevation: 2,
              child: ListTile(
                title: Text(
                  warehouses[index].name ?? 'Sin nombre',
                  style: const TextStyle(fontSize: 12, color: black),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 30),
              backgroundColor: primaryColorApp),
          child: const Text("Cerrar", style: TextStyle(color: white)),
        ),
      ],
    );
  }
}
