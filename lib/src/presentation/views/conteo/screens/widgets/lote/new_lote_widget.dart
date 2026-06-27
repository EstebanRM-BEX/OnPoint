// ignore_for_file: use_build_context_synchronously, unrelated_type_equality_checks

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
import 'package:wms_app/src/presentation/views/conteo/models/conteo_response_model.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/bloc/conteo_bloc.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/response_lotes_product_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/new_lote_widget.dart';

import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_advertencia_lote_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:intl/intl.dart'; // Importamos el paquete intl

class NewLoteOrdenScreen extends StatefulWidget {
  const NewLoteOrdenScreen({super.key, this.currentProduct});

  final CountedLine? currentProduct;

  @override
  State<NewLoteOrdenScreen> createState() => _NewLoteScreenState();
}

class _NewLoteScreenState extends State<NewLoteOrdenScreen> {
  bool viewList = true;
  DateTime? selectedDate;
  int? selectedIndex;
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _loteFocusNode = FocusNode();

  List<LotesProduct> _allLotes = [];
  List<LotesProduct> _filteredLotes = [];
  int? _suggestedLoteId;

  @override
  void initState() {
    super.initState();
    viewList = true;
    _initLotes();
  }

  void _initLotes() {
    final bloc = context.read<ConteoBloc>();
    _suggestedLoteId = bloc.currentProduct.lotId;

    var lotes = List<LotesProduct>.from(bloc.listLotesProduct);

    // Mueve el lote sugerido al índice 0
    if (_suggestedLoteId != null && _suggestedLoteId != 0) {
      final idx = lotes.indexWhere((l) => l.id == _suggestedLoteId);
      if (idx != -1) {
        final suggested = lotes.removeAt(idx);
        lotes.insert(0, suggested);
      }
    }

    _allLotes = lotes;
    _filteredLotes = List.from(_allLotes);
  }

  void _filterLotes(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _filteredLotes = q.isEmpty
          ? List.from(_allLotes)
          : _allLotes
                .where((l) => (l.name ?? '').toLowerCase().contains(q))
                .toList();
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _loteFocusNode.dispose();
    super.dispose();
  }

