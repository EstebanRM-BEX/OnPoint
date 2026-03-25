// ignore_for_file: public_member_api_docs, sort_constructors_first, no_leading_underscores_for_local_identifiers
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';

import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/conteo/models/conteo_response_model.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/bloc/conteo_bloc.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/tabs/tab1.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/tabs/tab2.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/tabs/tab3.dart';

class ConteoScreen extends StatefulWidget {
  final int initialTabIndex; // Nueva propiedad para la posición inicial
  final DatumConteo ordenConteo;

  const ConteoScreen({
    super.key,
    this.initialTabIndex = 0,
    required this.ordenConteo,
  });

  @override
  State<ConteoScreen> createState() => _ConteoScreenState();
}

class _ConteoScreenState extends State<ConteoScreen>
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
      child: BlocBuilder<ConteoBloc, ConteoState>(
        builder: (context, state) {
          final conteoBloc = context.read<ConteoBloc>();

          Map<String, List<CountedLine>> _groupByLocation(
              List<CountedLine> productos) {
            final map = <String, List<CountedLine>>{};
            for (final producto in productos) {
              final location = producto.locationName ?? 'Sin ubicación';
              map.putIfAbsent(location, () => []).add(producto);
            }
            return map;
          }

          final productosContados = conteoBloc.lineasContadas
              .where((element) => element.isDoneItem == 1)
              .toList();

          final productosPorContar = conteoBloc.lineasContadas
              .where((element) => element.isDoneItem != 1)
              .toList();

          return Scaffold(
            backgroundColor: primaryColorApp,
            appBar: AppBar(
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  //volvemos a llamar las entradas que tenemos guardadas en la bd

                  context.read<ConteoBloc>().add(GetConteosFromDBEvent());

                  Navigator.pushReplacementNamed(
                    context,
                    'conteo',
                  );
                },
              ),
              title: Text(
                'DETALLE DE CONTEO',
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
                            productosPorContar.length.toString(),
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
                            productosContados.length.toString(),
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
                color: white,
                child: Column(
                  children: [
                    const WarningWidgetCubit(isTop: false),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController, // Asignar el TabController
                        children: [
                          Tab1ScreenConteo(
                            ordenConteo: widget.ordenConteo,
                          ),
                          Tab2ScreenConteo(
                            ordenConteo: widget.ordenConteo,
                          ),
                          Tab3ScreenConteo(
                            ordenConteo: widget.ordenConteo,
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
      ),
    );
  }
}
