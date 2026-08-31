// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages, avoid_print

import 'dart:io';
import 'dart:async';
import 'package:wms_app/features/print_labels/presentation/bloc/print_labels_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_bloc.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/cluster_picking/cluster_picking_bloc.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/lote_producto/lote_producto_bloc.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/picking_cluster_list/picking_cluster_list_bloc.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/detail_cluster/detail_cluster_bloc.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/validate_cluster/validate_cluster_bloc.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/get_picking_cluster_data.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/get_local_picking_cluster_data.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/start_time_pick_use_case.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/view_product_image_usecase.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/validate_pedido_usecase.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/set_cluster_batch_pedido_field_use_case.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/get_pending_send_products_use_case.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/send_product_odoo_use_case.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/set_cluster_batch_product_field_use_case.dart';
import 'package:wms_app/features/picking_cluster/domain/usecases/end_time_pick_use_case.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/features/printing/presentation/bloc/printing_bloc.dart';
import 'package:wms_app/firebase_options.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/routes/app_router.dart';
import 'package:wms_app/src/api/api_request_service.dart';
import 'package:wms_app/src/api/http_response_handler.dart';
import 'package:wms_app/core/services/session_manager.dart';
import 'package:wms_app/core/utils/widgets/app_restart_widget.dart';
import 'package:wms_app/core/utils/widgets/error_widget.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/bloc/conteo_bloc.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';
import 'package:wms_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:wms_app/features/login/presentation/bloc/login_bloc.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/quick%20info/bloc/info_rapida_bloc.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/transfer/bloc/transfer_info_bloc.dart';
import 'package:wms_app/features/inventario/presentation/bloc/inventario_bloc.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/batchs/bloc/recepcion_batch_bloc.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/bloc/recepcion_bloc.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/bloc/crate_transfer_bloc.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/transfer-interna/bloc/transferencia_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/bloc/wms_packing_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-consolidade/bloc/packing_consolidade_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/bloc/packing_pedido_bloc.dart';
import 'package:wms_app/features/enterprise/presentation/bloc/enterprise_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/bloc/wms_picking_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/blocs/batch_bloc/batch_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/bloc/picking_pick_bloc.dart';
import 'package:wms_app/src/presentation/widgets/session_timeout_manager_widget.dart';
import 'package:wms_app/src/presentation/widgets/network_quality_overlay.dart';
import 'package:wms_app/src/presentation/providers/network_overlay/network_overlay_cubit.dart';
import 'package:wms_app/core/services/interfaces/i_websocket_service.dart';
import 'package:wms_app/features/expedition/data/services/expedition_sync_coordinator.dart';
import 'package:wms_app/features/websocket/presentation/bloc/websocket_bloc.dart';
import 'package:wms_app/features/expedition/presentation/bloc/assignment/expedicion_assignment_bloc.dart';
import 'package:wms_app/features/expedition/presentation/bloc/confirm/expedicion_confirm_bloc.dart';
import 'package:wms_app/features/expedition/presentation/bloc/detail/expedicion_detail_bloc.dart';
import 'package:wms_app/features/expedition/presentation/bloc/list/expedition_list_bloc.dart';
import 'package:wms_app/features/expedition/presentation/bloc/scan/expedicion_scan_bloc.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/detail/recepcion_multiusuario_my_claims_bloc.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/detail/recepcion_multiusuario_pool_bloc.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/list/recepcion_multiusuario_list_bloc.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/location_dest/recepcion_multiusuario_location_dest_bloc.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/lote/recepcion_multiusuario_lote_bloc.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/scan/recepcion_multiusuario_scan_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:wms_app/injection_container.dart';
// Chat global desactivado en desarrollo.
// import 'package:wms_app/features/chat/presentation/widgets/global_chat_overlay.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ApiRequestService apiRequestService = ApiRequestService();

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Configuración de errores de Flutter hacia Crashlytics
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Configuración de pantalla roja de error (Opcional)
      ErrorWidget.builder = (FlutterErrorDetails details) => ErrorMessageWidget(
        title: 'Algo salió mal',
        message: 'No se pudo cargar la información...',
        buttonText: 'Cerrar la app',
        onPressed: () {
          exit(0);
        },
      );

      // Initialize Dependency Injection
      await configureDependencies();

      apiRequestService.initialize(
        unencodePath: '/api',
        httpHandler: HttpResponseHandler(),
      );

      runApp(AppRestart(child: const MyApp()));

      // WebSocket en background: no debe bloquear el primer frame.
      // connect() ya retorna solo si no hay sesión activa.
      unawaited(getIt<IWebSocketService>().connect());

      // Instancia el coordinator de expedición (empieza a escuchar la red) e
      // intenta enviar validaciones offline pendientes al arrancar. Background.
      getIt<ExpeditionSyncCoordinator>().requestSync();
    },
    (error, stack) {
      // Zona de captura de errores globales
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    void logOut() async {
      debugPrint("⏱️ Sesión expirada por inactividad.");
      await SessionManager.closeSession();
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => NetworkOverlayCubit()),
        BlocProvider(create: (_) => getIt<ConnectionStatusCubit>()),
        BlocProvider(create: (_) => getIt<UserBloc>()),
        BlocProvider(create: (_) => RecepcionBloc()),
        BlocProvider(create: (_) => TransferenciaBloc()),
        BlocProvider(create: (_) => getIt<HomeBloc>()),
        BlocProvider(create: (_) => getIt<LoginBloc>()),
        BlocProvider(create: (_) => WMSPickingBloc()),
        BlocProvider(create: (_) => BatchBloc()),
        BlocProvider(create: (_) => WmsPackingBloc()),
        BlocProvider(create: (_) => TransferInfoBloc()),
        BlocProvider(
          create: (context) =>
              InfoRapidaBloc(userBloc: context.read<UserBloc>()),
        ),
        BlocProvider(create: (_) => getIt<InventarioBloc>()),
        BlocProvider(create: (_) => PickingPickBloc()),
        BlocProvider(create: (_) => RecepcionBatchBloc()),
        BlocProvider(create: (_) => PackingPedidoBloc()),
        BlocProvider(create: (_) => DevolucionesBloc()),
        BlocProvider(create: (_) => ConteoBloc()),
        BlocProvider(create: (_) => CreateTransferBloc()),
        BlocProvider(create: (_) => PackingConsolidateBloc()),
        BlocProvider(create: (_) => getIt<EnterpriseBloc>()),
        BlocProvider(create: (_) => getIt<ClusterPickingBloc>()),
        BlocProvider(
          create: (context) => PickingClusterListBloc(
            clusterPickingBloc: context.read<ClusterPickingBloc>(),
            getPickingClusterData: getIt<GetPickingClusterData>(),
            getLocalPickingClusterData: getIt<GetLocalPickingClusterData>(),
            startTimePickUseCase: getIt<StartTimePickUseCase>(),
          ),
        ),
        BlocProvider(
          create: (_) => DetailClusterBloc(
            viewProductImageUseCase: getIt<ViewProductImageUseCase>(),
          ),
        ),
        BlocProvider(
          create: (context) => ValidateClusterBloc(
            clusterPickingBloc: context.read<ClusterPickingBloc>(),
            validatePedidoUseCase: getIt<ValidatePedidoUseCase>(),
            setClusterBatchPedidoFieldUseCase:
                getIt<SetClusterBatchPedidoFieldUseCase>(),
            getPendingSendProductsUseCase:
                getIt<GetPendingSendProductsUseCase>(),
            sendProductOdooUseCase: getIt<SendProductOdooUseCase>(),
            setClusterBatchProductFieldUseCase:
                getIt<SetClusterBatchProductFieldUseCase>(),
            endTimePickUseCase: getIt<EndTimePickUseCase>(),
            networkInfo: getIt<NetworkInfo>(),
          ),
        ),
        BlocProvider(create: (_) => getIt<LoteProductoBloc>()),
        BlocProvider(create: (_) => getIt<PackagingTypeBloc>()),
        BlocProvider(create: (_) => getIt<PrintingBloc>()),
        BlocProvider(create: (_) => PrintLabelsBloc()),
        BlocProvider(create: (_) => getIt<WebSocketBloc>()),
        BlocProvider(create: (_) => getIt<ExpedicionListBloc>()),
        BlocProvider(create: (_) => getIt<ExpedicionAssignmentBloc>()),
        BlocProvider(create: (_) => getIt<ExpedicionDetailBloc>()),
        BlocProvider(create: (_) => getIt<ExpedicionScanBloc>()),
        BlocProvider(create: (_) => getIt<ExpedicionConfirmBloc>()),
        BlocProvider(create: (_) => getIt<RecepcionMultiusuarioListBloc>()),
        BlocProvider(create: (_) => getIt<RecepcionMultiusuarioLoteBloc>()),
        BlocProvider(
          create: (_) => getIt<RecepcionMultiusuarioLocationDestBloc>(),
        ),
        BlocProvider(create: (_) => getIt<RecepcionMultiusuarioPoolBloc>()),
        BlocProvider(create: (_) => getIt<RecepcionMultiusuarioMyClaimsBloc>()),
        BlocProvider(create: (_) => getIt<RecepcionMultiusuarioScanBloc>()),
      ],
      child: GetMaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.checkout,
        routes: AppRoutes.routes,
        supportedLocales: const [Locale('es', 'ES')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.grey[300],
          appBarTheme: AppBarTheme(elevation: 0, color: primaryColorApp),
          colorScheme: ColorScheme.light(
            primary: primaryColorApp,
            secondary: primaryColorApp,
          ),
        ),
        builder: (context, navigator) {
          return SessionTimeoutManager(
            duration: const Duration(minutes: 240),
            onSessionExpired: logOut,
            // Chat global desactivado en desarrollo. Para reactivarlo, envolver
            // de nuevo el navigator con GlobalChatOverlay.
            child: NetworkQualityOverlay(
              child: navigator ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
