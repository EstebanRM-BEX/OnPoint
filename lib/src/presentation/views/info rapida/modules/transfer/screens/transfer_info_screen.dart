import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/injection_container.dart';
// ignore_for_file: use_build_context_synchronously, unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/models/info_rapida_model.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/models/transfer_info_request.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/bloc/info_rapida_bloc.dart';
// import 'package:wms_app/src/presentation/views/info%20rapida/screens/quick%20info/bloc/info_rapida_bloc.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/transfer/bloc/transfer_info_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';

class TransferInfoScreen extends StatefulWidget {
  final InfoResult? infoRapidaResult;
  final Ubicacion? ubicacion;

  const TransferInfoScreen(
      {super.key, required this.infoRapidaResult, this.ubicacion});

  @override
  State<TransferInfoScreen> createState() => _TransferInfoScreenState();
}

class _TransferInfoScreenState extends State<TransferInfoScreen>
    with WidgetsBindingObserver {
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();

  @override
  void initState() {
    super.initState();
    // Añadimos el observer para escuchar el ciclo de vida de la app.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        // Aquí se ejecutan las acciones solo si la pantalla aún está montada
        showDialog(
          context: context,
          builder: (context) {
            return const DialogLoading(
              message: "Espere un momento...",
            );
          },
        );
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context);
        });
      }
    }
  }

