import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/injection_container.dart';
// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously

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
import 'package:wms_app/src/presentation/views/wms_packing/models/response_packing_pedido_model.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/bloc/packing_pedido_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_start_picking_widget.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

class ListPackingScreen extends StatefulWidget {
  const ListPackingScreen({super.key});

  @override
  State<ListPackingScreen> createState() => _WmsPackingScreenState();
}

class _WmsPackingScreenState extends State<ListPackingScreen> {
  NotchBottomBarController controller = NotchBottomBarController();
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();
  FocusNode focusNodeBuscar = FocusNode();
  final TextEditingController _controllerToDo = TextEditingController();

  void validateBarcode(String value, BuildContext context) {
    final bloc = context.read<PackingPedidoBloc>();
    final scan = (bloc.scannedValue5.isEmpty ? value : bloc.scannedValue5)
        .trim()
        .toLowerCase();

    _controllerToDo.clear();
    debugPrint('🔎 Scan barcode (batch picking): $scan');

    final listOfBatchs = bloc.listOfPedidosBD;

    void processBatch(PedidoPackingResult batch) {
      Future.microtask(() => focusNodeBuscar.requestFocus());

      try {
        _handlePackingOnTap(context, batch, context);
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
          b.zonaEntrega?.toLowerCase() == scan ||
          b.locationBarcode?.toLowerCase() == scan ||
          b.locationBarcodeCluster?.toLowerCase() == scan ||
          b.referencia?.toLowerCase() == scan,
      orElse: () => PedidoPackingResult(),
    );

    if (batchs.id != null) {
      debugPrint(
          '🔎 batch encontrado : ${batchs.id} ${batchs.name} - ${batchs.zonaEntrega}');
      processBatch(batchs);
      return;
    } else {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      Future.microtask(() => focusNodeBuscar.requestFocus());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Packing no encontrado en la lista')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return BlocConsumer<PackingPedidoBloc, PackingPedidoState>(
        listener: (context, state) {
      debugPrint("Estado del bloc: $state");

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

      if (state is LoadPedidoAndProductsLoading) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        //dialogo de cargando
        showDialog(
          context: context,
          barrierDismissible:
              false, // No permitir que el usuario cierre el diálogo manualmente
          builder: (_) => const DialogLoading(
            message: 'Cargando pedido...',
          ),
        );
      }

      if (state is LoadPedidoAndProductsLoaded) {
        //cerramos el dialogo de cargando
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        //navegamos a la pantalla de detalle
        Navigator.pushReplacementNamed(context, 'detail-packing-pedido',
            arguments: [0]);
      }

      // if (state is AssignUserToPedidoError) {
      //   //validamos que este un dialog abierto
      //   if (Navigator.canPop(context)) {
      //     Navigator.pop(context);
      //   }
      //   Get.snackbar(
      //     '360 Software Informa',
      //     state.error,
      //     backgroundColor: white,
      //     colorText: primaryColorApp,
      //     icon: Icon(Icons.error, color: Colors.red),
      //   );
      // }

      if (state is AssignUserToPedidoLoading) {
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

      if (state is AssignUserToPedidoLoaded) {
        // cerramos el dialogo de carga
        // Navigator.pop(context);
        context.read<PackingPedidoBloc>().add(LoadConfigurationsUser());
        //traemos el pedido y los productos
        context.read<PackingPedidoBloc>().add(LoadPedidoAndProductsEvent(
              state.id,
            ));

        // Navigator.pushReplacementNamed(context, 'detail-packing-pedido',
        //     arguments: [0]);
      }
    }, builder: (context, state) {
      final bloc = context.read<PackingPedidoBloc>();

      List<PedidoPackingResult> listToShow = bloc.listOfPedidosFilters
          .where((batch) => batch.isTerminate == 0)
          .toList();

      return Scaffold(
          backgroundColor: primaryColorApp,
          body: SafeArea(
            child: Container(
              color: Colors.white,
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
                            padding:
                                EdgeInsets.only(left: 10, right: 10, bottom: 0),
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
                                          left: size.width * 0.1),
                                      child: GestureDetector(
                                        onTap: () async {
                                          if (state
                                              is WmsPackingPedidoWMSLoading) {
                                            return;
                                          }

                                          await DataBaseSqlite()
                                              .delePacking('packing-pack');
                                          context
                                              .read<PackingPedidoBloc>()
                                              .add(LoadAllPackingPedidoEvent(
                                                true,
                                              ));
                                        },
                                        child: Row(
                                          children: [
                                            const Text(
                                              'PACKING PEDIDOS',
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
                                    // ✅ MENU DE FILTROS (Reemplaza al Spacer)
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: white,
                                      ),
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'priority_high':
                                            bloc.add(SortPackingListEvent(
                                                'priority', false));
                                            break;
                                          case 'priority_normal':
                                            bloc.add(SortPackingListEvent(
                                                'priority', true));
                                            break;
                                          case 'date_asc':
                                            bloc.add(SortPackingListEvent(
                                                'date', true));
                                            break;
                                          case 'date_desc':
                                            bloc.add(SortPackingListEvent(
                                                'date', false));
                                            break;
                                          case 'name_asc':
                                            bloc.add(SortPackingListEvent(
                                                'name', true));
                                            break;
                                          case 'name_desc':
                                            bloc.add(SortPackingListEvent(
                                                'name', false));
                                            break;
                                          case 'backorder_desc':
                                            bloc.add(SortPackingListEvent(
                                                'backorder', false));
                                            break;
                                          case 'backorder_asc':
                                            bloc.add(SortPackingListEvent(
                                                'backorder', true));
                                            break;
                                        }
                                      },
                                      itemBuilder: (BuildContext context) {
                                        final currentKey =
                                            bloc.currentFilterKey;
                                        // 2. Definimos el color de resaltado (Naranja o tu PrimaryColor)
                                        final Color activeColor =
                                            primaryColorApp; // O usa primaryColorApp
                                        final Color inactiveColor =
                                            Colors.black;

                                        TextStyle getStyle(String key) {
                                          final isSelected = currentKey == key;
                                          return TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? activeColor
                                                : inactiveColor,
                                          );
                                        }

                                        // 4. Icono seleccionado vs normal
                                        Color getIconColor(String key) {
                                          return currentKey == key
                                              ? activeColor
                                              : Colors.grey;
                                        }

                                        return <PopupMenuEntry<String>>[
                                          // --- SECCIÓN PRIORIDAD ---
                                          const PopupMenuItem<String>(
                                            enabled: false,
                                            height: 30,
                                            child: Text('PRIORIDAD',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Colors.grey)),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'priority_high',
                                            height: 40,
                                            child: Row(children: [
                                              Icon(Icons.warning,
                                                  size: 16,
                                                  color: currentKey ==
                                                          'priority_high'
                                                      ? Colors.red
                                                      : Colors
                                                          .grey), // Rojo si está seleccionado, o siempre rojo si prefieres
                                              SizedBox(width: 8),
                                              Text('Alta primero',
                                                  style: getStyle(
                                                      'priority_high')),
                                              if (currentKey ==
                                                  'priority_high') ...[
                                                Spacer(),
                                                Icon(Icons.check,
                                                    size: 15,
                                                    color: activeColor)
                                              ] // Check visual
                                            ]),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'priority_normal',
                                            height: 40,
                                            child: Row(children: [
                                              Icon(Icons.check_circle,
                                                  size: 16,
                                                  color: getIconColor(
                                                      'priority_normal')),
                                              SizedBox(width: 8),
                                              Text('Normal primero',
                                                  style: getStyle(
                                                      'priority_normal')),
                                              if (currentKey ==
                                                  'priority_normal') ...[
                                                Spacer(),
                                                Icon(Icons.check,
                                                    size: 15,
                                                    color: activeColor)
                                              ]
                                            ]),
                                          ),
                                          const PopupMenuDivider(),

                                          // --- SECCIÓN FECHA ---
                                          const PopupMenuItem<String>(
                                            enabled: false,
                                            height: 30,
                                            child: Text('FECHA',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Colors.grey)),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'date_asc',
                                            height: 40,
                                            child: Row(children: [
                                              Icon(
                                                  Icons.calendar_month_outlined,
                                                  size: 16,
                                                  color:
                                                      getIconColor('date_asc')),
                                              SizedBox(width: 8),
                                              Text('Más Antiguas',
                                                  style: getStyle('date_asc')),
                                              if (currentKey == 'date_asc') ...[
                                                Spacer(),
                                                Icon(Icons.check,
                                                    size: 15,
                                                    color: activeColor)
                                              ]
                                            ]),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'date_desc',
                                            height: 40,
                                            child: Row(children: [
                                              Icon(
                                                  Icons.calendar_month_outlined,
                                                  size: 16,
                                                  color: getIconColor(
                                                      'date_desc')),
                                              SizedBox(width: 8),
                                              Text('Más Recientes',
                                                  style: getStyle('date_desc')),
                                              if (currentKey ==
                                                  'date_desc') ...[
                                                Spacer(),
                                                Icon(Icons.check,
                                                    size: 15,
                                                    color: activeColor)
                                              ]
                                            ]),
                                          ),
                                          const PopupMenuDivider(),

                                          // --- SECCIÓN CONSECUTIVO ---
                                          const PopupMenuItem<String>(
                                            enabled: false,
                                            height: 30,
                                            child: Text('CONSECUTIVO',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Colors.grey)),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'name_asc',
                                            height: 40,
                                            child: Row(children: [
                                              Icon(Icons.arrow_upward,
                                                  size: 16,
                                                  color:
                                                      getIconColor('name_asc')),
                                              SizedBox(width: 8),
                                              Text('Consecutivo (A-Z)',
                                                  style: getStyle('name_asc')),
                                              if (currentKey == 'name_asc') ...[
                                                Spacer(),
                                                Icon(Icons.check,
                                                    size: 15,
                                                    color: activeColor)
                                              ]
                                            ]),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'name_desc',
                                            height: 40,
                                            child: Row(children: [
                                              Icon(Icons.arrow_downward,
                                                  size: 16,
                                                  color: getIconColor(
                                                      'name_desc')),
                                              SizedBox(width: 8),
                                              Text('Consecutivo (Z-A)',
                                                  style: getStyle('name_desc')),
                                              if (currentKey ==
                                                  'name_desc') ...[
                                                Spacer(),
                                                Icon(Icons.check,
                                                    size: 15,
                                                    color: activeColor)
                                              ]
                                            ]),
                                          ),
                                          const PopupMenuDivider(),

                                          // --- SECCIÓN BACKORDER ---
                                          const PopupMenuItem<String>(
                                            enabled: false,
                                            height: 30,
                                            child: Text('BACKORDER',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Colors.grey)),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'backorder_desc',
                                            height: 40,
                                            child: Row(children: [
                                              Icon(Icons.file_copy,
                                                  size: 16,
                                                  color: getIconColor(
                                                      'backorder_desc')),
                                              SizedBox(width: 8),
                                              Text('Con Backorder primero',
                                                  style: getStyle(
                                                      'backorder_desc')),
                                              if (currentKey ==
                                                  'backorder_desc') ...[
                                                Spacer(),
                                                Icon(Icons.check,
                                                    size: 15,
                                                    color: activeColor)
                                              ]
                                            ]),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'backorder_asc',
                                            height: 40,
                                            child: Row(children: [
                                              Icon(Icons.file_copy_outlined,
                                                  size: 16,
                                                  color: getIconColor(
                                                      'backorder_asc')),
                                              SizedBox(width: 8),
                                              Text('Sin Backorder primero',
                                                  style: getStyle(
                                                      'backorder_asc')),
                                              if (currentKey ==
                                                  'backorder_asc') ...[
                                                Spacer(),
                                                Icon(Icons.check,
                                                    size: 15,
                                                    color: activeColor)
                                              ]
                                            ]),
                                          ),
                                        ];
                                      },
                                    ),
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
                    controller:
                        context.read<PackingPedidoBloc>().searchController,
                    hintText: "Buscar pedido",
                    onSearchChanged: (value) {
                      context
                          .read<PackingPedidoBloc>()
                          .add(SearchPedidoEvent(value));
                    },
                    onSearchCleared: () {
                      final packingBloc = context.read<PackingPedidoBloc>();
                      packingBloc.searchController.clear();
                      packingBloc.add(SearchPedidoEvent(''));
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted) {
                          FocusScope.of(context).requestFocus(focusNodeBuscar);
                        }
                      });
                    },
                  ),

                  //*buscar por scan
                  BarcodeScannerField(
                    controller: _controllerToDo,
                    focusNode: focusNodeBuscar,
                    onBarcodeScanned: (value, context) {
                      return validateBarcode(value, context);
                    },
                  ),

                  //*listado de batchs
                  Expanded(
                    child: context
                            .read<PackingPedidoBloc>()
                            .listOfPedidosFilters
                            .where((batch) => batch.isTerminate == 0)
                            .isNotEmpty
                        ? ListView.builder(
                            padding: const EdgeInsets.only(top: 20, bottom: 20),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: listToShow.length,
                            itemBuilder: (contextBuilder, index) {
                              final List<PedidoPackingResult>
                                  inProgressBatches = context
                                      .read<PackingPedidoBloc>()
                                      .listOfPedidosFilters
                                      .where((batch) => batch.isTerminate == 0)
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

                              final batch = listToShow[index];

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                child: GestureDetector(
                                  onTap: () async {
                                    _handlePackingOnTap(
                                        context, batch, contextBuilder);
                                  },
                                  child: Card(
                                    color: batch.isTerminate == 1
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
                                      title: Text(batch.name ?? '',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: primaryColorApp,
                                              fontWeight: FontWeight.bold)),
                                      subtitle: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(batch.zonaEntrega ?? '',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: black)),
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
                                                    fontSize: 12, color: black),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
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
                                          if (batch.configPacking !=
                                              'cluster') ...[
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Row(
                                                children: [
                                                  Text('Ubicacion: ',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp)),
                                                  Text(
                                                    batch.locationName ?? '',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          if (batch.configPacking ==
                                              'cluster') ...[
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Row(
                                                children: [
                                                  Text('Ubicacion : ',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp)),
                                                  Text(
                                                    batch.locationNameCluster ??
                                                        '',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
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
                                                                  .fechaCreacion
                                                                  .toString()))
                                                      : "Sin fecha",
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: black),
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
                                                    batch.referencia.toString(),
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
                                                  Icons.person,
                                                  color: primaryColorApp,
                                                  size: 15,
                                                ),
                                                const SizedBox(width: 5),
                                                Expanded(
                                                  child: Text(
                                                    batch.proveedor == "" ||
                                                            batch.proveedor ==
                                                                null
                                                        ? "Sin proveedor"
                                                        : batch.proveedor ?? '',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: batch.proveedor ==
                                                                    "" ||
                                                                batch.proveedor ==
                                                                    null
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
                                                  Icons.add,
                                                  color: primaryColorApp,
                                                  size: 15,
                                                ),
                                                const SizedBox(width: 5),
                                                const Text(
                                                  "Cantidad de items: ",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: black),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    batch.cantidadProductos
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
                                                  "Cantidad de paquetes: ",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: black),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    batch.numeroPaquetes
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
                                                    batch.responsable == "" ||
                                                            batch.responsable ==
                                                                null
                                                        ? "Sin responsable"
                                                        : batch.responsable ??
                                                            '',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: batch.responsable ==
                                                                    "" ||
                                                                batch.responsable ==
                                                                    null
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
                                                                            'Este pedido fue iniciado a las ${batch.startTimeTransfer}',
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
    });
  }

  void validateTime(PedidoPackingResult pedido, BuildContext context) {
    final packingPedidoBloc = context.read<PackingPedidoBloc>();

    if (pedido.startTimeTransfer == "" || pedido.startTimeTransfer == null) {
      showDialog(
        context: context,
        barrierDismissible:
            false, // No permitir que el usuario cierre el diálogo manualmente
        builder: (dialogContext) => DialogStartTimeWidget(
          onAccepted: () async {
            packingPedidoBloc.searchControllerPedido.clear();
            packingPedidoBloc.add(SearchPedidoEvent(''));
            packingPedidoBloc.add(
                StartOrStopTimePack(pedido.id ?? 0, "start_time_transfer"));
            packingPedidoBloc.add(LoadPedidoAndProductsEvent(pedido.id ?? 0));
            Navigator.pop(dialogContext);
            // if (mounted) {
            //   Navigator.pushReplacementNamed(context, 'detail-packing-pedido',
            //       arguments: [0]);
            // }
          },
          title: 'Iniciar Packing',
        ),
      );
    } else {
      packingPedidoBloc.searchControllerPedido.clear();
      packingPedidoBloc.add(SearchPedidoEvent(''));
      packingPedidoBloc.add(
        LoadPedidoAndProductsEvent(pedido.id ?? 0),
      );
    }
  }

  void _handlePackingOnTap(
      BuildContext context, dynamic batch, BuildContext contextBuilder) async {
    try {
      // 1. Cargar las configuraciones una sola vez
      context.read<PackingPedidoBloc>().add(LoadConfigurationsUser());

      // 2. Lógica para asignar el responsable o continuar
      if (batch.responsableId == null || batch.responsableId == 0) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => DialogAsignUserWidget(
            title:
                'Esta seguro de tomar este pedido de packing, una vez aceptado no podrá ser cancelada desde la app, una vez asignada se registrará el tiempo de inicio de la operación.',
            onCancel: () {
              Future.microtask(() => focusNodeBuscar.requestFocus());
              Navigator.pop(dialogContext);
            },
            onAccepted: () async {
              // Lógica para asignar el usuario
              final packingBloc = context.read<PackingPedidoBloc>();
              packingBloc.add(AssignUserToPedido(batch.id ?? 0));
              packingBloc.searchController.clear();

              Navigator.pop(dialogContext); // Cierra el diálogo de asignación

              // Después de asignar el usuario, continuar con la validación de tiempo
              validateTime(batch, context);
            },
          ),
        );
      } else {
        // Si el responsable ya existe, validar el tiempo directamente
        validateTime(batch, context);
      }
    } catch (e) {
      // 3. Manejo de errores centralizado
      ScaffoldMessenger.of(contextBuilder).showSnackBar(
        const SnackBar(
          content: Text('Error al cargar los datos'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

// Nota: La función `validateTime` debe estar definida en la misma clase
// o ser un método del BLoC para ser accesible.
}
