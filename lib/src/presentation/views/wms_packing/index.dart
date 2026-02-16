// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously

import 'dart:ui';

import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/core/utils/sounds_utils.dart';
import 'package:wms_app/core/utils/vibrate_utils.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/features/user/presentation/widgets/dialog_info_widget.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/packing_response_model.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/bloc/wms_packing_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/screens/widgets/others/dialog_start_packing_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';
import 'package:wms_app/src/presentation/widgets/keyboard_widget.dart';

class WmsPackingScreen extends StatefulWidget {
  const WmsPackingScreen({super.key});

  @override
  State<WmsPackingScreen> createState() => _WmsPackingScreenState();
}

class _WmsPackingScreenState extends State<WmsPackingScreen> {
  NotchBottomBarController controller = NotchBottomBarController();

  final AudioService _audioService = AudioService();
  final VibrationService _vibrationService = VibrationService();
  FocusNode focusNodeBuscar = FocusNode();
  final TextEditingController _controllerToDo = TextEditingController();

  @override
  void initState() {
    controller.index = 0;
    super.initState();
  }

  void validateBarcode(String value, BuildContext context) {
    final bloc = context.read<WmsPackingBloc>();
    final scan = (bloc.scannedValue5.isEmpty ? value : bloc.scannedValue5)
        .trim()
        .toLowerCase();

    _controllerToDo.clear();
    print('🔎 Scan barcode (batch picking): $scan');

    final listOfBatchs = bloc.listOfBatchs;

    void processBatch(BatchPackingModel batch) {
      bloc.add(ClearScannedValuePackEvent('toDo'));

      print(batch.toMap());
      try {
        _handleBatchTap(context, batch, context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar los datos'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }

    // Buscar el producto usando el código de barras principal o el código de producto
    final batchs = listOfBatchs.firstWhere(
      (b) =>
          b.name?.toLowerCase() == scan || b.zonaEntrega?.toLowerCase() == scan,
      orElse: () => BatchPackingModel(),
    );

    if (batchs.id != null) {
      print(
          '🔎 batch encontrado : ${batchs.id} ${batchs.name} - ${batchs.zonaEntrega}');
      processBatch(batchs);
      return;
    } else {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      bloc.add(ClearScannedValuePackEvent('toDo'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BlocConsumer<WmsPackingBloc, WmsPackingState>(
        listener: (context, state) {
      if (state is NeedUpdateVersionState) {
        Get.snackbar(
          '360 Software Informa',
          'Hay una nueva versión disponible. Actualiza desde la configuración de la app, pulsando el nombre de usuario en el Home',
          backgroundColor: white,
          colorText: primaryColorApp,
          icon: Icon(Icons.error, color: Colors.amber),
          showProgressIndicator: true,
          duration: Duration(seconds: 5),
        );
      }
    }, builder: (context, state) {
      return Scaffold(
          backgroundColor: white,
          bottomNavigationBar: context.read<WmsPackingBloc>().isKeyboardVisible
              ? CustomKeyboard(
                  isLogin: false,
                  controller: context.read<WmsPackingBloc>().searchController,
                  onchanged: () {
                    context.read<WmsPackingBloc>().add(SearchBatchPackingEvent(
                        context.read<WmsPackingBloc>().searchController.text,
                        controller.index));
                  },
                )
              : null,
          body: Container(
            margin: const EdgeInsets.only(bottom: 10),
            width: size.width * 1,
            child:

                ///*listado de bacths
                Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: primaryColorApp,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
                      builder: (context, status) {
                    return Column(
                      children: [
                        const WarningWidgetCubit(),
                        Padding(
                          padding: EdgeInsets.only(
                              left: 10,
                              right: 10,
                              top: status != ConnectionStatus.online ? 0 : 25,
                              bottom: 0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back,
                                        color: white),
                                    onPressed: () {
                                      context
                                          .read<WmsPackingBloc>()
                                          .add(ShowKeyboardEvent(false));
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/home',
                                      );
                                    },
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: size.width * 0.22),
                                    child: GestureDetector(
                                      onTap: () async {
                                        await DataBaseSqlite()
                                            .delePacking('packing-batch');
                                        context
                                            .read<WmsPackingBloc>()
                                            .add(LoadAllPackingEvent(
                                              true,
                                            ));
                                      },
                                      child: Row(
                                        children: [
                                          const Text(
                                            'PACKING',
                                            style: TextStyle(
                                                color: white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 5),
                                          Icon(
                                            Icons.refresh,
                                            color: white,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),

                //*barra de buscar

                DynamicSearchBar(
                  // 1. CONTROLADOR Y FOCO
                  controller: context.read<WmsPackingBloc>().searchController,
                  hintText: "Buscar batch",

                  // 2. LÓGICA DE BÚSQUEDA (onChanged)
                  onSearchChanged: (value) {
                    // Integra directamente la lógica del BLoC
                    context
                        .read<WmsPackingBloc>()
                        .add(SearchBatchPackingEvent(value, controller.index));
                  },

                  // 3. LÓGICA DE LIMPIEZA (onSearchCleared)
                  onSearchCleared: () {
                    final packingBloc = context.read<WmsPackingBloc>();

                    // 1. Disparar el evento de búsqueda vacía y apagar el teclado
                    packingBloc
                        .add(SearchBatchPackingEvent('', controller.index));
                    packingBloc.add(ShowKeyboardEvent(false));

                    // 2. Restaurar el foco después de un breve retraso (para asegurar la UI)
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted) {
                        // Usamos mounted si estamos en un StatefulWidget
                        FocusScope.of(context).requestFocus(focusNodeBuscar);
                      }
                    });
                  },

                  // 4. LÓGICA DE ACTIVACIÓN DEL TECLADO (onTap)
                  onTap: () {
                    // El widget DynamicSearchBar internamente verifica si es Zebra.
                    context.read<WmsPackingBloc>().add(ShowKeyboardEvent(true));
                  },
                ),

                //*buscar por scan
                BarcodeScannerField(
                  controller: _controllerToDo,
                  focusNode: focusNodeBuscar,
                  scannedValue5: "",
                  onBarcodeScanned: (value, context) {
                    return validateBarcode(value, context);
                  },
                  onKeyScanned: (keyLabel, type, context) {
                    return context.read<WmsPackingBloc>().add(
                          UpdateScannedValuePackEvent(keyLabel, type),
                        );
                  },
                ),

                //*listado de batchs
                Expanded(
                  child: context
                          .read<WmsPackingBloc>()
                          .listOfBatchsDB
                          .where((batch) =>
                              batch.isSeparate == 0 || batch.isSeparate == null)
                          .isNotEmpty
                      ? ListView.builder(
                          padding: const EdgeInsets.only(top: 20, bottom: 20),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: context
                              .read<WmsPackingBloc>()
                              .listOfBatchsDB
                              .where((batch) =>
                                  batch.isSeparate == 0 ||
                                  batch.isSeparate == null)
                              .length,
                          itemBuilder: (contextBuilder, index) {
                            final List<BatchPackingModel> inProgressBatches =
                                context
                                    .read<WmsPackingBloc>()
                                    .listOfBatchsDB
                                    .where((batch) =>
                                        batch.isSeparate == 0 ||
                                        batch.isSeparate == null)
                                    .toList(); // Convertir a lista

                            // Asegurarse de que hay batches en progreso
                            if (inProgressBatches.isEmpty) {
                              return const Center(
                                  child: Text('No hay batches en progreso.'));
                            }

                            // Comprobar que el índice no está fuera de rango
                            if (index >= inProgressBatches.length) {
                              return const SizedBox(); // O manejar de otra forma
                            }

                            final batch = inProgressBatches[
                                index]; // Acceder al batch filtrado

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              child: GestureDetector(
                                onTap: () async {
                                  _handleBatchTap(
                                      context, batch, contextBuilder);
                                },
                                child: Card(
                                  color: batch.isSeparate == 1
                                      ? Colors.green[100]
                                      : batch.isSelected == 1
                                          ? primaryColorAppLigth
                                          : Colors.white,
                                  elevation: 5,
                                  child: ListTile(
                                    trailing: Icon(
                                      Icons.arrow_forward_ios,
                                      color: primaryColorApp,
                                    ),
                                    leading: GestureDetector(
                                      onTap: () {
                                        context
                                            .read<WmsPackingBloc>()
                                            .add(LoadDocOriginsEvent(
                                              batch.id ?? 0,
                                            ));
                                        showDialog(
                                            context: context,
                                            builder:
                                                (context) => BackdropFilter(
                                                      filter: ImageFilter.blur(
                                                          sigmaX: 5, sigmaY: 5),
                                                      child: AlertDialog(
                                                        actionsAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        title: Center(
                                                            child: Text(
                                                          "Documentos de origen",
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                              color:
                                                                  primaryColorApp,
                                                              fontSize: 20),
                                                        )),
                                                        content:
                                                            //lista de documentos
                                                            SizedBox(
                                                          height: 300,
                                                          width:
                                                              size.width * 0.9,
                                                          child:
                                                              ListView.builder(
                                                            itemCount: context
                                                                .read<
                                                                    WmsPackingBloc>()
                                                                .listOfOrigins
                                                                .length,
                                                            itemBuilder:
                                                                (context,
                                                                    index) {
                                                              return Card(
                                                                color: white,
                                                                elevation: 2,
                                                                child: ListTile(
                                                                  title: Text(
                                                                      context.read<WmsPackingBloc>().listOfOrigins[index].name ??
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
                                                                  backgroundColor:
                                                                      primaryColorApp,
                                                                  shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              10))),
                                                              child: const Text(
                                                                'Aceptar',
                                                                style: TextStyle(
                                                                    color:
                                                                        white),
                                                              ))
                                                        ],
                                                      ),
                                                    ));
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10),

                                            //sombras
                                            boxShadow: const [
                                              BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 5,
                                                  offset: Offset(0, 2))
                                            ]),
                                        child: Image.asset(
                                          "assets/icons/producto.png",
                                          color: primaryColorApp,
                                          width: 24,
                                        ),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(batch.name ?? '',
                                            style:
                                                const TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                    subtitle: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(batch.zonaEntrega ?? '',
                                              style: const TextStyle(
                                                  fontSize: 12, color: black)),
                                        ),
                                        Row(
                                          children: [
                                            const Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text("Tipo de operación:",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: grey)),
                                            ),
                                            const Spacer(),
                                            batch.startTimePack != ""
                                                ? GestureDetector(
                                                    onTap: () {
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              DialogInfo(
                                                                title:
                                                                    'Tiempo de inicio',
                                                                body:
                                                                    'Este batch fue iniciado a las ${batch.startTimePack}',
                                                              ));
                                                    },
                                                    child: Icon(
                                                      Icons.timer_sharp,
                                                      color: primaryColorApp,
                                                      size: 15,
                                                    ),
                                                  )
                                                : const SizedBox(),
                                          ],
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            batch.pickingTypeId.toString(),
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: primaryColorApp),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_month_sharp,
                                                color: primaryColorApp,
                                                size: 15,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                batch.scheduleddate != null
                                                    ? DateFormat('dd/MM/yyyy')
                                                        .format(DateTime.parse(
                                                            batch
                                                                .scheduleddate!))
                                                    : "Sin fecha",
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.add,
                                                color: primaryColorApp,
                                                size: 15,
                                              ),
                                              const SizedBox(width: 5),
                                              const Text(
                                                "Cantidad pedidos: ",
                                                style: TextStyle(
                                                    fontSize: 12, color: black),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  batch.cantidadPedidos
                                                      .toString(),
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: primaryColorApp),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.person,
                                                color: primaryColorApp,
                                                size: 15,
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  batch.userName == null ||
                                                          batch.userName == ""
                                                      ? "Sin responsable"
                                                      : batch.userName!,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: black),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 10),
                              Text('No se encontraron resultados',
                                  style: TextStyle(fontSize: 14, color: grey)),
                              Text('Intenta con otra búsqueda',
                                  style: TextStyle(fontSize: 12, color: grey)),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ));
    });
  }

  void goBatchInfo(BuildContext context, WmsPackingBloc batchBloc,
      BatchPackingModel batch) async {
    // mostramos un dialogo de carga y despues
    showDialog(
      context: context,
      barrierDismissible:
          false, // No permitir que el usuario cierre el diálogo manualmente
      builder: (_) => const DialogLoading(
        message: 'Cargando interfaz...',
      ),
    );

    await Future.delayed(const Duration(seconds: 1));
    Navigator.pop(context);

    Navigator.pushReplacementNamed(
      context,
      'packing-list',
      arguments: [batch],
    );
  }

  void _handleBatchTap(
      BuildContext context, dynamic batch, BuildContext contextBuilder) async {
    print('Batch seleccionado: ${batch.toMap()}');
    context.read<WmsPackingBloc>().add(LoadConfigurationsUserPack());

    if (batch.startTimePack != "") {
      context.read<WmsPackingBloc>().add(LoadAllPedidosFromBatchEvent(
            batch.id ?? 0,
          ));
      context.read<WmsPackingBloc>().add(ShowKeyboardEvent(false));
      goBatchInfo(contextBuilder, context.read<WmsPackingBloc>(), batch);
    } else {
      showDialog(
        context: context,
        barrierDismissible:
            false, // No permitir que el usuario cierre el diálogo manualmente
        builder: (context) => DialogStartPackingWidget(
          onAccepted: () async {
            // Disparar eventos de BatchBloc
            context.read<WmsPackingBloc>().add(LoadAllPedidosFromBatchEvent(
                  batch.id ?? 0,
                ));
            context.read<WmsPackingBloc>().add(ShowKeyboardEvent(false));
            // viajamos a la vista de detalles del batch con sus pedidos

            context
                .read<WmsPackingBloc>()
                .add(StartTimePack(batch.id ?? 0, DateTime.now()));

            Navigator.pop(context);

            goBatchInfo(contextBuilder, context.read<WmsPackingBloc>(), batch);
          },
        ),
      );
    }
  }
}
