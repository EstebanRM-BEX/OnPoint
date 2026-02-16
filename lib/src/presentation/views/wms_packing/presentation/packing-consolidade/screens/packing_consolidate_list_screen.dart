// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/packing_response_model.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-consolidade/bloc/packing_consolidade_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/keyboard_widget.dart';

import '../../../../../providers/network/cubit/warning_widget_cubit.dart';

class PackingConsolidateListScreen extends StatefulWidget {
  const PackingConsolidateListScreen({super.key, this.batchModel});

  final BatchPackingModel? batchModel;

  @override
  State<PackingConsolidateListScreen> createState() =>
      _PackingConsolidateListScreenState();
}

bool isSearch = false;

class _PackingConsolidateListScreenState
    extends State<PackingConsolidateListScreen> with WidgetsBindingObserver {
  FocusNode focusNodeBuscar = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _handlePedidoTap(BuildContext context, PedidoPacking pedido,
      BuildContext contextBuilder) async {
    context.read<PackingConsolidateBloc>().add(ShowDetailvent(true));

    // Limpiamos la lista de paquetes
    context.read<PackingConsolidateBloc>().packages = [];
    // Pedimos todos los productos de un pedido
    context.read<PackingConsolidateBloc>().add(LoadAllProductsFromPedidoEvent(
          pedido.id ?? 0,
        ));

    showDialog(
      context: context,
      barrierDismissible:
          false, // No permitir que el usuario cierre el diálogo manualmente
      builder: (_) => const DialogLoading(
        message: 'Cargando interfaz...',
      ),
    );

    await Future.delayed(const Duration(seconds: 1));
    Navigator.pop(context);

    //cerramos el teclado focus
    FocusScope.of(context).unfocus();

    // Viajamos a la vista de detalle de un pedido
    Navigator.pushReplacementNamed(context, 'packing-consolidate-detail',
        arguments: [pedido, widget.batchModel, 0]);
    print('Pedido seleccionado: ${pedido.toMap()}');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return BlocConsumer<PackingConsolidateBloc, PackingConsolidateState>(
      listener: (context, state) {},
      builder: (context, state) {
//*instancio del bloc
        final packingBloc = context.read<PackingConsolidateBloc>();

        //*pedido consolidado
        final packing = packingBloc.pedido;
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Scaffold(
            bottomNavigationBar:
                context.read<PackingConsolidateBloc>().isKeyboardVisible &&
                        context.read<UserBloc>().fabricante.contains("Zebra")
                    ? CustomKeyboard(
                        isLogin: false,
                        controller: context
                            .read<PackingConsolidateBloc>()
                            .searchControllerPedido,
                        onchanged: () {
                          context.read<PackingConsolidateBloc>().add(
                              SearchPedidoPackingEvent(
                                  context
                                      .read<PackingConsolidateBloc>()
                                      .searchControllerPedido
                                      .text,
                                  widget.batchModel?.id ?? 0));
                        },
                      )
                    : null,
            backgroundColor: Colors.white,
            body: Column(
              children: [
                //*appbar
                Container(
                  decoration: BoxDecoration(
                    color: primaryColorApp,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  width: double.infinity,
                  child: BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
                      builder: (context, status) {
                    context.read<PackingConsolidateBloc>().batch =
                        widget.batchModel;

                    context.read<PackingConsolidateBloc>().listOfOrigins =
                        context.read<PackingConsolidateBloc>().parseOrigins() ??
                            [];

                    return Column(
                      children: [
                        const WarningWidgetCubit(),
                        Padding(
                          padding: EdgeInsets.only(
                              // bottom: 10,
                              top: status != ConnectionStatus.online ? 0 : 25),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.arrow_back, color: white),
                                onPressed: () {
                                  context
                                      .read<PackingConsolidateBloc>()
                                      .add(LoadBatchPackingFromDBEvent());
                                  context
                                      .read<PackingConsolidateBloc>()
                                      .add(ShowKeyboardEvent(false));

                                  context
                                      .read<PackingConsolidateBloc>()
                                      .searchControllerPedido
                                      .clear();
                                  Navigator.pushReplacementNamed(
                                    context,
                                    'list-packing-consolidade',
                                  );
                                },
                              ),
                              Padding(
                                padding:
                                    EdgeInsets.only(left: size.width * 0.08),
                                child: const Text("PACKING CONSOLIDADO",
                                    style:
                                        TextStyle(color: white, fontSize: 18)),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 5,
                    color: white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 15),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(packing.name ?? " ",
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: primaryColorApp,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Row(
                            children: [
                              const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Responsable: ',
                                    style:
                                        TextStyle(fontSize: 12, color: black),
                                  )),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    widget.batchModel?.userName == false ||
                                            widget.batchModel?.userName == ""
                                        ? 'Sin responsable'
                                        : "${widget.batchModel?.userName}",
                                    style: TextStyle(
                                        fontSize: 12, color: primaryColorApp),
                                  )),
                            ],
                          ),
                          Row(
                            children: [
                              Text("Zona de entrega/planilla :",
                                  style: TextStyle(fontSize: 12, color: black)),
                              Flexible(
                                child: Text(packing.zonaEntrega ?? "",
                                    style: const TextStyle(
                                        fontSize: 12, color: primaryColorApp)),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text("Zona TMS:",
                                  style: TextStyle(fontSize: 12, color: black)),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(packing.zonaEntregaTms ?? " ",
                                    style: const TextStyle(
                                        fontSize: 12, color: primaryColorApp)),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text("Cantidad de lineas: ",
                                  style: TextStyle(fontSize: 12, color: black)),
                              Text(
                                  widget.batchModel?.cantidadTotalProductos
                                          .toString() ??
                                      "0",
                                  style: const TextStyle(
                                      fontSize: 12, color: primaryColorApp)),
                            ],
                          ),
                          Row(
                            children: [
                              Text("Cantidad de unidades: ",
                                  style: TextStyle(fontSize: 12, color: black)),
                              Text(
                                  widget.batchModel?.unidadesProductos
                                          .toString() ??
                                      "0",
                                  style: const TextStyle(
                                      fontSize: 12, color: primaryColorApp)),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Tipo de operación:",
                                style: TextStyle(fontSize: 12, color: black)),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: size.width * 0.9,
                            child: Text(packing.tipoOperacion ?? " ",
                                style: const TextStyle(
                                    fontSize: 12, color: primaryColorApp)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Fecha programada: ",
                                    style:
                                        TextStyle(fontSize: 12, color: black),
                                  )),
                              Builder(
                                builder: (context) {
                                  // Verifica si `scheduledDate` es false o null
                                  String displayDate;
                                  if (widget.batchModel?.scheduleddate ==
                                          false ||
                                      widget.batchModel?.scheduleddate ==
                                          null) {
                                    displayDate = 'sin fecha';
                                  } else {
                                    try {
                                      DateTime dateTime = DateTime.parse(widget
                                              .batchModel?.scheduleddate
                                              .toString() ??
                                          ""); // Parsear la fecha
                                      // Formatear la fecha usando Intl
                                      displayDate =
                                          DateFormat('dd MMMM yyyy', 'es_ES')
                                              .format(dateTime);
                                    } catch (e) {
                                      displayDate =
                                          'sin fecha'; // Si ocurre un error al parsear
                                    }
                                  }

                                  return Container(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      displayDate,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 12, color: primaryColorApp),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Center(
                  child: Text(' Expediciones/Packing consolidados',
                      style: TextStyle(fontSize: 14, color: primaryColorApp)),
                ),
                Expanded(
                  // Usamos Expanded para que el ListView ocupe el espacio restante
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 5, bottom: 5),
                    itemCount: packingBloc.listOfPedidos.length,
                    itemBuilder: (context, index) {
                      final String pedido = packingBloc.listOfPedidos[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(
                            Icons.inventory_2_outlined,
                            color: primaryColorApp,
                            size: 15,
                          ),
                          title: Text(
                            pedido,
                            style: const TextStyle(fontSize: 12, color: black),
                          ),
                          onTap: () {
                            // Lógica para navegar o realizar una acción con el pedido
                            print('Abriendo detalle de: $pedido');
                          },
                        ),
                      );
                    },
                  ),
                ),
                Center(
                  child: Text(' Documentos origen ',
                      style: TextStyle(fontSize: 14, color: primaryColorApp)),
                ),
                Expanded(
                  // Usamos Expanded para que el ListView ocupe el espacio restante
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 5),
                    itemCount: packingBloc.listOfPedidos.length,
                    itemBuilder: (context, index) {
                      final String pedido = packingBloc.listOfOrigins[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(
                            Icons.inventory_2_outlined,
                            color: primaryColorApp,
                            size: 10,
                          ),
                          title: Text(
                            pedido,
                            style: const TextStyle(fontSize: 12, color: black),
                          ),
                          onTap: () {
                            // Lógica para navegar o realizar una acción con el pedido
                            print('Abriendo detalle de: $pedido');
                          },
                        ),
                      );
                    },
                  ),
                ),

                ElevatedButton(
                    onPressed: () {
                      _handlePedidoTap(context, packing, context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColorApp,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: Size(size.width * 0.8, 40),
                    ),
                    child: Text(
                      'INICIAR',
                      style: TextStyle(
                        fontSize: 16,
                        color: white,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
