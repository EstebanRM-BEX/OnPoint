import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import '../../domain/entities/user_configuration.dart';
import 'dialog_info_widget.dart';

class PermissionsWidget extends StatelessWidget {
  final UserProfile profile;

  const PermissionsWidget({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: white,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Center(
              child: Text("Accesos:",
                  style: TextStyle(fontSize: 14, color: primaryColorApp)),
            ),

            //todo: permisos de picking
            Visibility(
              visible: profile?.rol == 'picking' || profile?.rol == 'admin',
              child: Card(
                elevation: 3,
                color: white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Center(
                        child: Text("Permisos Picking:",
                            style: TextStyle(
                                fontSize: 14, color: primaryColorApp)),
                      ),
                      Row(
                        children: [
                          const Text(
                              "Ocultar accion de validar\npicking por pedido : ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.hideValidatePicking ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title:
                                            "Ocultar accion de validar picking",
                                        body:
                                            "Ocultar  accion de validar picking en la aplicacion",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Ubicacion origen manual: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.locationPickingManual ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Ubicacion origen manual",
                                        body:
                                            "Permite seleccionar la ubicacion de origen en el proceso del picking de forma manual",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Seleccion producto manual: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.manualProductSelection ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Seleccionar producto manual",
                                        body:
                                            "Permite seleccionar el producto en el proceso del picking de forma manual",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Seleccionar cantidad manual: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.manualQuantity ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Seleccionar cantidad manual",
                                        body:
                                            "Permite seleccionar la cantidad en el proceso del picking de forma manual",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Ubicacion destino manual: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.manualSpringSelection ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Ubicacion destino manual",
                                        body:
                                            "Permite seleccionar la ubicacion destino en el proceso del picking de forma manual",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Ver detalles picking: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.showDetallesPicking ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Ver detalles picking",
                                        body:
                                            "Permite ver los detalles del picking de manera mas detallada, como la cantidad de productos, ubicaciones, etc.",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Ver proximas ubicaciones: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value:
                                  profile?.showNextLocationsInDetails ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Ver proximas ubicaciones",
                                        body:
                                            "Permite ver las proximas ubicaciones en los detalles del picking",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            //todo permisos de packing
            Visibility(
              visible: profile?.rol == 'packing' || profile?.rol == 'admin',
              child: Card(
                color: white,
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Center(
                        child: Text("Permisos Packing:",
                            style: TextStyle(
                                fontSize: 14, color: primaryColorApp)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text(
                              "Ocultar accion de validar\npacking por pedido: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.hideValidatePacking ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title:
                                            "Ocultar accion de validar packing",
                                        body:
                                            "Ocultar  accion de validar packing en la aplicacion",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Ubicacion de origen manual: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.locationPackManual ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Ubicacion de origen manual",
                                        body:
                                            "Permite seleccionar la ubicacion de origen en el proceso del packing de forma manual",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Seleccion producto manual: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value:
                                  profile?.manualProductSelectionPack ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Seleccionar producto manual",
                                        body:
                                            "Permite seleccionar el producto en el proceso del packing de forma manual",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Seleccionar cantidad manual: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.manualQuantityPack ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Seleccionar cantidad manual",
                                        body:
                                            "Permite seleccionar la cantidad en el proceso del packing de forma manual",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Ubicacion destino manual: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value:
                                  profile?.manualSpringSelectionPack ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Ubicacion destino manual",
                                        body:
                                            "Permite seleccionar la ubicacion destino  en el proceso del packing de forma manual",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Selec masiva de productos: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.scanProduct ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Seleccion masiva de productos",
                                        body:
                                            "Permite seleccionar de manera maisvo los productos a empacar directamente sin certificar la cantidad en el procesos de packing",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            //todo permisos de recepcion
            Visibility(
              visible: profile?.rol == 'reception' || profile?.rol == 'admin',
              child: Card(
                elevation: 3,
                color: white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Center(
                        child: Text("Permisos Recepcion:",
                            style: TextStyle(
                                fontSize: 14, color: primaryColorApp)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text("Mover mas de lo planteado: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.allowMoveExcess ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Mover mas de lo planteado",
                                        body:
                                            "Permite mover mas de lo planteado en el proceso de recepcion",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Mostrar campo propietario: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.showOwnerField ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Mostrar campo propietario",
                                        body:
                                            "Permite mostrar el campo de propietario en el proceso de recepcion",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Ocultar cantidad: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.hideExpectedQty ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Ocultar cantidad",
                                        body:
                                            "Ocualtar cantidad para el proceso de recepcion",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Seleccionar producto manual: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.manualProductReading ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Seleccionar producto manual",
                                        body:
                                            "Permite seleccionar el producto en el proceso del recepcion de forma manual",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Ubicacion destino manual: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value:
                                  profile?.scanDestinationLocationReception ??
                                      false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Ubicacion destino manual",
                                        body:
                                            "Permite seleccionar la ubicacion destino  en el proceso de recepcion de forma manual",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Ocultar accion de validar\nrecepcion : ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.hideValidateReception ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title:
                                            "Ocultar accion de validar recepcion",
                                        body:
                                            "Ocultar  accion de validar recepcion en la aplicacion",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            //todo permisos para transferencias
            Visibility(
              visible: profile?.rol == 'transfer' || profile?.rol == 'admin',
              child: Card(
                elevation: 3,
                color: white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Center(
                        child: Text("Permisos Transferencia:",
                            style: TextStyle(
                                fontSize: 14, color: primaryColorApp)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text("Ubicación de origen manual: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.manualSourceLocationTransfer ??
                                  false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Ubicación de origen manual",
                                        body:
                                            "Permite seleccionar la ubicacion de origen en el proceso de transferencia de forma manual",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Seleccionar producto manual: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.manualProductSelectionTransfer ??
                                  false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Seleccionar producto manual",
                                        body:
                                            "Permite seleccionar el producto en el proceso de transferencia de forma manual",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Ubicación destino manual : ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value:
                                  profile?.manualDestLocationTransfer ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Ubicación destino manual",
                                        body:
                                            "Permite seleccionar la ubicacion de destino en el proceso de transferencia de forma manual",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Seleccionar cant manual : ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.manualQuantityTransfer ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Seleccionar cantidad manual",
                                        body:
                                            "Permite seleccionar la cantidad en el proceso de transferencia de forma manual",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                              "Ocultar accion de validar\ntransferencia : ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.hideValidateTransfer ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title:
                                            "Ocultar accion de validar transferencia",
                                        body:
                                            "Ocultar  accion de validar transferencia en la aplicacion",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            //todo permisos de inventario
            Visibility(
              visible: profile?.rol == 'inventory' || profile?.rol == 'admin',
              child: Card(
                elevation: 3,
                color: white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Center(
                        child: Text("Permisos Inventario:",
                            style: TextStyle(
                                fontSize: 14, color: primaryColorApp)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text("Ver cantidad a contar: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.countQuantityInventory ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Ver cantidad a contar",
                                        body:
                                            "Permite ver la cantidad a contar en el proceso de inventario",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Seleccionar producto manual: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.manualProductSelectionInventory ??
                                  false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Seleccionar producto manual",
                                        body:
                                            "Permite seleccionar el producto en el proceso de inventario de forma manual",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      ),
                      Row(
                        children: [
                          const Text("Ubicación manual: ",
                              style: TextStyle(fontSize: 14, color: black)),
                          const Spacer(),
                          Checkbox(
                              value: profile?.locationManualInventory ?? false,
                              onChanged: null),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return const DialogInfo(
                                        title: "Ubicación manual",
                                        body:
                                            "Permite seleccionar la ubicacion en el proceso de inventario de forma manual",
                                      );
                                    });
                              },
                              icon: Icon(Icons.help, color: primaryColorApp))
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),

            //todo permisos de info rapida
            Card(
              elevation: 3,
              color: white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Center(
                      child: Text("Permisos Informacion Rapida:",
                          style:
                              TextStyle(fontSize: 14, color: primaryColorApp)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text("Editar producto: ",
                            style: TextStyle(fontSize: 14, color: black)),
                        const Spacer(),
                        Checkbox(
                            value: profile?.updateItemInventory ?? false,
                            onChanged: null),
                        IconButton(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return const DialogInfo(
                                      title: "Editar producto",
                                      body:
                                          "Permite editar la informacion del producto en el modulo de informacion rapida",
                                    );
                                  });
                            },
                            icon: Icon(Icons.help, color: primaryColorApp))
                      ],
                    ),
                    Row(
                      children: [
                        const Text("Editar ubicacion: ",
                            style: TextStyle(fontSize: 14, color: black)),
                        const Spacer(),
                        Checkbox(
                            value: profile?.updateItemInventory ?? false,
                            onChanged: null),
                        IconButton(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return const DialogInfo(
                                      title: "Editar Ubicacion",
                                      body:
                                          "Permite editar la informacion de la ubicacion en el modulo de informacion rapida",
                                    );
                                  });
                            },
                            icon: Icon(Icons.help, color: primaryColorApp))
                      ],
                    ),
                  ],
                ),
              ),
            ),
            //todo permisos generales
            Card(
              elevation: 3,
              color: white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Center(
                      child: Text("Permisos Devolucion:",
                          style:
                              TextStyle(fontSize: 14, color: primaryColorApp)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text("Ubicacion destino: ",
                            style: TextStyle(fontSize: 14, color: black)),
                        const SizedBox(width: 10),
                        Text(
                          profile?.returnsLocationDestOption == "predefined"
                              ? "Predefinida"
                              : "Dinamica",
                          style:
                              TextStyle(fontSize: 14, color: primaryColorApp),
                        ),
                        const Spacer(),
                        IconButton(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return const DialogInfo(
                                      title: "Ubicacion destino devolucion",
                                      body:
                                          "Permite seleccionar la ubicacion destino en el proceso de devolucion si se encuentra en modo dinamica",
                                    );
                                  });
                            },
                            icon: Icon(Icons.help, color: primaryColorApp))
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
