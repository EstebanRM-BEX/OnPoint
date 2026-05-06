import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/features/print_labels/presentation/bloc/print_labels_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';

class PrintLabelsScreen extends StatefulWidget {
  const PrintLabelsScreen({super.key});

  @override
  State<PrintLabelsScreen> createState() => _PrintLabelsScreenState();
}

class _PrintLabelsScreenState extends State<PrintLabelsScreen> {
  int _pendingLoads = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<PrintLabelsBloc>();

      // Si el BLoC ya tiene datos cargados, no volvemos a cargar
      final alreadyLoaded = bloc.ubicaciones.isNotEmpty &&
          bloc.productos.isNotEmpty &&
          bloc.configurations.result != null;

      if (alreadyLoaded) return;

      _pendingLoads = 3;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const DialogLoading(message: 'Cargando interfaz...'),
      );
      bloc
        ..add(GetListLocationsEvent())
        ..add(GetProductsList())
        ..add(LoadConfigurationsUserInfo());
    });
  }

  void _onInitLoadComplete(BuildContext context) {
    _pendingLoads--;
    if (_pendingLoads <= 0) {
      _pendingLoads = 0;
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: primaryColorApp,
      body: BlocListener<PrintLabelsBloc, PrintLabelsState>(
        listener: (context, state) {
          if (state is LoadLocationsSuccess || state is LoadLocationsFailure) {
            _onInitLoadComplete(context);
          } else if (state is GetProductsSuccess ||
              state is GetProductsFailure) {
            _onInitLoadComplete(context);
          } else if (state is ConfigurationLoadedPrintLabels ||
              state is ConfigurationError) {
            _onInitLoadComplete(context);
          }
        },
        child: SafeArea(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                CustomAppBar(),
                SizedBox(
                  width: double.infinity,
                  height: size.height * 0.87,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 10.0),
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: primaryColorApp,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.pushReplacementNamed(
                                  context, 'print-labels-products');
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.description,
                                      color: white),
                                ),
                                title: const Text(
                                  "PRODUCTOS",
                                  style: TextStyle(
                                    color: white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    color: white, size: 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 10.0),
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: primaryColorApp,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.pushReplacementNamed(
                                  context, 'print-labels-locations');
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.location_on,
                                      color: white),
                                ),
                                title: const Text(
                                  "UBICACIONES",
                                  style: TextStyle(
                                    color: white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    color: white, size: 20),
                              ),
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
        ),
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
      builder: (context, status) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: primaryColorApp,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              const WarningWidgetCubit(),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: white),
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/home'),
                  ),
                  const Spacer(),
                  const Text(
                    "IMPRIMIR ETIQUETAS",
                    style: TextStyle(color: white, fontSize: 18),
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
