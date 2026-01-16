// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_holo_date_picker/date_picker.dart';
import 'package:flutter_holo_date_picker/i18n/date_picker_i18n.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/core/utils/sounds_utils.dart';
import 'package:wms_app/src/core/utils/vibrate_utils.dart';
import 'package:wms_app/src/presentation/providers/network/check_internet_connection.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_start_picking_widget.dart';
import 'package:wms_app/src/presentation/views/user/screens/widgets/dialog_info_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_start_picking_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/bloc/picking_pick_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_model.dart';
import 'package:wms_app/src/presentation/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';
import 'package:wms_app/src/presentation/widgets/keyboard_widget.dart';

class IndexListPickScreen extends StatelessWidget {
  const IndexListPickScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final AudioService _audioService = AudioService();
    final VibrationService _vibrationService = VibrationService();
    FocusNode focusNodeBuscar = FocusNode();
    final TextEditingController _controllerToDo = TextEditingController();

    void validateBarcode(String value, BuildContext context) {
      final bloc = context.read<PickingPickBloc>();
      final scan = (bloc.scannedValue5.isEmpty ? value : bloc.scannedValue5)
          .trim()
          .toLowerCase();

      _controllerToDo.clear();
      print('🔎 Scan barcode (batch picking): $scan');

      final listOfBatchs = bloc.listOfPick;

      void processBatch(ResultPick batch) {
        bloc.add(ClearScannedValueEvent('toDo'));

        print(batch.toMap());
        try {
          _handleTransferTap(context, context, batch);
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
            b.name?.toLowerCase() == scan ||
            b.zonaEntrega?.toLowerCase() == scan,
        orElse: () => ResultPick(),
      );

      if (batchs.id != null) {
        print(
            '🔎 batch encontrado : ${batchs.id} ${batchs.name} - ${batchs.zonaEntrega}');
        processBatch(batchs);
        return;
      } else {
        _audioService.playErrorSound();
        _vibrationService.vibrate();
        bloc.add(ClearScannedValueEvent('toDo'));
      }
    }

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocConsumer<PickingPickBloc, PickingPickState>(
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

          if (state is AssignUserToPickError) {
            Get.snackbar(
              '360 Software Informa',
              state.error,
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: Icon(Icons.error, color: Colors.red),
            );
          }

          if (state is AssignUserToPickLoading) {
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

          if (state is AssignUserToPickSuccess) {
            // cerramos el dialogo de carga
            Navigator.pop(context);
            context
                .read<PickingPickBloc>()
                .add(FetchPickWithProductsEvent(state.id));
            context.read<PickingPickBloc>().add(LoadConfigurationsUser());
            Navigator.pushReplacementNamed(context, 'scan-product-pick',
                arguments: [true]);
          }
        },
        builder: (context, state) {
          final bloc = context.read<PickingPickBloc>();

          return Scaffold(
            backgroundColor: white,
            bottomNavigationBar: bloc.isKeyboardVisible
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: CustomKeyboard(
                      isLogin: false,
                      controller: bloc.searchPickController,
                      onchanged: () {
                        bloc.add(SearchPickEvent(
                            bloc.searchPickController.text, false));
                      },
                    ),
                  )
                : null,
            body: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  //*appbar
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
                                top:
                                    status != ConnectionStatus.online ? 20 : 20,
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
                                        Navigator.pushReplacementNamed(
                                            context, '/home');
                                      },
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        bloc.add(FetchPickingPickEvent(true));
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                            left: size.width * 0.15),
                                        child: Row(
                                          children: [
                                            const Text(
                                              'PICK PEDIDO',
                                              style: TextStyle(
                                                  color: white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
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

                  Row(
                    children: [
                      //*barra de buscar
                      DynamicSearchBar(
                        width: size.width * 0.8,
                        controller: bloc.searchPickController,
                        hintText: "Buscar pick",
                        onSearchChanged: (value) {
                          bloc.add(SearchPickEvent(value, false));
                        },
                        onSearchCleared: () {
                          bloc.searchPickController.clear();
                          bloc.add(SearchPickEvent('', false));
                          bloc.add(ShowKeyboard(
                              false)); // Asumo que ShowKeyboard es el evento de tu BLoC
                          Future.delayed(const Duration(milliseconds: 100), () {
                            FocusScope.of(context)
                                .requestFocus(focusNodeBuscar);
                          });
                        },
                        onTap: () {
                          bloc.add(ShowKeyboard(true));
                        },
                      ),

                      //icono de fecha
                      GestureDetector(
                        onTap: () async {
                          // Primero, asegúrate de que el FocusNode esté activo
                          FocusScope.of(context).unfocus();
                          var pickedDate =
                              await DatePicker.showSimpleDatePicker(
                            titleText: 'Seleccione una fecha',
                            context,
                            confirmText: 'Buscar',
                            cancelText: 'Cancelar',
                            // initialDate: DateTime(2020),
                            firstDate:
                                //un mes atras
                                DateTime.now()
                                    .subtract(const Duration(days: 30)),
                            lastDate: DateTime.now(),
                            dateFormat: "dd-MMMM-yyyy",
                            locale: DateTimePickerLocale.es,
                            looping: false,
                          );

                          // Verificar si el usuario seleccionó una fecha
                          if (pickedDate != null) {
                            // Formatear la fecha al formato "yyyy-MM-dd"
                            final formattedDate =
                                DateFormat('yyyy-MM-dd').format(pickedDate);

                            // Disparar el evento con la fecha seleccionada
                            context.read<PickingPickBloc>().add(
                                  LoadHistoryPickEvent(true, formattedDate),
                                );

                            // Navegar a la pantalla de historial
                            Navigator.pushReplacementNamed(context, 'pick-done',
                                arguments: [true]);
                          }
                        },
                        child: Card(
                          elevation: 3,
                          color: white,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.calendar_month,
                              color: primaryColorApp,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
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
                      return context.read<PickingPickBloc>().add(
                            UpdateScannedValueEvent(keyLabel, type),
                          );
                    },
                  ),

                  Expanded(
                    child: bloc.listOfPickFiltered
                            .where((batch) => batch.isSeparate == 0)
                            .isNotEmpty
                        ? ListView.builder(
                            padding: EdgeInsets.only(
                                top: 10, bottom: size.height * 0.15),
                            shrinkWrap: true,
                            physics: const ScrollPhysics(),
                            itemCount: bloc.listOfPickFiltered
                                .where((batch) => batch.isSeparate == 0)
                                .length,
                            itemBuilder: (contextBuilder, index) {
                              final batch = bloc.listOfPickFiltered
                                  .where((batch) => batch.isSeparate == 0)
                                  .toList()[index];
                              //convertimos la fecha

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: GestureDetector(
                                  onTap: () async {
                                    // Agrupar eventos de BatchBloc si es necesario
                                    _handleTransferTap(
                                        context, contextBuilder, batch);
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
                                      title: Text(batch.name ?? '',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: primaryColorApp,
                                              fontWeight: FontWeight.bold)),
                                      subtitle: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                    batch.zonaEntrega ?? '',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black)),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text("Operación: ",
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            primaryColorApp)),
                                              ),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  batch.pickingType.toString(),
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: black),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (batch.observacion != null &&
                                              batch
                                                  .observacion!.isNotEmpty) ...[
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text("Observación: ",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: primaryColorApp)),
                                            ),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                batch.observacion.toString(),
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: black),
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Row(
                                              children: [
                                                Text('Prioridad: ',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            primaryColorApp)),
                                                Text(
                                                  batch.priority == '0'
                                                      ? 'Normal'
                                                      : 'Alta'
                                                          "",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: batch.priority == '0'
                                                        ? black
                                                        : red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Divider(
                                            color: black,
                                            thickness: 1,
                                            height: 5,
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
                                                  batch.fechaCreacion != null
                                                      ? DateFormat('dd/MM/yyyy')
                                                          .format(DateTime
                                                              .parse(batch
                                                                  .fechaCreacion!))
                                                      : "Sin fecha",
                                                  style: const TextStyle(
                                                      color: black,
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
                                                  Icons.person,
                                                  color: primaryColorApp,
                                                  size: 15,
                                                ),
                                                const SizedBox(width: 5),
                                                Expanded(
                                                  child: Text(
                                                    batch.proveedor == ""
                                                        ? "Sin contacto"
                                                        : batch.proveedor ?? '',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            batch.proveedor ==
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
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.receipt,
                                                  color: primaryColorApp,
                                                  size: 15,
                                                ),
                                                const SizedBox(width: 5),
                                                const Text(
                                                  "Doc. Origen: ",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: black),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    batch.origin.toString(),
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
                                          Visibility(
                                            visible: batch.backorderId != 0,
                                            child: Row(
                                              children: [
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Icon(Icons.file_copy,
                                                      color: primaryColorApp,
                                                      size: 15),
                                                ),
                                                const SizedBox(
                                                  width: 5,
                                                ),
                                                Text(batch.backorderName ?? '',
                                                    style: TextStyle(
                                                        color: black,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold)),
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
                                                    batch.numeroLineas
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
                                                    batch.numeroItems
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
                                                    batch.responsable == ""
                                                        ? "Sin responsable"
                                                        : batch.responsable ??
                                                            '',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            batch.responsable ==
                                                                    ""
                                                                ? red
                                                                : black),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const Spacer(),
                                                batch.startTimeTransfer != ""
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
                                                                            'Este Pick fue iniciado a las ${batch.startTimeTransfer}',
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
                                        TextStyle(fontSize: 18, color: grey)),
                                Text('Intenta con otra búsqueda',
                                    style:
                                        TextStyle(fontSize: 14, color: grey)),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void goBatchInfo(
    BuildContext context,
    PickingPickBloc batchBloc,
    ResultPick batch,
  ) async {
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
    // Si batch.isSeparate es 1, entonces navegamos a "batch-detail"
    if (batch.isSeparate != 1) {
      batchBloc.add(ShowKeyboard(false));
      batchBloc.searchPickController.clear();
      Navigator.pushReplacementNamed(context, 'scan-product-pick',
          arguments: [true]);
    }
  }

// Tu código refactorizado en un método privado
  void _handleTransferTap(
      BuildContext context, BuildContext contextBuilder, dynamic batch) async {
    print("Batch: ${batch.toMap()}");
    final bloc = context.read<PickingPickBloc>(); // Asumo que es PickBloc

    try {
      // Lógica para asignar responsable si no existe
      if (batch.responsableId == null || batch.responsableId == 0) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => DialogAsignUserToOrderWidget(
            title:
                'Esta seguro de tomar este pick, una vez aceptado no podrá ser cancelada desde la app, una vez asignada se registrará el tiempo de inicio de la operación.',
            onAccepted: () async {
              // Se llama a la lógica del BLoC
              bloc.add(AssignUserToTransfer(batch.id ?? 0));
              Navigator.pop(dialogContext); // Cierra el diálogo de asignación
            },
          ),
        );
        // El resto del código se ejecuta después de que el diálogo se cierre.
        bloc.add(ShowKeyboard(false));
        bloc.searchPickController.clear();
        return; // Salimos de la función si solo se asignó el responsable
      }

      // Lógica para iniciar la transferencia si el tiempo no ha comenzado
      if (batch.startTimeTransfer == "") {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => DialogStartTimeWidget(
            title: 'Iniciar Pick',
            onAccepted: () async {
              bloc.add(StartOrStopTimeTransfer(
                batch.id ?? 0,
                'start_time_transfer',
              ));
              Navigator.pop(dialogContext); // Cierra el diálogo de inicio
            },
          ),
        );
      }

      // Lógica de carga y navegación que es común en ambos flujos
      bloc.add(ShowKeyboard(false));
      bloc.searchPickController.clear();
      bloc.add(FetchPickWithProductsEvent(batch.id ?? 0));
      bloc.add(LoadConfigurationsUser());

      goBatchInfo(
        contextBuilder,
        bloc,
        batch,
      );
    } catch (e) {
      // Manejo de errores centralizado
      ScaffoldMessenger.of(contextBuilder).showSnackBar(
        const SnackBar(
          content: Text('Error al cargar los datos'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}
