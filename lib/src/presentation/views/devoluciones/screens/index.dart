import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/utils/widgets/dialog_dispositivo_no_autorizado_widget.dart';
import 'package:wms_app/injection_container.dart';
// ignore_for_file: use_build_context_synchronously

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wms_app/shared/widgets/disposable_controllers_mixin.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/product_devolucion_model.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/response_terceros_model.dart';
// Asegúrate de que las rutas de tus imports sean correctas
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/widgets/buildBarcodeInputField_widget.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/widgets/custom_bar_widget.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/widgets/dialog_delete_product_widget.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/widgets/dialog_edit_product_widget.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/widgets/product_card_widget.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/widgets/product_search_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

class DevolucionesScreen extends StatefulWidget {
  const DevolucionesScreen({super.key});

  @override
  State<DevolucionesScreen> createState() => _DevolucionesScreenState();
}

class _DevolucionesScreenState extends State<DevolucionesScreen>
    with WidgetsBindingObserver, DisposableControllersMixin {
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();

  final TextEditingController _controllerSearch = TextEditingController();
  final TextEditingController _controllerLocation = TextEditingController();
  final TextEditingController _controllerContacto = TextEditingController();
  final TextEditingController _controllerPropietario = TextEditingController();
  final TextEditingController _controllerQuantity = TextEditingController();
  final FocusNode focusNode1 = FocusNode(); //foco de producto
  final FocusNode focusNode2 = FocusNode(); //foco de ubicacion
  final FocusNode focusNode3 = FocusNode(); //foco de contacto
  final FocusNode focusNodePropietario = FocusNode(); //foco de propietario
  final FocusNode focusNode4 = FocusNode();
  final FocusNode focusNode5 = FocusNode();

  @override
  List<ChangeNotifier> get disposables => [
        focusNode1,
        focusNode2,
        focusNode3,
        focusNodePropietario,
        focusNode4,
        focusNode5,
        _controllerSearch,
        _controllerLocation,
        _controllerContacto,
        _controllerPropietario,
        _controllerQuantity,
      ];

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      showDialog(
        context: context,
        builder: (context) =>
            const DialogLoading(message: "Espere un momento..."),
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ✅ INICIALIZACIÓN SMART: Carga todo lo necesario (Cache-First para Terceros)
    context.read<DevolucionesBloc>().add(InitializeDevolucionesData());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleFocusAccordingToState();
  }

  void _setOnlyFocus(FocusNode nodeToFocus) {
    for (final node in [
      focusNode1,
      focusNode2,
      focusNode3,
      focusNodePropietario,
      focusNode4,
      focusNode5,
    ]) {
      if (node == nodeToFocus) {
        FocusScope.of(context).requestFocus(node);
      } else {
        node.unfocus();
      }
    }
  }

  void _handleFocusAccordingToState() {
    debugPrint('_handleFocusAccordingToState');
    final bloc = context.read<DevolucionesBloc>();
    // Mientras hay un diálogo visible (ej. buscador de productos), esta
    // pantalla queda detrás pero sigue montada y sigue recibiendo
    // didChangeDependencies (p.ej. al aparecer/ocultarse el teclado del
    // diálogo). Si seguimos pidiendo foco aquí, se lo robamos al campo de
    // texto del diálogo y el teclado se cierra solo mientras el usuario
    // escribe.
    if (bloc.isDialogVisible) return;
    final step = getCurrentStep(bloc);

    final focusNodeByStep = {
      'location': focusNode2,
      'contacto': focusNode3,
      'propietario': focusNodePropietario,
      'product': focusNode1,
      'quantity': focusNode4,
    };

    final node = focusNodeByStep[step];
    if (node != null) {
      debugPrint('🚼 $step');
      _setOnlyFocus(node);
    }
  }

  String getCurrentStep(DevolucionesBloc bloc) {
    final requiresLocationFocus =
        bloc.configurations.result?.result?.returnsLocationDestOption ==
        "dynamic";

    if (requiresLocationFocus && !bloc.locationIsOk) {
      return 'location';
    } else if (!requiresLocationFocus || bloc.locationIsOk) {
      if (!bloc.almacenIsOk) return 'almacen';
      if (!bloc.contactoIsOk) return 'contacto';
      if (!bloc.propietarioIsOk) return 'propietario';
      if (!bloc.isDialogVisible) return 'product';
      return 'quantity';
    }
    return 'none';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void validateProducto(String value) {
    final bloc = context.read<DevolucionesBloc>();
    if (bloc.isDialogVisible) {
      Future.microtask(() => focusNode1.requestFocus());
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      return; // Evita validar si el diálogo ya está visible
    }
    final scan = value.trim();

    debugPrint('scan product: $scan');
    _controllerSearch.text = ''; // Limpia el campo de texto del producto
    //buscamos si hay un producto con ese código de barras

    bloc.add(
      GetProductEvent(
        scan.toUpperCase(),
        false, // Asumiendo que false es para escaneo
      ),
    );
    Future.microtask(() => focusNode1.requestFocus());
  }

  void validateLocation(String value) {
    final bloc = context.read<DevolucionesBloc>();
    final scan = value.trim().toLowerCase();

    debugPrint('scan location: $scan');
    _controllerLocation.text = ''; // Limpia el campo de texto del producto
    //buscamos si hay un producto con ese código de barras

    ResultUbicaciones? matchedUbicacion = bloc.ubicaciones.firstWhere(
      (ubicacion) => ubicacion.barcode?.toLowerCase() == scan,
      orElse: () =>
          ResultUbicaciones(), // Si no se encuentra ningún match, devuelve null
    );
    if (matchedUbicacion.barcode != null) {
      debugPrint('Ubicacion encontrada: ${matchedUbicacion.name}');
      bloc.add(SelectLocationEvent(matchedUbicacion));
      Future.microtask(() => focusNode2.requestFocus());
    } else {
      debugPrint('Ubicacion no encontrada');
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      Future.microtask(() => focusNode2.requestFocus());
    }
  }

  void validateContacto(String value) {
    final bloc = context.read<DevolucionesBloc>();
    final scan = value.trim().toLowerCase();

    debugPrint('scan contacto: $scan');
    _controllerContacto.text = ''; // Limpia el campo de texto del producto
    //buscamos si hay un producto con ese código de barras

    Terceros? matchedTercero = bloc.terceros.firstWhere(
      (tercero) => tercero.document?.toLowerCase() == scan,
      orElse: () =>
          Terceros(), // Si no se encuentra ningún match, devuelve null
    );
    if (matchedTercero.document != null) {
      debugPrint('contacto encontrado: ${matchedTercero.name}');
      bloc.add(SelectTerceroEvent(matchedTercero));
      Future.microtask(() => focusNode3.requestFocus());
    } else {
      debugPrint('contacto no encontrada');
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      Future.microtask(() => focusNode3.requestFocus());
    }
  }

  void validatePropietario(String value) {
    final bloc = context.read<DevolucionesBloc>();
    final scan = value.trim().toLowerCase();

    debugPrint('scan propietario: $scan');
    _controllerPropietario.text = '';

    Terceros? matchedPropietario = bloc.terceros.firstWhere(
      (tercero) => tercero.document?.toLowerCase() == scan,
      orElse: () => Terceros(),
    );
    if (matchedPropietario.document != null) {
      debugPrint('Propietario encontrado: ${matchedPropietario.name}');
      bloc.add(SelectPropietarioEvent(matchedPropietario));
      Future.microtask(() => focusNodePropietario.requestFocus());
    } else {
      debugPrint('Propietario no encontrado');
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      Future.microtask(() => focusNodePropietario.requestFocus());
    }
  }

  void validateQuantity(String value) {
    debugPrint("Validando cantidad: $value");
    final bloc = context.read<DevolucionesBloc>();
    final scan = value.trim().toLowerCase();
    _controllerQuantity.text = ''; // Limpia el campo de texto
    if (scan == bloc.currentProduct.barcode?.toLowerCase()) {
      bloc.add(SetQuantityEvent(1));
      Future.microtask(() => focusNode4.requestFocus());
    } else {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      Future.microtask(() => focusNode4.requestFocus());
    }
  }

  @override
  Widget build(BuildContext context) {
    final devolucionesBlocRef = context.read<DevolucionesBloc>();
    return BlocConsumer<DevolucionesBloc, DevolucionesState>(
      // Evita reconstruir la pantalla de fondo (y su BuildBarcodeInputField
      // con autofocus) mientras hay un diálogo visible (ej. buscador de
      // productos). Si se reconstruye, compite por el foco con el campo de
      // texto del diálogo y le cierra el teclado al usuario mientras escribe.
      buildWhen: (previous, current) => !devolucionesBlocRef.isDialogVisible,
      listener: (context, state) {
        debugPrint('Estado actual ❤️‍🔥: $state');

        if (state is AddProductFailure) {
          showScrollableErrorDialog(state.error);
        } else if (state is DeviceNotAuthorized) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const DialogUnauthorizedDevice(),
          );
        } else if (state is SelectWarehouseState) {
          Future.delayed(const Duration(seconds: 1), () {
            FocusScope.of(context).requestFocus(focusNode3);
          });
        } else if (state is SelectLocationState) {
          // next step is 'almacen' (manual only — no focus change needed)
        } else if (state is SelectTerceroState) {
          Future.delayed(const Duration(seconds: 1), () {
            FocusScope.of(context).requestFocus(focusNodePropietario);
          });
        } else if (state is SelectPropietarioState) {
          Future.delayed(const Duration(seconds: 1), () {
            FocusScope.of(context).requestFocus(focusNode1);
          });
        } else if (state is GetProductLoading) {
          showDialog(
            context: context, // Usa el context del listener
            barrierDismissible:
                false, // Evita que el usuario cierre el diálogo tocando fuera
            builder:
                (
                  dialogContext,
                ) => // Usa un nombre diferente para el contexto del diálogo
                    const DialogLoading(message: "Buscando información..."),
          );
        } else if (state is GetProductFailure) {
          _audioService.playErrorSound();
          _vibrationService.vibrate();

          //esperamos 1 y cerramos el diálogo de carga
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context); // Cierra el diálogo de carga
          });

          Get.snackbar(
            '360 Software Informa',
            'No se encontró producto con ese código de barras',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.error, color: Colors.red),
          );
        } else if (state is GetProductSuccess) {
          final bloc = context.read<DevolucionesBloc>();
          if (bloc.isDialogVisible) {
            return; // Evita duplicar el diálogo
          }

          bloc.add(ChangeStateIsDialogVisibleEvent(true));
          Navigator.pop(context); // Cierra el diálogo de carga

          //mostrar un dialogo para agregar el producto con cantidad y lote si es necesario
          showDialog(
            context: context,
            builder: (context) {
              return DialogEditProduct(
                functionValidate: (value) {
                  validateQuantity(value);
                },
                focusNode: focusNode4,
                focusNodeQuantityManual: focusNode5,
                controller: _controllerQuantity,
                isEdit: false,
              );
            },
          ).then((_) {
            // Se ejecuta al cerrar el diálogo
            bloc.add(ChangeStateIsDialogVisibleEvent(false));
          });
        } else if (state is SendDevolucionFailure) {
          showScrollableErrorDialog(state.error);
        } else if (state is SendDevolucionSuccess) {
          //dialogo para mostrar la devolucion creada
          final bloc = context.read<DevolucionesBloc>();
          final propietarioDocumento = bloc.currentPropietario.document;
          showDialog(
            context: context,
            builder: (context) {
              return BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: AlertDialog(
                  actionsAlignment: MainAxisAlignment.spaceBetween,
                  contentPadding: const EdgeInsets.all(5),
                  title: Center(
                    child: Text(
                      'DEVOLUCION CREADA',
                      style: TextStyle(color: green, fontSize: 16),
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.response.result?.nombreDevolucion ?? 'Sin nombre',
                        style: TextStyle(
                          color: primaryColorApp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text('Fecha: ', style: TextStyle(color: black)),
                          Text(
                            state.response.result?.fechaCreacion?.toString() ??
                                'Sin fecha',
                            style: TextStyle(color: primaryColorApp),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text('Almacén: ', style: TextStyle(color: black)),
                          Expanded(
                            child: Text(
                                state.response.result?.almacenNombre ??
                              'Sin almacen',
                              style: TextStyle(color: primaryColorApp),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Proveedor: ', style: TextStyle(color: black))),
                       Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          state.response.result?.proveedorNombre ??
                              'Sin proveedor',
                          maxLines: 2,

                          style: TextStyle(color: primaryColorApp),
                        ),
                      ),
                      if( state.response.result?.propietarioNombre != "")...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Propietario: ', style: TextStyle(color: black))),
                       Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          state.response.result?.propietarioNombre ??
                              'Sin proveedor',
                          maxLines: 2,
                          
                          style: TextStyle(color: primaryColorApp),
                        ),
                      ),
                      ],
                      if (propietarioDocumento != null)
                        Row(
                          children: [
                            Text(
                              'Doc. propietario: ',
                              style: TextStyle(color: black),
                            ),
                            Text(
                              propietarioDocumento,
                              style: TextStyle(color: primaryColorApp),
                            ),
                          ],
                        ),
                      Row(
                        children: [
                          Text(
                            'Ubicacion destino: ',
                            style: TextStyle(color: black),
                          ),
                          Expanded(
                            child: Text(
                              state.response.result?.ubicacionDestinoNombre ??
                                  'Sin ubicacion',
                              style: TextStyle(color: primaryColorApp),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text('Total items: ', style: TextStyle(color: black)),
                          Text(
                            state.response.result?.totalItems.toString() ?? "0",
                            style: TextStyle(color: primaryColorApp),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      //btn de cerrar
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: grey,
                          minimumSize: const Size(200, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text('CERRAR', style: TextStyle(color: white)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else if (state is GetProductExists) {
          //mostramos un dialogo diciendo que el producto ya existe

          final bloc = context.read<DevolucionesBloc>();
          if (bloc.isDialogVisible) {
            return; // Evita duplicar el diálogo
          }

          bloc.add(ChangeStateIsDialogVisibleEvent(true));

          Navigator.pop(context); // Cierra el diálogo de carga
          //verficamos si le producto tiene lote
          if (state.product.tracking == 'lot') {
            showDialog(
              barrierDismissible: false,
              context: context,
              builder: (context) {
                final size = MediaQuery.sizeOf(context);
                return PopScope(
                  canPop: false,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: AlertDialog(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      actionsAlignment: MainAxisAlignment.spaceAround,
                      title: Center(
                        child: Text(
                          'Productos relacionados',
                          style: TextStyle(
                            color: primaryColorApp,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(5),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icono o imagen del producto
                                  // Puedes usar Image.network(product.imageUrl) si tienes URLs de imagen
                                  Expanded(
                                    child:
                                        //LISTA DE PRODUCTOS RELACIONADOS
                                        ListView.builder(
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) => Card(
                                            elevation: 2,
                                            color: white,
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      SizedBox(
                                                        width:
                                                            size.width * 0.35,
                                                        child: Text(
                                                          state
                                                                  .productosRelacionados[index]
                                                                  .name ??
                                                              "",
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color: black,
                                                              ),
                                                          maxLines: 2,
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      GestureDetector(
                                                        onTap: () {
                                                          bloc.add(
                                                            ChangeStateIsDialogVisibleEvent(
                                                              true,
                                                            ),
                                                          );

                                                          bloc.add(
                                                            LoadCurrentProductEvent(
                                                              state
                                                                  .productosRelacionados[index]
                                                                  .toProduct(),
                                                            ),
                                                          );
                                                          Navigator.pop(
                                                            context,
                                                          ); // Cierra el diálogo
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) {
                                                              return DialogEditProduct(
                                                                functionValidate:
                                                                    (value) {
                                                                      validateQuantity(
                                                                        value,
                                                                      );
                                                                    },
                                                                focusNode:
                                                                    focusNode4,
                                                                focusNodeQuantityManual:
                                                                    focusNode5,
                                                                controller:
                                                                    _controllerQuantity,
                                                                isEdit: true,
                                                              );
                                                            },
                                                          ).then((_) {
                                                            bloc.add(
                                                              ChangeStateIsDialogVisibleEvent(
                                                                false,
                                                              ),
                                                            );
                                                          });
                                                        },
                                                        child: Icon(
                                                          Icons.edit,
                                                          color:
                                                              primaryColorApp,
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'Barcode: ',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${state.productosRelacionados[index].barcode}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'Código: ',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${state.productosRelacionados[index].code}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'Cantidad: ',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${state.productosRelacionados[index].quantity}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: black,
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        'unidad: ',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${state.productosRelacionados[index].uom}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Visibility(
                                                    visible:
                                                        state
                                                            .productosRelacionados[index]
                                                            .tracking ==
                                                        'lot',
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          'Lote: ',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                primaryColorApp,
                                                          ),
                                                        ),
                                                        Text(
                                                          '${state.productosRelacionados[index].lotName}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color: black,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                 Visibility(
                                            visible:
                                                state.productosRelacionados[index].manejaSegundaUnidad ==
                                                    1 ||
                                                state.productosRelacionados[index].manejaSegundaUnidad ==
                                                    true,
                                            child: Row(
                                              children: [
                                                Text(
                                                  "2nd Unidad: ",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: primaryColorApp,
                                                  ),
                                                ),
                                                Text(
                                                  "${state.productosRelacionados[index].uomSegundaUnidad}",
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          itemCount: state
                                              .productosRelacionados
                                              .length,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            context.read<DevolucionesBloc>().add(
                              ChangeStateIsDialogVisibleEvent(false),
                            );
                            Navigator.pop(context); // Cierra el diálogo
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: white),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            context.read<DevolucionesBloc>().add(
                              LoadCurrentProductEvent(
                                state.product.toProduct(
                                  clearLotId: true,
                                  clearLotName: true,
                                  clearQuantity: true,
                                ),
                              ),
                            );

                            Navigator.pop(
                              context,
                            ); // Cierra el diálogo de carga
                            //mostrar un dialogo para agregar el producto con cantidad y lote si es necesario
                            showDialog(
                              context: context,
                              builder: (context) {
                                return DialogEditProduct(
                                  functionValidate: (value) {
                                    validateQuantity(value);
                                  },
                                  focusNode: focusNode4,
                                  focusNodeQuantityManual: focusNode5,
                                  controller: _controllerQuantity,
                                  isEdit: false,
                                );
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColorApp,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Nuevo',
                            style: TextStyle(color: white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            showDialog(
              context: context,
              builder: (context) {
                return BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: AlertDialog(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    actionsAlignment: MainAxisAlignment.spaceAround,
                    title: Center(
                      child: Text(
                        'Producto ya existe',
                        style: TextStyle(color: primaryColorApp, fontSize: 18),
                      ),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icono o imagen del producto
                                // Puedes usar Image.network(product.imageUrl) si tienes URLs de imagen
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        state.product.name ?? "",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: black,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            'Barcode: ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: primaryColorApp,
                                            ),
                                          ),
                                          Text(
                                            '${state.product.barcode}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            'Código: ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: primaryColorApp,
                                            ),
                                          ),
                                          Text(
                                            '${state.product.code}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            'Cantidad: ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: primaryColorApp,
                                            ),
                                          ),
                                          Text(
                                            '${state.product.quantity}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: black,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'unidad: ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: primaryColorApp,
                                            ),
                                          ),
                                          Text(
                                            '${state.product.uom}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Visibility(
                                        visible:
                                            state.product.tracking == 'lot',
                                        child: Row(
                                          children: [
                                            Text(
                                              'Lote: ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: primaryColorApp,
                                              ),
                                            ),
                                            Text(
                                              '${state.product.lotName}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          bloc.add(ChangeStateIsDialogVisibleEvent(false));
                          // bloc.add(ClearScannedValueEvent('product'));
                          Navigator.pop(context); // Cierra el diálogo
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: white),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          context.read<DevolucionesBloc>().add(
                            ChangeStateIsDialogVisibleEvent(true),
                          );
                          context.read<DevolucionesBloc>().add(
                            LoadCurrentProductEvent(state.product.toProduct()),
                          );
                          Navigator.pop(context); // Cierra el diálogo
                          showDialog(
                            context: context,
                            builder: (context) {
                              return DialogEditProduct(
                                functionValidate: (value) {
                                  validateQuantity(value);
                                },
                                focusNode: focusNode4,
                                focusNodeQuantityManual: focusNode5,
                                controller: _controllerQuantity,
                                isEdit: true,
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColorApp,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Editar',
                          style: TextStyle(color: white),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        }
      },
      builder: (context, state) {
        final devolucionesBloc = context.read<DevolucionesBloc>();
        final currentStep = getCurrentStep(devolucionesBloc);

        // Determina si la lista de productos está vacía

        return Scaffold(
          backgroundColor: primaryColorApp,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.miniEndFloat,
          floatingActionButton: FloatingActionButton(
            mini: true,
            onPressed: () {
              devolucionesBloc.add(ChangeStateIsDialogVisibleEvent(true));
              showDialog(
                context: context,
                builder: (context) {
                  return SearchProductDevScreen();

                  ///cuando lo cerremos pasamos aChangeStateIsDialogVisibleEvent true
                },
              ).then((_) {
                // Se ejecuta al cerrar el diálogo
                devolucionesBloc.add(ChangeStateIsDialogVisibleEvent(false));
              });
            },
            backgroundColor: primaryColorApp,
            child: const Icon(Icons.add, color: white, size: 20),
          ),
          body: SafeArea(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  const CustomAppBar(), // Tu barra de aplicación personalizada
                  Expanded(
                    child: Column(
                      children: [
                        BuildBarcodeInputField(
                          focusNode: currentStep == 'location'
                              ? focusNode2
                              : currentStep == 'contacto'
                              ? focusNode3
                              : currentStep == 'propietario'
                              ? focusNodePropietario
                              : focusNode1,
                          controller: currentStep == 'location'
                              ? _controllerLocation
                              : currentStep == 'contacto'
                              ? _controllerContacto
                              : currentStep == 'propietario'
                              ? _controllerPropietario
                              : _controllerSearch,
                          functionValidate: (value) {
                            switch (currentStep) {
                              case 'location':
                                return validateLocation(value);
                              case 'contacto':
                                return validateContacto(value);
                              case 'propietario':
                                return validatePropietario(value);
                              case 'product':
                                return validateProducto(value);
                              default:
                                return;
                            }
                          },
                        ),

                        // UI para cuando hay productos en la lista
                        _buildProductListUI(
                          context,
                          devolucionesBloc,
                          context.read<DevolucionesBloc>().productosDevolucion,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductListUI(
    BuildContext context,
    DevolucionesBloc devolucionesBloc,
    List<ProductDevolucion> productosDevolucion,
  ) {
    final size = MediaQuery.sizeOf(context);
    return Expanded(
      // Envuelve en Expanded para que la lista ocupe el espacio y sea scrollable
      child: Column(
        children: [
          // Mensaje superior para escanear/agregar
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: GestureDetector(
                  onTap:
                      devolucionesBloc
                              .configurations
                              .result
                              ?.result
                              ?.returnsLocationDestOption ==
                          "predefined"
                      ? null
                      : () {
                          Navigator.pushReplacementNamed(
                            context,
                            'ubicaciones-devoluciones',
                          );
                        },
                  child: Card(
                    color:
                        devolucionesBloc
                                .configurations
                                .result
                                ?.result
                                ?.returnsLocationDestOption ==
                            "predefined"
                        ? Colors.grey[200]
                        : white,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color:
                                    devolucionesBloc
                                            .configurations
                                            .result
                                            ?.result
                                            ?.returnsLocationDestOption ==
                                        "predefined"
                                    ? Colors.grey
                                    : devolucionesBloc.locationIsOk
                                    ? Colors.green
                                    : Colors.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Text(
                            'Ubicación destino: ',
                            style: TextStyle(
                              fontSize: 11,
                              color: primaryColorApp,
                            ),
                          ),
                          Text(
                            devolucionesBloc
                                        .configurations
                                        .result
                                        ?.result
                                        ?.returnsLocationDestOption ==
                                    "predefined"
                                ? 'Predefinida'
                                : devolucionesBloc.currentLocation.name ??
                                      'Esperando escaneo',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  devolucionesBloc
                                          .configurations
                                          .result
                                          ?.result
                                          ?.returnsLocationDestOption ==
                                      "predefined"
                                  ? grey
                                  : devolucionesBloc.currentLocation.name ==
                                        null
                                  ? red
                                  : black,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.location_on,
                            color: primaryColorApp,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      'almacenes-devoluciones',
                    );
                  },
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: devolucionesBloc.almacenIsOk
                                    ? Colors.green
                                    : Colors.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Text(
                            'Almacén: ',
                            style: TextStyle(
                              fontSize: 11,
                              color: primaryColorApp,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              devolucionesBloc.currentWarehouse.name ??
                                  'Esperando selección',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    devolucionesBloc.currentWarehouse.name ==
                                        null
                                    ? red
                                    : black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.warehouse_outlined,
                            color: primaryColorApp,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    if (devolucionesBloc.terceros.isNotEmpty) {
                      Navigator.pushReplacementNamed(context, 'terceros');
                    } else {
                      devolucionesBloc.add(LoadTercerosEvent());
                    }
                  },
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: devolucionesBloc.contactoIsOk
                                        ? Colors.green
                                        : Colors.amber,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Text(
                                'Contacto: ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: primaryColorApp,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  devolucionesBloc.currentTercero.name ??
                                      'Esperando escaneo',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        devolucionesBloc.currentTercero.name ==
                                            null
                                        ? red
                                        : black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.person,
                                color: primaryColorApp,
                                size: 20,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: devolucionesBloc.contactoIsOk
                                        ? Colors.green
                                        : Colors.amber,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Text(
                                'Documento: ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: primaryColorApp,
                                ),
                              ),
                              Text(
                                devolucionesBloc.currentTercero.document ??
                                    'Esperando escaneo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      devolucionesBloc
                                              .currentTercero
                                              .document ==
                                          null
                                      ? red
                                      : black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      'propietario-devoluciones',
                    );
                  },
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color:
                                        devolucionesBloc.propietarioIsOk &&
                                            devolucionesBloc
                                                    .currentPropietario
                                                    .id !=
                                                null
                                        ? Colors.green
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Text(
                                'Propietario: ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: primaryColorApp,
                                ),
                              ),
                              Text(
                                devolucionesBloc.currentPropietario.name ??
                                    'Esperando escaneo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      devolucionesBloc
                                              .currentPropietario
                                              .name ==
                                          null
                                      ? grey
                                      : black,
                                ),
                              ),
                              const Spacer(),
                              if (!devolucionesBloc.propietarioIsOk)
                                GestureDetector(
                                  onTap: () {
                                    devolucionesBloc.add(
                                      SelectPropietarioEvent(Terceros()),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.grey[400]!,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.skip_next,
                                          color: Colors.grey[500],
                                          size: 12,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Saltar',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (devolucionesBloc.propietarioIsOk)
                                GestureDetector(
                                  onTap: () {
                                    devolucionesBloc.add(
                                      ResetPropietarioEvent(),
                                    );
                                  },
                                  child: Icon(
                                    Icons.close,
                                    color: grey,
                                    size: 16,
                                  ),
                                ),
                              Icon(
                                Icons.person_outline,
                                color: primaryColorApp,
                                size: 20,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color:
                                        devolucionesBloc.propietarioIsOk &&
                                            devolucionesBloc
                                                    .currentPropietario
                                                    .id !=
                                                null
                                        ? Colors.green
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Text(
                                'Documento: ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: primaryColorApp,
                                ),
                              ),
                              Text(
                                devolucionesBloc.currentPropietario.document ??
                                    'Esperando escaneo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      devolucionesBloc
                                              .currentPropietario
                                              .document ==
                                          null
                                      ? grey
                                      : black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 8.0,
                  right: 8.0,
                  bottom: 5,
                ),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: devolucionesBloc.productIsOk
                                  ? Colors.green
                                  : Colors.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Text(
                          'Productos: ',
                          style: TextStyle(
                            fontSize: 11,
                            color: primaryColorApp,
                          ),
                        ),
                        Text(
                          '${productosDevolucion.length}',
                          style: const TextStyle(fontSize: 11, color: black),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // La lista de productos existentes
          Expanded(
            // Esto es crucial para que ListView.builder no desborde dentro de una Column
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              itemCount: productosDevolucion.length,
              itemBuilder: (context, index) {
                final product = productosDevolucion[index];
                return ProductDevolucionCard(
                  product: product,
                  onRemove: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return DialogDeletedProduct(product: product);
                      },
                    );
                  },
                  onEdit: () {
                    debugPrint('Editando producto: ${product.toMap()}');
                    context.read<DevolucionesBloc>().add(
                      ChangeStateIsDialogVisibleEvent(true),
                    );
                    context.read<DevolucionesBloc>().add(
                      LoadCurrentProductEvent(product.toProduct()),
                    );
                    showDialog(
                      context: context,
                      builder: (context) {
                        return DialogEditProduct(
                          functionValidate: (value) {
                            validateQuantity(value);
                          },
                          focusNode: focusNode4,
                          focusNodeQuantityManual: focusNode5,
                          controller: _controllerQuantity,
                          isEdit: true,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 5), // Espacio inferior
          Padding(
            padding: const EdgeInsets.only(right: 50),
            child: ElevatedButton(
              onPressed: () {
                //verficiamos que tengmos ubicacion y tercero
                if (devolucionesBloc.currentLocation.name == null &&
                    devolucionesBloc
                            .configurations
                            .result
                            ?.result
                            ?.returnsLocationDestOption ==
                        "dynamic") {
                  Get.snackbar(
                    '360 Software Informa',
                    'Debe seleccionar una ubicación destino',
                    backgroundColor: white,
                    colorText: primaryColorApp,
                    icon: const Icon(Icons.error, color: Colors.red),
                  );
                  return;
                }
                if (!devolucionesBloc.almacenIsOk) {
                  Get.snackbar(
                    '360 Software Informa',
                    'Debe seleccionar un almacén',
                    backgroundColor: white,
                    colorText: primaryColorApp,
                    icon: const Icon(Icons.error, color: Colors.red),
                  );
                  return;
                }
                if (devolucionesBloc.currentTercero.name == null) {
                  Get.snackbar(
                    '360 Software Informa',
                    'Debe seleccionar un proveedor',
                    backgroundColor: white,
                    colorText: primaryColorApp,
                    icon: const Icon(Icons.error, color: Colors.red),
                  );
                  return;
                }

                //verificamos que tengamos productos
                if (devolucionesBloc.productosDevolucion.isEmpty) {
                  Get.snackbar(
                    '360 Software Informa',
                    'Debe agregar al menos un producto a la devolución',
                    backgroundColor: white,
                    colorText: primaryColorApp,
                    icon: const Icon(Icons.error, color: Colors.red),
                  );
                  return;
                }
                devolucionesBloc.add(SendDevolucionEvent());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColorApp,
                minimumSize: (Size(size.width * 0.7, 30)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('CREAR DEVOLUCION', style: TextStyle(color: white)),
            ),
          ),
          const SizedBox(height: 10), // Espacio inferior
        ],
      ),
    );
  }

  // Widget auxiliar para el campo de entrada de código de barras
}
