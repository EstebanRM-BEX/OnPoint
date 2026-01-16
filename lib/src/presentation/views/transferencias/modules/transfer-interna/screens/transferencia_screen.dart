import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/transferencias/models/response_transferencias.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/transfer-interna/bloc/transferencia_bloc.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/transfer-interna/screens/tabs/tab1.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/transfer-interna/screens/tabs/tab2.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/transfer-interna/screens/tabs/tab3.dart';

class TransferenciaScreen extends StatefulWidget {
  const TransferenciaScreen({
    super.key,
    this.initialTabIndex = 0,
    required this.transferencia, // Valor por defecto es 0
  });

  final int initialTabIndex; // Nueva propiedad para la posición inicial
  final ResultTransFerencias? transferencia;

  @override
  State<TransferenciaScreen> createState() => _TransferenciaScreenState();
}

class _TransferenciaScreenState extends State<TransferenciaScreen>
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
    return BlocConsumer<TransferenciaBloc, TransferenciaState>(
      listener: (context, state) {},
      builder: (context, state) {
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  //volvemos a llamar las entradas que tenemos guardadas en la bd
                  if (widget.transferencia?.type == 'entrega') {
                    context
                        .read<TransferenciaBloc>()
                        .add(FetchAllEntregaDB(false));
                    Navigator.pushReplacementNamed(
                      context,
                      'list-entrada-productos',
                    );
                  } else if (widget.transferencia?.type == 'transfer') {
                    context
                        .read<TransferenciaBloc>()
                        .add(FetchAllTransferenciasDB(false));

                    Navigator.pushReplacementNamed(
                      context,
                      'transferencias',
                    );
                  }
                },
              ),
              title: Text(
                'DETALLES TRANSFERENCIA',
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
                                .read<TransferenciaBloc>()
                                .listProductsTransfer
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
                          backgroundColor: green,
                          child: Text(
                            context
                                .read<TransferenciaBloc>()
                                .listProductsTransfer
                                .where((element) {
                                  return element.isDoneItem == 1;
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
                      Tab1ScreenTrans(
                        transFerencia: widget.transferencia,
                      ),
                      Tab2ScreenTrans(
                        transFerencia: widget.transferencia,
                      ),
                      Tab3ScreenTrans(
                          // ordenCompra: widget.ordenCompra,
                          ),
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
