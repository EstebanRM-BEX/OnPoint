import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/injection_container.dart';
// ignore_for_file: use_build_context_synchronously

import 'dart:ui';

import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_start_picking_widget.dart';
import 'package:wms_app/features/user/presentation/widgets/dialog_info_widget.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/packing_response_model.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/screens/widgets/others/dialog_start_packing_widget.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-consolidade/bloc/packing_consolidade_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

class ListPackingConsolidadeScreen extends StatefulWidget {
  const ListPackingConsolidadeScreen({super.key});

  @override
  State<ListPackingConsolidadeScreen> createState() =>
      _ListPackingConsolidadeScreenState();
}

class _ListPackingConsolidadeScreenState
    extends State<ListPackingConsolidadeScreen> {
  NotchBottomBarController controller = NotchBottomBarController();
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();
  FocusNode focusNodeBuscar = FocusNode();
  final TextEditingController _controllerToDo = TextEditingController();

  void validateBarcode(String value, BuildContext context) {
    final bloc = context.read<PackingConsolidateBloc>();
    final scan = (bloc.scannedValue5.isEmpty ? value : bloc.scannedValue5)
        .trim()
        .toLowerCase();

    _controllerToDo.clear();
    debugPrint('🔎 Scan barcode (batch picking): $scan');

    final listOfBatchs = bloc.listOfBatchs;

    void processBatch(BatchPackingModel batch) {
      bloc.add(ClearScannedValuePackEvent('toDo'));

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
      debugPrint(
          '🔎 batch encontrado : ${batchs.id} ${batchs.name} - ${batchs.zonaEntrega}');
      processBatch(batchs);
      return;
    } else {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      bloc.add(ClearScannedValuePackEvent('toDo'));
    }
  }

  void _handleBatchTap(
      BuildContext context, dynamic batch, BuildContext contextBuilder) async {
    debugPrint('Batch seleccionado: ${batch.toMap()}');
    context
        .read<PackingConsolidateBloc>()
        .add(LoadConfigurationsUserPackConsolidate());

    // 2. Lógica para asignar el responsable o continuar
    if (batch.userName == null || batch.userName == "" || batch.userName == 0) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => DialogAsignUserWidget(
          title:
              'Esta seguro de tomar este batch de packing consolidado, una vez aceptado no podrá ser cancelada desde la app, una vez asignado se registrará el tiempo de inicio de la operación.',
          onCancel: () {
            Future.microtask(() => focusNodeBuscar.requestFocus());
            Navigator.pop(dialogContext);
          },
          onAccepted: () async {
            // Lógica para asignar el usuario
            final packingBloc = context.read<PackingConsolidateBloc>();
            packingBloc.add(AssignUserToBatch(batch.id ?? 0, batch));
            packingBloc.searchController.clear();
            packingBloc.add(LoadAllPedidosFromBatchEvent(
              batch.id ?? 0,
            ));

            // validamos si tiene tiempo de separacion de inicio
            if (batch.startTimePack == "" || batch.startTimePack == null) {
              packingBloc.add(
                StartTimePack(batch.id ?? 0, DateTime.now()),
              );
            }

            Navigator.pop(dialogContext); // Cierra el diálogo de asignación

            // Después de asignar el usuario, continuar con la validación de tiempo
          },
        ),
      );
    } else {
      // Si el responsable ya existe, validar el tiempo directamente
      validateTime(batch, context);
    }
  }

  void validateTime(dynamic batch, BuildContext context) {
    final packingConsolidateBloc = context.read<PackingConsolidateBloc>();

    if (batch.startTimePack == "" || batch.startTimePack == null) {
      showDialog(
        context: context,
        barrierDismissible:
            false, // No permitir que el usuario cierre el diálogo manualmente
        builder: (dialogContext) => DialogStartPackingWidget(
          onAccepted: () async {
            packingConsolidateBloc
                .add(LoadAllPedidosFromBatchEvent(batch.id ?? 0));
            packingConsolidateBloc
                .add(StartTimePack(batch.id ?? 0, DateTime.now()));
            Navigator.pop(context);
            goBatchInfo(context, packingConsolidateBloc, batch);
          },
        ),
      );
    } else {
      packingConsolidateBloc.add(LoadAllPedidosFromBatchEvent(batch.id ?? 0));
      goBatchInfo(context, packingConsolidateBloc, batch);
    }
  }

  void goBatchInfo(BuildContext context, PackingConsolidateBloc batchBloc,
      BatchPackingModel batch) async {
    // 1. Variable para capturar el contexto ESPECÍFICO del diálogo
    BuildContext? dialogContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx; // Asignamos el contexto aquí
        return const DialogLoading(
          message: 'Cargando interfaz...',
        );
      },
    );

    // Simulamos carga
    await Future.delayed(const Duration(seconds: 1));

    // 2. Verificar 'mounted' de la pantalla principal antes de hacer nada
    if (!mounted) return;

    // 3. Verificar si el DIÁLOGO existe y está montado antes de usar '!'
    if (dialogContext != null && dialogContext!.mounted) {
      Navigator.pop(dialogContext!); // Cerramos usando el contexto seguro
    } else {
      // Fallback: Si el diálogo no se capturó correctamente, intentamos cerrar con el contexto padre
      // solo si es seguro hacerlo.
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }

    // 4. Navegación segura
    Navigator.pushReplacementNamed(
      context,
      'pedido-packing-consolidate-list',
      arguments: [batch],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BlocConsumer<PackingConsolidateBloc, PackingConsolidateState>(
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

        if (state is AssignUserToBatchError) {
          //validamos que este un dialog abierto
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          Get.snackbar(
            '360 Software Informa',
            state.error,
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: Icon(Icons.error, color: Colors.red),
          );
        }

        if (state is AssignUserToBatchLoading) {
          // mostramos un dialogo de carga y despues
          showDialog(
            context: context,
            barrierDismissible:
                false, // No permitir que el usuario cierre el diálogo manualmente
            builder: (_) => const DialogLoading(
              message: 'Cargando interfaz...',
            ),
          );
        }

        if (state is AssignUserToBatchLoaded) {
          // cerramos el dialogo de carga
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          Navigator.pushReplacementNamed(
            context,
            'pedido-packing-consolidate-list',
            arguments: [state.batchPackingModel],
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
            backgroundColor: primaryColorApp,
            body: SafeArea(
              child: Container(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 10),
                width: size.width * 1,
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
                      child:
                          BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
                              builder: (context, status) {
                        return Column(
                          children: [
                            const WarningWidgetCubit(),
                            Padding(
                              padding: EdgeInsets.only(
                                  left: 10, right: 10, bottom: 0),
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
                                          Navigator.pushReplacementNamed(
                                            context,
                                            '/home',
                                          );
                                        },
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                            left: size.width * 0.05),
                                        child: GestureDetector(
                                          onTap: () async {
                                            await DataBaseSqlite().delePacking(
                                                'packing-batch-consolidate');

                                            context
                                                .read<PackingConsolidateBloc>()
                                                .add(
                                                    LoadAllPackingConsolidateEvent());
                                          },
                                          child: Row(
                                            children: [
                                              const Text(
                                                'PACKING CONSOLIDADO',
                                                style: TextStyle(
                                                    color: white,
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold),
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
                      controller: context
                          .read<PackingConsolidateBloc>()
                          .searchController,
                      hintText: "Buscar batch",
                      // 2. LÓGICA DE BÚSQUEDA (onChanged)
                      onSearchChanged: (value) {
                        // Integra directamente la lógica del BLoC
                        context.read<PackingConsolidateBloc>().add(
                            SearchBatchPackingEvent(value, controller.index));
                      },
                      // 3. LÓGICA DE LIMPIEZA (onSearchCleared)
                      onSearchCleared: () {
                        //todo
                        final packingBloc =
                            context.read<PackingConsolidateBloc>();
                        // 1. Disparar el evento de búsqueda vacía y apagar el teclado

                        // 2. Restaurar el foco después de un breve retraso (para asegurar la UI)
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            // Usamos mounted si estamos en un StatefulWidget
                            FocusScope.of(context)
                                .requestFocus(focusNodeBuscar);
                          }
                        });
                      },
                      // 4. LÓGICA DE ACTIVACIÓN DEL TECLADO (onTap)
                    ),

                    //*buscar por scan
                    BarcodeScannerField(
                      controller: _controllerToDo,
                      focusNode: focusNodeBuscar,
                      onBarcodeScanned: (value, context) {
                        return validateBarcode(value, context);
                      },
                      // onKeyScanned: (keyLabel, type, context) {
                      //   return context.read<PackingConsolidateBloc>().add(
                      //         UpdateScannedValuePackEvent(keyLabel, type),
                      //       );
                      // },
                    ),

                    //*listado de batchs
                    Expanded(
                      child: context
                              .read<PackingConsolidateBloc>()
                              .listOfBatchsDB
                              .where((batch) =>
                                  batch.isSeparate == 0 ||
                                  batch.isSeparate == null)
                              .isNotEmpty
                          ? ListView.builder(
                              padding:
                                  const EdgeInsets.only(top: 20, bottom: 20),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: context
                                  .read<PackingConsolidateBloc>()
                                  .listOfBatchsDB
                                  .where((batch) =>
                                      batch.isSeparate == 0 ||
                                      batch.isSeparate == null)
                                  .length,
                              itemBuilder: (contextBuilder, index) {
                                final List<BatchPackingModel>
                                    inProgressBatches = context
                                        .read<PackingConsolidateBloc>()
                                        .listOfBatchsDB
                                        .where((batch) =>
                                            batch.isSeparate == 0 ||
                                            batch.isSeparate == null)
                                        .toList(); // Convertir a lista

                                // Asegurarse de que hay batches en progreso
                                if (inProgressBatches.isEmpty) {
                                  return const Center(
                                      child:
                                          Text('No hay batches en progreso.'));
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
                                                .read<PackingConsolidateBloc>()
                                                .batch = batch;

                                            context
                                                .read<PackingConsolidateBloc>()
                                                .listOfOrigins = context
                                                    .read<
                                                        PackingConsolidateBloc>()
                                                    .parseOrigins() ??
                                                [];

                                            //todo

                                            showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    BackdropFilter(
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
                                                                    PackingConsolidateBloc>()
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
                                                                      context.read<PackingConsolidateBloc>().listOfOrigins[
                                                                          index],
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
                                                style: const TextStyle(
                                                    fontSize: 14)),
                                          ],
                                        ),
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
                                                batch.startTimePack != ""
                                                    ? GestureDetector(
                                                        onTap: () {
                                                          showDialog(
                                                              context: context,
                                                              builder:
                                                                  (context) =>
                                                                      DialogInfo(
                                                                        title:
                                                                            'Tiempo de inicio',
                                                                        body:
                                                                            'Este batch fue iniciado a las ${batch.startTimePack}',
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
                                                  Expanded(
                                                    child: Text(
                                                      'Cantidad de pedidos: ',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: black),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    batch.cantidadTotalPedidos
                                                        .toString(),
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                  Expanded(
                                                    child: Text(
                                                      'Cantidad de lineas: ',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: black),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    batch.cantidadTotalProductos
                                                        .toString(),
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                  Expanded(
                                                    child: Text(
                                                      'Cantidad unidades: ',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: black),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    batch.unidadesProductos
                                                        .toString(),
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                              batch.userName ==
                                                                  ""
                                                          ? "Sin responsable"
                                                          : batch.userName!,
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: batch.userName ==
                                                                      null ||
                                                                  batch.userName ==
                                                                      ""
                                                              ? red
                                                              : black),
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
                                      style:
                                          TextStyle(fontSize: 14, color: grey)),
                                  Text('Intenta con otra búsqueda',
                                      style:
                                          TextStyle(fontSize: 12, color: grey)),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ));
      },
    );
  }
}
