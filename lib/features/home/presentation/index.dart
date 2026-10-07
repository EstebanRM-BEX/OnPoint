import 'package:flutter/material.dart';
import 'package:wms_app/core/services/preload_status.dart';
import 'package:wms_app/shared/utils/app_navigation.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:wms_app/features/home/presentation/widgets/home_header.dart';
import 'package:wms_app/features/home/presentation/models/home_module_catalog.dart';
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
import 'package:wms_app/core/services/productos_sync_service.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/bloc/wms_packing_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/bloc/packing_pedido_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/screens/widgets/dialog_packing_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/blocs/batch_bloc/batch_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  /// Resumen operativo desplegado/contraído. Se guarda por dispositivo
  /// (sobrevive a salir del Home y a cerrar sesión).
  bool _isExpanded = true;

  /// false hasta leer las prefs: así el resumen no se pinta desplegado un
  /// frame y luego se contrae con animación.
  bool _summaryLoaded = false;

  /// null hasta leer las prefs, para no pintar el orden por defecto un frame.
  HomeModulesLayout? _modulesLayout;

  @override
  void initState() {
    super.initState();
    _loadModulesLayout();
    // Añadimos el observer para escuchar el ciclo de vida de la app.
    WidgetsBinding.instance.addObserver(this);

    // Disparamos los eventos para obtener los conteos de la bd local
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ProductosSyncService.instance.refreshCount();
      context.read<UserBloc>().add(LoadUserLocationsCountEvent());
      context.read<UserBloc>().add(LoadUserNoveltiesCountEvent());
      context.read<UserBloc>().add(LoadWarehousesCountEvent());
    });
  }

  Future<void> _loadModulesLayout() async {
    final layout = await HomeModulesPrefs.load();
    final summaryExpanded = await HomeModulesPrefs.loadSummaryExpanded();
    if (!mounted) return;
    setState(() {
      _modulesLayout = layout;
      _isExpanded = summaryExpanded;
      _summaryLoaded = true;
    });
  }

  void _toggleSummary() {
    final expanded = !_isExpanded;
    setState(() => _isExpanded = expanded);
    HomeModulesPrefs.saveSummaryExpanded(expanded);
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

  VoidCallback _onTapFor(HomeModuleId id) => switch (id) {
    HomeModuleId.picking => _openPicking,
    HomeModuleId.packing => _openPacking,
    HomeModuleId.devolucion => () => _openRoleDialog(
      'reception',
      (dialogContext) => DialogDevoluciones(contextHome: dialogContext),
      seconds: 2,
    ),
    HomeModuleId.recepcion => () => _openRoleDialog(
      'reception',
      (_) => DialogRecepcion(contextHome: context),
      seconds: 2,
    ),
    HomeModuleId.transferencia => () => _openRoleDialog(
      'transfer',
      (_) => DialogTransferencia(contextHome: context),
    ),
    HomeModuleId.inventario => () => _openRoleDialog(
      'inventory',
      (dialogContext) => DialogInventario(contextHome: dialogContext),
    ),
    // Sin validación de permisos (estaba comentada en la versión anterior):
    // se mantiene el mismo comportamiento.
    HomeModuleId.componentes => () => showDialog(
      context: context,
      builder: (dialogContext) =>
          DialogPickingComponentes(contextHome: dialogContext),
    ),
    HomeModuleId.entradaProductos => _openEntradaProductos,
    HomeModuleId.infoRapida => () => Navigator.pushReplacementNamed(
      context,
      'info-rapida',
    ),
    HomeModuleId.etiquetas => () => Navigator.pushReplacementNamed(
      context,
      AppRoutes.printLabels,
    ),
    HomeModuleId.expedicion => () => Navigator.pushReplacementNamed(
      context,
      AppRoutes.listExpedition,
    ),
  };

  /// Módulos visibles en el orden configurado, en páginas de 9.
  List<List<HomeModule>> _modulePages(HomeModulesLayout layout) {
    final modules = [
      for (final id in layout.visible)
        HomeModule(
          title: id.title,
          subtitle: id.subtitle,
          icon: id.icon,
          onTap: _onTapFor(id),
        ),
    ];
    const perPage = HomeModuleGrid.modulesPerPage;
    return [
      for (var i = 0; i < modules.length; i += perPage)
        modules.sublist(
          i,
          i + perPage > modules.length ? modules.length : i + perPage,
        ),
    ];
  }

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
          // floatingActionButton: const UpdateRequiredTestFab(),
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
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const WarningWidgetCubit(),
                          _buildHeader(),
                          _buildSummary(),
                        ]),
                      ),
                    ),
                    // Ocupa el alto restante: con el resumen contraído los
                    // módulos quedan centrados en el espacio libre; si no
                    // caben, crece y la página hace scroll como antes.
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        24 + MediaQuery.paddingOf(context).bottom,
                      ),
                      sliver: SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: _modulesLayout == null
                              ? const SizedBox.shrink()
                              : HomeModuleGrid(
                                  pages: _modulePages(_modulesLayout!),
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
    if (!_summaryLoaded) return const SizedBox.shrink();
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        final userBloc = context.read<UserBloc>();
        final productosSync = ProductosSyncService.instance;
        return ListenableBuilder(
          listenable: Listenable.merge([PreloadStatus.instance, productosSync]),
          builder: (context, _) => OperationalSummaryCard(
            expanded: _isExpanded,
            onToggle: _toggleSummary,
            productos: SummaryMetric(
              pending: PreloadStatus.instance.isPending(
                PreloadStatus.productos,
              ),
              count: productosSync.count,
              loading: productosSync.isLoading,
              error: productosSync.error,
              onRetry: () => productosSync.download(),
            ),
            ubicaciones: SummaryMetric(
              pending: PreloadStatus.instance.isPending(
                PreloadStatus.ubicaciones,
              ),
              count: userBloc.locationsCount,
              // Propiedad persistente: DownloadLocationsEvent (la
              // descarga real post-login) emite DownloadUserDataLoading,
              // no UserLocationsLoading, así que ese chequeo solo nunca
              // detectaba la carga real.
              loading:
                  userBloc.isLoadingLocations ||
                  userState is UserLocationsLoading,
            ),
            novedades: SummaryMetric(
              pending: PreloadStatus.instance.isPending(
                PreloadStatus.novedades,
              ),
              count: userBloc.noveltiesCount,
              loading: userState is UserNoveltiesLoading,
            ),
            almacenes: SummaryMetric(count: userBloc.warehousesCount),
          ),
        );
      },
    );
  }
}
