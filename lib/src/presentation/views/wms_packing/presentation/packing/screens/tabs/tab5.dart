import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/un_pack_request.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/screens/widgets/dialog_unPacking.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/bloc/packing_pedido_bloc.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/packing_response_model.dart';

class Tab5Screen extends StatefulWidget {
  const Tab5Screen({super.key});

  @override
  State<Tab5Screen> createState() => _Tab5ScreenState();
}

class _Tab5ScreenState extends State<Tab5Screen> {
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();
  FocusNode focusNodeBuscar = FocusNode(); //cantidad textformfield

  final TextEditingController _controllerToDo = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PackingPedidoBloc>().add(LoadAllLocationsEvent());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FocusScope.of(context).requestFocus(focusNodeBuscar);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    focusNodeBuscar.dispose();
    super.dispose();
  }

  void validateBarcode(String value, BuildContext context) {
    final bloc = context.read<PackingPedidoBloc>();
    final scan = value.trim().toLowerCase();

    _controllerToDo.clear();
    debugPrint('🔎 Scan barcode (packing pedido paquete): $scan');

    // MODO 2: Si ya hay un paquete expandido, validar UBICACIÓN
    if (bloc.expandedPackage.isNotEmpty) {
      final ubicacionEncontrada = bloc.ubicaciones.firstWhere(
        (u) =>
            u.barcode?.toLowerCase() == scan || u.name?.toLowerCase() == scan,
        orElse: () => ResultUbicaciones(),
      );

      if (ubicacionEncontrada.id != null) {
        Get.defaultDialog(
          title: 'Confirmación',
          titleStyle: TextStyle(color: primaryColorApp),
          middleText:
              '¿Quieres asignar esta ubicación de destino (${ubicacionEncontrada.name}) a la caja ${bloc.expandedPackage}?',
          textConfirm: 'Aceptar',
          textCancel: 'Cancelar',
          confirmTextColor: Colors.white,
          buttonColor: primaryColorApp,
          onConfirm: () {
            Get.back();
            bloc.add(AssignLocationToPackageEvent(
              bloc.expandedPackage,
              ubicacionEncontrada.name ?? '',
              ubicacionEncontrada.id ?? 0,
            ));
          },
          onCancel: () {
            Get.back();
          },
        );
      } else {
        _vibrationService.vibrate();
        _audioService.playErrorSound();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Ubicación no encontrada"),
          duration: Duration(milliseconds: 1000),
        ));
      }
    }
    // MODO 1: Buscar PAQUETE por nombre
    else {
      final package = bloc.packages.firstWhere(
        (p) => p.packingBarcode?.toLowerCase() == scan,
        orElse: () => Paquete(),
      );

      if (package.id != null) {
        bloc.add(ExpandPackageEvent(package.packingBarcode ?? ''));

        // Scroll al inicio
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        _vibrationService.vibrate();
        _audioService.playErrorSound();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Paquete no encontrado"),
          duration: Duration(milliseconds: 1000),
        ));
      }
    }

    Future.microtask(() => focusNodeBuscar.requestFocus());
  }

  void _showQRDialog(BuildContext context, String data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          title: Center(
              child: Text(
            "Información del paquete",
            style: TextStyle(
              color: primaryColorApp,
              fontSize: 16,
            ),
          )),
          content: SizedBox(
            height: 200, // Establecemos el tamaño del dialogo
            width: 200,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Esto hace que el contenido sea flexible
              children: [
                QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ],
            ),
          ),
          actions: <Widget>[
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
                'Cerrar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PackingPedidoBloc, PackingPedidoState>(
      listener: (context, state) {
        if (state is UnPackignSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            duration: const Duration(milliseconds: 1000),
            content: Text(state.message),
            backgroundColor: Colors.green[200],
          ));
        }

        if (state is AssignLocationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            duration: const Duration(milliseconds: 2000),
            content: Text(state.msg),
            backgroundColor: Colors.green,
          ));
        }

        if (state is AssignLocationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            duration: const Duration(milliseconds: 3000),
            content: Text(state.error),
            backgroundColor: Colors.red,
          ));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              const SizedBox(height: 10),
              Text("Listado de empaques",
                  style: TextStyle(
                      fontSize: 14,
                      color: primaryColorApp,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              //*espacio para escanear y buscar el producto
              if (context
                      .read<PackingPedidoBloc>()
                      .currentPedidoPack
                      .configPacking ==
                  'cluster')
                BarcodeScannerField(
                  controller: _controllerToDo,
                  focusNode: focusNodeBuscar,
                  onBarcodeScanned: (value, context) {
                    return validateBarcode(value, context);
                  },
                ),
              Expanded(
                child: (context.read<PackingPedidoBloc>().packages.isEmpty)
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('No hay empaques',
                                style: TextStyle(fontSize: 14, color: grey)),
                            Text('Realiza el proceso de empaque',
                                style: TextStyle(fontSize: 12, color: grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(
                            bottom: 10, left: 10, right: 10),
                        itemCount:
                            context.read<PackingPedidoBloc>().packages.length,
                        itemBuilder: (BuildContext context, int index) {
                          final bloc = context.read<PackingPedidoBloc>();

                          // --- LÓGICA DE ORDENAMIENTO ---
                          List<Paquete> sortedPackages =
                              List.from(bloc.packages);
                          if (bloc.expandedPackage.isNotEmpty) {
                            final foundIdx = sortedPackages.indexWhere((p) =>
                                p.packingBarcode?.toLowerCase() ==
                                bloc.expandedPackage.toLowerCase());
                            if (foundIdx != -1) {
                              final pToMove = sortedPackages.removeAt(foundIdx);
                              sortedPackages.insert(0, pToMove);
                            }
                          }
                          // ------------------------------

                          final package = sortedPackages[index];

                          // Filtrar los productos de acuerdo al id_package del paquete actual
                          final filteredProducts = context
                              .read<PackingPedidoBloc>()
                              .listOfProductos
                              .where(
                                  (product) => product.idPackage == package.id)
                              .toList();

                          return CustomExpansionTile(
                            key: ValueKey(package.id ?? package.name),
                            isExpanded: bloc.expandedPackage.toLowerCase() ==
                                package.packingBarcode?.toLowerCase(),
                            onTap: () {
                              if (bloc.expandedPackage.toLowerCase() ==
                                  package.packingBarcode?.toLowerCase()) {
                                bloc.add(ExpandPackageEvent(''));
                              } else {
                                bloc.add(ExpandPackageEvent(
                                    package.packingBarcode ?? ''));
                              }
                              Future.microtask(
                                  () => focusNodeBuscar.requestFocus());
                            },
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${package.name}",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: primaryColorApp,
                                      fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "${package.consecutivo}",
                                      style:
                                          TextStyle(fontSize: 10, color: black),
                                    ),
                                    const SizedBox(width: 10),
                                    if (context
                                            .read<PackingPedidoBloc>()
                                            .currentPedidoPack
                                            .configPacking ==
                                        'cluster')
                                      Row(
                                        children: [
                                          Icon(Icons.scale,
                                              size: 12, color: primaryColorApp),
                                          const SizedBox(width: 5),
                                          Text(
                                            package.peso == null
                                                ? "0.0"
                                                : "${package.peso}",
                                            style: const TextStyle(
                                                fontSize: 12, color: black),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "Cantidad de productos: ${package.cantidadProductos}",
                                      style: const TextStyle(
                                          fontSize: 12, color: black),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () async {
                                        var url =
                                            await PrefUtils.getEnterprise();

                                        url =
                                            '$url/package/info/${package.name}';

                                        _showQRDialog(context, url);
                                      },
                                      child: Icon(
                                        Icons.qr_code,
                                        color: primaryColorApp,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                ),
                                if (bloc.currentPedidoPack.configPacking ==
                                    'cluster')
                                  Text(
                                    "Ubicación: ${package.locationDestName}",
                                    style: const TextStyle(
                                        fontSize: 12, color: black),
                                  ),
                                if (context
                                        .read<PackingPedidoBloc>()
                                        .currentPedidoPack
                                        .configPacking ==
                                    'cluster')
                                  Row(
                                    children: [
                                      Text(
                                        "Tipo de empaque: ",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: primaryColorApp),
                                      ),
                                      Text(
                                        package.typePaquete ?? 'No asignado',
                                        style: const TextStyle(
                                            fontSize: 12, color: black),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 8),
                                child: Column(
                                  children: [
                                    if (bloc.currentLocation.id != null &&
                                        bloc.expandedPackage.toLowerCase() ==
                                            package.name?.toLowerCase())
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                        child: Row(
                                          children: [
                                            Icon(Icons.location_on,
                                                color: primaryColorApp,
                                                size: 16),
                                            const SizedBox(width: 5),
                                            Text(
                                              "Destino: ${bloc.currentLocation.name}",
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryColorApp),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (bloc.currentPedidoPack.configPacking ==
                                        'cluster')
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pushReplacementNamed(
                                            context,
                                            'locations-dest-packing',
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColorApp,
                                          minimumSize:
                                              const Size(double.infinity, 40),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: const Text(
                                          'Asignar ubicación de destino',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Aquí generamos la lista de productos filtrados
                              SizedBox(
                                height: 200,
                                child: ListView.builder(
                                  itemCount: filteredProducts
                                      .length, // La cantidad de productos filtrados
                                  itemBuilder: (context, index) {
                                    final product = filteredProducts[index];
                                    return GestureDetector(
                                      onTap: () {
                                        debugPrint(
                                            "info paquete: ${package.toMap()}");
                                        debugPrint("--------------------");
                                        debugPrint(
                                            "Producto seleccionado: ${product.toMap()}");
                                      },
                                      child: Card(
                                        color: white,
                                        elevation: 2,
                                        child: ListTile(
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                    product.productId ?? "",
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black)),
                                              ),
                                              if (product.barcode != null)
                                                GestureDetector(
                                                  onTap: () {
                                                    //validar si el producto  actual se encuentra  la lista de por hacer

                                                    bool isInProgress = context
                                                        .read<
                                                            PackingPedidoBloc>()
                                                        .listOfProductosProgress
                                                        .any((p) =>
                                                            p.productId ==
                                                            product.productId);
                                                    if (isInProgress) {
                                                      Get.defaultDialog(
                                                        title:
                                                            '360 Software Informa',
                                                        titleStyle:
                                                            const TextStyle(
                                                                color:
                                                                    Colors.red,
                                                                fontSize: 18),
                                                        middleText:
                                                            "Este producto se encuentra en estado por hacer, por favor seleccione otro para desempacar",
                                                        middleTextStyle:
                                                            const TextStyle(
                                                                color: black,
                                                                fontSize: 14),
                                                        backgroundColor:
                                                            Colors.white,
                                                        radius: 10,
                                                        actions: [
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              Get.back();
                                                            },
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  primaryColorApp,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                              ),
                                                            ),
                                                            child: const Text(
                                                                'Aceptar',
                                                                style: TextStyle(
                                                                    color:
                                                                        white)),
                                                          ),
                                                        ],
                                                      );
                                                      return;
                                                    }
                                                    //mensaje de confirmacion de desempacar el
                                                    showDialog(
                                                      context: context,
                                                      builder: (_) =>
                                                          DialogUnPacking(
                                                        product: product,
                                                        package: package,
                                                        onConfirm: () async {
                                                          final idOperario =
                                                              await PrefUtils
                                                                  .getUserId();

                                                          if (!context.mounted)
                                                            return;
                                                          context
                                                              .read<
                                                                  PackingPedidoBloc>()
                                                              .add(
                                                                  UnPackingEvent(
                                                                UnPackRequest(
                                                                  idTransferencia:
                                                                      package.batchId ??
                                                                          0,
                                                                  idPaquete:
                                                                      package.id ??
                                                                          0,
                                                                  listItems: [
                                                                    ListItemUnpack(
                                                                      idMove:
                                                                          product.idMove ??
                                                                              0,
                                                                      observacion:
                                                                          "Desempacado",
                                                                      idOperario:
                                                                          idOperario,
                                                                    )
                                                                  ],
                                                                ),
                                                                product.pedidoId ??
                                                                    0,
                                                                product.idProduct ??
                                                                    0,
                                                                package
                                                                    .consecutivo,
                                                              ));
                                                        },
                                                      ),
                                                    );
                                                  },
                                                  child: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                    size: 20,
                                                  ),
                                                ),
                                            ],
                                          ), // Muestra el nombre del producto
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  if (product.isCertificate !=
                                                      0)
                                                    RichText(
                                                      text: TextSpan(
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.black,
                                                        ),
                                                        children: <TextSpan>[
                                                          const TextSpan(
                                                            text:
                                                                "Cantidad empacada: ",
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: black),
                                                          ),
                                                          TextSpan(
                                                            text:
                                                                (product.quantitySeparate ??
                                                                        0.0)
                                                                    .toString(),
                                                            style: TextStyle(
                                                              color:
                                                                  primaryColorApp,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                  if (product.isCertificate ==
                                                      0)
                                                    RichText(
                                                      text: const TextSpan(
                                                        style: TextStyle(
                                                          fontSize:
                                                              14, // Tamaño del texto
                                                          color: Colors
                                                              .black, // Color del texto por defecto (puedes cambiarlo aquí)
                                                        ),
                                                        children: <TextSpan>[
                                                          TextSpan(
                                                              text:
                                                                  "Cantidad: ",
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      black)), // Parte del texto en color negro (o el color que prefieras)

                                                          TextSpan(
                                                            text:
                                                                "No certificado", // La cantidad en color rojo
                                                            style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                                fontSize:
                                                                    12), // Estilo solo para la cantidad
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  //icono de check

                                                  Visibility(
                                                    visible:
                                                        product.isCertificate ==
                                                            0,
                                                    child: const Icon(
                                                        Icons.warning,
                                                        color: Colors.amber,
                                                        size: 15),
                                                  ),
                                                  //icono de check
                                                  Visibility(
                                                    visible:
                                                        product.isCertificate ==
                                                            1,
                                                    child: const Icon(
                                                        Icons.check,
                                                        color: green,
                                                        size: 15),
                                                  ),
                                                  const Spacer(),
                                                  RichText(
                                                    text: TextSpan(
                                                      style: const TextStyle(
                                                        fontSize:
                                                            14, // Tamaño del texto
                                                        color: Colors
                                                            .black, // Color del texto por defecto (puedes cambiarlo aquí)
                                                      ),
                                                      children: <TextSpan>[
                                                        const TextSpan(
                                                            text: "Unidades: ",
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    black)), // Parte del texto en color negro (o el color que prefieras)
                                                        TextSpan(
                                                          text:
                                                              "${product.unidades}", // La cantidad en color rojo
                                                          style: TextStyle(
                                                              color:
                                                                  primaryColorApp,
                                                              fontSize:
                                                                  12), // Estilo solo para la cantidad
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Visibility(
                                                visible:
                                                    product.isCertificate == 0,
                                                child: Row(
                                                  children: [
                                                    RichText(
                                                      text: TextSpan(
                                                        style: const TextStyle(
                                                          fontSize:
                                                              14, // Tamaño del texto
                                                          color: Colors
                                                              .black, // Color del texto por defecto (puedes cambiarlo aquí)
                                                        ),
                                                        children: <TextSpan>[
                                                          const TextSpan(
                                                              text:
                                                                  "Cantidad empacada: ",
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      black)), // Parte del texto en color negro (o el color que prefieras)

                                                          TextSpan(
                                                            text: (product
                                                                        .quantity ??
                                                                    0.0)
                                                                .toString(), // La cantidad en color rojo
                                                            style: TextStyle(
                                                                color:
                                                                    primaryColorApp,
                                                                fontSize:
                                                                    12), // Estilo solo para la cantidad
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Visibility(
                                                visible:
                                                    product.isCertificate == 1,
                                                child: Row(
                                                  children: [
                                                    RichText(
                                                      text: TextSpan(
                                                        style: const TextStyle(
                                                          fontSize:
                                                              14, // Tamaño del texto
                                                          color: Colors
                                                              .black, // Color del texto por defecto (puedes cambiarlo aquí)
                                                        ),
                                                        children: <TextSpan>[
                                                          const TextSpan(
                                                              text: "Novedad: ",
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      black)), // Parte del texto en color negro (o el color que prefieras)

                                                          TextSpan(
                                                            text: product
                                                                        .observation ==
                                                                    null
                                                                ? "Sin novedad"
                                                                : "${product.observation}", // La cantidad en color rojo
                                                            style: TextStyle(
                                                                color:
                                                                    primaryColorApp,
                                                                fontSize:
                                                                    12), // Estilo solo para la cantidad
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Visibility(
                                                visible:
                                                    product.manejaTemperatura ==
                                                        1,
                                                child: Row(
                                                  children: [
                                                    RichText(
                                                      text: TextSpan(
                                                        style: const TextStyle(
                                                          fontSize:
                                                              14, // Tamaño del texto
                                                          color: Colors
                                                              .black, // Color del texto por defecto (puedes cambiarlo aquí)
                                                        ),
                                                        children: <TextSpan>[
                                                          const TextSpan(
                                                              text:
                                                                  "Temperatura: ",
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      black)), // Parte del texto en color negro (o el color que prefieras)
                                                          TextSpan(
                                                            text: product
                                                                        .temperatura ==
                                                                    null
                                                                ? "Sin temperatura"
                                                                : "${product.temperatura}", // La cantidad en color rojo
                                                            style: TextStyle(
                                                                color:
                                                                    primaryColorApp,
                                                                fontSize:
                                                                    12), // Estilo solo para la cantidad
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Visibility(
                                                      visible:
                                                          product.image != "",
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          showImageDialog(
                                                            context,
                                                            product.image ??
                                                                '', // URL o path de la imagen
                                                          );
                                                        },
                                                        child: Icon(
                                                          Icons.image,
                                                          color:
                                                              primaryColorApp,
                                                          size: 23,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CustomExpansionTile extends StatelessWidget {
  final Widget title;
  final bool isExpanded;
  final VoidCallback onTap;
  final List<Widget> children;

  const CustomExpansionTile({
    super.key,
    required this.title,
    required this.isExpanded,
    required this.onTap,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isExpanded ? const Color.fromARGB(198, 138, 205, 247) : white,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 3,
      child: Column(
        children: [
          ListTile(
            onTap: onTap,
            title: title,
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
          ),
          AnimatedCrossFade(
            firstChild: Container(),
            secondChild: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(children: children),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
