import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

class CantLineasMuelle extends StatelessWidget {
  const CantLineasMuelle({
    super.key,
    required this.productsOk,
  });

  final List<dynamic> productsOk;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return GestureDetector(
      onTap: productsOk.isEmpty
          ? null
          : () {
              //mostramos un dialog
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    actionsAlignment: MainAxisAlignment.center,
                    title: Center(
                        child: Text(
                      "Productos separados sin ubicacion destino",
                      style: TextStyle(fontSize: 12, color: primaryColorApp),
                    )),
                    content: SizedBox(
                      width: size.width * 0.8, // Ancho máximo fijo (opcional)
                      height: size.height * 0.4,
                      child: ListView.builder(
                        itemCount: productsOk.length,
                        itemBuilder: (context, index) {
                          return Card(
                            child: ListTile(
                              title: Text(
                                productsOk[index].productId,
                                style:
                                    const TextStyle(fontSize: 12, color: black),
                              ),
                              onTap: () {
                                debugPrint(
                                    'product: ${productsOk[index].toMap()}');
                              },
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "Cant: ${productsOk[index].quantity}",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: primaryColorApp),
                                      ),
                                      const Spacer(),
                                      Text(
                                        "Sepa: ${productsOk[index].quantitySeparate}",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: primaryColorApp),
                                      ),
                                    ],
                                  ),
                                  Text(
                                      "Ubicacion destino: ${productsOk[index].locationDestId}",
                                      style: const TextStyle(
                                          fontSize: 12, color: black)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    actions: [
                      ElevatedButton(
                          onPressed: () {
                            //cerramos el dialog
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColorApp,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Cerrar",
                            style: TextStyle(color: white, fontSize: 14),
                          ))
                    ],
                  );
                },
              );
            },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Image.asset(
                "assets/icons/producto.png",
                color: primaryColorApp,
                width: 20,
              ),
              const SizedBox(
                width: 10,
              ),
              const Text("Productos:  ",
                  style: TextStyle(
                    fontSize: 12,
                  )),
              Text(
                productsOk.length.toString(),
                style: TextStyle(color: primaryColorApp, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
