import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/injection_container.dart';
// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/features/user/presentation/widgets/dialog_info_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/bloc/picking_pick_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_model.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';

class IndexListPickDoneScreen extends StatelessWidget {
  final bool isFromPick;

  const IndexListPickDoneScreen({super.key, required this.isFromPick});

  @override
  Widget build(BuildContext context) {
    final IAudioService _audioService = getIt<IAudioService>();
    final IVibrationService _vibrationService = getIt<IVibrationService>();
    FocusNode focusNodeBuscar = FocusNode();
    final TextEditingController _controllerToDo = TextEditingController();

    final size = MediaQuery.of(context).size;

    void validateBarcode(String value, BuildContext context) {
      final bloc = context.read<PickingPickBloc>();
      final scan = (bloc.scannedValue5.isEmpty ? value : bloc.scannedValue5)
          .trim()
          .toLowerCase();

      _controllerToDo.clear();
      debugPrint('🔎 Scan barcode (batch picking): $scan');

      final listOfBatchs = bloc.filtersHistoryPicks;

      void processBatch(ResultPick batch) {
        // bloc.add(ClearScannedValueEvent('toDo'));

        try {
          context
              .read<PickingPickBloc>()
              .add(LoadHistoryPickIdEvent(true, batch.id ?? 0));

          Navigator.pushReplacementNamed(context, 'detail-pick-done');
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al cargar los datos'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }

      // // Buscar el producto usando el código de barras principal o el código de producto
      final batchs = listOfBatchs.firstWhere(
        (b) =>
            b.name?.toLowerCase() == scan ||
            b.zonaEntrega?.toLowerCase() == scan,
        orElse: () => ResultPick(),
      );

      if (batchs.id != null) {
        debugPrint(
            '🔎 batch encontrado : ${batchs.id} ${batchs.name} - ${batchs.zonaEntrega}');
        processBatch(batchs);
        return;
      } else {
        _audioService.playErrorSound();
        _vibrationService.vibrate();
        // bloc.add(ClearScannedValueEvent('toDo'));
      }
    }

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocConsumer<PickingPickBloc, PickingPickState>(
        listener: (context, state) {},
        builder: (context, state) {
          final bloc = context.read<PickingPickBloc>();

          return Scaffold(
            backgroundColor: primaryColorApp,
            body: SafeArea(
              child: Container(
                color: Colors.white,
                child: Padding(
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
                        child: BlocBuilder<ConnectionStatusCubit,
                            ConnectionStatus>(builder: (context, status) {
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
                                            if (isFromPick) {
                                              Navigator.pushReplacementNamed(
                                                  context, 'pick');
                                            }
                                            if (!isFromPick) {
                                              Navigator.pushReplacementNamed(
                                                  context,
                                                  'picking-componentes');
                                            } else {
                                              Navigator.pushReplacementNamed(
                                                  context, '/home');
                                            }
                                          },
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(
                                              left: isFromPick
                                                  ? size.width * 0.15
                                                  : 20),
                                          child: Text(
                                            isFromPick
                                                ? 'HISTORIAL PICK'
                                                : 'HISTORIAL COMPONENTES',
                                            style: TextStyle(
                                                color: white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
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

                      Padding(
                        padding: const EdgeInsets.only(
                          left: 10,
                          // right: 5,
                        ),
                        child: SizedBox(
                          height: 55,
                          child: Card(
                            color: Colors.white,
                            elevation: 3,
                            child: TextFormField(
                              textAlignVertical: TextAlignVertical.center,
                              controller: bloc.searchPickController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search,
                                    color: grey, size: 20),
                                suffixIcon: IconButton(
                                    onPressed: () {
                                      bloc.searchPickController.clear();
                                      bloc.add(SearchPickEvent('', false));
                                      FocusScope.of(context).unfocus();
                                    },
                                    icon: IconButton(
                                      onPressed: () {
                                        bloc.add(SearchPickEvent('', false));
                                        bloc.searchPickController.clear();

                                        //pasamos el foco a focusNodeBuscar
                                        Future.delayed(
                                            const Duration(seconds: 1), () {
                                          // _handleDependencies();
                                          FocusScope.of(context)
                                              .requestFocus(focusNodeBuscar);
                                        });
                                      },
                                      icon: const Icon(Icons.close,
                                          color: grey, size: 20),
                                    )),
                                disabledBorder: const OutlineInputBorder(),
                                hintText: "Buscar pick",
                                hintStyle: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                bloc.add(SearchPickEvent(value, false));
                              },
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 14),
                            ),
                          ),
                        ),
                      ),

                      //*buscar por scan
                      BarcodeScannerField(
                        controller: _controllerToDo,
                        focusNode: focusNodeBuscar,
                        onBarcodeScanned: (value, context) {
                          return validateBarcode(value, context);
                        },
                        // onKeyScanned: (keyLabel, type, context) {
                        //   return context.read<PickingPickBloc>().add(
                        //         UpdateScannedValueEvent(keyLabel, type),
                        //       );
                        // },
                      ),

                      Expanded(
                        child: bloc.filtersHistoryPicks.isNotEmpty
                            ? ListView.builder(
                                padding: EdgeInsets.only(
                                    top: 10, bottom: size.height * 0.15),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: bloc.filtersHistoryPicks.length,
                                itemBuilder: (contextBuilder, index) {
                                  final batch = bloc.filtersHistoryPicks[index];
                                  //convertimos la fecha

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: GestureDetector(
                                      onTap: () async {
                                        context.read<PickingPickBloc>().add(
                                            LoadHistoryPickIdEvent(
                                                true, batch.id ?? 0));

                                        Navigator.pushReplacementNamed(
                                            context, 'detail-pick-done',
                                            arguments: [isFromPick]);
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
                                                    alignment:
                                                        Alignment.centerLeft,
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
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text("Operación: ",
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                primaryColorApp)),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      batch.pickingType
                                                          .toString(),
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
                                                        color: batch.priority ==
                                                                '0'
                                                            ? black
                                                            : red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Row(
                                                  children: [
                                                    Text('Estado: ',
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                primaryColorApp)),
                                                    Text(
                                                      batch?.state == 'done'
                                                          ? 'Completado'
                                                          : batch?.state ==
                                                                  'draft'
                                                              ? 'Borrador'
                                                              : batch?.state ==
                                                                      'waiting'
                                                                  ? 'Esperando'
                                                                  : batch?.state ==
                                                                          'confirmed'
                                                                      ? 'Confirmado'
                                                                      : batch?.state ==
                                                                              'assigned'
                                                                          ? 'Asignado'
                                                                          : "",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: batch?.state ==
                                                                'done'
                                                            ? green
                                                            : batch?.state ==
                                                                    'draft'
                                                                ? grey
                                                                : batch?.state ==
                                                                        'waiting'
                                                                    ? yellow
                                                                    : batch?.state ==
                                                                            'confirmed'
                                                                        ? red
                                                                        : batch?.state ==
                                                                                'assigned'
                                                                            ? red
                                                                            : black,
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
                                                      Icons
                                                          .calendar_month_sharp,
                                                      color: primaryColorApp,
                                                      size: 15,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      batch.fechaCreacion !=
                                                              null
                                                          ? DateFormat(
                                                                  'dd/MM/yyyy')
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
                                                        batch.referencia
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
                                                        batch.proveedor == ""
                                                            ? "Sin contacto"
                                                            : batch.proveedor ??
                                                                '',
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                batch.proveedor ==
                                                                        ""
                                                                    ? red
                                                                    : black),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Align(
                                              //   alignment: Alignment.centerLeft,
                                              //   child: Row(
                                              //     children: [
                                              //       Icon(
                                              //         Icons.receipt,
                                              //         color: primaryColorApp,
                                              //         size: 15,
                                              //       ),
                                              //       const SizedBox(width: 5),
                                              //       const Text(
                                              //         "Doc. Origen: ",
                                              //         style: TextStyle(
                                              //             fontSize: 12,
                                              //             color: black),
                                              //         maxLines: 2,
                                              //         overflow:
                                              //             TextOverflow.ellipsis,
                                              //       ),
                                              //       Expanded(
                                              //         child: Text(
                                              //           batch.origin.toString(),
                                              //           style: TextStyle(
                                              //               fontSize: 12,
                                              //               color: primaryColorApp),
                                              //           maxLines: 2,
                                              //           overflow:
                                              //               TextOverflow.ellipsis,
                                              //         ),
                                              //       ),
                                              //     ],
                                              //   ),
                                              // ),
                                              Visibility(
                                                visible: batch.backorderId != 0,
                                                child: Row(
                                                  children: [
                                                    Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Icon(
                                                          Icons.file_copy,
                                                          color:
                                                              primaryColorApp,
                                                          size: 15),
                                                    ),
                                                    const SizedBox(
                                                      width: 5,
                                                    ),
                                                    Text(
                                                        batch.backorderName ??
                                                            '',
                                                        style: TextStyle(
                                                            color: black,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
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
                                                        batch.numeroItems
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
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    batch.startTimeTransfer !=
                                                            ""
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
                ),
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
      batchBloc.searchPickController.clear();
      Navigator.pushReplacementNamed(context, 'scan-product-pick');
    }
  }
}
