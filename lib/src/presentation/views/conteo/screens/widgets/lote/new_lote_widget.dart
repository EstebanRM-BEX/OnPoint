// ignore_for_file: use_build_context_synchronously, unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_holo_date_picker/date_picker.dart';
import 'package:flutter_holo_date_picker/i18n/date_picker_i18n.dart';
import 'package:get/get.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/presentation/providers/network/check_internet_connection.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/conteo/models/conteo_response_model.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/bloc/conteo_bloc.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/new_lote_widget.dart';

import 'package:wms_app/src/presentation/views/user/screens/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/keyboard_widget.dart';

import 'package:intl/intl.dart'; // Importamos el paquete intl

class NewLoteOrdenScreen extends StatefulWidget {
  const NewLoteOrdenScreen({super.key, this.currentProduct});

  final CountedLine? currentProduct;

  @override
  State<NewLoteOrdenScreen> createState() => _NewLoteScreenState();
}

class _NewLoteScreenState extends State<NewLoteOrdenScreen> {
  bool viewList = true;
  DateTime? selectedDate; // Para almacenar la fecha seleccionada
  int? selectedIndex; // Para almacenar el índice del lote seleccionado

  @override
  void initState() {
    super.initState();
    viewList = true;
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
        backgroundColor: white,
        bottomNavigationBar:
            !viewList && context.read<UserBloc>().fabricante.contains("Zebra")
                ? Padding(
                    padding: const EdgeInsets.only(
                      bottom: 35,
                    ),
                    child: CustomKeyboard(
                      isLogin: false,
                      controller: context.read<ConteoBloc>().newLoteController,
                      onchanged: () {
                        context.read<ConteoBloc>().newLoteController.text =
                            context.read<ConteoBloc>().newLoteController.text;
                      },
                    ),
                  )
                : null,
        body: BlocBuilder<ConteoBloc, ConteoState>(
          builder: (context, state) {
            final bloc = context.read<ConteoBloc>();
            return SizedBox(
              width: size.width * 1,
              height: size.height * 1,
              child: Column(
                children: [
                  BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
                    builder: (context, connectionStatus) {
                      return BlocConsumer<ConteoBloc, ConteoState>(
                        listener: (context, state) {
                          print('STATE ❤️‍🔥 $state');

                          if (state is CreateLoteProductSuccess) {
                            Navigator.pop(context);
                            Navigator.pushReplacementNamed(
                                context, 'scan-product-conteo');
                          }

                          if (state is CreateLoteProductLoading) {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return const DialogLoading(
                                  message: "Creando lote espere un momento...",
                                );
                              },
                            );
                          }

                          if (state is CreateLoteProductFailure) {
                            Navigator.pop(context);
                            showScrollableErrorDialog(state.error);
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
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: connectionStatus !=
                                            ConnectionStatus.online
                                        ? 0
                                        : 35,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.arrow_back,
                                            color: white),
                                        onPressed: () {
                                          context.read<ConteoBloc>().add(
                                                ShowKeyboardEvent(false),
                                              );
                                          Navigator.pushReplacementNamed(
                                              context, 'scan-product-conteo');
                                        },
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                            left: size.width * 0.2),
                                        child: const Text(
                                          'CREAR LOTE',
                                          style: TextStyle(
                                              color: white, fontSize: 18),
                                        ),
                                      ),
                                      const Spacer(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 10),
                  if (!context.read<ConteoBloc>().isKeyboardVisible)
                    Padding(
                      padding:
                          EdgeInsets.only(bottom: 5, top: viewList ? 0 : 10),
                      child: Text(widget.currentProduct?.productName ?? '',
                          style: TextStyle(fontSize: 12, color: black)),
                    ),

                  //184170

                  //todo barra buscar
                  Visibility(
                    visible: viewList,
                    child: SizedBox(
                        height: 55,
                        width: size.width * 1,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 10,
                            right: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: size.width * 0.9,
                                child: Card(
                                  color: Colors.white,
                                  elevation: 3,
                                  child: TextFormField(
                                    style:
                                        TextStyle(color: black, fontSize: 14),
                                    readOnly: context
                                            .read<UserBloc>()
                                            .fabricante
                                            .contains("Zebra")
                                        ? true
                                        : false,
                                    textAlignVertical: TextAlignVertical.center,
                                    controller: context
                                        .read<ConteoBloc>()
                                        .searchControllerLote,
                                    showCursor: true,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: grey,
                                        size: 20,
                                      ),
                                      suffixIcon: IconButton(
                                          onPressed: () {
                                            context
                                                .read<ConteoBloc>()
                                                .searchControllerLote
                                                .clear();
                                            context
                                                .read<ConteoBloc>()
                                                .add(SearchLotevent(
                                                  '',
                                                ));
                                            context
                                                .read<ConteoBloc>()
                                                .add(ShowKeyboardEvent(false));
                                            FocusScope.of(context).unfocus();
                                          },
                                          icon: const Icon(
                                            Icons.close,
                                            color: grey,
                                            size: 20,
                                          )),
                                      disabledBorder:
                                          const OutlineInputBorder(),
                                      hintText: "Buscar lote",
                                      hintStyle: const TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (value) {
                                      context
                                          .read<ConteoBloc>()
                                          .add(SearchLotevent(
                                            value,
                                          ));
                                    },
                                    onTap: !context
                                            .read<UserBloc>()
                                            .fabricante
                                            .contains("Zebra")
                                        ? null
                                        : () {
                                            context
                                                .read<ConteoBloc>()
                                                .add(ShowKeyboardEvent(true));
                                          },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ),

                  const SizedBox(height: 10),
                  if(viewList)
                  Expanded(
                      child: ListView.builder(
                          itemCount: bloc.listLotesProductFilters.length,
                          itemBuilder: (context, index) {
                            bool isSelected = selectedIndex == index;
                            // 1. Obtener el dato crudo
                            final rawDate = bloc
                                .listLotesProductFilters[index].expirationDate;
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
                                        horizontal: 10, vertical: 5),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Lote: ${bloc.listLotesProductFilters[index].name}',
                                          style: TextStyle(
                                              color: primaryColorApp,
                                              fontSize: 12),
                                        ),
                                        if (bloc.listLotesProductFilters[index]
                                                .expirationDate !=
                                            "") ...[
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
                                                Icon(Icons.warning_amber_rounded,
                                                    color: Colors.red, size: 16),
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
                                              color: daysLeft! < 15
                                                  ? Colors.orange[50]
                                                  : Colors.blue[50],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                  color: daysLeft! < 15
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
                                                    color: daysLeft! < 15
                                                        ? Colors.orange[800]
                                                        : Colors.blue[700],
                                                    size: 16),
                                                const SizedBox(width: 5),
                                                Text(
                                                  daysLeft == 0
                                                      ? "Vence hoy"
                                                      : "Vence en $daysLeft días",
                                                  style: TextStyle(
                                                    color: daysLeft! < 15
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
                          })),
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
                          SizedBox(
                            height: 40,
                            child: TextFormField(
                              controller: bloc.newLoteController,
                              style: TextStyle(color: black, fontSize: 14),
                                      
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
                                labelStyle: TextStyle(color: primaryColorApp),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
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
                                      
                          // ---------------------------------------------------------
                          // 2. CAMPO: FECHA DE CADUCIDAD
                          // ---------------------------------------------------------
                          Visibility(
                            visible: bloc.currentProduct.useExpirationDate ==
                                    true ||
                                bloc.currentProduct.useExpirationDate == 1,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 40,
                                  child: TextFormField(
                                    style:
                                        TextStyle(color: black, fontSize: 14),
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
                                        lastDate: DateTime.now()
                                            .add(const Duration(days: 2000)),
                                        dateFormat: "dd-MMMM-yyyy",
                                        locale: DateTimePickerLocale.es,
                                        looping: false,
                                      );
                                      
                                      if (pickedDate != null) {
                                        final formattedDate =
                                            DateFormat('yyyy-MM-dd hh:mm')
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
                                              color:
                                                  textColor.withOpacity(0.3)),
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
                          // Aquí puedes manejar la lógica de lo que suceda cuando se seleccione el lote
                          var selectedLote = context
                              .read<ConteoBloc>()
                              .listLotesProductFilters[selectedIndex!];

                          context
                              .read<ConteoBloc>()
                              .add(SelectecLoteEvent(selectedLote));

                          Navigator.pushReplacementNamed(
                            context,
                            'scan-product-conteo',
                          );

                          Get.snackbar(
                            'Lote Seleccionado',
                            'Has seleccionado el lote: ${selectedLote.name}',
                            backgroundColor: white,
                            colorText: primaryColorApp,
                            icon: Icon(Icons.check, color: Colors.green),
                          );
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
                  Visibility(
                    visible: !context.read<ConteoBloc>().isKeyboardVisible,
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
                                //ocultamos la lista de lotes
                                setState(() {
                                  viewList = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColorApp,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                              child: Text(
                                'CREAR LOTE',
                                style: TextStyle(
                                  color: white,
                                ),
                              )),
                        ),
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
                                    icon:
                                        Icon(Icons.error, color: Colors.amber),
                                  );
                                  return;
                                }
//validacion nombre lote no vacio

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
                                    icon:
                                        Icon(Icons.error, color: Colors.amber),
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
                                    icon:
                                        Icon(Icons.error, color: Colors.amber),
                                  );
                                  return;
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

                                  if (selectedDateOnly.isBefore(nowDateOnly) ||
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

                                context
                                    .read<ConteoBloc>()
                                    .add(CreateLoteProduct(
                                      context
                                          .read<ConteoBloc>()
                                          .newLoteController
                                          .text,
                                      context
                                          .read<ConteoBloc>()
                                          .dateLoteController
                                          .text,
                                    ));
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColorApp,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
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

                  Visibility(
                    visible: context.read<ConteoBloc>().isKeyboardVisible &&
                        context.read<UserBloc>().fabricante.contains("Zebra"),
                    child: CustomKeyboard(
                      isLogin: false,
                      controller:
                          context.read<ConteoBloc>().searchControllerLote,
                      onchanged: () {
                        context.read<ConteoBloc>().add(SearchLotevent(
                              context
                                  .read<ConteoBloc>()
                                  .searchControllerLote
                                  .text,
                            ));
                      },
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
