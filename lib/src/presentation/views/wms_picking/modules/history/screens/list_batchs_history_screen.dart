import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/core/utils/sounds_utils.dart';
import 'package:wms_app/core/utils/vibrate_utils.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/bloc/wms_picking_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/index.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/history/models/hisotry_done_model.dart';
import 'package:wms_app/src/presentation/widgets/barcode_scanner_widget.dart';

class HistoryListScreen extends StatelessWidget {
  const HistoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AudioService audioService = AudioService();
    final VibrationService vibrationService = VibrationService();
    FocusNode focusNodeBuscar = FocusNode();

    void validateBarcode(String value, BuildContext context) {
      final bloc = context.read<WMSPickingBloc>();
      final scan = (bloc.scannedToDo.isEmpty ? value : bloc.scannedToDo)
          .trim()
          .toLowerCase();

      bloc.searchHistoryController.clear();
      print('🔎 Scan barcode (batch picking): $scan');

      final listOfBatchs = bloc.filtersHistoryBatchs;

      void processBatch(HistoryBatch batch) {
        bloc.add(ClearScannedValuePickingEvent('toDo'));
        context
            .read<WMSPickingBloc>()
            .add(LoadHistoryBatchIdEvent(true, batch.id ?? 0));

        Navigator.pushNamed(
          context,
          'history-detail',
        );
        print(batch.toMap());
        try {} catch (e) {
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
        (b) => b.name?.toLowerCase() == scan,
        orElse: () => HistoryBatch(),
      );

      if (batchs.id != null) {
        print('🔎 batch encontrado : ${batchs.id} ${batchs.name}');
        processBatch(batchs);
        return;
      } else {
        audioService.playErrorSound();
        vibrationService.vibrate();
        bloc.add(ClearScannedValuePickingEvent('toDo'));
      }
    }

    final size = MediaQuery.sizeOf(context);
    return BlocBuilder<WMSPickingBloc, PickingState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: white,
          body: Column(
            children: [
              //*barra informativa
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
                            top: status != ConnectionStatus.online ? 20 : 20,
                            bottom: 10),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back,
                                      color: white),
                                  onPressed: () {
                                    context
                                        .read<WMSPickingBloc>()
                                        .filtersHistoryBatchs = [];
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const WMSPickingPage()),
                                        (route) => false);
                                  },
                                ),
                                Padding(
                                  padding:
                                      EdgeInsets.only(left: size.width * 0.15),
                                  child: const Text(
                                    'HISTORIAL BATCHS',
                                    style: TextStyle(
                                        color: white,
                                        fontSize: 16,
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

              SizedBox(
                  height: 60, //120
                  width: size.width * 1,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 10,
                        ),
                        child: SizedBox(
                          width: size.width * 0.95,
                          height: 55,
                          child: Card(
                            color: Colors.white,
                            elevation: 3,
                            child: TextFormField(
                                textAlignVertical: TextAlignVertical.center,
                                controller: context
                                    .read<WMSPickingBloc>()
                                    .searchHistoryController,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.search,
                                      color: grey, size: 20),
                                  suffixIcon: IconButton(
                                      onPressed: () {},
                                      icon: IconButton(
                                        onPressed: () {
                                          context
                                              .read<WMSPickingBloc>()
                                              .add(ShowKeyboardEvent(false));
                                          context
                                              .read<WMSPickingBloc>()
                                              .searchHistoryController
                                              .clear();

                                          context
                                              .read<WMSPickingBloc>()
                                              .add(SearchBatchHistoryEvent(''));

                                          //pasamos el foco a focusNodeBuscar
                                          Future.delayed(
                                              const Duration(seconds: 1), () {
                                            // _handleDependencies();
                                            // ignore: use_build_context_synchronously
                                            FocusScope.of(context)
                                                .requestFocus(focusNodeBuscar);
                                          });
                                        },
                                        icon: const Icon(Icons.close,
                                            color: grey, size: 20),
                                      )),
                                  disabledBorder: const OutlineInputBorder(),
                                  hintText: "Buscar batch",
                                  hintStyle: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) {
                                  context
                                      .read<WMSPickingBloc>()
                                      .add(SearchBatchHistoryEvent(value));
                                },
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 14),
                                onTap: !context
                                        .read<UserBloc>()
                                        .fabricante
                                        .contains("Zebra")
                                    ? null
                                    : () {
                                        context
                                            .read<WMSPickingBloc>()
                                            .add(ShowKeyboardEvent(true));
                                      }),
                          ),
                        ),
                      ),
                    ],
                  )),

              //*buscar por scan
              BarcodeScannerField(
                controller:
                    context.read<WMSPickingBloc>().searchHistoryController,
                focusNode: focusNodeBuscar,
                scannedValue5: "",
                onBarcodeScanned: (value, context) {
                  return validateBarcode(value, context);
                },
                onKeyScanned: (keyLabel, type, context) {
                  return context.read<WMSPickingBloc>().add(
                        UpdateScannedValuePickingEvent(keyLabel, 'toDo'),
                      );
                },
              ),

              //*listado de batchs

              Expanded(
                child: Container(
                  child: context
                          .read<WMSPickingBloc>()
                          .filtersHistoryBatchs
                          .isNotEmpty
                      ? ListView.builder(
                          padding: EdgeInsets.only(
                              top: 10, bottom: size.height * 0.15),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: context
                              .read<WMSPickingBloc>()
                              .filtersHistoryBatchs
                              .length,
                          itemBuilder: (context, index) {
                            final batch = context
                                .read<WMSPickingBloc>()
                                .filtersHistoryBatchs[index];
                            //convertimos la fecha

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: GestureDetector(
                                onTap: () async {
                                  context.read<WMSPickingBloc>().add(
                                      LoadHistoryBatchIdEvent(
                                          true, batch.id ?? 0));

                                  Navigator.pushNamed(
                                    context,
                                    'history-detail',
                                  );
                                },
                                child: Card(
                                  color: batch.state == "in_progress"
                                      ? primaryColorAppLigth
                                      : Colors.green[100],
                                  elevation: 3,
                                  child: ListTile(
                                    trailing: Icon(
                                      Icons.arrow_forward_ios,
                                      color: primaryColorApp,
                                    ),
                                    leading: Container(
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
                                    title: Text(batch.name ?? '',
                                        style: const TextStyle(fontSize: 14)),
                                    subtitle: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text("Tipo de operación:",
                                              style: TextStyle(
                                                  fontSize: 14, color: grey)),
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            batch.pickingTypeId.toString(),
                                            style: TextStyle(
                                                fontSize: 14,
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
                                                            batch.scheduleddate
                                                                .toString()))
                                                    : "Sin fecha",
                                                style: const TextStyle(
                                                    fontSize: 14),
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
                                                "Total Productos: ",
                                                style: TextStyle(
                                                    fontSize: 14, color: black),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  batch.countItems.toString(),
                                                  style: TextStyle(
                                                      fontSize: 14,
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
                                                "Productos separados: ",
                                                style: TextStyle(
                                                    fontSize: 14, color: black),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  batch.itemsSeparado
                                                      .toString(),
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: primaryColorApp),
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
                                  style: TextStyle(fontSize: 18, color: grey)),
                              Text('Intenta con otra búsqueda',
                                  style: TextStyle(fontSize: 14, color: grey)),
                            ],
                          ),
                        ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
