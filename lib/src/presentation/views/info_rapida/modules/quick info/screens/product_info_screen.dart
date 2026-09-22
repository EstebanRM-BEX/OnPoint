// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/shared/widgets/auth/auth_brand_gradient.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/info_rapida/models/update_product_request.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/quick%20info/bloc/info_rapida_bloc.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/quick%20info/widgets/location_card.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/quick%20info/widgets/product_detail_card.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

class ProductInfoScreen extends StatelessWidget {
  const ProductInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BlocConsumer<InfoRapidaBloc, InfoRapidaState>(
      listener: (context, state) {
        debugPrint("state product info 👹 $state");
        if (state is UpdateProductSuccess) {
          Get.snackbar(
            '360 Software Informa',
            'Producto actualizado exitosamente',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.check_circle, color: Colors.green),
          );
        } else if (state is UpdateProductFailure) {
          Get.snackbar(
            '360 Software Informa',
            state.error,
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.error, color: Colors.red),
          );
        } else if (state is ViewProductImageSuccess) {
          showImageDialog(context, state.imageUrl);
        } else if (state is ViewProductImageFailure) {
          showScrollableErrorDialog(state.error);
        }
      },
      builder: (context, state) {
        final bloc = context.read<InfoRapidaBloc>();
        final product = bloc.infoRapidaResult.result;

        if (product == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.pushReplacementNamed(
                context,
                'info-rapida',
                arguments: [bloc],
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'No se pudo cargar la información del producto',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
          return Scaffold(
            backgroundColor: white,
            body: Center(
              child: CircularProgressIndicator(color: primaryColorApp),
            ),
          );
        }

        final referenceController = TextEditingController(
          text: product.referencia ?? '',
        );
        final priceController = TextEditingController(
          text: product.precio != null ? '${product.precio}' : '',
        );
        final pesoController = TextEditingController(
          text: product.peso != null ? '${product.peso}' : '',
        );
        final volumenController = TextEditingController(
          text: product.volumen != null ? '${product.volumen}' : '',
        );
        final barcodeController = TextEditingController(
          text: product.codigoBarras ?? '',
        );
        final nameController = TextEditingController(
          text: product.nombre ?? '',
        );

        void submitUpdate() {
          if (nameController.text.isEmpty ||
              barcodeController.text.isEmpty ||
              referenceController.text.isEmpty ||
              priceController.text.isEmpty ||
              pesoController.text.isEmpty ||
              volumenController.text.isEmpty) {
            Get.snackbar(
              '360 Software Informa',
              'Por favor, complete todos los campos',
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: const Icon(Icons.check_circle, color: Colors.red),
            );
            return;
          }

          bloc.add(
            UpdateProductEvent(
              UpdateProductRequest(
                productId: product.id ?? 0,
                name: nameController.text,
                barcode: barcodeController.text,
                defaultCode: referenceController.text,
                listPrice: priceController.text,
                weight: pesoController.text,
                volume: volumenController.text,
              ),
            ),
          );
        }

        void transferLocation(dynamic ubicacion) async {
          showDialog(
            context: context,
            builder: (dialogContext) {
              return const DialogLoading(message: "Cargando informacion...");
            },
          );

          // Da tiempo a que el diálogo se pinte antes de navegar (comportamiento
          // preexistente, sin cambios funcionales).
          await Future.delayed(const Duration(seconds: 1));

          if (context.mounted) {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(
              context,
              'transfer-info',
              arguments: [product, ubicacion, bloc],
            );
          }
        }

        return WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            // Mismo color que el cuerpo: si difiere del degradado del header
            // se ve una franja plana detrás del status bar, separada del
            // header curvo (el SafeArea de abajo no cubre esa franja).
            backgroundColor: Colors.grey.shade50,
            body: SafeArea(
              // El header pinta su propio SafeArea por dentro para que el
              // degradado llegue hasta arriba del todo (detrás del status
              // bar/notch) en vez de cortarse ahí.
              top: false,
              child: Container(
                width: size.width,
                height: size.height,
                color: Colors.grey.shade50,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppBar(size: size),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                        child: ProductDetailCard(
                          product: product,
                          isEditMode: bloc.isEdit,
                          isExpanded: bloc.isExpanded,
                          nameController: nameController,
                          referenceController: referenceController,
                          priceController: priceController,
                          pesoController: pesoController,
                          volumenController: volumenController,
                          barcodeController: barcodeController,
                          onViewImage: () {
                            context.read<InfoRapidaBloc>().add(
                              ViewProductImageEvent(product.id ?? 0),
                            );
                          },
                          onToggleExpanded: () {
                            context.read<InfoRapidaBloc>().add(
                              ToggleProductExpansionEvent(!bloc.isExpanded),
                            );
                          },
                          onSubmitUpdate: submitUpdate,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Row(
                          children: [
                            Text(
                              "Ubicaciones",
                              style: TextStyle(
                                color: Colors.grey.shade900,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColorApp.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${bloc.ubicacionesProducto?.length ?? 0} activas',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColorApp,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "Ordenar",
                              style: TextStyle(
                                color: primaryColorApp,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: primaryColorApp,
                                size: 20,
                              ),
                              onSelected: (value) {
                                final bloc = context.read<InfoRapidaBloc>();
                                switch (value) {
                                  case 'location_asc':
                                    bloc.add(
                                      SortLocationsEvent('location', true),
                                    );
                                    break;
                                  case 'location_desc':
                                    bloc.add(
                                      SortLocationsEvent('location', false),
                                    );
                                    break;
                                  case 'lote_asc':
                                    bloc.add(SortLocationsEvent('lote', true));
                                    break;
                                  case 'lote_desc':
                                    bloc.add(SortLocationsEvent('lote', false));
                                    break;
                                  case 'date_asc':
                                    bloc.add(SortLocationsEvent('date', true));
                                    break;
                                  case 'date_desc':
                                    bloc.add(SortLocationsEvent('date', false));
                                    break;
                                  case 'date_asc_entrada':
                                    bloc.add(
                                      SortLocationsEvent('entrada', true),
                                    );
                                    break;
                                  case 'date_desc_entrada':
                                    bloc.add(
                                      SortLocationsEvent('entrada', false),
                                    );
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      enabled: false,
                                      height: 30,
                                      child: Text(
                                        'UBICACIÓN',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'location_asc',
                                      height: 40,
                                      child: Row(
                                        children: [
                                          Icon(Icons.arrow_upward, size: 16),
                                          SizedBox(width: 8),
                                          Text(
                                            'Nombre (A-Z)',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'location_desc',
                                      height: 40,
                                      child: Row(
                                        children: [
                                          Icon(Icons.arrow_downward, size: 16),
                                          SizedBox(width: 8),
                                          Text(
                                            'Nombre (Z-A)',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem<String>(
                                      enabled: false,
                                      height: 30,
                                      child: Text(
                                        'LOTE',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'lote_asc',
                                      height: 40,
                                      child: Row(
                                        children: [
                                          Icon(Icons.arrow_upward, size: 16),
                                          SizedBox(width: 8),
                                          Text(
                                            'Ascendente (A-Z)',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'lote_desc',
                                      height: 40,
                                      child: Row(
                                        children: [
                                          Icon(Icons.arrow_downward, size: 16),
                                          SizedBox(width: 8),
                                          Text(
                                            'Descendente (Z-A)',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem<String>(
                                      enabled: false,
                                      height: 30,
                                      child: Text(
                                        'FECHA CADUCIDAD',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'date_asc',
                                      height: 40,
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_month, size: 16),
                                          SizedBox(width: 8),
                                          Text(
                                            'Más Próximas',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'date_desc',
                                      height: 40,
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_month, size: 16),
                                          SizedBox(width: 8),
                                          Text(
                                            'Más Lejanas',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      enabled: false,
                                      height: 30,
                                      child: Text(
                                        'FECHA ENTRADA',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'date_asc_entrada',
                                      height: 40,
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_month, size: 16),
                                          SizedBox(width: 8),
                                          Text(
                                            'Más Antiguas',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'date_desc_entrada',
                                      height: 40,
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_month, size: 16),
                                          SizedBox(width: 8),
                                          Text(
                                            'Más Recientes',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: DynamicSearchBar(
                          controller: bloc.searchControllerLocation,
                          focusNode: bloc.searchLocationFocusNode,
                          hintText: "Buscar ubicación (ej. CVC, 50-P01)...",
                          // watchdog: reabre el teclado si el IME del PDA
                          // (Zebra/Urovo/Chainway) lo cierra solo.
                          persistentKeyboard: true,
                          onSearchChanged: (value) {
                            bloc.add(SearchLocationProductsEvent(value));
                          },
                          onSearchCleared: () {
                            bloc.searchControllerLocation.clear();
                            bloc.add(SearchLocationProductsEvent(''));
                          },
                          onTap: () {},
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          cacheExtent: 500, // Precarga 500px adicionales
                          itemCount: bloc.ubicacionesProducto?.length ?? 0,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (contextList, index) {
                            if (product.ubicaciones == null ||
                                index >= (product.ubicaciones?.length ?? 0)) {
                              return const SizedBox.shrink();
                            }

                            final ubicacion = bloc.ubicacionesProducto?[index];
                            if (ubicacion == null) {
                              return const SizedBox.shrink();
                            }

                            return LocationCard(
                              ubicacion: ubicacion,
                              onTransfer: () => transferLocation(ubicacion),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AppBar extends StatelessWidget {
  const AppBar({super.key, required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    bool showEditIcon = false;
    try {
      final configurations = context.read<InfoRapidaBloc>().configurations;
      if (configurations.result != null) {
        showEditIcon =
            configurations.result?.result?.updateItemInventory == true;
      }
    } catch (e) {
      showEditIcon = false;
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: authBrandGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      width: double.infinity,
      // El degradado ya pinta detrás del status bar (Scaffold no le agrega
      // top padding); este SafeArea solo empuja el contenido interno hacia
      // abajo del notch, sin dejar una franja de color distinta encima.
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            const WarningWidgetCubit(),
            Padding(
              padding: EdgeInsets.only(
                left: size.width * 0.05,
                right: size.width * 0.05,
                bottom: 14,
                top: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Material(
                    color: Colors.white.withOpacity(0.15),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        final bloc = context.read<InfoRapidaBloc>();
                        bloc.searchControllerLocation.clear();
                        bloc.add(IsEditEvent(false));
                        bloc.add(GetProductsList());
                        Navigator.pushReplacementNamed(
                          context,
                          'info-rapida',
                          arguments: [bloc],
                        );
                      },
                      child: const SizedBox.square(
                        dimension: 40,
                        child: Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    "INFORMACIÓN RÁPIDA",
                    style: TextStyle(
                      color: white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Visibility(
                    visible: showEditIcon,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: GestureDetector(
                      onTap: () {
                        context.read<InfoRapidaBloc>().add(
                          IsEditEvent(!context.read<InfoRapidaBloc>().isEdit),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          context.read<InfoRapidaBloc>().isEdit
                              ? Icons.close
                              : Icons.edit,
                          color: white,
                          size: 20,
                        ),
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
  }
}
