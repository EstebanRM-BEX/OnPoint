// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages, avoid_print

import 'dart:io';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/features/picking/presentation/bloc/cluster_picking_bloc.dart';
import 'package:wms_app/firebase_options.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/routes/app_router.dart';
import 'package:wms_app/src/api/api_request_service.dart';
import 'package:wms_app/src/api/http_response_handler.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/core/utils/widgets/error_widget.dart';
import 'package:wms_app/src/presentation/blocs/keyboard/keyboard_bloc.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';

import 'package:wms_app/src/presentation/views/conteo/screens/bloc/conteo_bloc.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';
import 'package:wms_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:wms_app/features/login/presentation/bloc/login_bloc.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/bloc/info_rapida_bloc.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/transfer/bloc/transfer_info_bloc.dart';
import 'package:wms_app/src/presentation/views/inventario/screens/bloc/inventario_bloc.dart';
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
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/core/services/interfaces/i_websocket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:wms_app/injection_container.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ApiRequestService apiRequestService = ApiRequestService();

void main() {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configuración de errores de Flutter hacia Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

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

    // 5. Iniciar WebSocket (Usando DI)
    await getIt<IWebSocketService>().connect();
    runApp(const MyApp());
  }, (error, stack) {
    // Zona de captura de errores globales
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    void logOut() async {
      print("⏳ Sesión expirada por inactividad.");
      final contextWithProviders = navigatorKey.currentContext;
      if (contextWithProviders != null) {
        PrefUtils.clearPrefs();
        getIt<IStorageService>().removeUrlWebsite();
        await DataBaseSqlite().deleteBDCloseSession();
        await Future.delayed(const Duration(seconds: 1));
        PrefUtils.setIsLoggedIn(false);
      }

      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('enterprice', (route) => false);
    }

    return GetMaterialApp(
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
        apiRequestService.initialize(
          unencodePath: '/api',
          httpHandler: HttpResponseHandler(),
        );
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => getIt<ConnectionStatusCubit>()),
            BlocProvider(create: (_) => getIt<UserBloc>()),
            BlocProvider(create: (_) => RecepcionBloc()),
            BlocProvider(create: (_) => TransferenciaBloc()),
            BlocProvider(create: (_) => getIt<HomeBloc>()),
            BlocProvider(create: (_) => getIt<LoginBloc>()),
            BlocProvider(create: (_) => WMSPickingBloc()),
            BlocProvider(create: (_) => BatchBloc()),
            BlocProvider(create: (_) => WmsPackingBloc()),
            BlocProvider(create: (_) => KeyboardBloc()),
            BlocProvider(create: (_) => TransferInfoBloc()),
            BlocProvider(
                create: (context) =>
                    InfoRapidaBloc(userBloc: context.read<UserBloc>())),
            BlocProvider(create: (_) => InventarioBloc()),
            BlocProvider(create: (_) => PickingPickBloc()),
            BlocProvider(create: (_) => RecepcionBatchBloc()),
            BlocProvider(create: (_) => PackingPedidoBloc()),
            BlocProvider(create: (_) => DevolucionesBloc()),
            BlocProvider(create: (_) => ConteoBloc()),
            BlocProvider(create: (_) => CreateTransferBloc()),
            BlocProvider(create: (_) => PackingConsolidateBloc()),
            BlocProvider(create: (_) => getIt<EnterpriseBloc>()),
            BlocProvider(create: (_) => ClusterPickingBloc()),
          ],
          child: SessionTimeoutManager(
            duration: const Duration(hours: 1),
            onSessionExpired: logOut,
            child: navigator ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
