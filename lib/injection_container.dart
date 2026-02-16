import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';

import 'package:wms_app/src/api/api_request_service.dart';

import 'injection_container.config.dart';

final getIt = GetIt.instance;

/// Configures all dependencies using injectable code generation.
///
/// Call this function in main() before runApp().
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async => getIt.init();

/// Module for registering external dependencies that don't have @injectable annotations.
@module
abstract class RegisterModule {
  @lazySingleton
  http.Client get httpClient => http.Client();

  @lazySingleton
  Connectivity get connectivity => Connectivity();

  @lazySingleton
  DataBaseSqlite get database => DataBaseSqlite();

  @lazySingleton
  ApiRequestService get apiRequestService => ApiRequestService();
}
