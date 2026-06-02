// ignore_for_file: use_build_context_synchronously, unrelated_type_equality_checks

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_holo_date_picker/date_picker.dart';
import 'package:flutter_holo_date_picker/i18n/date_picker_i18n.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_products_model.dart';
import 'package:wms_app/src/presentation/views/inventario/screens/bloc/inventario_bloc.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/new_lote_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_advertencia_lote_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:intl/intl.dart';

class NewLoteInventarioScreen extends StatefulWidget {
  const NewLoteInventarioScreen({super.key, this.currentProduct});

  final Product? currentProduct;

  @override
  State<NewLoteInventarioScreen> createState() => _NewLoteScreenState();
}

class _NewLoteScreenState extends State<NewLoteInventarioScreen> {
  bool viewList = true;
  DateTime? selectedDate;
  int? selectedIndex;

  // FocusNode persistente — sobrevive todos los rebuilds del árbol
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    viewList = true;
    // Abre el teclado automáticamente al entrar a la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // bloc leído una sola vez — sin BlocBuilder externo que envuelva toda la pantalla
    final bloc = context.read<InventarioBloc>();

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: primaryColorApp,
        // BlocListener separado para los estados de creación de lote
        body: BlocListener<InventarioBloc, InventarioState>(
          listenWhen: (_, curr) =>
              curr is CreateLoteProductLoading ||
              curr is CreateLoteProductSuccess ||
              curr is CreateLoteProductFailure,
          listener: (context, state) {
            debugPrint('STATE ❤️‍🔥 $state');

            if (state is CreateLoteProductLoading) {
              showDialog(
                context: context,
                builder: (_) => const DialogLoading(
                    message: "Creando lote espere un momento..."),
              );
            } else if (state is CreateLoteProductSuccess) {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, 'inventario');
            } else if (state is CreateLoteProductFailure) {
              Navigator.pop(context);
              if (state.code == 400) {
                showScrollableErrorDialog(state.error);
              } else if (state.code == 202 &&
                  (bloc.configurations.result?.result
                              ?.allowPriorExpirationDate ==
                          true ||
                      bloc.configurations.result?.result
                              ?.allowPriorExpirationDate ==
                          1)) {
                showScrollableWarningLoteDialog(state.error, onContinue: () {
                  bloc.add(CreateLoteProduct(
                      bloc.newLoteController.text,
                      bloc.dateLoteController.text,
                      true));
                });
              } else {
                showScrollableErrorDialog(state.error);
              }
            }
          },
          child: SafeArea(
            child: Container(
              color: white,
              width: size.width,
              height: size.height,
              child: Column(
                children: [
                  // AppBar — solo escucha ConnectionStatusCubit, no InventarioBloc
                  _AppBarInfo(size: size),

                  const SizedBox(height: 10),
                  Text(
                    widget.currentProduct?.name ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: black),
                  ),

                  // Barra de búsqueda — fuera de cualquier BlocBuilder
                  Visibility(
                    visible: viewList,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 10, right: 10, top: 5),
                      child: SizedBox(
                        height: 55,
                        width: size.width,
                        child: Card(
                          color: Colors.white,
                          elevation: 3,
                          child: TextFormField(
                            focusNode: _searchFocusNode,
                            style:
                                TextStyle(color: black, fontSize: 14),
                            textAlignVertical: TextAlignVertical.center,
                            controller: bloc.searchControllerLote,
                            showCursor: true,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search,
                                  color: grey, size: 20),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  bloc.searchControllerLote.clear();
                                  bloc.add(SearchLotevent(''));
                                  // Mantiene el foco en vez de cerrar el teclado
                                  _searchFocusNode.requestFocus();
                                },
                                icon: const Icon(Icons.close,
                                    color: grey, size: 20),
                              ),
                              disabledBorder:
                                  const OutlineInputBorder(),
                              hintText: "Buscar lote",
                              hintStyle: const TextStyle(
                                  color: Colors.grey, fontSize: 14),
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              // Debounce: evita disparar evento en cada tecla
                              if (_debounce?.isActive ?? false) {
                                _debounce!.cancel();
                              }
                              _debounce = Timer(
                                  const Duration(milliseconds: 300),
                                  () => bloc.add(SearchLotevent(value)));
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Lista de lotes — BlocBuilder acotado solo a estados de búsqueda
                  if (viewList)
                    Expanded(
                      child: BlocBuilder<InventarioBloc, InventarioState>(
                        buildWhen: (_, curr) =>
                            curr is SearchLoteSuccess ||
                            curr is SearchLoading ||
                            curr is SearchFailure ||
                            curr is GetLotesProductSuccess,
                        builder: (context, state) {
                          return _buildLoteList(bloc);
                        },
                      ),
                    ),

                  // Formulario crear lote — visible cuando viewList == false
                  if (!viewList) _buildCreateForm(bloc, size),

                  // Botón seleccionar lote
                  Visibility(
                    visible: selectedIndex != null && viewList,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedIndex == null) return;
                          final selectedLote =
                              bloc.listLotesProductFilters[selectedIndex!];
                          bloc.add(SelectecLoteEvent(selectedLote));
                          Navigator.pushReplacementNamed(
                              context, 'inventario');
                          Get.snackbar(
                            'Lote Seleccionado',
                            'Has seleccionado el lote: ${selectedLote.name}',
                            backgroundColor: white,
                            colorText: primaryColorApp,
                            icon: const Icon(Icons.check,
                                color: Colors.green),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColorApp,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Seleccionar lote',
                            style: TextStyle(color: white)),
                      ),
                    ),
                  ),

