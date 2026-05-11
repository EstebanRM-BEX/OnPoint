// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/printing/presentation/widgets/modal_printers_list.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/bloc/packing_pedido_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/screens/tabs/tab1.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/screens/tabs/tab2.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/screens/tabs/tab3.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/screens/tabs/tab4.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/screens/tabs/tab5.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

class PackingPedidoDetailScreen extends StatefulWidget {
  const PackingPedidoDetailScreen({
    super.key,
    this.initialTabIndex = 0, // Valor por defecto es 0
  });

  final int initialTabIndex; // Nueva propiedad para la posición inicial

  @override
  State<PackingPedidoDetailScreen> createState() => _PackingDetailScreenState();
}

class _PackingDetailScreenState extends State<PackingPedidoDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Inicializar el TabController con la longitud de las pestañas
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex, // Posición inicial
    );
  }

  @override
  void dispose() {
    _tabController.dispose(); // Desechar el TabController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PackingPedidoBloc, PackingPedidoState>(
      listener: (context, state) {
        if (state is WmsPackingErrorState) {
          showScrollableErrorDialog(state.error);
        }
      },
      builder: (context, state) {
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Scaffold(
            backgroundColor: primaryColorApp,
            appBar: AppBar(
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  context.read<PackingPedidoBloc>().add(
                        LoadPackingPedidoFromDBEvent(),
                      );
                  Navigator.pushReplacementNamed(
                    context,
                    'list-packing',
                  );
                },
              ),
              title: const Text(
                'PACKING - DETAIL',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.print,
                    color: Colors.white,
                    size: 25,
                  ),
                  onPressed: () {
                    ModalPrintersList.show(context,
                        resIds: [
                          context.read<PackingPedidoBloc>().currentPedidoPack.id
                        ],
                        companyId: context
                            .read<PackingPedidoBloc>()
                            .currentPedidoPack
                            .warehouseId);
                  },
                ),
              ],
              bottom: TabBar(
                controller: _tabController, // Asignar el TabController
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: EdgeInsets.symmetric(vertical: 2),
                labelStyle: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                tabs: [
                  Tab(
                    text: 'Detalles',
                    icon: Icon(
                      Icons.details,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  Stack(
                    children: [
                      Tab(
                        text: 'Por hacer',
                        icon: Icon(
                          Icons.pending_actions,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Text(
                            context
                                .read<PackingPedidoBloc>()
                                .listOfProductosProgress
                                .length
                                .toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      Tab(
                        text: 'Preparado',
                        icon: Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: yellow,
                          child: Text(
                            context
                                .read<PackingPedidoBloc>()
                                .productsDone
                                .length
                                .toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      Tab(
                        text: 'Listo',
                        icon: Icon(
                          Icons.done,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: green,
                          child: Text(
                            context
                                .read<PackingPedidoBloc>()
                                .productsDonePacking
                                .length
                                .toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      Tab(
                        text: 'Paquetes',
                        icon: Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: green,
                          child: Text(
                            context
                                .read<PackingPedidoBloc>()
                                .packages
                                .length
                                .toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
            ),
            body: SafeArea(
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    const WarningWidgetCubit(isTop: false),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController, // Asignar el TabController
                        children: [
                          const Tab1PedidoScreen(),
                          const Tab2PedidoScreen(),
                          const Tab3PedidoScreen(),
                          const Tab4PedidoScreen(),
                          const Tab5Screen(),
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
    );
  }
}
