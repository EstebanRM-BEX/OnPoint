import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_bloc.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_event.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_state.dart';
import 'package:wms_app/features/user/domain/entities/user_configuration.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/home/presentation/widgets/background.dart';
import 'package:wms_app/features/home/presentation/widgets/update_app_dialog_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:wms_app/src/presentation/views/inventario/screens/bloc/inventario_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import '../bloc/user_bloc.dart';
import '../widgets/device_info_card.dart';
import '../widgets/permissions_widget.dart';
import '../widgets/user_info_card.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: white,
      body: MultiBlocListener(
        listeners: [
          BlocListener<HomeBloc, HomeState>(
            listener: (context, state) {
              if (state is AppVersionUpdateState) {
                showDialog(
                    context: context, builder: (context) => UpdateAppDialog());
              }
              if (state is AppVersionLoadedState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("No hay actualizaciones disponibles"),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          BlocListener<InventarioBloc, InventarioState>(
            listener: (context, state) {
              debugPrint('state inventario : $state');
              if (state is GetProductsLoadingInventory) {
                showDialog(
                    context: context,
                    builder: (context) => const DialogLoading(
                        message: 'Descargando productos...'));
              }
              if (state is GetProductsSuccess) {
                if (Navigator.canPop(context)) Navigator.pop(context);
                Get.snackbar(
                  '360 Software Informa',
                  "Se han descargado ${state.products.length} productos",
                  backgroundColor: white,
                  colorText: primaryColorApp,
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                );
              }
              if (state is GetProductsFailureInventory) {
                if (Navigator.canPop(context)) Navigator.pop(context);
                Get.snackbar(
                  '360 Software Informa',
                  state.error,
                  backgroundColor: white,
                  colorText: primaryColorApp,
                  icon: const Icon(Icons.error, color: Colors.red),
                );
              }
            },
          ),
          BlocListener<PackagingTypeBloc, PackagingTypeState>(
            listener: (context, state) {
              debugPrint('state packaging type : $state');
              if (state is PackagingTypesLoadInProgress) {
                showDialog(
                    context: context,
                    builder: (context) => const DialogLoading(
                        message: 'Descargando tipos de empaque...'));
              }
              if (state is PackagingTypesLoadSuccess) {
                if (Navigator.canPop(context)) Navigator.pop(context);
                Get.snackbar(
                  '360 Software Informa',
                  "Se han descargado ${state.packagingTypes.length} tipos de empaque",
                  backgroundColor: white,
                  colorText: primaryColorApp,
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                );
              }
              if (state is PackagingTypeLoadFailure) {
                if (Navigator.canPop(context)) Navigator.pop(context);
                Get.snackbar(
                  '360 Software Informa',
                  state.message,
                  backgroundColor: white,
                  colorText: primaryColorApp,
                  icon: const Icon(Icons.error, color: Colors.red),
                );
              }
            },
          ),
        ],
        child: Container(
          width: size.width,
          height: size.height,
          color: primaryColorApp,
          child: Stack(
            children: [
              const Background(),
              BlocConsumer<UserBloc, UserState>(
                listener: (context, state) {
                  if (state is UserError) {
                    showScrollableErrorDialog(state.message);
                  }
                  if (state is DeviceRegistrationSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text("Dispositivo registrado correctamente")),
                    );
                  }
                  if (state is DeviceRegistrationFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text("Error registro: ${state.message}")),
                    );
                  }
                },
                builder: (context, state) {
                  debugPrint('state user page: $state');
                  if (state is UserLoading) {
                    return DialogLoading(message: 'Cargando...');
                  } else if (state is UserLoaded) {
                    return SizedBox(
                      width: size.width,
                      height: size.height,
                      child: Container(
                        padding:
                            const EdgeInsets.only(left: 10, top: 35, right: 10),
                        width: size.width,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildBackButton(context),
                              _buildUpdateCheckButton(context),
                              UserInfoCard(
                                profile: state.configuration.result?.result ??
                                    const UserProfile(),
                                versionApp: state.deviceInfo.appVersion,
                              ),
                              DeviceInfoCard(deviceInfo: state.deviceInfo),
                              _buildActionButtons(context, state),
                              const SizedBox(height: 20),
                              PermissionsWidget(
                                  profile: state.configuration.result?.result ??
                                      const UserProfile()),
                              const SizedBox(height: 20),
                              _buildDeleteDatabaseButton(context),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Card(
      color: white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Card(
              color: white,
              elevation: 2,
              child: IconButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  icon:
                      Icon(Icons.arrow_back, color: primaryColorApp, size: 30)),
            ),
            const SizedBox(width: 10),
            Text("Bienvenido a,  ",
                style: TextStyle(fontSize: 14, color: primaryColorApp)),
            const Text('OnPoint', style: TextStyle(fontSize: 14, color: black))
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateCheckButton(BuildContext context) {
    return Card(
      color: white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: ElevatedButton(
          onPressed: () {
            context.read<HomeBloc>().add(AppVersionEvent());
          },
          style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 30),
              backgroundColor: grey),
          child: const Text(
            "Comprobar actualizaciones",
            style: TextStyle(color: white),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, UserLoaded state) {
    return Card(
      color: white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                context.read<InventarioBloc>().add(GetProductsEvent());
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 30),
                  backgroundColor: grey),
              child: const Text(
                "Descargar productos",
                style: TextStyle(color: white),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                context
                    .read<PackagingTypeBloc>()
                    .add(SyncPackagingTypesEvent());
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 30),
                  backgroundColor: grey),
              child: const Text(
                "Descargar tipos de empaque",
                style: TextStyle(color: white),
              ),
            ),
            // ElevatedButton(
            //   onPressed: () {
            //      final warehouses = state.configuration.result?.result?.allowedWarehouses ?? [];
            //      showDialog(
            //        context: context,
            //        builder: (context) => WarehousesDialog(warehouses: warehouses),
            //      );
            //   },
            //   style: ElevatedButton.styleFrom(
            //       minimumSize: const Size(double.infinity, 30),
            //       backgroundColor: grey),
            //   child: const Text(
            //     "Ver Almacenes",
            //     style: TextStyle(color: white),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  /// Botón para eliminar la base de datos local
  ///
  /// Muestra un diálogo de confirmación antes de proceder con la eliminación.
  /// Sigue las mejores prácticas de Flutter:
  /// - Extrae la lógica del UI a métodos separados
  /// - Maneja el contexto correctamente en operaciones asíncronas
  /// - Proporciona feedback visual al usuario
  Widget _buildDeleteDatabaseButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _showDeleteDatabaseConfirmation(context),
      style: ElevatedButton.styleFrom(backgroundColor: grey),
      child: const Text(
        "Eliminar Base de Datos",
        style: TextStyle(color: white),
      ),
    );
  }

  /// Muestra un diálogo de confirmación para eliminar la base de datos
  ///
  /// Implementa las mejores prácticas:
  /// - Usa Future<void> para operaciones asíncronas
  /// - Verifica mounted antes de usar context después de async
  /// - Maneja errores con try-catch
  /// - Proporciona feedback claro al usuario
  Future<void> _showDeleteDatabaseConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
          child: Text(
            "Eliminar Base de Datos",
            style: TextStyle(color: primaryColorApp, fontSize: 14),
          ),
        ),
        content: const Text(
          "¿Estás seguro de eliminar la base de datos?\n\n"
          "Esta acción no se puede deshacer y perderás todo el progreso "
          "que llevas realizado y está guardado en la base de datos.",
          style: TextStyle(fontSize: 12, color: black),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: grey),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text("Cancelar", style: TextStyle(color: white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );

    // Si el usuario canceló o el diálogo se cerró sin confirmación
    if (confirmed != true) return;

    // Verificar que el widget aún está montado antes de continuar
    if (!mounted) return;

    try {
      // Importar DataBaseSqlite
      await DataBaseSqlite().deleteBDCloseSession();

      // Verificar mounted nuevamente después de la operación asíncrona
      if (!mounted) return;

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Base de datos eliminada correctamente"),
          backgroundColor: Colors.green,
        ),
      );

      // Navegar a home
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      // Verificar mounted antes de mostrar error
      if (!mounted) return;

      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al eliminar la base de datos: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
