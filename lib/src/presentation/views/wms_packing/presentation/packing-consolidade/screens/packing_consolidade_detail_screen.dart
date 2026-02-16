// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/packing_response_model.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-consolidade/bloc/packing_consolidade_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-consolidade/screens/tabs/tab1.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-consolidade/screens/tabs/tab2.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-consolidade/screens/tabs/tab3.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-consolidade/screens/tabs/tab4.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

class PackingConsolidateDetailScreen extends StatefulWidget {
  const PackingConsolidateDetailScreen({
    super.key,
    required this.packingModel,
    this.batchModel,
    this.initialTabIndex = 0, // Valor por defecto es 0
  });

  final PedidoPacking? packingModel;
  final BatchPackingModel? batchModel;
  final int initialTabIndex; // Nueva propiedad para la posición inicial

  @override
  State<PackingConsolidateDetailScreen> createState() =>
      _PackingDetailScreenState();
}

class _PackingDetailScreenState extends State<PackingConsolidateDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Inicializar el TabController con la longitud de las pestañas
    _tabController = TabController(
      length: 4,
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
    final Size size = MediaQuery.sizeOf(context);
    return BlocConsumer<PackingConsolidateBloc, PackingConsolidateState>(
      listener: (context, state) {
        if (state is PackingConsolidateError) {
            showScrollableErrorDialog(state.error);
        }
        if (state is SetPackingsOkState) {
          Get.snackbar(
            '360 Software Informa',
            state.message,
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: Icon(Icons.error, color: Colors.green),
          );
        }
      },
      builder: (context, state) {
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  context
                      .read<PackingConsolidateBloc>()
                      .listOfProductsForPacking
                      .clear();
                  context.read<PackingConsolidateBloc>().add(
                        LoadAllPedidosFromBatchEvent(
                          widget.packingModel?.batchId ?? 0,
                        ),
                      );
                  Navigator.pushReplacementNamed(
                    context,
                    'pedido-packing-consolidate-list',
                    arguments: [widget.batchModel],
                  );
                },
              ),
              title: const Text(
                'PACKING CONSOLIDADO - DETALLE',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              bottom: TabBar(
                controller: _tabController, // Asignar el TabController
                indicatorWeight: 3,
                indicatorPadding: EdgeInsets.symmetric(vertical: 5),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                tabs: [
                  Tab(
                    text: 'Detalles',
                    icon: Icon(
                      Icons.details,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Stack(
                    children: [
                      Tab(
                        text: 'Por hacer',
                        icon: Icon(
                          Icons.pending_actions,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Text(
                            context
                                .read<PackingConsolidateBloc>()
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
                          size: 20,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: yellow,
                          child: Text(
                            context
                                .read<PackingConsolidateBloc>()
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
                        text: ' Listo ',
                        icon: Icon(
                          Icons.done,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: green,
                          child: Text(
                            context
                                .read<PackingConsolidateBloc>()
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
                ],
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
            ),
            body: Column(
              children: [
                const WarningWidgetCubit(isTop: false),
                Expanded(
                  child: TabBarView(
                    controller: _tabController, // Asignar el TabController
                    children: [
                      Tab1Screen(
                        size: size,
                        packingModel: widget.packingModel ?? PedidoPacking(),
                        batchModel: widget.batchModel ?? BatchPackingModel(),
                      ),
                      Tab2Screen(
                        packingModel: widget.packingModel ?? PedidoPacking(),
                        batchModel: widget.batchModel ?? BatchPackingModel(),
                      ),
                      Tab3Screen(),
                      Tab4Screen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DialogNewPackage extends StatelessWidget {
  const DialogNewPackage({super.key, required this.onPackageAdded});

  final Function(String) onPackageAdded;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
          child: Text(
            'Agregar empaque',
            style: TextStyle(
              color: primaryColorApp,
              fontSize: 18,
            ),
          ),
        ),
        content: const SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¿Estás seguro de agregar un empaque?',
                style: TextStyle(color: black),
              ),
              SizedBox(height: 10),
              // Puedes agregar más detalles aquí si es necesario
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Aquí se agrega un nuevo empaque
              onPackageAdded('Nuevo Paquete'); // Cambia esto según tu lógica
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColorApp,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Aceptar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