  // Función para mostrar el selector de fecha y hora

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: primaryColorApp,
        body: BlocBuilder<ConteoBloc, ConteoState>(
          builder: (context, state) {
            final bloc = context.read<ConteoBloc>();
            return SafeArea(
              child: Container(
                color: Colors.white,
                width: size.width * 1,
                height: size.height * 1,
                child: Column(
                  children: [
                    BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
                      builder: (context, connectionStatus) {
                        return BlocConsumer<ConteoBloc, ConteoState>(
                          listener: (context, state) {
                            debugPrint('STATE ❤️‍🔥 $state');

                            if (state is CreateLoteProductSuccess) {
                              Navigator.pop(context);
                              Navigator.pushReplacementNamed(
                                context,
                                'scan-product-conteo',
                              );
                            }

                            if (state is CreateLoteProductLoading) {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return const DialogLoading(
                                    message:
                                        "Creando lote espere un momento...",
                                  );
                                },
                              );
                            }

                            if (state is CreateLoteProductFailure) {
                              Navigator.pop(context);
                              if (state.code == 400) {
                                showScrollableErrorDialog(state.error);
                              } else if (state.code == 202 &&
                                  (context
                                              .read<ConteoBloc>()
                                              .configurations
                                              .result
                                              ?.result
                                              ?.allowPriorExpirationDate ==
                                          true ||
                                      context
                                              .read<ConteoBloc>()
                                              .configurations
                                              .result
                                              ?.result
                                              ?.allowPriorExpirationDate ==
                                          1)) {
                                showScrollableWarningLoteDialog(
                                  state.error,
                                  onContinue: () {
                                    //creamos el lote sin prioridad de caducidadz
                                    bloc.add(
                                      CreateLoteProduct(
                                        bloc.newLoteController.text,
                                        bloc.dateLoteController.text,
                                        true,
                                      ),
                                    );
                                  },
                                );
                              } else {
                                showScrollableErrorDialog(state.error);
                              }
                            }
                          },
                          builder: (context, state) {
                            return Container(
                              decoration: BoxDecoration(
                                color: primaryColorApp,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              width: double.infinity,
                              child: Column(
                                children: [
                                  const WarningWidgetCubit(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.arrow_back,
                                          color: white,
                                        ),
                                        onPressed: () {
                                          Navigator.pushReplacementNamed(
                                            context,
                                            'scan-product-conteo',
                                          );
                                        },
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: size.width * 0.2,
                                        ),
                                        child: const Text(
                                          'CREAR LOTE',
                                          style: TextStyle(
                                            color: white,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 10),
                    Text(
                      widget.currentProduct?.productName ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: black),
                    ),

                    //184170

                    //todo barra buscar
                    Visibility(
                      visible: viewList,
                      child: DynamicSearchBar(
                        controller: context
                            .read<ConteoBloc>()
                            .searchControllerLote,
                        focusNode: _searchFocusNode,
                        hintText: "Buscar lote",
                        persistentKeyboard: true,
                        onKeyboardEvent: (event) {
                          FirebaseCrashlytics.instance
                              .log('[NewLoteOrden] $event');
                        },
                        onSearchChanged: _filterLotes,
                        onSearchCleared: () {
                          _filterLotes('');
                        },
                      ),
                    ),

                    const SizedBox(height: 10),
                    if (viewList)
                      Expanded(
                        child: ListView.builder(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.manual,
                          itemCount: _filteredLotes.length,
                          itemBuilder: (context, index) {
                            final loteData = _filteredLotes[index];
                            final bool isSelected = selectedIndex == index;
                            final bool isSuggested =
                                _suggestedLoteId != null &&
                                _suggestedLoteId != 0 &&
                                loteData.id == _suggestedLoteId;
                            final rawDate = loteData.expirationDate;
                            bool isExpired = false;
                            int? daysLeft;

                            if (rawDate != null &&
                                rawDate != false &&
                                rawDate.toString().isNotEmpty) {
                              final expiration = DateTime.tryParse(
                                rawDate.toString(),
                              );
                              if (expiration != null) {
                                final now = DateTime.now();
                                final dateExpiration = DateTime(
                                  expiration.year,
                                  expiration.month,
                                  expiration.day,
                                );
                                final dateNow = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                );
                                final difference = dateExpiration
                                    .difference(dateNow)
                                    .inDays;
                                if (difference < 0) {
                                  isExpired = true;
                                } else {
                                  daysLeft = difference;
                                }
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 0,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  _searchFocusNode.unfocus();
                                  setState(() {
                                    selectedIndex = isSelected ? null : index;
                                  });
                                },
                                child: Card(
                                  elevation: 3,
                                  color: isSelected
                                      ? Colors.green[100]
                                      : Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Nombre + badge Sugerido
                                        Row(
                                          children: [
                                            Text(
                                              'Lote: ${loteData.name}',
                                              style: TextStyle(
                                                color: primaryColorApp,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (isSuggested) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[50],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color:
                                                        Colors.green.shade300,
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Sugerido',
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (rawDate != null &&
                                            rawDate != '') ...[
                                          Row(
                                            children: [
                                              const Text(
                                                'Fecha de caducidad: ',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                '${rawDate == false ? 'Sin fecha' : rawDate}',
                                                style: TextStyle(
                                                  color:
                                                      (rawDate == false ||
                                                          isExpired)
                                                      ? Colors.red
                                                      : Colors.black,
                                                  fontSize: 12,
                                                  fontWeight: isExpired
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        // CASO 1: LOTE VENCIDO
                                        if (isExpired) ...[
                                          const SizedBox(height: 5),
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.red.shade200,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Colors.red,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 5),
                                                Text(
                                                  '¡LOTE VENCIDO!',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ]
                                        // CASO 2: POR VENCER
                                        else if (daysLeft != null) ...[
                                          const SizedBox(height: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: daysLeft < 15
                                                  ? Colors.orange[50]
                                                  : Colors.blue[50],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: daysLeft < 15
                                                    ? Colors.orange.shade300
                                                    : Colors.blue.shade200,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.av_timer,
                                                  color: daysLeft < 15
                                                      ? Colors.orange[800]
                                                      : Colors.blue[700],
                                                  size: 16,
                                                ),
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
                        ),
                      ),
                    //todo crear lote
                    Visibility(
                      visible: !viewList,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),

                            // ---------------------------------------------------------
                            // 1. CAMPO: NOMBRE DEL LOTE (Mayúsculas y Sin Espacios)
                            // ---------------------------------------------------------
                            if (bloc
                                    .configurations
                                    .result
                                    ?.result
                                    ?.manageExpirationDateWithoutLot ==
                                false)
                              SizedBox(
                                height: 40,
                                child: TextFormField(
                                  focusNode: _loteFocusNode,
                                  autofocus: true,
                                  controller: bloc.newLoteController,
                                  style: TextStyle(color: black, fontSize: 14),

                                  // UX: Abre el teclado en mayúsculas
                                  textCapitalization:
                                      TextCapitalization.characters,

                                  // LÓGICA: Fuerza mayúsculas y bloquea espacio
                                  inputFormatters: [
                                    UpperCaseTextFormatter(), // Clase auxiliar (ver abajo)
                                    FilteringTextInputFormatter.deny(
                                      RegExp(r'\s'),
                                    ),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Nombre del lote',
                                    labelStyle: TextStyle(
                                      color: primaryColorApp,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        bloc.newLoteController.clear();
                                        FocusScope.of(context).unfocus();
                                      },
                                      icon: const Icon(
                                        Icons.close,
                                        color: grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 10),

                            // ---------------------------------------------------------
                            // 2. CAMPO: FECHA DE CADUCIDAD
                            // ---------------------------------------------------------
                            Visibility(
                              visible:
                                  bloc.currentProduct.useExpirationDate ==
                                      true ||
                                  bloc.currentProduct.useExpirationDate == 1,
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 40,
                                    child: TextFormField(
                                      style: TextStyle(
                                        color: black,
                                        fontSize: 14,
                                      ),
                                      controller: bloc.dateLoteController,
                                      readOnly:
                                          true, // Para evitar escritura manual
                                      decoration: InputDecoration(
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            bloc.dateLoteController.clear();
                                            // Limpiamos la fecha seleccionada y actualizamos UI
                                            setState(() {
                                              selectedDate = null;
                                            });
                                            FocusScope.of(context).unfocus();
                                          },
                                          icon: const Icon(
                                            Icons.close,
                                            color: grey,
                                          ),
                                        ),
                                        labelText: 'Fecha de caducidad',
                                        labelStyle: TextStyle(
                                          color: primaryColorApp,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      onTap: () async {
                                        FocusScope.of(context).unfocus();

                                        // Tu selector de fecha actual
                                        var pickedDate =
                                            await DatePicker.showSimpleDatePicker(
                                              titleText: 'Seleccione una fecha',
                                              context,
                                              confirmText: 'Seleccionar',
                                              cancelText: 'Cancelar',
                                              firstDate: DateTime.now()
                                                  .subtract(
                                                    const Duration(days: 30),
                                                  ),
                                              lastDate: DateTime.now().add(
                                                const Duration(days: 2000),
                                              ),
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
                                          final formattedDate = DateFormat(
                                            'yyyy-MM-dd HH:mm:ss',
                                          ).format(pickedDate);

                                          // ✅ Actualizamos el estado para mostrar los días restantes
                                          setState(() {
                                            selectedDate = pickedDate;
                                            bloc.dateLoteController.text =
                                                formattedDate;
                                          });
                                        }
                                      },
                                    ),
                                  ),

                                  // ---------------------------------------------------------
                                  // 3. INDICADOR VISUAL: DÍAS POR VENCER
                                  // ---------------------------------------------------------
                                  if (selectedDate != null) ...[
                                    const SizedBox(height: 10),
                                    Builder(
                                      builder: (context) {
                                        // A. Cálculos (Normalizando fecha para ignorar horas)
                                        final now = DateTime.now();
                                        final dateExpiration = DateTime(
                                          selectedDate!.year,
                                          selectedDate!.month,
                                          selectedDate!.day,
                                        );
                                        final dateNow = DateTime(
                                          now.year,
                                          now.month,
                                          now.day,
                                        );

                                        final daysLeft = dateExpiration
                                            .difference(dateNow)
                                            .inDays;

                                        // B. Definición de estilos según urgencia
                                        Color bgColor;
                                        Color textColor;
                                        IconData icon;
                                        String text;

                                        if (daysLeft < 0) {
                                          // CASO: Vencido
                                          bgColor = Colors.red[50]!;
                                          textColor = Colors.red;
                                          icon = Icons.warning_amber_rounded;
                                          text =
                                              "La fecha ingresada venció hace ${daysLeft.abs()} días";
                                        } else if (daysLeft < 15) {
                                          // CASO: Alerta (menos de 15 días)
                                          bgColor = Colors.orange[50]!;
                                          textColor = Colors.orange[900]!;
                                          icon = Icons.warning_amber_rounded;
                                          text = daysLeft == 0
                                              ? "La fecha ingresada vence hoy"
                                              : "La fecha ingresada vence en $daysLeft días";
                                        } else {
                                          // CASO: Seguro
                                          bgColor = Colors.blue[50]!;
                                          textColor = Colors.blue[900]!;
                                          icon = Icons.check_circle_outline;
                                          text =
                                              "La fecha ingresada vence en $daysLeft días";
                                        }

                                        // C. Widget Visual
                                        return Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: bgColor,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: textColor.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                icon,
                                                color: textColor,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                text,
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Visibility(
                      visible: selectedIndex != null && viewList,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            final selectedLote = _filteredLotes[selectedIndex!];
                            final isSuggested =
                                _suggestedLoteId != null &&
                                _suggestedLoteId != 0 &&
                                selectedLote.id == _suggestedLoteId;

                            void confirmSelection() {
                              context.read<ConteoBloc>().add(
                                SelectecLoteEvent(selectedLote),
                              );
                              Navigator.pushReplacementNamed(
                                context,
                                'scan-product-conteo',
                              );
                              Get.snackbar(
                                'Lote Seleccionado',
                                'Has seleccionado el lote: ${selectedLote.name}',
                                backgroundColor: white,
                                colorText: primaryColorApp,
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                ),
                              );
                            }

                            if (isSuggested) {
                              confirmSelection();
                            } else {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  title: const Text(
                                    '360 Software Informa',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  content: Text(
                                    'El lote seleccionado (${selectedLote.name}) es diferente al lote sugerido.\n¿Desea continuar con este lote?',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        confirmSelection();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColorApp,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Continuar',
                                        style: TextStyle(color: white),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColorApp,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Seleccionar lote',
                            style: TextStyle(color: white),
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: MediaQuery.viewInsetsOf(context).bottom == 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              context
                                  .read<ConteoBloc>()
                                  .newLoteController
                                  .clear();
                              context
                                  .read<ConteoBloc>()
                                  .dateLoteController
                                  .clear();
                              setState(() {
                                viewList = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'CANCELAR',
                              style: TextStyle(color: white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Visibility(
                            visible: viewList,
                            child: ElevatedButton(
                              onPressed: () {
                                //todo reglas de la creacion lote automatico
                                // Que el producto no maneje fecha de vencimiento "use_expiration_date": false,
                                // y el permiso de crear lote sin nombre este activado   "manage_expiration_date_without_lot": true,

                                if ((widget.currentProduct?.useExpirationDate ==
                                            false ||
                                        widget.currentProduct
                                                ?.useExpirationDate ==
                                            0) &&
                                    (bloc.configurations.result?.result
                                            ?.manageExpirationDateWithoutLot ==
                                        true)) {
                                  final nombreLote = DateFormat('ddMMyyyyHHmmss')
                                      .format(DateTime.now());

                                  showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: Colors.white,
                                      title: const Text(
                                        '360 Software Informa',
                                        style: TextStyle(
                                            color: Colors.orange, fontSize: 16),
                                        textAlign: TextAlign.center,
                                      ),
                                      content: Text(
                                        'Se creará el lote "$nombreLote" sin fecha de vencimiento.\n¿Desea continuar?',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColorApp,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('Crear lote',
                                              style: TextStyle(color: white)),
                                        ),
                                      ],
                                    ),
                                  ).then((confirmed) {
                                    if (confirmed == true && mounted) {
                                      bloc.newLoteController.text = nombreLote;
                                      bloc.add(CreateLoteProduct(
                                          nombreLote, '', false));
                                    }
                                  });

                                  return; // no abre el formulario manual
                                }

                                //ocultamos la lista de lotes (formulario manual)
                                setState(() {
                                  viewList = false;
                                });

                                // Foco automático al campo nombre si está visible
                                if (bloc.configurations.result?.result
                                        ?.manageExpirationDateWithoutLot ==
                                    false) {
                                  Future.delayed(
                                      const Duration(milliseconds: 100), () {
                                    if (mounted) _loteFocusNode.requestFocus();
                                  });
                                }

                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColorApp,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'CREAR LOTE',
                                style: TextStyle(color: white),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: !viewList,
                            child: ElevatedButton(
                              onPressed: () {
                                final conteoBloc = context.read<ConteoBloc>();
                                final nombreLote =
                                    conteoBloc.newLoteController.text.trim();
                                final fechaLote =
                                    conteoBloc.dateLoteController.text.trim();
                                final requiresExpiration =
                                    conteoBloc.currentProduct.useExpirationDate ==
                                            true ||
                                        conteoBloc.currentProduct
                                                .useExpirationDate ==
                                            1;
                                final manageWithoutLot = conteoBloc
                                    .configurations
                                    .result
                                    ?.result
                                    ?.manageExpirationDateWithoutLot;

                                // Validar nombre duplicado
                                if (conteoBloc.listLotesProduct
                                    .any((e) => e.name == nombreLote)) {
                                  Get.snackbar(
                                    'Error al crear lote',
                                    'El lote ya existe, por favor ingrese otro nombre',
                                    backgroundColor: white,
                                    colorText: primaryColorApp,
                                    icon: Icon(Icons.error, color: Colors.amber),
                                  );
                                  return;
                                }
                                // Validar fecha vacía si el producto requiere fecha
                                if (requiresExpiration && fechaLote.isEmpty) {
                                  Get.snackbar(
                                    'Error al crear lote',
                                    'La fecha de caducidad no puede estar vacía para este producto',
                                    backgroundColor: white,
                                    colorText: primaryColorApp,
                                    icon: Icon(Icons.error, color: Colors.amber),
                                  );
                                  return;
                                }

                                // Validar o generar nombre del lote
                                String nombreFinal = nombreLote;
                                if (manageWithoutLot == false) {
                                  if (nombreLote.isEmpty) {
                                    Get.snackbar(
                                      'Error al crear lote',
                                      'El nombre del lote no puede estar vacío',
                                      backgroundColor: white,
                                      colorText: primaryColorApp,
                                      icon:
                                          Icon(Icons.error, color: Colors.amber),
                                    );
                                    return;
                                  }
                                } else {
                                  if (selectedDate == null) {
                                    Get.snackbar(
                                      'Error al crear lote',
                                      'Debe seleccionar una fecha de caducidad',
                                      backgroundColor: white,
                                      colorText: primaryColorApp,
                                      icon:
                                          Icon(Icons.error, color: Colors.amber),
                                    );
                                    return;
                                  }
                                  nombreFinal =
                                      DateFormat('ddMMyyyyHHmmss').format(
                                    DateTime(
                                      selectedDate!.year,
                                      selectedDate!.month,
                                      selectedDate!.day,
                                      DateTime.now().hour,
                                      DateTime.now().minute,
                                      DateTime.now().second,
                                    ),
                                  );
                                  conteoBloc.newLoteController.text = nombreFinal;
                                }

                                // Validar que la fecha no sea pasada o igual a hoy
                                if (selectedDate != null) {
                                  final now = DateTime.now();
                                  final soloFechaSeleccionada = DateTime(
                                      selectedDate!.year,
                                      selectedDate!.month,
                                      selectedDate!.day);
                                  final soloHoy =
                                      DateTime(now.year, now.month, now.day);

                                  if (soloFechaSeleccionada
                                          .isBefore(soloHoy) ||
                                      soloFechaSeleccionada
                                          .isAtSameMomentAs(soloHoy)) {
                                    Get.snackbar(
                                      'Error al crear lote',
                                      'La fecha de caducidad debe ser mayor a la fecha actual.',
                                      backgroundColor: white,
                                      duration: const Duration(seconds: 4),
                                      colorText: primaryColorApp,
                                      icon:
                                          Icon(Icons.error, color: Colors.amber),
                                    );
                                    return;
                                  }
                                }

                                // Todas las validaciones pasaron — mostrar confirmación
                                final nombreParaCrear = nombreFinal;
                                final fechaParaCrear = fechaLote;

                                showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: Colors.white,
                                    title: const Text(
                                      '360 Software Informa',
                                      style: TextStyle(
                                          color: Colors.orange, fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                    content: Text(
                                      '¿Está seguro que desea crear el lote "$nombreParaCrear"?',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(ctx, true);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColorApp,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text('Crear lote',
                                            style: TextStyle(color: white)),
                                      ),
                                    ],
                                  ),
                                ).then((confirmed) {
                                  if (confirmed == true && mounted) {
                                    context.read<ConteoBloc>().add(
                                          CreateLoteProduct(
                                              nombreParaCrear, fechaParaCrear, false),
                                        );
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColorApp,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'AGREGAR LOTE',
                                style: TextStyle(color: white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
