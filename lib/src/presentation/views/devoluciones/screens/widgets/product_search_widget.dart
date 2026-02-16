// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/widgets/keyboard_widget.dart';

class SearchProductDevScreen extends StatefulWidget {
  const SearchProductDevScreen({Key? key}) : super(key: key);

  @override
  State<SearchProductDevScreen> createState() => _SearchProductDevScreenState();
}

class _SearchProductDevScreenState extends State<SearchProductDevScreen> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return BlocConsumer<DevolucionesBloc, DevolucionesState>(
      listener: (context, state) {},
      builder: (context, state) {
        final bloc = context.read<DevolucionesBloc>();
        return WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            backgroundColor: white,
            body: Column(
              children: [
                _AppBarInfo(size: size),
                _SearchBar(size: size),
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
                        bloc.add(ShowKeyboardEvent(false));
                        FocusScope.of(context).unfocus();
                        bloc.add(ChangeStateIsDialogVisibleEvent(false));
                        bloc.add(GetProductEvent(
                          selectedProduct.barcode ?? '',
                          true,
                          selectedProduct.productId ?? 0,
                        ));
                        Navigator.pop(context);
                        print(
                            'producto seleccionado ${bloc.productosFilters[selectedIndex!].toMap()}');
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
                    onchanged: () {
                      bloc.add(SearchProductEvent(
                          bloc.searchControllerProducts.text));
                    },
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
                _buildProductRow(
                    'Nombre',
                    context
                        .read<DevolucionesBloc>()
                        .productosFilters[index]
                        .name,
                    isError: false),
                _buildProductRow(
                    'Barcode',
                    context
                        .read<DevolucionesBloc>()
                        .productosFilters[index]
                        .barcode,
                    isError: context
                                .read<DevolucionesBloc>()
                                .productosFilters[index]
                                .barcode ==
                            null ||
                        context
                            .read<DevolucionesBloc>()
                            .productosFilters[index]
                            .barcode!
                            .isEmpty),
                _buildProductRow(
                    'Code',
                    context
                        .read<DevolucionesBloc>()
                        .productosFilters[index]
                        .code,
                    isError: context
                                .read<DevolucionesBloc>()
                                .productosFilters[index]
                                .code ==
                            null ||
                        context
                            .read<DevolucionesBloc>()
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: white),
                  onPressed: () {
                    context
                        .read<DevolucionesBloc>()
                        .searchControllerProducts
                        .clear();
                    context
                        .read<DevolucionesBloc>()
                        .add(ShowKeyboardEvent(false));
                    Navigator.pop(context);
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
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({super.key, required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        elevation: 3,
        child: TextFormField(
          readOnly: context.read<UserBloc>().fabricante.contains("Zebra"),
          controller: context.read<DevolucionesBloc>().searchControllerProducts,
          textAlignVertical: TextAlignVertical.center,
          showCursor: true,
          style: const TextStyle(color: black, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: grey, size: 20),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close, color: grey, size: 20),
              onPressed: () {
                context
                    .read<DevolucionesBloc>()
                    .searchControllerProducts
                    .clear();
                context.read<DevolucionesBloc>().add(SearchProductEvent(''));
                context.read<DevolucionesBloc>().add(ShowKeyboardEvent(false));
                FocusScope.of(context).unfocus();
              },
            ),
            hintText: "Buscar producto",
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            border: InputBorder.none,
          ),
          onChanged: (value) =>
              context.read<DevolucionesBloc>().add(SearchProductEvent(value)),
          onTap: context.read<UserBloc>().fabricante.contains("Zebra")
              ? () =>
                  context.read<DevolucionesBloc>().add(ShowKeyboardEvent(true))
              : null,
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