                  // Botones CANCELAR / CREAR LOTE / AGREGAR LOTE
                  // BlocBuilder acotado solo a ShowKeyboardState
                  BlocBuilder<InventarioBloc, InventarioState>(
                    buildWhen: (_, curr) => curr is ShowKeyboardState,
                    builder: (context, state) {
                      return Visibility(
                        visible: !bloc.isKeyboardVisible,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                bloc.newLoteController.clear();
                                bloc.dateLoteController.clear();
                                setState(() => viewList = true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: grey,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10)),
                              ),
                              child: const Text('CANCELAR',
                                  style: TextStyle(color: white)),
                            ),
                            const SizedBox(width: 10),
                            if (viewList)
                              ElevatedButton(
                                onPressed: () => _onCrearLote(bloc),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColorApp,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                                child: const Text('CREAR LOTE',
                                    style: TextStyle(color: white)),
                              ),
                            if (!viewList)
                              ElevatedButton(
                                onPressed: () =>
                                    _onAgregarLote(bloc),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColorApp,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                                child: const Text('AGREGAR LOTE',
                                    style: TextStyle(color: white)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 5),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Lista de lotes ───────────────────────────────────────────────
  Widget _buildLoteList(InventarioBloc bloc) {
    return ListView.builder(
      itemCount: bloc.listLotesProductFilters.length,
      itemBuilder: (context, index) {
        final lote = bloc.listLotesProductFilters[index];
        final bool isSelected = selectedIndex == index;
        final rawDate = lote.expirationDate;
        bool isExpired = false;
        int? daysLeft;

        if (rawDate != null &&
            rawDate != false &&
            rawDate.toString().isNotEmpty) {
          final expiration = DateTime.tryParse(rawDate.toString());
          if (expiration != null) {
            final now = DateTime.now();
            final dateExpiration = DateTime(
                expiration.year, expiration.month, expiration.day);
            final dateNow = DateTime(now.year, now.month, now.day);
            final difference =
                dateExpiration.difference(dateNow).inDays;
            if (difference < 0) {
              isExpired = true;
            } else {
              daysLeft = difference;
            }
          }
        }

        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          child: GestureDetector(
            onTap: () => setState(
                () => selectedIndex = isSelected ? null : index),
            child: Card(
              elevation: 3,
              color: isSelected ? Colors.green[100] : Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lote: ${lote.name}',
                        style: TextStyle(
                            color: primaryColorApp, fontSize: 12)),
                    if (lote.expirationDate != '') ...[
                      Row(children: [
                        const Text('Fecha de caducidad: ',
                            style: TextStyle(
                                color: Colors.black, fontSize: 12)),
                        Text(
                          '${rawDate == false ? 'Sin fecha' : rawDate}',
                          style: TextStyle(
                            color: (rawDate == false || isExpired)
                                ? Colors.red
                                : Colors.black,
                            fontSize: 12,
                            fontWeight: isExpired
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ]),
                    ],
                    if (isExpired) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.red, size: 16),
                            SizedBox(width: 5),
                            Text('¡LOTE VENCIDO!',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ] else if (daysLeft != null) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: daysLeft < 15
                              ? Colors.orange[50]
                              : Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: daysLeft < 15
                                  ? Colors.orange.shade300
                                  : Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.av_timer,
                                color: daysLeft < 15
                                    ? Colors.orange[800]
                                    : Colors.blue[700],
                                size: 16),
                            const SizedBox(width: 5),
                            Text(
                              daysLeft == 0
                                  ? 'Vence hoy'
                                  : 'Vence en $daysLeft días',
                              style: TextStyle(
                                color: daysLeft < 15
                                    ? Colors.orange[900]
                                    : Colors.blue[900],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Formulario de creación manual ───────────────────────────────
  Widget _buildCreateForm(InventarioBloc bloc, Size size) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          if (bloc.configurations.result?.result
                  ?.manageExpirationDateWithoutLot ==
              false)
            SizedBox(
              height: 40,
              child: TextFormField(
                controller: bloc.newLoteController,
                style: TextStyle(color: black, fontSize: 14),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                decoration: InputDecoration(
                  labelText: 'Nombre del lote',
                  labelStyle: TextStyle(color: primaryColorApp),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    onPressed: () {
                      bloc.newLoteController.clear();
                      FocusScope.of(context).unfocus();
                    },
                    icon: const Icon(Icons.close, color: grey),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Visibility(
            visible:
                bloc.currentProduct?.useExpirationDate == true ||
                    bloc.currentProduct?.useExpirationDate == 1,
            child: Column(
              children: [
                SizedBox(
                  height: 40,
                  child: TextFormField(
                    style: TextStyle(color: black, fontSize: 14),
                    controller: bloc.dateLoteController,
                    readOnly: true,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: () {
                          bloc.dateLoteController.clear();
                          setState(() => selectedDate = null);
                          FocusScope.of(context).unfocus();
                        },
                        icon:
                            const Icon(Icons.close, color: grey),
                      ),
                      labelText: 'Fecha de caducidad',
                      labelStyle:
                          TextStyle(color: primaryColorApp),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      var pickedDate =
                          await DatePicker.showSimpleDatePicker(
                        context,
                        titleText: 'Seleccione una fecha',
                        confirmText: 'Seleccionar',
                        cancelText: 'Cancelar',
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 30)),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 2000)),
                        dateFormat: "dd-MMMM-yyyy",
                        locale: DateTimePickerLocale.es,
                        looping: false,
                      );
                      if (pickedDate != null) {
                        final now = DateTime.now();
                        pickedDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          now.hour,
                          now.minute,
                          now.second,
                        );
                        final formattedDate =
                            DateFormat('yyyy-MM-dd HH:mm:ss')
                                .format(pickedDate);
                        setState(() {
                          selectedDate = pickedDate;
                          bloc.dateLoteController.text =
                              formattedDate;
                        });
                      }
                    },
                  ),
                ),
                if (selectedDate != null) ...[
                  const SizedBox(height: 10),
                  Builder(builder: (context) {
                    final now = DateTime.now();
                    final dateExpiration = DateTime(selectedDate!.year,
                        selectedDate!.month, selectedDate!.day);
                    final dateNow =
                        DateTime(now.year, now.month, now.day);
                    final daysLeft =
                        dateExpiration.difference(dateNow).inDays;

                    Color bgColor;
                    Color textColor;
                    IconData icon;
                    String text;

                    if (daysLeft < 0) {
                      bgColor = Colors.red[50]!;
                      textColor = Colors.red;
                      icon = Icons.warning_amber_rounded;
                      text =
                          'La fecha ingresada venció hace ${daysLeft.abs()} días';
                    } else if (daysLeft < 15) {
                      bgColor = Colors.orange[50]!;
                      textColor = Colors.orange[900]!;
                      icon = Icons.warning_amber_rounded;
                      text = daysLeft == 0
                          ? 'La fecha ingresada vence hoy'
                          : 'La fecha ingresada vence en $daysLeft días';
                    } else {
                      bgColor = Colors.blue[50]!;
                      textColor = Colors.blue[900]!;
                      icon = Icons.check_circle_outline;
                      text =
                          'La fecha ingresada vence en $daysLeft días';
                    }

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: textColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: textColor, size: 18),
                          const SizedBox(width: 8),
                          Text(text,
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Lógica del botón CREAR LOTE ─────────────────────────────────
  void _onCrearLote(InventarioBloc bloc) {
    if ((widget.currentProduct?.useExpirationDate == false ||
            widget.currentProduct?.useExpirationDate == 0) &&
        (bloc.configurations.result?.result
                ?.manageExpirationDateWithoutLot ==
            true)) {
      bloc.newLoteController.text =
          DateFormat('ddMMyyyyHHmmss').format(DateTime.now());
      bloc.add(CreateLoteProduct(
          bloc.newLoteController.text, '', false));
    }
    setState(() => viewList = false);
  }

  // ─── Lógica del botón AGREGAR LOTE ───────────────────────────────
  void _onAgregarLote(InventarioBloc bloc) {
    if (bloc.listLotesProduct
        .any((e) => e.name == bloc.newLoteController.text)) {
      Get.snackbar('Error al crear lote',
          'El lote ya existe, por favor ingrese otro nombre',
          backgroundColor: white,
          colorText: primaryColorApp,
          icon: const Icon(Icons.error, color: Colors.amber));
      return;
    }

    if ((bloc.currentProduct?.useExpirationDate == true ||
            bloc.currentProduct?.useExpirationDate == 1) &&
        bloc.dateLoteController.text.isEmpty) {
      Get.snackbar('Error al crear lote',
          'La fecha de caducidad no puede estar vacía para este producto',
          backgroundColor: white,
          colorText: primaryColorApp,
          icon: const Icon(Icons.error, color: Colors.amber));
      return;
    }

    if (bloc.configurations.result?.result
            ?.manageExpirationDateWithoutLot ==
        false) {
      if (bloc.newLoteController.text.isEmpty) {
        Get.snackbar('Error al crear lote',
            'El nombre del lote no puede estar vacío',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.error, color: Colors.amber));
        return;
      }
    } else {
      if (selectedDate == null) {
        Get.snackbar('Error al crear lote',
            'Debe seleccionar una fecha de caducidad',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.error, color: Colors.amber));
        return;
      }
      bloc.newLoteController.text =
          DateFormat('ddMMyyyyHHmmss').format(DateTime(
              selectedDate!.year,
              selectedDate!.month,
              selectedDate!.day,
              DateTime.now().hour,
              DateTime.now().minute,
              DateTime.now().second));
    }

    if (selectedDate != null) {
      final now = DateTime.now();
      final soloFecha = DateTime(selectedDate!.year,
          selectedDate!.month, selectedDate!.day);
      final soloHoy = DateTime(now.year, now.month, now.day);
      if (soloFecha.isBefore(soloHoy) ||
          soloFecha.isAtSameMomentAs(soloHoy)) {
        Get.snackbar('Error al crear lote',
            'La fecha de caducidad debe ser mayor a la fecha actual.\nRevise la fecha de caducidad real del producto e intente de nuevo',
            backgroundColor: white,
            duration: const Duration(seconds: 4),
            colorText: primaryColorApp,
            icon: const Icon(Icons.error, color: Colors.amber));
        return;
      }
    }

    bloc.add(CreateLoteProduct(
        bloc.newLoteController.text,
        bloc.dateLoteController.text,
        false));
  }
}

// ─── AppBar ───────────────────────────────────────────────────────
class _AppBarInfo extends StatelessWidget {
  const _AppBarInfo({required this.size});
  final Size size;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
      builder: (context, connectionStatus) {
        return Container(
          padding: const EdgeInsets.only(top: 20),
          decoration: const BoxDecoration(
            color: primaryColorApp,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          width: double.infinity,
          child: Column(
            children: [
              const WarningWidgetCubit(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: white),
                    onPressed: () => Navigator.pushReplacementNamed(
                        context, 'inventario'),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.only(left: size.width * 0.2),
                    child: const Text('CREAR LOTE',
                        style:
                            TextStyle(color: white, fontSize: 18)),
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
