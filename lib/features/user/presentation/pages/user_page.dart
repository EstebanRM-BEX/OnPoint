import 'package:flutter/material.dart';
import 'package:wms_app/shared/utils/app_navigation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_bloc.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_event.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_state.dart';
import 'package:wms_app/features/user/domain/entities/user_configuration.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/home/presentation/widgets/update_app_dialog_widget.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:wms_app/features/inventario/presentation/bloc/inventario_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import '../bloc/user_bloc.dart';
import 'package:wms_app/shared/widgets/confirm_delete_dialog.dart';
import '../widgets/config_header.dart';
import '../widgets/danger_zone_button.dart';
import '../widgets/device_info_card.dart';
import '../widgets/network_indicator_card.dart';
import '../widgets/sync_actions_card.dart';
import '../widgets/permissions_widget.dart';
import '../widgets/user_info_card.dart';
import '../widgets/warehouses_dialog.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_warehouses/warehouse_repository.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: MultiBlocListener(
        listeners: [
          BlocListener<HomeBloc, HomeState>(
            listener: (context, state) {
              if (state is AppVersionUpdateState) {
                showDialog(
                  context: context,
                  builder: (context) => UpdateAppDialog(),
                );
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
                  builder: (context) =>
                      const DialogLoading(message: 'Descargando productos...'),
                );
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
                debugPrint("error: ${state.message}");
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
          BlocListener<PackagingTypeBloc, PackagingTypeState>(
            listener: (context, state) {
              debugPrint('state packaging type : $state');
              if (state is PackagingTypesLoadInProgress) {
                showDialog(
                  context: context,
                  builder: (context) => const DialogLoading(
                    message: 'Descargando tipos de empaque...',
                  ),
                );
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
          BlocListener<DevolucionesBloc, DevolucionesState>(
            listener: (context, state) {
              debugPrint('state devoluciones: $state');
              if (state is DownloadAllTercerosLoading) {
                showDialog(
                  context: context,
                  builder: (context) =>
                      const DialogLoading(message: 'Descargando terceros...'),
                );
              }
              if (state is DownloadAllTercerosSuccess) {
                if (Navigator.canPop(context)) Navigator.pop(context);
                Get.snackbar(
                  '360 Software Informa',
                  "Se han descargado ${state.terceros.length} terceros",
                  backgroundColor: white,
                  colorText: primaryColorApp,
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                );
              }
              if (state is DownloadAllTercerosFailure) {
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
        ],
        child: BlocConsumer<UserBloc, UserState>(
          listener: (context, state) {
            if (state is UserError) {
              showScrollableErrorDialog(state.message);
            }
            if (state is UserOfflineWarning) {
              Get.snackbar(
                '360 Software Informa',
                'Sin conexión: mostrando los datos guardados localmente.',
                backgroundColor: white,
                colorText: primaryColorApp,
                icon: const Icon(Icons.cloud_off, color: Colors.orange),
                duration: const Duration(seconds: 3),
              );
            }
            if (state is DownloadUserDataLoading) {
              showDialog(
                context: context,
                builder: (context) => DialogLoading(message: state.message),
              );
            }
            if (state is DownloadUserDataSuccess) {
              if (Navigator.canPop(context)) Navigator.pop(context);
              Get.snackbar(
                '360 Software Informa',
                state.message,
                backgroundColor: white,
                colorText: primaryColorApp,
                icon: const Icon(Icons.check_circle, color: Colors.green),
              );
            }
            if (state is DownloadUserDataError) {
              if (Navigator.canPop(context)) Navigator.pop(context);
              Get.snackbar(
                '360 Software Informa',
                state.message,
                backgroundColor: white,
                colorText: primaryColorApp,
                icon: const Icon(Icons.error, color: Colors.red),
              );
            }
            if (state is DeviceRegistrationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Dispositivo registrado correctamente"),
                ),
              );
            }
            if (state is DeviceRegistrationFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error registro: ${state.message}")),
              );
            }
          },
          builder: (context, state) {
            final bloc = context.read<UserBloc>();
            final loading =
                state is UserLoading ||
                (state is UserOfflineWarning && bloc.userConfiguration == null);
            final ready =
                bloc.userConfiguration != null && bloc.deviceInfo != null;

            return Column(
              children: [
                ConfigHeader(onBack: () => goToScreen(context, '/home')),
                Expanded(
                  child: loading
                      ? const DialogLoading(message: 'Cargando...')
                      : ready
                      ? _buildContent(context, bloc)
                      : const SizedBox.shrink(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserBloc bloc) {
    final profile =
        bloc.userConfiguration?.result?.result ?? const UserProfile();

    // La primera tarjeta sube 20px para solapar la cabecera (diseño).
    return Transform.translate(
      offset: const Offset(0, -20),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          14,
          0,
          14,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          UserInfoCard(
            profile: profile,
            versionApp: bloc.deviceInfo?.appVersion ?? '',
            onCheckUpdates: () =>
                context.read<HomeBloc>().add(AppVersionEvent()),
          ),
          const SizedBox(height: 14),
          DeviceInfoCard(deviceInfo: bloc.deviceInfo!),
          const SizedBox(height: 14),
          _buildSyncActions(context),
          const SizedBox(height: 14),
          PermissionsWidget(profile: profile),
          const SizedBox(height: 14),
          const NetworkIndicatorCard(),
          const SizedBox(height: 24),
          DangerZoneButton(onPressed: _showDeleteDatabaseConfirmation),
        ],
      ),
    );
  }

  Widget _buildSyncActions(BuildContext context) {
    return SyncActionsCard(
      primary: SyncAction(
        label: 'Ver Almacenes',
        icon: Icons.warehouse_outlined,
        onPressed: () async {
          final warehouses = await WarehouseRepository().getAllowedWarehouse();
          if (!context.mounted) return;
          showDialog(
            context: context,
            builder: (_) => WarehousesDialog(warehouses: warehouses),
          );
        },
      ),
      actions: [
        SyncAction(
          label: 'Descargar productos',
          icon: Icons.inventory_2_outlined,
          onPressed: () =>
              context.read<InventarioBloc>().add(GetProductsEvent()),
        ),
        SyncAction(
          label: 'Descargar ubicaciones',
          icon: Icons.place_outlined,
          onPressed: () =>
              context.read<UserBloc>().add(DownloadLocationsEvent()),
        ),
        SyncAction(
          label: 'Descargar novedades',
          icon: Icons.campaign_outlined,
          onPressed: () =>
              context.read<UserBloc>().add(DownloadNoveltiesEvent()),
        ),
        SyncAction(
          label: 'Descargar terceros',
          icon: Icons.people_outline,
          onPressed: () =>
              context.read<DevolucionesBloc>().add(DownloadAllTercerosEvent()),
        ),
        SyncAction(
          label: 'Descargar tipos de empaque',
          icon: Icons.all_inbox_outlined,
          onPressed: () =>
              context.read<PackagingTypeBloc>().add(SyncPackagingTypesEvent()),
        ),
      ],
    );
  }

  /// Muestra un diálogo de confirmación para eliminar la base de datos
  ///
  /// Implementa las mejores prácticas:
  /// - Usa Future<void> para operaciones asíncronas
  /// - Verifica mounted antes de usar context después de async
  /// - Maneja errores con try-catch
  /// - Proporciona feedback claro al usuario
  /// Confirma y elimina la base de datos local. Usa el `context` del State
  /// (protegido por `mounted`) tras cada `await`.
  Future<void> _showDeleteDatabaseConfirmation() async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Eliminar Base de Datos',
      message:
          'Esta acción no se puede deshacer y perderás todo el progreso '
          'que llevas realizado y está guardado en la base de datos.',
    );
    if (!confirmed || !mounted) return;

    try {
      await DataBaseSqlite().deleteBDCloseSession();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Base de datos eliminada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      goToScreen(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar la base de datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
