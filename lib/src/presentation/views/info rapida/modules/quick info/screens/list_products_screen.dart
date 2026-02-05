// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/presentation/providers/network/check_internet_connection.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/bloc/info_rapida_bloc.dart';
import 'package:wms_app/src/presentation/views/user/screens/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';
import 'package:wms_app/src/presentation/widgets/keyboard_widget.dart';

class ListProductsScreen extends StatefulWidget {
  const ListProductsScreen({super.key});

  @override
  State<ListProductsScreen> createState() => _ListProductsScreenState();
}

class _ListProductsScreenState extends State<ListProductsScreen> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return BlocConsumer<InfoRapidaBloc, InfoRapidaState>(
      listener: (context, state) {
        print("state es $state");

        if (state is DeviceNotAuthorized) {
          Navigator.pop(context);
          Get.defaultDialog(
            title: 'Dispositivo no autorizado',
            titleStyle: TextStyle(
                color: primaryColorApp,
                fontWeight: FontWeight.bold,
                fontSize: 16),
            middleText:
                'Este dispositivo no está autorizado para usar la aplicación. su suscripción ha expirado o no está activa, por favor contacte con el administrador.',
            middleTextStyle: TextStyle(color: black, fontSize: 14),
            backgroundColor: Colors.white,
            radius: 10,
            barrierDismissible:
                false, // Evita que se cierre al tocar fuera del diálogo
            onWillPop: () async => false,
          );
        } else if (state is NeedUpdateVersionState) {
          Get.snackbar(
            '360 Software Informa',
            'Hay una nueva versión disponible. Actualiza desde la configuración de la app, pulsando el nombre de usuario en el Home',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: Icon(Icons.error, color: Colors.amber),
            showProgressIndicator: true,
            duration: Duration(seconds: 5),
          );
        } else if (state is InfoRapidaError) {
          Navigator.pop(context);
          Get.snackbar(
            '360 Software Informa',
            'No se encontró producto, lote, paquete ni ubicación con ese código de barras',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.error, color: Colors.red),
          );
        } else if (state is InfoRapidaLoading) {
          showDialog(
            context: context,
            builder: (_) =>
                const DialogLoading(message: "Buscando informacion..."),
          );
        } else if (state is InfoRapidaLoaded) {
          Navigator.pop(context); // Cierra el loader

          // ✅ CORRECCIÓN 1: Evitar Crash si el resultado es nulo
          if (state.infoRapidaResult == null) {
            Get.snackbar(
              'Aviso',
              'La búsqueda no arrojó datos válidos.',
              backgroundColor: white,
              colorText: Colors.orange,
              icon: const Icon(Icons.warning, color: Colors.orange),
            );
            return;
          }

          Get.snackbar(
            '360 Software Informa',
            'Información encontrada',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.check_circle, color: Colors.green),
          );

          // ✅ CORRECCIÓN 2: Bloque Try-Catch para "Bad state: No element"
          // Si infoRapidaResult intenta acceder a lista.first y está vacía, capturamos el error.
          try {
            final route = state.infoRapidaResult!.type == 'product'
                ? 'product-info'
                : 'location-info';

            Navigator.pushReplacementNamed(
              context,
              route,
              arguments:
                  route == 'location-info' ? [state.infoRapidaResult] : null,
            );
          } catch (e) {
            print("Error al procesar resultado: $e");
            Get.snackbar(
              'Error',
              'Error al procesar los datos encontrados.',
              backgroundColor: white,
              colorText: Colors.red,
              icon: const Icon(Icons.error, color: Colors.red),
            );
          }
        }
      },
      builder: (context, state) {
        final bloc = context.read<InfoRapidaBloc>();

        return WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            backgroundColor: white,
            body: Column(
              children: [
                _AppBarInfo(size: size),
                //*barra de buscar
                DynamicSearchBar(
                  controller: bloc.searchControllerProducts,
                  hintText: "Buscar producto",
                  onSearchChanged: (value) {
                    bloc.add(SearchProductEvent(value));
                  },
                  onSearchCleared: () {
                    bloc.searchControllerProducts.clear();
                    bloc.add(SearchProductEvent(''));
                    bloc.add(
                        ShowKeyboardInfoEvent(false, TextEditingController()));
                    Future.microtask(() {
                      if (mounted) {
                        FocusScope.of(context).unfocus();
                      }
                    });
                  },
                  onTap: () {
                    bloc.add(
                        ShowKeyboardInfoEvent(true, TextEditingController()));
                  },
                ),
                Expanded(
                  child: bloc.productosFilters.isEmpty
                      ? const _NoProductsMessage()
                      : ListView.builder(
                          itemCount: bloc.productosFilters.length,
                          itemBuilder: (_, index) {
                            return ProductListTile(
                              index: index,
                              isSelected: selectedIndex == index,
                              onSelect: () {
                                setState(() => selectedIndex = index);
                              },
                            );
                          },
                        ),
                ),

                if (selectedIndex != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        final selectedProduct =
                            bloc.productosFilters[selectedIndex!];
                        bloc.add(ShowKeyboardInfoEvent(
                            false, TextEditingController()));
                        FocusScope.of(context).unfocus();
                        bloc.add(GetInfoRapida(
                          selectedProduct.productId.toString(),
                          true,
                          true,
                          false,
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColorApp,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size(size.width * 0.9, 40),
                      ),
                      child: const Text("Seleccionar",
                          style: TextStyle(color: white)),
                    ),
                  ),
                if (bloc.isKeyboardVisible &&
                    context.read<UserBloc>().fabricante.contains("Zebra"))
                  CustomKeyboard(
                    isLogin: false,
                    controller: bloc.searchControllerProducts,
                    onchanged: () => bloc.add(
                        SearchProductEvent(bloc.searchControllerProducts.text)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProductListTile extends StatelessWidget {
  const ProductListTile({
    super.key,
    required this.index,
    required this.isSelected,
    required this.onSelect,
  });

  final int index;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: onSelect,
        child: Card(
          elevation: 3,
          color: isSelected ? Colors.green[100] : white,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductRow('Nombre',
                    context.read<InfoRapidaBloc>().productosFilters[index].name,
                    isError: false),
                _buildProductRow(
                    'Barcode',
                    context
                        .read<InfoRapidaBloc>()
                        .productosFilters[index]
                        .barcode,
                    isError: context
                                .read<InfoRapidaBloc>()
                                .productosFilters[index]
                                .barcode ==
                            null ||
                        context
                            .read<InfoRapidaBloc>()
                            .productosFilters[index]
                            .barcode!
                            .isEmpty),
                _buildProductRow('Code',
                    context.read<InfoRapidaBloc>().productosFilters[index].code,
                    isError: context
                                .read<InfoRapidaBloc>()
                                .productosFilters[index]
                                .code ==
                            null ||
                        context
                            .read<InfoRapidaBloc>()
                            .productosFilters[index]
                            .code!
                            .isEmpty),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductRow(String label, String? value, {bool isError = false}) {
    final displayValue =
        (value == null || value.isEmpty) ? 'Sin ${label.toLowerCase()}' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: black, fontSize: 12)),
          Expanded(
            child: Text(
              displayValue,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isError ? red : primaryColorApp,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBarInfo extends StatelessWidget {
  const _AppBarInfo({super.key, required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: primaryColorApp,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      width: double.infinity,
      child: BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
        builder: (context, status) => Column(
          children: [
            const WarningWidgetCubit(),
            Padding(
              padding: EdgeInsets.only(
                  top: status != ConnectionStatus.online ? 0 : 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: white),
                    onPressed: () {
                      context
                          .read<InfoRapidaBloc>()
                          .searchControllerProducts
                          .clear();
                      context.read<InfoRapidaBloc>().add(ShowKeyboardInfoEvent(
                          false, TextEditingController()));
                      Navigator.pushReplacementNamed(context, 'info-rapida');
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: size.width * 0.22),
                    child: const Text('PRODUCTOS',
                        style: TextStyle(color: white, fontSize: 18)),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoProductsMessage extends StatelessWidget {
  const _NoProductsMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text('No hay productos', style: TextStyle(fontSize: 14, color: grey)),
        Text('No tiene productos en la base de datos',
            style: TextStyle(fontSize: 12, color: grey)),
        SizedBox(height: 60),
      ],
    );
  }
}
