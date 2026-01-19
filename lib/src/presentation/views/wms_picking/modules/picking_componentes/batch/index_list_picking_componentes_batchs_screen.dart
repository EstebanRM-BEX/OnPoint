// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:ui';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/core/utils/sounds_utils.dart';
import 'package:wms_app/src/core/utils/vibrate_utils.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/network/check_internet_connection.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/home/widgets/Dialog_ProductsNotSends.dart';
import 'package:wms_app/src/presentation/views/user/screens/widgets/dialog_info_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/bloc/wms_picking_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/blocs/batch_bloc/batch_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_start_picking_widget.dart';
import 'package:wms_app/src/presentation/widgets/barcode_scanner_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PickingCompoBatchScreen extends StatefulWidget {
  const PickingCompoBatchScreen({
    super.key,
  });

  @override
  State<PickingCompoBatchScreen> createState() =>
      _PickingCompoBatchScreenState();
}

class _PickingCompoBatchScreenState extends State<PickingCompoBatchScreen> {
  final AudioService _audioService = AudioService();
  final VibrationService _vibrationService = VibrationService();
  FocusNode focusNodeBuscar = FocusNode();
  final TextEditingController _controllerToDo = TextEditingController();

  void validateBarcode(String value, BuildContext context) {
    final bloc = context.read<WMSPickingBloc>();
    final scan = (bloc.scannedToDo.isEmpty ? value : bloc.scannedToDo)
        .trim()
        .toLowerCase();

    _controllerToDo.clear();
    print('🔎 Scan barcode (batch picking): $scan');

    final listOfBatchs = bloc.listOfBatchsByComponents;

    void processBatch(BatchsModel batch) {
      bloc.add(ClearScannedValuePickingEvent('toDo'));

      print(batch.toMap());
      try {
        _handleBatchSelection(context, context, batch);
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
      orElse: () => BatchsModel(),
    );

    if (batchs.id != null) {
      print(
          '🔎 batch encontrado : ${batchs.id} ${batchs.name} - ${batchs.zonaEntrega}');
      processBatch(batchs);
      return;
    } else {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      bloc.add(ClearScannedValuePickingEvent('toDo'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<WMSPickingBloc, PickingState>(
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
          }),
          BlocListener<BatchBloc, BatchState>(
            listener: (context, state) {
              if (state is PickingOkState) {
                context.read<WMSPickingBloc>().add(FilterBatchesBStatusEvent(
                      '',
                      'components',
                    ));
              }
            },
          ),
        ],
        child: BlocBuilder<WMSPickingBloc, PickingState>(
          builder: (context, state) {
            return Scaffold(
                backgroundColor: white,
                body: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: primaryColorApp,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: BlocBuilder<ConnectionStatusCubit,
                            ConnectionStatus>(builder: (context, status) {
                          return Column(
                            children: [
                              const WarningWidgetCubit(),
                              Padding(
                                padding: EdgeInsets.only(
                                    left: 10,
                                    right: 10,
                                    top: status != ConnectionStatus.online
                                        ? 20
                                        : 20,
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
                                                .read<WMSPickingBloc>()
                                                .searchController
                                                .clear();
                                            Navigator.pushReplacementNamed(
                                                context, '/home');
                                          },
                                        ),
                                        Spacer(),
                                        GestureDetector(
                                          onTap: () async {
                                            final products =
                                                await DataBaseSqlite()
                                                    .getProducts('components');
                                            final productsNoSendOdoo = products
                                                .where((element) =>
                                                    element.isSendOdoo == 0)
                                                .toList();
                                            if (productsNoSendOdoo.isEmpty) {
                                              await DataBaseSqlite()
                                                  .delePicking('components');
                                              context
                                                  .read<WMSPickingBloc>()
                                                  .add(LoadAllBatchsByComponentsEvent(
                                                      true, 'components'));
                                            } else {
                                              showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return const DialogProductsNotSends();
                                                  });
                                            }
                                          },
                                          child: Row(
                                            children: [
                                              const Text(
                                                'COMPONENTES BATCH',
                                                style: TextStyle(
                                                    color: white,
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),

                                              const SizedBox(
                                                width: 5,
                                              ),
                                              //icono de refres
                                              Icon(
                                                Icons.refresh,
                                                color: white,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Spacer(),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),

                      BarcodeScannerField(
                        controller: _controllerToDo,
                        focusNode: focusNodeBuscar,
                        scannedValue5: "",
                        onBarcodeScanned: (value, context) {
                          return validateBarcode(value, context);
                        },
                        onKeyScanned: (keyLabel, type, context) {
                          return context.read<WMSPickingBloc>().add(
                                UpdateScannedValuePickingEvent(keyLabel, type),
                              );
                        },
                      ),

                      //filtro por tipo de batch

                      //*listado de batchs
                      Expanded(
                        child: 
                        
                        context
                                .read<WMSPickingBloc>()
                                .filteredBatchsByComponents
                                .where((batch) => batch.isSeparate == null)
                                .isNotEmpty
                            ?
                             ListView.builder(
                                padding: EdgeInsets.only(
                                    top: 10, bottom: size.height * 0.15),
                                shrinkWrap: true,
                                physics: const ScrollPhysics(),
                                itemCount: context
                                    .read<WMSPickingBloc>()
                                    .filteredBatchsByComponents
                                    .where((batch) => batch.isSeparate == null)
                                    .length,
                                itemBuilder: (contextBuilder, index) {
                                  final batch = context
                                      .read<WMSPickingBloc>()
                                      .filteredBatchsByComponents
                                      .where(
                                          (batch) => batch.isSeparate == null)
                                      .toList()[index];
                                  //convertimos la fecha

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: GestureDetector(
                                      onTap: () async {
                                        print(batch.toMap());
                                        try {
                                          _handleBatchSelection(
                                              context, contextBuilder, batch);
                                        } catch (e) {
                                          ScaffoldMessenger.of(contextBuilder)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Error al cargar los datos'),
                                              duration: Duration(seconds: 4),
                                            ),
                                          );
                                        }
                                      },
                                      child: Card(
                                        color: batch.isSeparate == 1
                                            ? Colors.green[100]
                                            : batch.isSelected == 1
                                                ? primaryColorAppLigth
                                                : Colors.white,
                                        elevation: 3,
                                        child: ListTile(
                                          trailing: Icon(
                                            Icons.arrow_forward_ios,
                                            color: primaryColorApp,
                                          ),
                                          leading: GestureDetector(
                                            onTap: () {
                                              context
                                                  .read<WMSPickingBloc>()
                                                  .add(LoadDocOriginsEvent(
                                                    batch.id ?? 0,
                                                  ));
                                              showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      BackdropFilter(
                                                        filter:
                                                            ImageFilter.blur(
                                                                sigmaX: 5,
                                                                sigmaY: 5),
                                                        child: AlertDialog(
                                                          actionsAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          title: Center(
                                                              child: Text(
                                                            "Documentos de origen",
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                                color:
                                                                    primaryColorApp,
                                                                fontSize: 20),
                                                          )),
                                                          content:
                                                              //lista de documentos
                                                              SizedBox(
                                                            height: 300,
                                                            width: size.width *
                                                                0.9,
                                                            child: ListView
                                                                .builder(
                                                              itemCount: context
                                                                  .read<
                                                                      WMSPickingBloc>()
                                                                  .listOfOrigins
                                                                  .length,
                                                              itemBuilder:
                                                                  (context,
                                                                      index) {
                                                                return Card(
                                                                  color: white,
                                                                  elevation: 2,
                                                                  child:
                                                                      ListTile(
                                                                    title: Text(
                                                                        context.read<WMSPickingBloc>().listOfOrigins[index].name ??
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
                                                                child:
                                                                    const Text(
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
                                          title: Text(batch.name ?? '',
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                          subtitle: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                    batch.zonaEntrega ?? '',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black)),
                                              ),
                                              Row(
                                                children: [
                                                  const Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                        "Tipo de operación:",
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: grey)),
                                                  ),
                                                  const Spacer(),
                                                  batch.startTimePick != ""
                                                      ? GestureDetector(
                                                          onTap: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) =>
                                                                        DialogInfo(
                                                                          title:
                                                                              'Tiempo de inicio',
                                                                          body:
                                                                              'Este batch fue iniciado a las ${batch.startTimePick}',
                                                                        ));
                                                          },
                                                          child: Icon(
                                                            Icons.timer_sharp,
                                                            color:
                                                                primaryColorApp,
                                                            size: 15,
                                                          ),
                                                        )
                                                      : const SizedBox(),
                                                ],
                                              ),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  batch.pickingTypeId
                                                      .toString(),
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: primaryColorApp),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .calendar_month_sharp,
                                                      color: primaryColorApp,
                                                      size: 15,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      batch.scheduleddate !=
                                                              null
                                                          ? DateFormat(
                                                                  'dd/MM/yyyy')
                                                              .format(DateTime
                                                                  .parse(batch
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
                                                      "Cantidad de lineas: ",
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: black),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        batch.countItems
                                                            .toString(),
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                primaryColorApp),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
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
                                                      Icons.add,
                                                      color: primaryColorApp,
                                                      size: 15,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    const Text(
                                                      "Cantidad unidades: ",
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: black),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        batch.totalQuantityItems
                                                            .toString(),
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                primaryColorApp),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
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
                                                        batch.userName ??
                                                            "Sin responsable",
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            color: black),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
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
                                        style: TextStyle(
                                            fontSize: 18, color: grey)),
                                    Text('Intenta con otra búsqueda',
                                        style: TextStyle(
                                            fontSize: 14, color: grey)),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ));
          },
        ),
      ),
    );
  }

  void goBatchInfo(
      BuildContext context, BatchBloc batchBloc, BatchsModel batch) async {
    // 1. Mostrar Diálogo (Capturamos el contexto del diálogo)
    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx; // ✅ Capturamos el contexto del diálogo
        return const DialogLoading(
          message: 'Cargando interfaz...',
        );
      },
    );

    // ⚠️ NOTA: El código que carga los datos del Batch debe ejecutarse aquí
    // Ejemplo: batchBloc.add(FetchBatchData(batch.id));

    // 2. Esperar un tiempo mínimo fijo para el UX del diálogo (retraso muy corto)
    // Reemplazamos await Future.delayed(const Duration(seconds: 1));
    await Future.delayed(const Duration(milliseconds: 300));

    // 3. Cierre Seguro del Diálogo
    // Usamos el contexto capturado, asegurando que la acción de pop sea válida
    if (dialogContext != null) {
      Navigator.of(dialogContext!, rootNavigator: true).pop();
    }

    // 4. Navegación (Lógica sin cambios)
    // Si batch.isSeparate es 1, entonces navegamos a "batch-detail"
    if (batch.isSeparate != 1) {
      Navigator.pushReplacementNamed(context, 'batch');
    } else {
      Navigator.pushReplacementNamed(
          context, 'batch-detail'); // Asumo que va aquí
    }
  }

// Tu código refactorizado en un método privado
  void _handleBatchSelection(
      BuildContext context, BuildContext contextBuilder, dynamic batch) {
    final batchBloc = context.read<BatchBloc>();

    // 1. Cargar todos los datos del BLoC de forma asíncrona y una sola vez
    batchBloc.add(FetchBatchWithProductsEvent(batch.id ?? 0, 'components'));
    batchBloc.add(LoadInfoDeviceEvent());
    batchBloc.add(LoadConfigurationsUser());

    // 2. Definir la función de navegación, que se llama después de cargar
    void navigateToBatchInfo() {
      goBatchInfo(contextBuilder, batchBloc, batch);
    }

    // 3. Lógica para decidir si mostrar el diálogo o navegar directamente
    if (batch.startTimePick != "") {
      navigateToBatchInfo();
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => DialogStartTimeWidget(
          onAccepted: () async {
            batchBloc.add(
                StartTimePick(batch.id ?? 0, DateTime.now(), 'components'));
            Navigator.pop(context);
            navigateToBatchInfo();
          },
          title: 'Iniciar Picking',
        ),
      );
    }
  }
}
