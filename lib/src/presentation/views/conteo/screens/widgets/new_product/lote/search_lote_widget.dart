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
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/new_lote_widget.dart';

import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_advertencia_lote_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:intl/intl.dart';

class SearchLoteConteoScreen extends StatefulWidget {
  const SearchLoteConteoScreen({super.key, this.currentProduct});

  final CountedLine? currentProduct;

  @override
  State<SearchLoteConteoScreen> createState() => _NewLoteScreenState();
}

class _NewLoteScreenState extends State<SearchLoteConteoScreen> {
  bool viewList = true;
  DateTime? selectedDate;
  int? selectedIndex;
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _loteFocusNode = FocusNode();
  int? _suggestedLoteId;
  List<dynamic> _sortedLotes = [];

  // true cuando el código llama unfocus() intencionalmente (botón X).
  // Permite distinguir en Crashlytics si el foco se perdió por código o por el sistema.
  bool _intentionalUnfocus = false;

  // ── Analytics + Crashlytics helpers ─────────────────────────────────────

  void _log(String event) {
    FirebaseCrashlytics.instance.log(
      '[SearchLote] $event | viewList:$viewList | hasFocus:${_searchFocusNode.hasFocus}',
    );
  }

  void _logAnalytics(String eventName, {Map<String, Object>? parameters}) {
    FirebaseAnalytics.instance.logEvent(
      name: eventName,
      parameters: {
        'view_list': viewList ? '1' : '0',
        'has_focus': _searchFocusNode.hasFocus ? '1' : '0',
        ...?parameters,
      },
    );
  }

  void _onSearchFocusChanged() {
    if (_searchFocusNode.hasFocus) {
      _intentionalUnfocus = false;
      FirebaseCrashlytics.instance.setCustomKey('lote_has_focus', true);
      _log('focus_gained');
      _logAnalytics('lote_focus_gained');
    } else {
      // "unexpected" = el sistema/Android cerró el teclado sin que el código lo pidiera
      final cause = _intentionalUnfocus ? 'intentional' : 'unexpected';
      _intentionalUnfocus = false;
      FirebaseCrashlytics.instance.setCustomKey('lote_has_focus', false);
      _log('focus_lost:$cause');
      _logAnalytics('lote_focus_lost', parameters: {'cause': cause});
    }
  }

