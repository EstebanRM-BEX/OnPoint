import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';

class AlmacenesDevolucionesScreen extends StatefulWidget {
  const AlmacenesDevolucionesScreen({super.key});

  @override
  State<AlmacenesDevolucionesScreen> createState() =>
      _AlmacenesDevolucionesScreenState();
}

class _AlmacenesDevolucionesScreenState
    extends State<AlmacenesDevolucionesScreen> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return BlocBuilder<DevolucionesBloc, DevolucionesState>(
      builder: (context, state) {
        final bloc = context.read<DevolucionesBloc>();

        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: primaryColorApp,
            body: SafeArea(
              child: Container(
                color: Colors.white,
                width: size.width,
                height: size.height,
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
                      width: double.infinity,
                      child: BlocBuilder<ConnectionStatusCubit,
                          ConnectionStatus>(
                        builder: (context, connectionStatus) {
                          return Column(
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
                                        Navigator.pushReplacementNamed(
                                            context, 'devoluciones-create');
                                      },
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                          left: size.width * 0.18),
                                      child: const Text(
                                        'ALMACÉN',
                                        style: TextStyle(
                                            color: white, fontSize: 18),
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      height: 55,
                      width: size.width,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Card(
                          color: Colors.white,
                          elevation: 3,
                          child: TextFormField(
                            showCursor: true,
                            textAlignVertical: TextAlignVertical.center,
                            controller: bloc.searchControllerAlmacen,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search,
                                  color: grey, size: 20),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  bloc.searchControllerAlmacen.clear();
                                  bloc.allowedWarehousesFilters =
                                      List.from(bloc.allowedWarehouses);
                                  setState(() {});
                                  FocusScope.of(context).unfocus();
                                },
                                icon: const Icon(Icons.close,
                                    color: grey, size: 20),
                              ),
                              hintText: 'Buscar almacén',
                              hintStyle: const TextStyle(
                                  color: Colors.grey, fontSize: 14),
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              final query = value.toLowerCase();
                              bloc.allowedWarehousesFilters =
                                  query.isEmpty
                                      ? List.from(bloc.allowedWarehouses)
                                      : bloc.allowedWarehouses
                                          .where((w) =>
                                              w.name
                                                  ?.toLowerCase()
                                                  .contains(query) ??
                                              false)
                                          .toList();
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: bloc.allowedWarehousesFilters.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay almacenes disponibles',
                                style: TextStyle(color: grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: bloc.allowedWarehousesFilters.length,
                              itemBuilder: (context, index) {
                                final warehouse =
                                    bloc.allowedWarehousesFilters[index];
                                final isSelected = selectedIndex == index;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 2),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedIndex =
                                            isSelected ? null : index;
                                      });
                                    },
                                    child: Card(
                                      elevation: 3,
                                      color: isSelected
                                          ? Colors.green[100]
                                          : white,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.warehouse_outlined,
                                              color: isSelected
                                                  ? Colors.green
                                                  : primaryColorApp,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                warehouse.name ?? '',
                                                style: TextStyle(
                                                  color: primaryColorApp,
                                                  fontSize: 13,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              const Icon(Icons.check_circle,
                                                  color: Colors.green,
                                                  size: 18),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 10),
                    Visibility(
                      visible: selectedIndex != null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedIndex != null) {
                              final selected =
                                  bloc.allowedWarehousesFilters[selectedIndex!];
                              bloc.add(SelectWarehouseEvent(selected));
                              FocusScope.of(context).unfocus();
                              setState(() => selectedIndex = null);
                              Navigator.pushReplacementNamed(
                                  context, 'devoluciones-create');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColorApp,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: Size(size.width * 0.9, 40),
                          ),
                          child: const Text('Seleccionar',
                              style: TextStyle(color: white)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
