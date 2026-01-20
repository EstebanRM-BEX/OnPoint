// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/home/bloc/home_bloc.dart';
import 'package:wms_app/src/presentation/views/home/widgets/background.dart';
import 'package:wms_app/src/presentation/views/home/widgets/update_app_dialog_widget.dart'; // Asegúrate de importar esto si no está
import 'package:wms_app/src/presentation/views/home/widgets/widget.dart';
import 'package:wms_app/src/presentation/views/inventario/screens/bloc/inventario_bloc.dart';
import 'package:wms_app/src/presentation/views/user/screens/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/user/screens/widgets/dialog_info_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/services/preferences.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: white,
      body: Container(
          width: size.width,
          height: size.height,
          color: primaryColorApp, // Color de fondo blanco
          child: Stack(
            children: [
              const Background(),
              // ⚡️ CORRECCIÓN: Anidación manual de Listeners (Adiós MultiBlocListener)
              
              // 1. Primer Listener: HomeBloc
              BlocListener<HomeBloc, HomeState>(
                listener: (context, state) {
                  if (state is AppVersionUpdateState) {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return UpdateAppDialog();
                        });
                  }

                  if (state is AppVersionLoadedState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("No hay actualizaciones disponibles"),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
                // 2. Segundo Listener: InventarioBloc (Hijo del primero)
                child: BlocListener<InventarioBloc, InventarioState>(
                  listener: (context, state) {
                    if (state is GetProductsLoadingInventory) {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return const DialogLoading(
                                message: 'Descargando productos...');
                          });
                    }

                    if (state is GetProductsSuccess) {
                      // Usar Navigator.of(context).pop() es más seguro
                      if (Navigator.canPop(context)) Navigator.pop(context);
                      
                      Get.snackbar(
                        '360 Software Informa',
                        "Se han descargado ${state.products.length} productos",
                        backgroundColor: white,
                        colorText: primaryColorApp,
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                      );
                    }

                    if (state is GetProductsFailureInventory) {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                      
                      Get.snackbar(
                        '360 Software Informa',
                        state.error,
                        backgroundColor: white,
                        colorText: primaryColorApp,
                        icon: const Icon(Icons.error, color: Colors.red),
                      );
                    }
                  },
                  // 3. Child Visual: BlocConsumer de UserBloc (Hijo del segundo)
                  child: BlocConsumer<UserBloc, UserState>(
                    listener: (context, state) {
                      if (state is ConfigurationError) {
                        showScrollableErrorDialog(state.message);
                      }
                    },
                    builder: (context, state) {
                      final config = context.read<UserBloc>().configurations;
                      return SizedBox(
                        width: size.width,
                        height: size.height,
                        child: Container(
                          padding: const EdgeInsets.only(
                              left: 10, top: 35, right: 10),
                          width: size.width,
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Card(
                                  color: white,
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Card(
                                              color: white,
                                              elevation: 2,
                                              child: IconButton(
                                                  onPressed: () {
                                                    Navigator
                                                        .pushReplacementNamed(
                                                            context, '/home');
                                                  },
                                                  icon: Icon(Icons.arrow_back,
                                                      color: primaryColorApp,
                                                      size: 30)),
                                            ),
                                            const SizedBox(width: 10),
                                            Text("Bienvenido a,  ",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: primaryColorApp)),
                                            // Text('WMS',
                                            const Text('OnPoint',
                                                style: TextStyle(
                                                    fontSize: 14, color: black))
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Card(
                                  color: white,
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        context
                                            .read<HomeBloc>()
                                            .add(AppVersionEvent());
                                      },
                                      style: ElevatedButton.styleFrom(
                                          minimumSize:
                                              const Size(double.infinity, 30),
                                          backgroundColor: grey),
                                      child: const Text(
                                        "Comprobar actualizaciones",
                                        style: TextStyle(color: white),
                                      ),
                                    ),
                                  ),
                                ),
                                Card(
                                  color: white,
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Text("Nombre: ",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: primaryColorApp)),
                                            // Text('WMS',
                                            Text(
                                                config.result?.result?.name ??
                                                    '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 14, color: black))
                                          ],
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text("Correo: ",
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: primaryColorApp)),
                                        ),
                                        SizedBox(
                                          width: size.width * 0.9,
                                          child: Text(
                                              config.result?.result?.email ??
                                                  '',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 14, color: black)),
                                        ),
                                        Row(
                                          children: [
                                            Text("Rol: ",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: primaryColorApp)),
                                            // Text('WMS',
                                            Text(
                                                config.result?.result?.rol ??
                                                    '',
                                                style: const TextStyle(
                                                    fontSize: 14, color: black))
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text("Version App: ",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: primaryColorApp)),
                                            // Text('WMS',
                                            Text(
                                                context
                                                    .read<UserBloc>()
                                                    .versionApp,
                                                style: const TextStyle(
                                                    fontSize: 14, color: black))
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text("Url: ",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: primaryColorApp)),
                                            // Text('WMS',
                                            Text(
                                                Preferences.urlWebsite
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontSize: 14, color: black))
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text("DataBase: ",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: primaryColorApp)),
                                            // Text('WMS',
                                            Text(
                                                Preferences.nameDatabase
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontSize: 14, color: black))
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text("Version Database Onpoint: ",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: primaryColorApp)),
                                            // Text('WMS',
                                            const Text('16',
                                                style: TextStyle(
                                                    fontSize: 14, color: black))
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Card(
                                    color: white,
                                    elevation: 2,
                                    child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          children: [
                                            Center(
                                              child: Text("Informacion PDA:",
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: primaryColorApp)),
                                            ),
                                            Row(
                                              children: [
                                                Text("Modelo: ",
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            primaryColorApp)),
                                                // Text('WMS',
                                                Text(
                                                    context
                                                        .read<UserBloc>()
                                                        .modelo,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color: black))
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text("Version: ",
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            primaryColorApp)),
                                                // Text('WMS',
                                                Text(
                                                    context
                                                        .read<UserBloc>()
                                                        .version,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color: black))
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text("Fabricante: ",
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            primaryColorApp)),
                                                // Text('WMS',
                                                Text(
                                                    context
                                                        .read<UserBloc>()
                                                        .fabricante,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color: black))
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text("Mac: ",
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            primaryColorApp)),
                                                // Text('WMS',
                                                Text(
                                                    context
                                                        .read<UserBloc>()
                                                        .mac,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color: black))
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text("IMEI: ",
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            primaryColorApp)),
                                                // Text('WMS',
                                                Text(
                                                    context
                                                        .read<UserBloc>()
                                                        .imei,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color: black))
                                              ],
                                            ),
                                          ],
                                        ))),
                                Card(
                                  color: white,
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    child: Column(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            context
                                                .read<InventarioBloc>()
                                                .add(GetProductsEvent());
                                          },
                                          style: ElevatedButton.styleFrom(
                                              minimumSize: const Size(
                                                  double.infinity, 30),
                                              backgroundColor: grey),
                                          child: const Text(
                                            "Descargar productos",
                                            style: TextStyle(color: white),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    backgroundColor: white,
                                                    title: Center(
                                                      child: Text("Alamacenes",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  primaryColorApp)),
                                                    ),
                                                    content: SizedBox(
                                                      height: 300,
                                                      width: size.width * 0.9,
                                                      child: ListView.builder(
                                                        itemCount: context
                                                            .read<UserBloc>()
                                                            .almacenes
                                                            .length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          return Card(
                                                            color: white,
                                                            elevation: 2,
                                                            child: ListTile(
                                                              title: Text(
                                                                  context
                                                                          .read<
                                                                              UserBloc>()
                                                                          .almacenes[
                                                                              index]
                                                                          .name ??
                                                                      'Sin nombre',
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color:
                                                                          black)),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    actions: [
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                            minimumSize:
                                                                const Size(
                                                                    double
                                                                        .infinity,
                                                                    30),
                                                            backgroundColor:
                                                                primaryColorApp),
                                                        child: const Text(
                                                            "Cerrar",
                                                            style: TextStyle(
                                                                color: white)),
                                                      ),
                                                    ],
                                                  );
                                                });
                                          },
                                          style: ElevatedButton.styleFrom(
                                              minimumSize: const Size(
                                                  double.infinity, 30),
                                              backgroundColor: grey),
                                          child: const Text(
                                            "Ver Almacenes",
                                            style: TextStyle(color: white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: size.width,
                                  height: 350,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 10),
                                        Card(
                                          color: white,
                                          elevation: 3,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              children: [
                                                Center(
                                                  child: Text("Accesos:",
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              primaryColorApp)),
                                                ),
                                                const SizedBox(height: 10),
                                                Row(
                                                  children: [
                                                    const Text(
                                                        "Acceso al modulo de produccion: ",
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color: black)),
                                                    const Spacer(),
                                                    Checkbox(
                                                        value: config
                                                                .result
                                                                ?.result
                                                                ?.accessProductionModule ??
                                                            false,
                                                        onChanged: null),
                                                    IconButton(
                                                        onPressed: () {
                                                          showDialog(
                                                              context: context,
                                                              builder:
                                                                  (context) {
                                                                return const DialogInfo(
                                                                  title:
                                                                      "Acceso al modulo de produccion",
                                                                  body:
                                                                      "Acceso al modulo de produccion en la aplicacion",
                                                                );
                                                              });
                                                        },
                                                        icon: Icon(Icons.help,
                                                            color:
                                                                primaryColorApp))
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        //todo: permisos de picking
                                        Visibility(
                                          visible: config.result?.result?.rol ==
                                                  'picking' ||
                                              config.result?.result?.rol ==
                                                  'admin',
                                          child: Card(
                                            elevation: 3,
                                            color: white,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                children: [
                                                  Center(
                                                    child: Text(
                                                        "Permisos Picking:",
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                primaryColorApp)),
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Ocultar accion de validar\npicking por pedido : ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.hideValidatePicking ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Ocultar accion de validar picking",
                                                                    body:
                                                                        "Ocultar  accion de validar picking en la aplicacion",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Ubicacion origen manual: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.locationPickingManual ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Ubicacion origen manual",
                                                                    body:
                                                                        "Permite seleccionar la ubicacion de origen en el proceso del picking de forma manual",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Seleccion producto manual: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.manualProductSelection ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Seleccionar producto manual",
                                                                    body:
                                                                        "Permite seleccionar el producto en el proceso del picking de forma manual",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Seleccionar cantidad manual: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.manualQuantity ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Seleccionar cantidad manual",
                                                                    body:
                                                                        "Permite seleccionar la cantidad en el proceso del picking de forma manual",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Ubicacion destino manual: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.manualSpringSelection ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Ubicacion destino manual",
                                                                    body:
                                                                        "Permite seleccionar la ubicacion destino en el proceso del picking de forma manual",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Ver detalles picking: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.showDetallesPicking ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Ver detalles picking",
                                                                    body:
                                                                        "Permite ver los detalles del picking de manera mas detallada, como la cantidad de productos, ubicaciones, etc.",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Ver proximas ubicaciones: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.showNextLocationsInDetails ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Ver proximas ubicaciones",
                                                                    body:
                                                                        "Permite ver las proximas ubicaciones en los detalles del picking",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
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
                                          visible: config.result?.result?.rol ==
                                                  'packing' ||
                                              config.result?.result?.rol ==
                                                  'admin',
                                          child: Card(
                                            color: white,
                                            elevation: 3,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                children: [
                                                  Center(
                                                    child: Text(
                                                        "Permisos Packing:",
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                primaryColorApp)),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Ocultar accion de validar\npacking por pedido: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.hideValidatePacking ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Ocultar accion de validar packing",
                                                                    body:
                                                                        "Ocultar  accion de validar packing en la aplicacion",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Ubicacion de origen manual: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.locationPackManual ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Ubicacion de origen manual",
                                                                    body:
                                                                        "Permite seleccionar la ubicacion de origen en el proceso del packing de forma manual",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Seleccion producto manual: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.manualProductSelectionPack ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Seleccionar producto manual",
                                                                    body:
                                                                        "Permite seleccionar el producto en el proceso del packing de forma manual",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Seleccionar cantidad manual: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.manualQuantityPack ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Seleccionar cantidad manual",
                                                                    body:
                                                                        "Permite seleccionar la cantidad en el proceso del packing de forma manual",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Ubicacion destino manual: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.manualSpringSelectionPack ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Ubicacion destino manual",
                                                                    body:
                                                                        "Permite seleccionar la ubicacion destino  en el proceso del packing de forma manual",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Seleccion masiva de productos: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.scanProduct ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Seleccion masiva de productos",
                                                                    body:
                                                                        "Permite seleccionar de manera maisvo los productos a empacar directamente sin certificar la cantidad en el procesos de packing",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
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
                                          visible: config.result?.result?.rol ==
                                                  'reception' ||
                                              config.result?.result?.rol ==
                                                  'admin',
                                          child: Card(
                                            elevation: 3,
                                            color: white,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                children: [
                                                  Center(
                                                    child: Text(
                                                        "Permisos Recepcion:",
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                primaryColorApp)),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Mover mas de lo planteado: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.allowMoveExcess ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Mover mas de lo planteado",
                                                                    body:
                                                                        "Permite mover mas de lo planteado en el proceso de recepcion",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Mostrar campo propietario: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.showOwnerField ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Mostrar campo propietario",
                                                                    body:
                                                                        "Permite mostrar el campo de propietario en el proceso de recepcion",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Ocultar cantidad: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.hideExpectedQty ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Ocultar cantidad",
                                                                    body:
                                                                        "Ocualtar cantidad para el proceso de recepcion",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Seleccionar producto manual: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.manualProductReading ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Seleccionar producto manual",
                                                                    body:
                                                                        "Permite seleccionar el producto en el proceso del recepcion de forma manual",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Ubicacion destino manual: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.scanDestinationLocationReception ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Ubicacion destino manual",
                                                                    body:
                                                                        "Permite seleccionar la ubicacion destino  en el proceso de recepcion de forma manual",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Ocultar accion de validar\nrecepcion : ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.hideValidateReception ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Ocultar accion de validar recepcion",
                                                                    body:
                                                                        "Ocultar  accion de validar recepcion en la aplicacion",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        //todo permisos para transferencias
                                        Visibility(
                                          visible: config.result?.result?.rol ==
                                                  'transfer' ||
                                              config.result?.result?.rol ==
                                                  'admin',
                                          child: Card(
                                            elevation: 3,
                                            color: white,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                children: [
                                                  Center(
                                                    child: Text(
                                                        "Permisos Transferencia:",
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                primaryColorApp)),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Ubicación de origen manual: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.manualSourceLocationTransfer ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Ubicación de origen manual",
                                                                    body:
                                                                        "Permite seleccionar la ubicacion de origen en el proceso de transferencia de forma manual",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Seleccionar producto manual: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.manualProductSelectionTransfer ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Seleccionar producto manual",
                                                                    body:
                                                                        "Permite seleccionar el producto en el proceso de transferencia de forma manual",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Ubicación destino manual : ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.manualDestLocationTransfer ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Ubicación destino manual",
                                                                    body:
                                                                        "Permite seleccionar la ubicacion de destino en el proceso de transferencia de forma manual",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Seleccionar cantidad manual : ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.manualQuantityTransfer ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Seleccionar cantidad manual",
                                                                    body:
                                                                        "Permite seleccionar la cantidad en el proceso de transferencia de forma manual",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Ocultar accion de validar\ntransferencia : ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.hideValidateTransfer ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Ocultar accion de validar transferencia",
                                                                    body:
                                                                        "Ocultar  accion de validar transferencia en la aplicacion",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        //todo permisos de inventario
                                        Visibility(
                                          visible: config.result?.result?.rol ==
                                                  'inventory' ||
                                              config.result?.result?.rol ==
                                                  'admin',
                                          child: Card(
                                            elevation: 3,
                                            color: white,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                children: [
                                                  Center(
                                                    child: Text(
                                                        "Permisos Inventario:",
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                primaryColorApp)),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Ver cantidad a contar: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.countQuantityInventory ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Ver cantidad a contar",
                                                                    body:
                                                                        "Permite ver la cantidad a contar en el proceso de inventario",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Seleccionar producto manual: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.manualProductSelectionInventory ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Seleccionar producto manual",
                                                                    body:
                                                                        "Permite seleccionar el producto en el proceso de inventario de forma manual",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                          "Ubicación manual: ",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: black)),
                                                      const Spacer(),
                                                      Checkbox(
                                                          value: config
                                                                  .result
                                                                  ?.result
                                                                  ?.locationManualInventory ??
                                                              false,
                                                          onChanged: null),
                                                      IconButton(
                                                          onPressed: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return const DialogInfo(
                                                                    title:
                                                                        "Ubicación manual",
                                                                    body:
                                                                        "Permite seleccionar la ubicacion en el proceso de inventario de forma manual",
                                                                  );
                                                                });
                                                          },
                                                          icon: Icon(Icons.help,
                                                              color:
                                                                  primaryColorApp))
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
                                                  child: Text(
                                                      "Permisos Informacion Rapida:",
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              primaryColorApp)),
                                                ),
                                                const SizedBox(height: 10),
                                                Row(
                                                  children: [
                                                    const Text(
                                                        "Editar producto: ",
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color: black)),
                                                    const Spacer(),
                                                    Checkbox(
                                                        value: config
                                                                .result
                                                                ?.result
                                                                ?.updateItemInventory ??
                                                            false,
                                                        onChanged: null),
                                                    IconButton(
                                                        onPressed: () {
                                                          showDialog(
                                                              context: context,
                                                              builder:
                                                                  (context) {
                                                                return const DialogInfo(
                                                                  title:
                                                                      "Editar producto",
                                                                  body:
                                                                      "Permite editar la informacion del producto en el modulo de informacion rapida",
                                                                );
                                                              });
                                                        },
                                                        icon: Icon(Icons.help,
                                                            color:
                                                                primaryColorApp))
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    const Text(
                                                        "Editar ubicacion: ",
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color: black)),
                                                    const Spacer(),
                                                    Checkbox(
                                                        value: config
                                                                .result
                                                                ?.result
                                                                ?.updateItemInventory ??
                                                            false,
                                                        onChanged: null),
                                                    IconButton(
                                                        onPressed: () {
                                                          showDialog(
                                                              context: context,
                                                              builder:
                                                                  (context) {
                                                                return const DialogInfo(
                                                                  title:
                                                                      "Editar Ubicacion",
                                                                  body:
                                                                      "Permite editar la informacion de la ubicacion en el modulo de informacion rapida",
                                                                );
                                                              });
                                                        },
                                                        icon: Icon(Icons.help,
                                                            color:
                                                                primaryColorApp))
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
                                                  child: Text(
                                                      "Permisos Devolucion:",
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              primaryColorApp)),
                                                ),
                                                const SizedBox(height: 10),
                                                Row(
                                                  children: [
                                                    const Text(
                                                        "Ubicacion destino: ",
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color: black)),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      config.result?.result
                                                                  ?.returnsLocationDestOption ==
                                                              "predefined"
                                                          ? "Predefinida"
                                                          : "Dinamica",
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              primaryColorApp),
                                                    ),
                                                    const Spacer(),
                                                    IconButton(
                                                        onPressed: () {
                                                          showDialog(
                                                              context: context,
                                                              builder:
                                                                  (context) {
                                                                return const DialogInfo(
                                                                  title:
                                                                      "Ubicacion destino devolucion",
                                                                  body:
                                                                      "Permite seleccionar la ubicacion destino en el proceso de devolucion si se encuentra en modo dinamica",
                                                                );
                                                              });
                                                        },
                                                        icon: Icon(Icons.help,
                                                            color:
                                                                primaryColorApp))
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    //modal de confirmacion
                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            actionsAlignment:
                                                MainAxisAlignment.center,
                                            title: Center(
                                                child: Text(
                                                    "Eliminar Base de Datos",
                                                    style: TextStyle(
                                                        color: primaryColorApp,
                                                        fontSize: 14))),
                                            content: const Text(
                                                "¿Estas seguro de eliminar la base de datos?\nEsta accion no se puede deshacer y perderas todo el progreso que llevas realizado y esta guardado en la base de datos",
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: black)),
                                            actions: [
                                              ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              grey),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text("Cancelar",
                                                      style: TextStyle(
                                                          color: white))),
                                              ElevatedButton(
                                                  onPressed: () async {
                                                    await DataBaseSqlite()
                                                        .deleteBDCloseSession();
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                            const SnackBar(
                                                      content: Text(
                                                          "Base de datos eliminada correctamente"),
                                                    ));
                                                    Navigator.pop(context);
                                                    Navigator
                                                        .pushReplacementNamed(
                                                            context, '/home');
                                                  },
                                                  child: const Text("Aceptar")),
                                            ],
                                          );
                                        });
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: grey),
                                  child: const Text(
                                    "Eliminar Base de Datos",
                                    style: TextStyle(color: white),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          )),
    );
  }
}