//focus para escanear

  FocusNode focusNode1 = FocusNode(); // ubicacion Dest
  FocusNode focusNodeCantidad = FocusNode(); // Cantidad

  String? selectedLocation;

  //controller
  final TextEditingController _controllerLocationDest = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleDependencies();
  }

  void validateMuelle(String value) {
//VAMOS A VAIDAR QUE LA UBICACION DE DESTINO YA ESTE
    final bloc = context.read<TransferInfoBloc>();
    if (bloc.selectedLocationDest.id != 0 &&
        bloc.selectedLocationDest.id != null) {
      return;
    }

    // ✅ PROTECCIÓN 1: Si la lista de ubicaciones aún no carga, evitamos el CRASH.
    if (bloc.ubicaciones.isEmpty) {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Las ubicaciones aún no han cargado. Intente nuevamente."),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      // Limpiamos el campo para que el usuario pueda intentar de nuevo
      _controllerLocationDest.clear();
      Future.microtask(() => focusNode1.requestFocus());

      return;
    }

    final scan = value.trim().toLowerCase();
    // ✅ PROTECCIÓN 2: Uso seguro de firstWhere con manejo de nulos
    // (Aseguramos que name/barcode no sean nulos antes de comparar)
    ResultUbicaciones matchedUbicacion = bloc.ubicaciones.firstWhere(
        (ubicacion) => (ubicacion.barcode?.toLowerCase() ?? '') == scan,
        orElse: () =>
            ResultUbicaciones() // Retorna objeto vacío si no encuentra
        );

    // Validamos si se encontró una ubicación real (que tenga ID o Barcode válido)
    if (matchedUbicacion.barcode != null && matchedUbicacion.barcode != "") {
      bloc.add(ValidateFieldsEventTransfer(field: "muelle", isOk: true));
      bloc.add(ChangeLocationDestIsOkEventTransfer(
        true,
        matchedUbicacion,
      ));

      Future.microtask(() => focusNode1.requestFocus());
      _controllerLocationDest.clear();
    } else {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      debugPrint('Ubicacion no encontrada');
      // Feedback visual opcional
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ubicación de destino no encontrada")),
      );
      bloc.add(ValidateFieldsEventTransfer(field: "muelle", isOk: false));
      _controllerLocationDest.clear();

      Future.microtask(() => focusNode1.requestFocus());
    }
  }

  void _handleDependencies() {
    FocusScope.of(context).requestFocus(focusNode1);
    setState(() {});
  }

  void validateQuantity(dynamic quantity, BuildContext context) {
    final bloc = context.read<TransferInfoBloc>();

    String input = _cantidadController.text.trim();
    //validamos quantity

    // Si está vacío, usar la cantidad seleccionada del bloc
    if (input.isEmpty) {
      input = bloc.quantitySelected.toString();
    }

    // Reemplaza coma por punto para manejar formatos decimales europeos
    input = input.replaceAll(',', '.');

    // Expresión regular para validar un número válido
    final isValid = RegExp(r'^\d+([.,]?\d+)?$').hasMatch(input);

    // Validación de formato
    if (!isValid) {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      Get.snackbar(
        'Error',
        'Cantidad inválida',
        backgroundColor: white,
        colorText: primaryColorApp,
        duration: const Duration(milliseconds: 1000),
        icon: Icon(Icons.error, color: Colors.amber),
        snackPosition: SnackPosition.TOP,
      );

      return;
    }

    // Intentar convertir a double
    double? cantidad = double.tryParse(input);
    if (cantidad == null) {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      Get.snackbar(
        'Error',
        'Cantidad inválida',
        backgroundColor: white,
        colorText: primaryColorApp,
        duration: const Duration(milliseconds: 1000),
        icon: Icon(Icons.error, color: Colors.amber),
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    if (cantidad > widget.ubicacion!.cantidadMano) {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      Get.snackbar(
        '360 Software Informa',
        'Cantidad superior a la cantidad en ubicacion',
        backgroundColor: white,
        colorText: primaryColorApp,
        icon: Icon(Icons.error, color: Colors.red),
      );
      return;
    }

    if (bloc.selectedLocationDest.id == 0 ||
        bloc.selectedLocationDest.id == null) {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      Get.snackbar(
        '360 Software Informa',
        'Ubicacion de destino no valida',
        backgroundColor: white,
        colorText: primaryColorApp,
        icon: Icon(Icons.error, color: Colors.red),
      );
      return;
    }

    if (cantidad == 0.0) {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      Get.snackbar(
        '360 Software Informa',
        'Cantidad no valida',
        backgroundColor: white,
        colorText: primaryColorApp,
        icon: Icon(Icons.error, color: Colors.red),
      );
      return;
    }

    final dateStarProduct = bloc.dateStartProduct;
    final dateEnd = DateTime.now().toString();

//sacamos la diferencia en segundos
    final differenceInSeconds = DateTime.parse(dateEnd)
        .difference(DateTime.parse(dateStarProduct))
        .inSeconds;
    debugPrint("diferencia en segundos $differenceInSeconds");

    bloc.add(SendTransferInfo(
        TransferInfoRequest(
          idAlmacen: widget.ubicacion?.idAlmacen ?? 0,
          idMove: widget.ubicacion?.idMove ?? 0,
          idProducto: widget.infoRapidaResult?.id ?? 0,
          idLote: widget.ubicacion?.loteId,
          idUbicacionOrigen: widget.ubicacion?.idUbicacion ?? 0,
          timeLine: differenceInSeconds,
          observacion: "Sin novedad",
        ),
        cantidad));

    debugPrint('timeline: $differenceInSeconds');
  }

  @override
  void dispose() {
    focusNode1.dispose(); //ubicaicon Dest
    focusNodeCantidad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return BlocBuilder<TransferInfoBloc, TransferInfoState>(
      builder: (context, state) {
        final product = widget.infoRapidaResult;
        final bloc = context.read<TransferInfoBloc>();
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Scaffold(
            backgroundColor: primaryColorApp,
            body: SafeArea(
              child: Container(
                color: Colors.white,
                width: size.width * 1,
                height: size.height * 1,
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: primaryColorApp,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    width: double.infinity,
                    // ⚡️ CORRECCIÓN: Reemplazo de MultiBlocListener por anidación manual
                    child: BlocListener<TransferInfoBloc, TransferInfoState>(
                      // 1. PRIMER LISTENER: ESCUCHA DE TRANSFERENCIA
                      listenWhen: (prev, current) =>
                          current is SendTransferInfoSuccess,
                      listener: (listenerContext, state) {
                        if (state is SendTransferInfoSuccess) {
                          // 💥 Paso 1: DISPARAR la carga de datos en el BLoC de destino
                          listenerContext.read<InfoRapidaBloc>().add(
                              GetInfoRapida(state.productId.toString(), true,
                                  true, false));

                          // Opcional: Mostrar diálogo de carga AQUI
                          showDialog(
                            context: listenerContext,
                            barrierDismissible: false,
                            builder: (_) => const DialogLoading(
                                message: "Actualizando información..."),
                          );
                        }
                      },
                      // 2. SEGUNDO LISTENER (ANIDADO): INFORMACIÓN RÁPIDA
                      child: BlocListener<InfoRapidaBloc, InfoRapidaState>(
                        listenWhen: (prev, current) =>
                            current is InfoRapidaLoaded ||
                            current is InfoRapidaError,
                        listener: (listenerContext, state) {
                          // Cerramos el diálogo de carga de forma segura
                          // Verificamos si hay un diálogo o ruta activa para cerrar
                          Navigator.of(listenerContext).pop();

                          if (state is InfoRapidaLoaded) {
                            // ✅ Paso 2: La carga fue exitosa. La navegación es segura.
                            debugPrint(
                                'Datos de Info Rápida cargados. Navegando...');
                            Navigator.pushReplacementNamed(
                              listenerContext,
                              'product-info',
                            );
                          } else if (state is InfoRapidaError) {
                            // Manejo del error de carga de Info Rápida
                            Get.snackbar('Error',
                                state.error ?? 'Fallo al cargar información.');
                          }
                        },
                        // 3. HIJO FINAL: TU UI VISUAL (El BlocBuilder original)
                        child: BlocBuilder<ConnectionStatusCubit,
                            ConnectionStatus>(builder: (context, status) {
                          return Column(
                            children: [
                              const WarningWidgetCubit(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back,
                                        color: white),
                                    onPressed: () {
                                      context
                                          .read<TransferInfoBloc>()
                                          .clearFields();

                                      Navigator.pushReplacementNamed(
                                        context,
                                        'product-info',
                                      );
                                    },
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.only(left: size.width * 0.2),
                                    child: Text('TRANSFERENCIA',
                                        style: TextStyle(
                                            color: white, fontSize: 18)),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(top: 2),
                      child: SingleChildScrollView(
                        child: Column(children: [
                          //todo : ubicacion de origen
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Card(
                                color: Colors.green[100],
                                elevation: 5,
                                child: Container(
                                    // color: Colors.amber,
                                    width: size.width * 0.85,
                                    height: 60,
                                    padding: const EdgeInsets.only(
                                        left: 10,
                                        right: 10,
                                        top: 10,
                                        bottom: 10),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Ubicación de origen',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: primaryColorApp,
                                              ),
                                            ),
                                            const Spacer(),
                                            Image.asset(
                                              "assets/icons/ubicacion.png",
                                              color: primaryColorApp,
                                              width: 20,
                                            ),
                                          ],
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              Text(
                                                widget.ubicacion?.ubicacion ??
                                                    'Sin nombre',
                                                style: const TextStyle(
                                                    fontSize: 14, color: black),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )),
                              ),
                            ],
                          ),
                          //todo : product
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Card(
                                color: Colors.green[100],
                                elevation: 5,
                                child: Container(
                                    // color: Colors.amber,
                                    width: size.width * 0.85,
                                    // height: 150,
                                    padding: const EdgeInsets.only(
                                        left: 10,
                                        right: 10,
                                        top: 10,
                                        bottom: 10),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Product',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: primaryColorApp,
                                              ),
                                            ),
                                            const Spacer(),
                                            Image.asset(
                                              "assets/icons/producto.png",
                                              color: primaryColorApp,
                                              width: 20,
                                            ),
                                          ],
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            product?.nombre ?? 'Sin nombre',
                                            style: const TextStyle(
                                                fontSize: 14, color: black),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: SvgPicture.asset(
                                                  color: primaryColorApp,
                                                  "assets/icons/barcode.svg",
                                                  height: 20,
                                                  width: 20,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                product?.codigoBarras ==
                                                            false ||
                                                        product?.codigoBarras ==
                                                            null ||
                                                        product?.codigoBarras ==
                                                            ""
                                                    ? "Sin codigo de barras"
                                                    : product?.codigoBarras ??
                                                        "",
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: product?.codigoBarras ==
                                                                false ||
                                                            product?.codigoBarras ==
                                                                null ||
                                                            product?.codigoBarras ==
                                                                ""
                                                        ? red
                                                        : black),
                                              ),
                                              const Spacer(),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            if (widget.ubicacion?.lote != "")
                                              Row(
                                                children: [
                                                  Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      'Lote/serie:',
                                                      style: TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              primaryColorApp),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      widget.ubicacion?.lote ??
                                                          'Sin nombre',
                                                      style: const TextStyle(
                                                          fontSize: 13,
                                                          color: black),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    )),
                              ),
                            ],
                          ),

                          //todo: muelle
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color:
                                        bloc.locationDestIsOk ? green : yellow,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Card(
                                color: bloc.isLocationDestOk
                                    ? bloc.locationDestIsOk
                                        ? Colors.green[100]
                                        : Colors.grey[300]
                                    : Colors.red[200],
                                elevation: 5,
                                child: Container(
                                    width: size.width * 0.85,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    child: Column(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pushReplacementNamed(
                                                context,
                                                'search-locations-dest-trans-info',
                                                arguments: [
                                                  widget.infoRapidaResult,
                                                  widget.ubicacion
                                                ]);
                                          },
                                          child: Row(
                                            children: [
                                              Text(
                                                'Ubicación de destino',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: primaryColorApp,
                                                ),
                                              ),
                                              const Spacer(),
                                              SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: SvgPicture.asset(
                                                  color: primaryColorApp,
                                                  "assets/icons/packing.svg",
                                                  height: 20,
                                                  width: 20,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        BarcodeScannerField(
                                          controller: _controllerLocationDest,
                                          focusNode: focusNode1,
                                          onBarcodeScanned: (value, context) {
                                            return validateMuelle(
                                              value,
                                            );
                                          },
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                              bloc.selectedLocationDest.name ==
                                                          "" ||
                                                      bloc.selectedLocationDest
                                                              .name ==
                                                          null
                                                  ? 'Esperando escaneo'
                                                  : bloc.selectedLocationDest
                                                          .name ??
                                                      "",
                                              style: TextStyle(
                                                  fontSize: 14, color: black)),
                                        )
                                      ],
                                    )),
                              ),
                            ],
                          ),
                        ]),
                      ),
                    ),
                  ),
                  //todo: cantidad
                  SizedBox(
                    width: size.width,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          child: Card(
                            color: white,
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Center(
                                child: Row(
                                  children: [
                                    const Text('Disponible:',
                                        style: TextStyle(
                                            color: black, fontSize: 13)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5),
                                      child: Text(
                                        '(${(widget.ubicacion?.cantidadMano ?? 0.0).toString()})',
                                        style: TextStyle(
                                            color: primaryColorApp,
                                            fontSize: 15),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        // padding: const EdgeInsets.only(bottom: 5),
                                        height: 40,
                                        alignment: Alignment.center,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 0),
                                          child: Container(
                                            alignment: Alignment.center,
                                            child: TextFormField(
                                                focusNode: focusNodeCantidad,
                                                enabled: true,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .allow(
                                                          RegExp(r'[0-9.,]')),
                                                ],
                                                onChanged: (value) {
                                                  // Verifica si el valor no está vacío y si es un número válido
                                                  if (value.isNotEmpty) {
                                                    try {
                                                      bloc.quantitySelected =
                                                          int.parse(value);
                                                    } catch (e) {
                                                      // Manejo de errores si la conversión falla
                                                      debugPrint(
                                                          'Error al convertir a entero: $e');
                                                      // Aquí puedes mostrar un mensaje al usuario o manejar el error de otra forma
                                                    }
                                                  } else {
                                                    // Si el valor está vacío, puedes establecer un valor por defecto
                                                    bloc.quantitySelected =
                                                        0; // O cualquier valor que consideres adecuado
                                                  }
                                                },
                                                controller: _cantidadController,
                                                showCursor: false,
                                                style: TextStyle(
                                                  color: black,
                                                  fontSize: 15,
                                                ),
                                                textAlign: TextAlign.center,
                                                keyboardType:
                                                    TextInputType.number,
                                                maxLines: 1,
                                                //icono de editar
                                                decoration: InputDecoration(
                                                  suffixIcon: IconButton(
                                                    onPressed: () {
                                                      if (focusNodeCantidad
                                                          .hasFocus) {
                                                        focusNodeCantidad
                                                            .unfocus();
                                                      } else {
                                                        focusNodeCantidad
                                                            .requestFocus();
                                                      }
                                                    },
                                                    icon: Icon(
                                                      focusNodeCantidad.hasFocus
                                                          ? Icons.close
                                                          : Icons.edit,
                                                      size: 20,
                                                      color: primaryColorApp,
                                                    ),
                                                  ),
                                                  hintText: '0',
                                                  hintMaxLines: 2,
                                                  hintStyle: TextStyle(
                                                      color: black,
                                                      fontSize: 13),
                                                  border: InputBorder.none,
                                                  focusedBorder:
                                                      InputBorder.none,
                                                  enabledBorder:
                                                      InputBorder.none,
                                                )),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 0),
                            child: ElevatedButton(
                              onPressed: () {
                                validateQuantity(
                                    _cantidadController.text == "" ||
                                            _cantidadController.text.isEmpty
                                        ? 0
                                        : _cantidadController.text,
                                    context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColorApp,
                                minimumSize: Size(size.width * 0.93, 30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'APLICAR CANTIDAD',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            )),
                        //teclado de la app
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}
