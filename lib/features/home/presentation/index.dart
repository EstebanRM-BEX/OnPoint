import 'package:flutter/material.dart';
import 'package:wms_app/shared/utils/app_navigation.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:wms_app/features/home/presentation/widgets/home_header.dart';
import 'package:wms_app/features/home/presentation/widgets/home_module_grid.dart';
import 'package:wms_app/features/home/presentation/widgets/operational_summary_card.dart';
import 'package:wms_app/shared/widgets/auth/auth_brand_gradient.dart';
import 'package:wms_app/core/routes/app_router.dart';
import 'package:wms_app/features/home/presentation/widgets/dialog_devoluciones_widget.dart';
import 'package:wms_app/features/home/presentation/widgets/dialog_inventario_widget.dart';
import 'package:wms_app/features/home/presentation/widgets/dialog_picking_componentes_widget.dart';
import 'package:wms_app/features/home/presentation/widgets/dialog_picking_widget.dart';
import 'package:wms_app/features/home/presentation/widgets/dialog_recepcion_widget.dart';
import 'package:wms_app/features/home/presentation/widgets/dialog_transferencia_widget.dart';
import 'package:wms_app/features/home/presentation/widgets/widget.dart';
import 'package:wms_app/features/inventario/presentation/bloc/inventario_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/bloc/wms_packing_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-consolidade/bloc/packing_consolidade_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/bloc/packing_pedido_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/screens/widgets/dialog_packing_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/blocs/batch_bloc/batch_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart'
    as dev_bloc;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _isExpanded = true;
  @override
  void initState() {
    super.initState();
    // Añadimos el observer para escuchar el ciclo de vida de la app.
    WidgetsBinding.instance.addObserver(this);

    // Disparamos los eventos para obtener los conteos de la bd local
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<dev_bloc.DevolucionesBloc>().add(
        dev_bloc.LoadTercerosCountEvent(),
      );
      context.read<InventarioBloc>().add(LoadProductosCountEvent());
      context.read<UserBloc>().add(LoadUserLocationsCountEvent());
      context.read<UserBloc>().add(LoadUserNoveltiesCountEvent());
      context.read<UserBloc>().add(LoadWarehousesCountEvent());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Acceso a módulos ─────────────────────────────────────────────────────

  void _snack(String message, {int seconds = 4}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: seconds),
      ),
    );
  }

  void _denyAccess({int seconds = 4}) => _snack(
    'Su usuario no tiene permisos para acceder a este módulo',
    seconds: seconds,
  );

  bool _homeRolIs(String rol) {
    final current = context.read<HomeBloc>().userRol;
    return current == rol || current == 'admin';
  }

  Future<void> _openPicking() async {
    final String rol = await PrefUtils.getUserRol();
    if (!mounted) return;
    if (rol == 'picking' || rol == 'admin') {
      context.read<BatchBloc>().add(LoadAllNovedadesEvent());
      showDialog(
        context: context,
        builder: (dialogContext) => DialogPicking(contextHome: dialogContext),
      );
    } else if (rol.isEmpty) {
      _snack('Cargue la configuración de su usuario');
    } else {
      _denyAccess();
    }
  }

  Future<void> _openPacking() async {
    final String rol = await PrefUtils.getUserRol();
    if (!mounted) return;
    if (rol == 'packing' || rol == 'admin') {
      context.read<WmsPackingBloc>().add(LoadAllNovedadesPackingEvent());
      context.read<PackingPedidoBloc>().add(LoadAllNovedadesPackEvent());
      context.read<PackingConsolidateBloc>().add(
        LoadAllNovedadesPackingConsolidateEvent(),
      );
      showDialog(
        context: context,
        builder: (dialogContext) => DialogPacking(contextHome: dialogContext),
      );
    } else {
      _denyAccess();
    }
  }

  /// [builder] recibe el contexto del diálogo; cada módulo decide qué
  /// contexto pasar como `contextHome` (se respeta el de la versión previa).
  void _openRoleDialog(String rol, WidgetBuilder builder, {int seconds = 4}) {
    if (_homeRolIs(rol)) {
      showDialog(context: context, builder: builder);
    } else {
      _denyAccess(seconds: seconds);
    }
  }

  Future<void> _openEntradaProductos() async {
    final homeConfig = context.read<HomeBloc>().configurations.result?.result;
    final userConfig = context.read<UserBloc>().configurations;
    final hasAccess =
        homeConfig?.accessProductionModule ??
        userConfig?.accessProductionModule ??
        false;
    if (!hasAccess) return _denyAccess();

    showDialog(
      context: context,
      builder: (_) =>
          const DialogLoading(message: 'Cargando entrega de productos...'),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.pushReplacementNamed(context, 'list-entrada-productos');
  }

  Future<void> _openUserProfile() async {
    context.read<UserBloc>().add(LoadUserInfoEvent());
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const DialogLoading(message: 'Cargando información del usuario...'),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    Get.back(); // Cierra el diálogo
    // Get.offNamed reemplaza la ruta de arriba: si el diálogo seguía ahí,
    // se lo comía y el Home (y lo que hubiera debajo) quedaba vivo en el
    // stack.
    goToScreen(context, AppRoutes.user);
  }

  List<List<HomeModule>> _modulePages() => [
    [
      HomeModule(
        title: 'Picking',
        subtitle: 'Preparación',
        icon: Icons.assignment_turned_in_outlined,
        onTap: _openPicking,
      ),
      HomeModule(
        title: 'Packing',
        subtitle: 'Empaque',
        icon: Icons.inventory_2_outlined,
        onTap: _openPacking,
      ),
      HomeModule(
        title: 'Devolución',
        subtitle: 'Retorno',
        icon: Icons.keyboard_return,
        onTap: () => _openRoleDialog(
          'reception',
          (dialogContext) => DialogDevoluciones(contextHome: dialogContext),
          seconds: 2,
        ),
      ),
      HomeModule(
        title: 'Recepción',
        subtitle: 'Ingreso mercancía',
        icon: Icons.input,
        onTap: () => _openRoleDialog(
          'reception',
          (_) => DialogRecepcion(contextHome: context),
          seconds: 2,
        ),
      ),
      HomeModule(
        title: 'Transferencia',
        subtitle: 'Entre ubicaciones',
        icon: Icons.sync_alt,
        onTap: () => _openRoleDialog(
          'transfer',
          (_) => DialogTransferencia(contextHome: context),
        ),
      ),
      HomeModule(
        title: 'Inventario',
        subtitle: 'Conteo físico',
        icon: Icons.shelves,
        onTap: () => _openRoleDialog(
          'inventory',
          (dialogContext) => DialogInventario(contextHome: dialogContext),
        ),
      ),
      HomeModule(
        title: 'Componentes',
        subtitle: 'Picking componentes',
        icon: Icons.settings_suggest_outlined,
        // Sin validación de permisos (estaba comentada en la versión
        // anterior): se mantiene el mismo comportamiento.
        onTap: () => showDialog(
          context: context,
          builder: (dialogContext) =>
              DialogPickingComponentes(contextHome: dialogContext),
        ),
      ),
      HomeModule(
        title: 'Entrada Prod.',
        subtitle: 'Entrega productos',
        icon: Icons.move_to_inbox_outlined,
        onTap: _openEntradaProductos,
      ),
      HomeModule(
        title: 'Info Rápida',
        subtitle: 'Consulta directa',
        icon: Icons.qr_code_scanner,
        onTap: () => Navigator.pushReplacementNamed(context, 'info-rapida'),
      ),
    ],
    [
      HomeModule(
        title: 'Etiquetas',
        subtitle: 'Impresión',
        icon: Icons.print_outlined,
        onTap: () =>
            Navigator.pushReplacementNamed(context, AppRoutes.printLabels),
      ),
      HomeModule(
        title: 'Expedición',
        subtitle: 'Despachos',
        icon: Icons.local_shipping_outlined,
        onTap: () =>
            Navigator.pushReplacementNamed(context, AppRoutes.listExpedition),
      ),
    ],
  ];

  // ── UI ──────────────────────────────────────────────────────────────────

  static const double _bandHeight = 256;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BlocListener<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is HomeLoadErrorState) {
            Get.snackbar(
              'Error',
              'Error al cargar los datos del usuario',
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: const Icon(Icons.error, color: Colors.red),
            );
          }
          if (state is AppVersionUpdateState) {
            showDialog(
              context: context,
              builder: (context) => const UpdateAppDialog(),
            );
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          // floatingActionButton: const CrashlyticsTestFab(),
          body: Stack(
            children: [
              // Banda de marca con base curva detrás de la cabecera.
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _bandHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: authBrandGradient,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(40),
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    const WarningWidgetCubit(),
                    _buildHeader(),
                    _buildSummary(),
                    const SizedBox(height: 18),
                    HomeModuleGrid(pages: _modulePages()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<HomeBloc, HomeState>(
      // Solo se reconstruye cuando el Home terminó de cargar o se cargó la
      // configuración.
      buildWhen: (previous, current) =>
          current is HomeLoadedState || current is ConfigurationLoadedHomeState,
      builder: (context, state) {
        final homeBloc = context.read<HomeBloc>();
        return HomeHeader(
          name: homeBloc.userName,
          email: homeBloc.userEmail,
          rol: homeBloc.userRol,
          database: getIt<IStorageService>().nameDatabase,
          version: context.read<UserBloc>().versionApp,
          onProfileTap: _openUserProfile,
          onLogout: () => showDialog(
            context: context,
            builder: (_) => const CloseSession(),
          ),
        );
      },
    );
  }

  Widget _buildSummary() {
    return BlocBuilder<dev_bloc.DevolucionesBloc, dev_bloc.DevolucionesState>(
      builder: (context, devState) {
        final devBloc = context.read<dev_bloc.DevolucionesBloc>();
        return BlocBuilder<InventarioBloc, InventarioState>(
          builder: (context, invState) {
            final invBloc = context.read<InventarioBloc>();
            return BlocBuilder<UserBloc, UserState>(
              builder: (context, userState) {
                final userBloc = context.read<UserBloc>();
                return OperationalSummaryCard(
                  expanded: _isExpanded,
                  onToggle: () => setState(() => _isExpanded = !_isExpanded),
                  terceros: SummaryMetric(
                    count: devBloc.tercerosCount,
                    loading:
                        devState is dev_bloc.DownloadAllTercerosLoading ||
                        devState is dev_bloc.LoadTercerosFromDBLoading,
                  ),
                  productos: SummaryMetric(
                    count: invBloc.productosCount,
                    // Propiedad persistente del bloc (no solo el estado
                    // transitorio) para evitar carreras.
                    loading:
                        invBloc.isLoading ||
                        invState is GetProductsLoadingInventory ||
                        invState is GetProductsLoadingBD,
                  ),
                  ubicaciones: SummaryMetric(
                    count: userBloc.locationsCount,
                    loading: userState is UserLocationsLoading,
                  ),
                  novedades: SummaryMetric(
                    count: userBloc.noveltiesCount,
                    loading: userState is UserNoveltiesLoading,
                  ),
                  almacenes: SummaryMetric(count: userBloc.warehousesCount),
                );
              },
            );
          },
        );
      },
    );
  }
}