  // ────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    FirebaseCrashlytics.instance.setCustomKey('lote_screen_active', true);
    FirebaseCrashlytics.instance.setCustomKey('lote_view_mode', 'list');
    FirebaseCrashlytics.instance.setCustomKey('lote_has_focus', false);
    _log('screen_init');
    _logAnalytics('lote_screen_open');
    viewList = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _suggestedLoteId = context.read<ConteoBloc>().currentProduct.lotId;
      _log('focus_requested:route_start');
      final route = ModalRoute.of(context);
      if (route?.animation?.isCompleted ?? true) {
        if (viewList) _searchFocusNode.requestFocus();
      } else {
        route!.animation!.addStatusListener(_onRouteAnimationStatus);
      }
    });
  }

  void _onRouteAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      ModalRoute.of(context)
          ?.animation
          ?.removeStatusListener(_onRouteAnimationStatus);
      if (mounted && viewList) {
        _log('focus_requested:route_complete');
        _searchFocusNode.requestFocus();
      }
    }
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    FirebaseCrashlytics.instance.setCustomKey('lote_screen_active', false);
    _log('screen_dispose');
    _searchFocusNode.dispose();
    _loteFocusNode.dispose();
    super.dispose();
  }

  // Función para mostrar el selector de fecha y hora

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bloc = context.read<ConteoBloc>();

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocListener<ConteoBloc, ConteoState>(
        listenWhen: (_, curr) =>
            curr is CreateLoteProductSuccess ||
            curr is CreateLoteProductLoading ||
            curr is CreateLoteProductFailure,
        listener: (context, state) {
          final bloc = context.read<ConteoBloc>();
          debugPrint('STATE ❤️‍🔥 $state');

          if (state is CreateLoteProductSuccess) {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, 'new-product-conteo');
          }

          if (state is CreateLoteProductLoading) {
            showDialog(
              context: context,
              builder: (_) =>
                  const DialogLoading(message: "Creando lote espere un momento..."),
            );
          }

          if (state is CreateLoteProductFailure) {
            Navigator.pop(context);
            if (state.code == 400) {
              showScrollableErrorDialog(state.error);
            } else if (state.code == 202 &&
                (bloc.configurations.result?.result?.allowPriorExpirationDate ==
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
        child: Scaffold(
          backgroundColor: primaryColorApp,
          body: SafeArea(
            child: Container(
              color: white,
              width: size.width,
              height: size.height,
              child: Column(
                children: [
                  BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
                    builder: (context, connectionStatus) {
                      return Container(
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
                                      context, 'new-product-conteo'),
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
                  ),

                    const SizedBox(height: 10),
                    Text(widget.currentProduct?.productName ?? '',
                        style: TextStyle(fontSize: 12, color: black)),

                    //184170

                    //todo barra buscar
                    Visibility(
                      visible: viewList,
                      child: DynamicSearchBar(
                        controller: context.read<ConteoBloc>().searchControllerLote,
                        focusNode: _searchFocusNode,
                        hintText: "Buscar lote",
                        persistentKeyboard: true,
                        onKeyboardEvent: (event) {
                          _log(event);
                          _logAnalytics('lote_$event');
                        },
                        onSearchChanged: (value) {
                          context.read<ConteoBloc>().add(SearchLotevent(value));
                        },
                        onSearchCleared: () {
                          // Marcar antes de que DynamicSearchBar llame unfocus()
                          _intentionalUnfocus = true;
                          _log('clear_button_pressed');
                          _logAnalytics('lote_clear_pressed');
                          context.read<ConteoBloc>().add(SearchLotevent(''));
                        },
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(height: 10),
                    if(viewList)
                    Expanded(
                      child: BlocBuilder<ConteoBloc, ConteoState>(
                        buildWhen: (_, curr) =>
                            curr is SearchLoteSuccess ||
                            curr is SearchFailure ||
                            curr is GetLotesProductSuccess ||
                            curr is GetLotesProductFailure,
                        builder: (context, state) {
                          // Reordenar: sugerido siempre en índice 0
                          final rawList = List.of(
                              context.read<ConteoBloc>().listLotesProductFilters);
                          if (_suggestedLoteId != null && _suggestedLoteId != 0) {
                            final idx = rawList
                                .indexWhere((l) => l.id == _suggestedLoteId);
                            if (idx > 0) {
                              rawList.insert(0, rawList.removeAt(idx));
                            }
                          }
                          // Guardar en estado para que el botón "Seleccionar" use
                          // el mismo orden sin acceder a listLotesProductFilters directamente.
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _sortedLotes = rawList);
                          });
                          return ListView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.manual,
                        itemCount: rawList.length,
                        itemBuilder: (context, index) {
                          bool isSelected = selectedIndex == index;
                          final loteData = rawList[index];
                          final bool isSuggested =
                              _suggestedLoteId != null &&
                              _suggestedLoteId != 0 &&
                              loteData.id == _suggestedLoteId;
                          // 1. Obtener el dato crudo
                          final rawDate = loteData.expirationDate;
                          bool isExpired = false;
                          int?
                              daysLeft; // Variable para guardar los días restantes
                      
                          if (rawDate != null &&
                              rawDate != false &&
                              rawDate.toString().isNotEmpty) {
                            DateTime? expiration =
                                DateTime.tryParse(rawDate.toString());
                      
                            if (expiration != null) {
                              final now = DateTime.now();
                      
                              // Normalizamos las fechas (Solo Año, Mes, Día) para que la hora no afecte
                              final dateExpiration = DateTime(expiration.year,
                                  expiration.month, expiration.day);
                              final dateNow =
                                  DateTime(now.year, now.month, now.day);
                      
                              // Calculamos la diferencia
                              final difference =
                                  dateExpiration.difference(dateNow).inDays;
                      
                              if (difference < 0) {
                                isExpired = true; // Ya pasó la fecha
                              } else {
                                daysLeft =
                                    difference; // Guardamos cuántos días faltan
                              }
                            }
                          }
                      
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 0),
                            child: GestureDetector(
                              onTap: () {
                                _log('card_tapped:index=$index');
                                _logAnalytics('lote_card_tapped', parameters: {'index': index.toString()});
                                setState(() {
                                  selectedIndex = isSelected ? null : index;
                                });
                                // Re-solicitar foco: tocar un card cierra el
                                // teclado en Android; esto lo mantiene abierto
                                // para que el scanner siga enviando input.
                                _searchFocusNode.requestFocus();
                              },
                              child: Card(
                                elevation: 3,
                                color: isSelected
                                    ? Colors.green[100]
                                    : Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
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
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green[50],
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                    color: Colors.green.shade300),
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
                                      if (loteData.expirationDate != "") ...[
                                        Row(
                                          children: [
                                            const Text('Fecha de caducidad: ',
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 12)),
                                            Text(
                                              '${rawDate == false ? 'Sin fecha' : rawDate}',
                                              style: TextStyle(
                                                color: (rawDate == false ||
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
                      
                                      // --- SECCIÓN DE ESTADO DEL LOTE ---
                      
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
                                                color: Colors.red.shade200),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Colors.red,
                                                  size: 16),
                                              SizedBox(width: 5),
                                              Text("¡LOTE VENCIDO!",
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ]
                                      // CASO 2: POR VENCER (Mostrar días restantes)
                                      else if (daysLeft != null) ...[
                                        const SizedBox(height: 5),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            // Si faltan menos de 15 días: Fondo Naranja suave, sino Azul suave
                                            color: daysLeft < 15
                                                ? Colors.orange[50]
                                                : Colors.blue[50],
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color: daysLeft < 15
                                                    ? Colors.orange.shade300
                                                    : Colors.blue.shade200),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                  Icons
                                                      .av_timer, // Icono de cronómetro
                                                  // Si faltan menos de 15 días: Naranja, sino Azul
                                                  color: daysLeft < 15
                                                      ? Colors.orange[800]
                                                      : Colors.blue[700],
                                                  size: 16),
                                              const SizedBox(width: 5),
                                              Text(
                                                daysLeft == 0
                                                    ? "Vence hoy"
                                                    : "Vence en $daysLeft días",
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
                        });
                        },
                      ),
                    ),
                    //todo crear lote
                    Visibility(
                      visible: !viewList,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                    
                            // ---------------------------------------------------------
                            // 1. CAMPO: NOMBRE DEL LOTE (Mayúsculas y Sin Espacios)
                            // ---------------------------------------------------------
                            if (bloc.configurations.result?.result
                                    ?.manageExpirationDateWithoutLot ==
                                false)
                              SizedBox(
                                height: 40,
                                child: TextFormField(
                                  focusNode: _loteFocusNode,
                                  autofocus: true,
                                  controller: bloc.newLoteController,
                                  style:
                                      TextStyle(color: black, fontSize: 14),

                                  // UX: Abre el teclado en mayúsculas
                                  textCapitalization:
                                      TextCapitalization.characters,
                    
                                  // LÓGICA: Fuerza mayúsculas y bloquea espacio
                                  inputFormatters: [
                                    UpperCaseTextFormatter(), // Clase auxiliar (ver abajo)
                                    FilteringTextInputFormatter.deny(
                                        RegExp(r'\s')),
                                  ],
                    
                                  decoration: InputDecoration(
                                    labelText: 'Nombre del lote',
                                    labelStyle:
                                        TextStyle(color: primaryColorApp),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        bloc.newLoteController.clear();
                                        FocusScope.of(context).unfocus();
                                      },
                                      icon: const Icon(Icons.close,
                                          color: grey),
                                    ),
                                  ),
                                ),
                              ),
                    
                            const SizedBox(height: 10),
                    
                            // ---------------------------------------------------------
                            // 2. CAMPO: FECHA DE CADUCIDAD
                            // ---------------------------------------------------------
                            Visibility(
                              visible: bloc
                                          .currentProduct.useExpirationDate ==
                                      true ||
                                  bloc.currentProduct.useExpirationDate == 1,
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 40,
                                    child: TextFormField(
                                      style: TextStyle(
                                          color: black, fontSize: 14),
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
                                          icon: const Icon(Icons.close,
                                              color: grey),
                                        ),
                                        labelText: 'Fecha de caducidad',
                                        labelStyle:
                                            TextStyle(color: primaryColorApp),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      onTap: () async {
                                        FocusScope.of(context).unfocus();
                    
                                        // Tu selector de fecha actual
                                        var pickedDate = await DatePicker
                                            .showSimpleDatePicker(
                                          titleText: 'Seleccione una fecha',
                                          context,
                                          confirmText: 'Seleccionar',
                                          cancelText: 'Cancelar',
                                          firstDate: DateTime.now().subtract(
                                              const Duration(days: 30)),
                                          lastDate: DateTime.now().add(
                                              const Duration(days: 2000)),
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
                                                  'yyyy-MM-dd HH:mm:ss')
                                              .format(pickedDate);
                    
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
                                            selectedDate!.day);
                                        final dateNow = DateTime(
                                            now.year, now.month, now.day);
                    
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
                                              horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: bgColor,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: textColor
                                                    .withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(icon,
                                                  color: textColor, size: 18),
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
                            final selectedLote = _sortedLotes.isNotEmpty
                                ? _sortedLotes[selectedIndex!]
                                : context
                                    .read<ConteoBloc>()
                                    .listLotesProductFilters[selectedIndex!];
                            final isSelectedSuggested =
                                _suggestedLoteId != null &&
                                _suggestedLoteId != 0 &&
                                selectedLote.id == _suggestedLoteId;

                            void confirmSelection() {
                              context
                                  .read<ConteoBloc>()
                                  .add(SelectecLoteEvent(selectedLote));
                              Navigator.pushReplacementNamed(
                                  context, 'new-product-conteo');
                              Get.snackbar(
                                'Lote Seleccionado',
                                'Has seleccionado el lote: ${selectedLote.name}',
                                backgroundColor: white,
                                colorText: primaryColorApp,
                                icon: Icon(Icons.check, color: Colors.green),
                              );
                            }

                            if (isSelectedSuggested ||
                                _suggestedLoteId == null ||
                                _suggestedLoteId == 0) {
                              confirmSelection();
                            } else {
                              showDialog(
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
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Continuar',
                                          style: TextStyle(color: white)),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColorApp,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Seleccionar lote',
                            style: TextStyle(color: white),
                          ),
                        ),
                      ),
                    ),
                    //todo botones
                    Visibility(
                      visible: MediaQuery.viewInsetsOf(context).bottom == 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                              onPressed: () {
                                _log('cancelar_pressed');
                                _logAnalytics('lote_cancelar');
                                FirebaseCrashlytics.instance
                                    .setCustomKey('lote_view_mode', 'list');
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
                                _searchFocusNode.requestFocus();
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: grey,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                              child: Text(
                                'CANCELAR',
                                style: TextStyle(
                                  color: white,
                                ),
                              )),
                          const SizedBox(width: 10),
                          Visibility(
                            visible: viewList,
                            child: ElevatedButton(
                                onPressed: () {
                                  //todo reglas de la creacion lote automatico
                                  // Que el producto no maneje fecha de vencimiento "use_expiration_date": false,
                                  // y el permiso de crear lote sin nombre este activado   "manage_expiration_date_without_lot": true,

                                  if ((widget.currentProduct
                                                  ?.useExpirationDate ==
                                              false ||
                                          widget.currentProduct
                                                  ?.useExpirationDate ==
                                              0) &&
                                      (bloc.configurations.result?.result
                                              ?.manageExpirationDateWithoutLot ==
                                          true)) {
                                    //todo creamos el lote manual sin fecha y con el nombre de la fecha actual

                                    bloc.newLoteController.text =
                                        //la fecha actual sin separar los numeros
                                        DateFormat('ddMMyyyyHHmmss')
                                            .format(DateTime.now());

                                    bloc.add(CreateLoteProduct(
                                      bloc.newLoteController.text,
                                      '',
                                      false,
                                    ));
                                  }

                                  _log('crear_lote_pressed');
                                  _logAnalytics('lote_crear_lote');
                                  FirebaseCrashlytics.instance
                                      .setCustomKey('lote_view_mode', 'create');
                                  setState(() {
                                    viewList = false;
                                  });
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
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                child: Text(
                                  'CREAR LOTE',
                                  style: TextStyle(
                                    color: white,
                                  ),
                                )),
                          ),
                          //todo boton agregar lote
                          Visibility(
                            visible: !viewList,
                            child: ElevatedButton(
                                onPressed: () {
                                  //ocultamos la lista de lotes
                                  ///validamos que l nombre del lote no sea el mismo que ya existe en la lista
                                  if (context
                                      .read<ConteoBloc>()
                                      .listLotesProduct
                                      .where((element) =>
                                          element.name ==
                                          context
                                              .read<ConteoBloc>()
                                              .newLoteController
                                              .text)
                                      .isNotEmpty) {
                                    Get.snackbar(
                                      'Error al crear lote',
                                      'El lote ya existe, por favor ingrese otro nombre',
                                      backgroundColor: white,
                                      colorText: primaryColorApp,
                                      icon: Icon(Icons.error,
                                          color: Colors.amber),
                                    );
                                    return;
                                  }

                                  //validamos que la fecha no este vacia si el producto requiere fecha de caducidad
                                  if ((context
                                                  .read<ConteoBloc>()
                                                  .currentProduct
                                                  .useExpirationDate ==
                                              true ||
                                          context
                                                  .read<ConteoBloc>()
                                                  .currentProduct
                                                  .useExpirationDate ==
                                              1) &&
                                      (context
                                              .read<ConteoBloc>()
                                              .dateLoteController
                                              .text
                                              .isEmpty ||
                                          context
                                                  .read<ConteoBloc>()
                                                  .dateLoteController
                                                  .text ==
                                              "")) {
                                    Get.snackbar(
                                      'Error al crear lote',
                                      'La fecha de caducidad no puede estar vacía para este producto',
                                      backgroundColor: white,
                                      colorText: primaryColorApp,
                                      icon: Icon(Icons.error,
                                          color: Colors.amber),
                                    );
                                    return;
                                  }
                                  //validacion nombre lote no vacio

                                  if (bloc.configurations.result?.result
                                          ?.manageExpirationDateWithoutLot ==
                                      false) {
                                    if (context
                                            .read<ConteoBloc>()
                                            .newLoteController
                                            .text
                                            .isEmpty ||
                                        context
                                                .read<ConteoBloc>()
                                                .newLoteController
                                                .text ==
                                            '') {
                                      Get.snackbar(
                                        'Error al crear lote',
                                        'El nombre del lote no puede estar vacío',
                                        backgroundColor: white,
                                        colorText: primaryColorApp,
                                        icon: Icon(Icons.error,
                                            color: Colors.amber),
                                      );
                                      return;
                                    }
                                  } else {
                                    bloc.newLoteController.text =
                                        //la fecha seleccionada sin separar los numeros
                                        DateFormat('ddMMyyyyHHmmss').format(
                                            DateTime(
                                                selectedDate!.year,
                                                selectedDate!.month,
                                                selectedDate!.day,
                                                DateTime.now().hour,
                                                DateTime.now().minute,
                                                DateTime.now().second));
                                  }

                                  //validacion que la fecha del lote no puede ser menor o igual la fecha actual
                                  if (selectedDate != null) {
                                    final now = DateTime.now();
                                    final selectedDateOnly = DateTime(
                                        selectedDate!.year,
                                        selectedDate!.month,
                                        selectedDate!.day);
                                    final nowDateOnly =
                                        DateTime(now.year, now.month, now.day);

                                    if (selectedDateOnly
                                            .isBefore(nowDateOnly) ||
                                        selectedDateOnly
                                            .isAtSameMomentAs(nowDateOnly)) {
                                      Get.snackbar(
                                        'Error al crear lote',
                                        'La fecha de caducidad debe ser mayor a la fecha actual.\nRevise la fecha de caducidad real del producto e intente de nuevo',
                                        backgroundColor: white,
                                        duration: const Duration(seconds: 4),
                                        colorText: primaryColorApp,
                                        icon: Icon(Icons.error,
                                            color: Colors.amber),
                                      );
                                      return;
                                    }
                                  }

                                  context.read<ConteoBloc>().add(
                                      CreateLoteProduct(
                                          context
                                              .read<ConteoBloc>()
                                              .newLoteController
                                              .text,
                                          context
                                              .read<ConteoBloc>()
                                              .dateLoteController
                                              .text,
                                          false));
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColorApp,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                child: Text(
                                  'AGREGAR LOTE',
                                  style: TextStyle(
                                    color: white,
                                  ),
                                )),
                          ),
                        ],
                      ),
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
}