import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/recepcion_response_batch_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/batchs/bloc/recepcion_batch_bloc.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/batchs/tabs/tab1.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/batchs/tabs/tab2.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/batchs/tabs/tab3.dart';

class RecepcionBatchScreen extends StatefulWidget {
  const RecepcionBatchScreen({
    super.key,
    required this.recepcionBatch,
    this.initialTabIndex = 0, // Valor por defecto es 0
  });

  final ReceptionBatch? recepcionBatch;
  final int initialTabIndex; // Nueva propiedad para la posición inicial

  @override
  State<RecepcionBatchScreen> createState() => _RecepcionScreenState();
}

class _RecepcionScreenState extends State<RecepcionBatchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Inicializar el TabController con la longitud de las pestañas
    _tabController = TabController(
      length: 3,
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
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocBuilder<RecepcionBatchBloc, RecepcionBatchState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: white,
            appBar: AppBar(
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  //volvemos a llamar las entradas que tenemos guardadas en la bd
                  // context.read<RecepcionBatchBloc>().add(FetchRecepcionBatchEventFromBD());
                  Navigator.pushReplacementNamed(
                    context,
                    'list-recepction-batch',
                  );
                },
              ),
              title: Text(
                'RECEPCIÓN - BATCH',
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
                  fontSize: 12,
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
                                .read<RecepcionBatchBloc>()
                                .listProductsEntrada
                                .where((element) {
                                  return (element.isSeparate == 0 ||
                                          element.isSeparate == null) &&
                                      (element.isDoneItem == 0 ||
                                          element.isDoneItem == null);
                                })
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
                                .read<RecepcionBatchBloc>()
                                .listProductsEntrada
                                .where((element) {
                                  return element.isDoneItem == 1 ||
                                      element.isDoneItem == true;
                                })
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
                      Tab1ScreenRecepBatch(
                        ordenCompra: widget.recepcionBatch,
                      ),
                      Tab2ScreenRecepBatch(
                        ordenCompra: widget.recepcionBatch,
                      ),
                      Tab3ScreenRecepBatch(
                        ordenCompra: widget.recepcionBatch,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
