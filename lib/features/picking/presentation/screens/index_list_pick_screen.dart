import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/features/picking/presentation/bloc/list/picking_list_bloc.dart';
import 'package:wms_app/features/picking/presentation/bloc/scan/pick_scan_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/bloc/picking_pick_bloc.dart' as ppb;
import 'package:wms_app/injection_container.dart';
// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_holo_date_picker/date_picker.dart';
import 'package:flutter_holo_date_picker/i18n/date_picker_i18n.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_start_picking_widget.dart';
import 'package:wms_app/features/user/presentation/widgets/dialog_info_widget.dart';
import 'package:wms_app/shared/widgets/loading_dialog_mixin.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_start_picking_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_model.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

class IndexListPickScreen extends StatefulWidget {
  const IndexListPickScreen({super.key});

  @override
  State<IndexListPickScreen> createState() => _IndexListPickScreenState();
}

class _IndexListPickScreenState extends State<IndexListPickScreen>
    with LoadingDialogMixin {
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();
  final FocusNode focusNodeBuscar = FocusNode();
  final TextEditingController _controllerToDo = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => focusNodeBuscar.requestFocus());
  }

  @override
  void dispose() {
    focusNodeBuscar.dispose();
    _controllerToDo.dispose();
    super.dispose();
  }

  void validateBarcode(String value, BuildContext context) {
    final bloc = context.read<PickingListBloc>();
    final scan = (bloc.scannedValue1.isEmpty ? value : bloc.scannedValue1)
        .trim()
        .toLowerCase();

    _controllerToDo.clear();
    debugPrint('🔎 Scan barcode (batch picking): $scan');

    final listOfPick = bloc.listOfPick;

    void processBatch(ResultPick batch) {
      try {
        _handleTap(context, context, batch);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar los datos'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }

    // Buscar el pick usando el código de barras o el nombre
    final pick = listOfPick.firstWhere(
      (b) =>
          b.name?.toLowerCase() == scan || b.zonaEntrega?.toLowerCase() == scan,
      orElse: () => ResultPick(),
    );

    if (pick.id != null) {
      debugPrint(
          '🔎 pick encontrado : ${pick.id} ${pick.name} - ${pick.zonaEntrega}');
      processBatch(pick);
      return;
    } else {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      Future.microtask(() => focusNodeBuscar.requestFocus());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick no encontrado en la lista')),
      );
    }
  }

  void _handleTap(
      BuildContext context, BuildContext contextBuilder, dynamic batch) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    debugPrint("Batch: ${batch.toMap()}");
    final bloc = context.read<PickingListBloc>();

    try {
      // Lógica para asignar responsable si no existe
      if (batch.responsableId == null || batch.responsableId == 0) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => DialogAsignUserWidget(
            title:
                'Esta seguro de tomar este pick, una vez aceptado no podrá ser cancelada desde la app, una vez asignada se registrará el tiempo de inicio de la operación.',
            onCancel: () {
              Future.microtask(() => focusNodeBuscar.requestFocus());
              Navigator.pop(dialogContext);
            },
            onAccepted: () async {
              bloc.add(AssignUserToPickEvent(batch.id ?? 0));
              Navigator.pop(dialogContext);
            },
          ),
        );
        bloc.searchPickController.clear();
        return;
      }

      // Lógica para iniciar la transferencia si el tiempo no ha comenzado
      if (batch.startTimeTransfer == "") {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => DialogStartTimeWidget(
            title: 'Iniciar Pick',
            onAccepted: () async {
              bloc.add(StartStopTimePickEvent(
                batch.id ?? 0,
                'start_time_transfer',
              ));
              Navigator.pop(dialogContext);
            },
          ),
        );
      }

      bloc.searchPickController.clear();
      bloc.add(LoadPickWithProductsEvent(batch.id ?? 0));
      bloc.add(LoadPickConfigurationsEvent());

      // Cargar en PickScanBloc (lógica nueva de la pantalla de scan)
      context.read<PickScanBloc>().add(FetchPickWithProductsEvent(batch.id ?? 0));

      // Cargar en PickingPickBloc (puente para widgets internos que aún lo usan)
      context.read<ppb.PickingPickBloc>().add(ppb.FetchPickWithProductsEvent(batch.id ?? 0));
      context.read<ppb.PickingPickBloc>().add(ppb.LoadConfigurationsUser());

      _goBatchInfo(
        contextBuilder,
        bloc,
        batch,
      );
    } catch (e) {
      ScaffoldMessenger.of(contextBuilder).showSnackBar(
        const SnackBar(
          content: Text('Error al cargar los datos'),
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _goBatchInfo(
    BuildContext context,
    PickingListBloc batchBloc,
    ResultPick batch,
  ) async {
    showLoadingDialog('Cargando interfaz...');

    // Esperar a que PickScanBloc termine de cargar el pick antes de navegar
    // evita race condition donde currentProduct está vacío al abrir la pantalla
    try {
      await context.read<PickScanBloc>().stream.firstWhere(
        (s) => s is LoadProductsBatchSuccesStateBD || s is EmptyProductsPick,
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Si hay timeout o error, igual navegamos (el loading en scan screen cubre esto)
    }

    if (!context.mounted) return;
    hideLoadingDialog();

    if (batch.isSeparate != 1) {
      batchBloc.searchPickController.clear();
      Navigator.pushReplacementNamed(context, 'scan-product-pick',
          arguments: [true]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocConsumer<PickingListBloc, PickingListState>(
        listener: (context, state) {
         
          if (state is AssignUserToPickError) {
            // El error no cerraba el loader y quedaba pegado.
            hideLoadingDialog();
            Get.snackbar(
              '360 Software Informa',
              state.message,
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: Icon(Icons.error, color: Colors.red),
            );
          }

          if (state is AssignUserToPickLoading) {
            showLoadingDialog('Cargando interfaz...');
          }

          if (state is AssignUserToPickSuccess) {
            hideLoadingDialog();
            context.read<PickingListBloc>().add(LoadPickWithProductsEvent(state.id));
            context.read<PickingListBloc>().add(LoadPickConfigurationsEvent());
            // Puente: cargar en PickScanBloc y PickingPickBloc
            context.read<PickScanBloc>().add(FetchPickWithProductsEvent(state.id));
            context.read<ppb.PickingPickBloc>().add(ppb.FetchPickWithProductsEvent(state.id));
            context.read<ppb.PickingPickBloc>().add(ppb.LoadConfigurationsUser());
            Navigator.pushReplacementNamed(context, 'scan-product-pick',
                arguments: [true]);
          }

          // Sincronizar configuraciones al PickScanBloc cuando se cargan
          if (state is PickConfigurationsLoaded) {
            context.read<PickScanBloc>().configurations = state.configurations;
          }
        },
        builder: (context, state) {
          final bloc = context.read<PickingListBloc>();

          List<ResultPick> listToShow = bloc.listOfPickFiltered
              .where((batch) => batch.isSeparate == 0)
              .toList();

          return Scaffold(
            backgroundColor: primaryColorApp,
            body: SafeArea(
              child: Container(
                padding: const EdgeInsets.only(bottom: 10),
                color: Colors.white,
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
                              padding: const EdgeInsets.only(
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
                                              context, '/home');
                                        },
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          if (_isProcessing ||
                                              bloc.state is PickingListLoading ||
                                              bloc.state is PickingListDbLoading) {
                                            return;
                                          }
                                          setState(() => _isProcessing = true);
                                          try {
                                            bloc.add(FetchPicksEvent(true));
                                          } finally {
                                            if (mounted) {
                                              setState(() => _isProcessing = false);
                                            }
                                          }
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
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(width: 5),
                                              const Icon(
                                                Icons.refresh,
                                                color: white,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert,
                                            color: white, size: 24),
                                        onSelected: (value) {
                                          switch (value) {
                                            case 'priority_high':
                                              bloc.add(SortPicksEvent(
                                                  'priority', false));
                                              break;
                                            case 'priority_normal':
                                              bloc.add(SortPicksEvent(
                                                  'priority', true));
                                              break;
                                            case 'date_asc':
                                              bloc.add(SortPicksEvent(
                                                  'date', true));
                                              break;
                                            case 'date_desc':
                                              bloc.add(SortPicksEvent(
                                                  'date', false));
                                              break;
                                            case 'name_asc':
                                              bloc.add(SortPicksEvent(
                                                  'name', true));
                                              break;
                                            case 'name_desc':
                                              bloc.add(SortPicksEvent(
                                                  'name', false));
                                              break;
                                            case 'backorder_desc':
                                              bloc.add(SortPicksEvent(
                                                  'backorder', false));
                                              break;
                                            case 'backorder_asc':
                                              bloc.add(SortPicksEvent(
                                                  'backorder', true));
                                              break;
                                          }
                                        },
                                        itemBuilder: (BuildContext context) {
                                          final currentKey =
                                              bloc.currentFilterKey;
                                          const Color activeColor =
                                              primaryColorApp;
                                          const Color inactiveColor = black;

                                          TextStyle getStyle(String key) {
                                            final isSelected =
                                                currentKey == key;
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

                                          Color getIconColor(String key) {
                                            return currentKey == key
                                                ? activeColor
                                                : Colors.grey;
                                          }

                                          return <PopupMenuEntry<String>>[
                                            const PopupMenuItem<String>(
                                              enabled: false,
                                              height: 30,
                                              child: Text('PRIORIDAD',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                        : Colors.grey),
                                                const SizedBox(width: 8),
                                                Text('Alta primero',
                                                    style: getStyle(
                                                        'priority_high')),
                                                if (currentKey ==
                                                    'priority_high') ...[
                                                  const Spacer(),
                                                  const Icon(Icons.check,
                                                      size: 15,
                                                      color: activeColor)
                                                ]
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
                                                const SizedBox(width: 8),
                                                Text('Normal primero',
                                                    style: getStyle(
                                                        'priority_normal')),
                                                if (currentKey ==
                                                    'priority_normal') ...[
                                                  const Spacer(),
                                                  const Icon(Icons.check,
                                                      size: 15,
                                                      color: activeColor)
                                                ]
                                              ]),
                                            ),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem<String>(
                                              enabled: false,
                                              height: 30,
                                              child: Text('FECHA',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                      color: Colors.grey)),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'date_asc',
                                              height: 40,
                                              child: Row(children: [
                                                Icon(
                                                    Icons
                                                        .calendar_month_outlined,
                                                    size: 16,
                                                    color: getIconColor(
                                                        'date_asc')),
                                                const SizedBox(width: 8),
                                                Text('Más Antiguas',
                                                    style:
                                                        getStyle('date_asc')),
                                                if (currentKey ==
                                                    'date_asc') ...[
                                                  const Spacer(),
                                                  const Icon(Icons.check,
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
                                                    Icons
                                                        .calendar_month_outlined,
                                                    size: 16,
                                                    color: getIconColor(
                                                        'date_desc')),
                                                const SizedBox(width: 8),
                                                Text('Más Recientes',
                                                    style:
                                                        getStyle('date_desc')),
                                                if (currentKey ==
                                                    'date_desc') ...[
                                                  const Spacer(),
                                                  const Icon(Icons.check,
                                                      size: 15,
                                                      color: activeColor)
                                                ]
                                              ]),
                                            ),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem<String>(
                                              enabled: false,
                                              height: 30,
                                              child: Text('CONSECUTIVO',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                      color: Colors.grey)),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'name_asc',
                                              height: 40,
                                              child: Row(children: [
                                                Icon(Icons.arrow_upward,
                                                    size: 16,
                                                    color: getIconColor(
                                                        'name_asc')),
                                                const SizedBox(width: 8),
                                                Text('Consecutivo (A-Z)',
                                                    style:
                                                        getStyle('name_asc')),
                                                if (currentKey ==
                                                    'name_asc') ...[
                                                  const Spacer(),
                                                  const Icon(Icons.check,
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
                                                const SizedBox(width: 8),
                                                Text('Consecutivo (Z-A)',
                                                    style:
                                                        getStyle('name_desc')),
                                                if (currentKey ==
                                                    'name_desc') ...[
                                                  const Spacer(),
                                                  const Icon(Icons.check,
                                                      size: 15,
                                                      color: activeColor)
                                                ]
                                              ]),
                                            ),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem<String>(
                                              enabled: false,
                                              height: 30,
                                              child: Text('BACKORDER',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                const SizedBox(width: 8),
                                                Text('Con Backorder primero',
                                                    style: getStyle(
                                                        'backorder_desc')),
                                                if (currentKey ==
                                                    'backorder_desc') ...[
                                                  const Spacer(),
                                                  const Icon(Icons.check,
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
                                                const SizedBox(width: 8),
                                                Text('Sin Backorder primero',
                                                    style: getStyle(
                                                        'backorder_asc')),
                                                if (currentKey ==
                                                    'backorder_asc') ...[
                                                  const Spacer(),
                                                  const Icon(Icons.check,
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
                    Row(
                      children: [
                        DynamicSearchBar(
                          width: size.width * 0.8,
                          controller: bloc.searchPickController,
                          hintText: "Buscar pick",
                          // watchdog: reabre el teclado si el IME del PDA
                          // (Zebra/Urovo/Chainway) lo cierra solo.
                          persistentKeyboard: true,
                          onSearchChanged: (value) {
                            bloc.add(SearchPickListEvent(value, false));
                          },
                          onSearchCleared: () {
                            bloc.searchPickController.clear();
                            bloc.add(SearchPickListEvent('', false));
                            Future.delayed(const Duration(milliseconds: 100),
                                () {
                              FocusScope.of(context)
                                  .requestFocus(focusNodeBuscar);
                            });
                          },
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (_isProcessing ||
                                context.read<PickingListBloc>().state
                                    is PickingListLoading) {
                              return;
                            }

                            setState(() => _isProcessing = true);

                            try {
                              FocusScope.of(context).unfocus();
                              var pickedDate =
                                  await DatePicker.showSimpleDatePicker(
                                titleText: 'Seleccione una fecha',
                                context,
                                confirmText: 'Buscar',
                                cancelText: 'Cancelar',
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 30)),
                                lastDate: DateTime.now(),
                                dateFormat: "dd-MMMM-yyyy",
                                locale: DateTimePickerLocale.es,
                                looping: false,
                              );

                              if (pickedDate != null) {
                                final formattedDate = DateFormat('yyyy-MM-dd')
                                    .format(pickedDate);
                                context.read<PickingListBloc>().add(
                                      LoadPickHistoryEvent(true, formattedDate),
                                    );
                                Navigator.pushReplacementNamed(
                                    context, 'pick-done',
                                    arguments: [true]);
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isProcessing = false);
                              }
                            }
                          },
                          child: const Card(
                            elevation: 3,
                            color: white,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
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
                    BarcodeScannerField(
                      controller: _controllerToDo,
                      focusNode: focusNodeBuscar,
                      onBarcodeScanned: (value, context) {
                        return validateBarcode(value, context);
                      },
                    ),
                    Expanded(
                      child: bloc.listOfPickFiltered
                              .where((batch) => batch.isSeparate == 0)
                              .isNotEmpty
                          ? ListView.builder(
                              padding: EdgeInsets.only(
                                  top: 10, bottom: size.height * 0.15),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: listToShow.length,
                              itemBuilder: (contextBuilder, index) {
                                final batch = listToShow[index];
                                //convertimos la fecha

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: GestureDetector(
                                    onTap: () => _handleTap(
                                        context, contextBuilder, batch),
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
                                            if (batch.observacion != null &&
                                                batch.observacion!
                                                    .isNotEmpty) ...[
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text("Observación: ",
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            primaryColorApp)),
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
                                                      color:
                                                          batch.priority == '0'
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
                                                          color:
                                                              primaryColorApp),
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
                                                  Text(
                                                      batch.backorderName ?? '',
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
                                                          color:
                                                              primaryColorApp),
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
                                                          color:
                                                              primaryColorApp),
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
            ),
          );
        },
      ),
    );
  }
}
