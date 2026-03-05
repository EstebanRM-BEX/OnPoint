// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:get_it/get_it.dart' as _i174;
import 'package:http/http.dart' as _i519;
import 'package:injectable/injectable.dart' as _i526;

import 'core/interfaces/i_audio_service.dart' as _i688;
import 'core/interfaces/i_device_info_service.dart' as _i311;
import 'core/interfaces/i_vibration_service.dart' as _i537;
import 'core/network/network_info.dart' as _i75;
import 'core/services/audio_service_impl.dart' as _i927;
import 'core/services/device_info_service_impl.dart' as _i910;
import 'core/services/interfaces/i_notification_service.dart' as _i615;
import 'core/services/interfaces/i_storage_service.dart' as _i206;
import 'core/services/interfaces/i_websocket_service.dart' as _i1062;
import 'core/services/notification_service.dart' as _i1011;
import 'core/services/storage_service.dart' as _i243;
import 'core/services/vibration_service_impl.dart' as _i869;
import 'core/services/websocket_service.dart' as _i1020;
import 'features/auth/data/datasources/auth_local_data_source.dart' as _i791;
import 'features/auth/data/repositories/auth_repository_impl.dart' as _i111;
import 'features/auth/domain/repositories/auth_repository.dart' as _i1015;
import 'features/auth/domain/usecases/validate_session.dart' as _i52;
import 'features/auth/presentation/bloc/auth_bloc.dart' as _i363;
import 'features/enterprise/data/datasources/enterprise_local_data_source.dart'
    as _i854;
import 'features/enterprise/data/datasources/enterprise_remote_data_source.dart'
    as _i918;
import 'features/enterprise/data/repositories/enterprise_repository_impl.dart'
    as _i331;
import 'features/enterprise/domain/repositories/enterprise_repository.dart'
    as _i309;
import 'features/enterprise/domain/usecases/delete_recent_url.dart' as _i552;
import 'features/enterprise/domain/usecases/get_recent_urls.dart' as _i91;
import 'features/enterprise/domain/usecases/save_recent_url.dart' as _i747;
import 'features/enterprise/domain/usecases/search_enterprise.dart' as _i138;
import 'features/enterprise/presentation/bloc/enterprise_bloc.dart' as _i20;
import 'features/home/data/datasources/home_local_data_source.dart' as _i205;
import 'features/home/data/datasources/home_remote_data_source.dart' as _i359;
import 'features/home/data/repositories/home_repository_impl.dart' as _i689;
import 'features/home/domain/repositories/home_repository.dart' as _i649;
import 'features/home/domain/usecases/get_app_version.dart' as _i312;
import 'features/home/domain/usecases/get_user_configurations.dart' as _i698;
import 'features/home/domain/usecases/get_user_data.dart' as _i485;
import 'features/home/presentation/bloc/home_bloc.dart' as _i123;
import 'features/login/data/datasources/login_local_data_source.dart' as _i544;
import 'features/login/data/datasources/login_remote_data_source.dart' as _i18;
import 'features/login/data/repositories/login_repository_impl.dart' as _i1059;
import 'features/login/domain/repositories/login_repository.dart' as _i889;
import 'features/login/domain/usecases/authenticate_user.dart' as _i792;
import 'features/login/domain/usecases/save_user_session.dart' as _i311;
import 'features/login/presentation/bloc/login_bloc.dart' as _i1070;
import 'features/picking_cluster/data/datasources/picking_cluster_local_data_source.dart'
    as _i130;
import 'features/picking_cluster/data/datasources/picking_remote_data_source.dart'
    as _i681;
import 'features/picking_cluster/data/repositories/picking_cluster_impl.dart'
    as _i110;
import 'features/picking_cluster/domain/repositories/picking_cluster_repository.dart'
    as _i932;
import 'features/picking_cluster/domain/usecases/crear_lote_producto_use_case.dart'
    as _i975;
import 'features/picking_cluster/domain/usecases/get_barcodes_product_use_case.dart'
    as _i309;
import 'features/picking_cluster/domain/usecases/get_field_table_products_use_case.dart'
    as _i235;
import 'features/picking_cluster/domain/usecases/get_local_batch_products_data.dart'
    as _i61;
import 'features/picking_cluster/domain/usecases/get_local_picking_cluster_data.dart'
    as _i295;
import 'features/picking_cluster/domain/usecases/get_lotes_producto_use_case.dart'
    as _i799;
import 'features/picking_cluster/domain/usecases/get_picking_cluster_data.dart'
    as _i524;
import 'features/picking_cluster/domain/usecases/get_product_batch_use_case.dart'
    as _i410;
import 'features/picking_cluster/domain/usecases/increment_product_separate_qty_use_case.dart'
    as _i360;
import 'features/picking_cluster/domain/usecases/increment_quantity_separate_use_case.dart'
    as _i85;
import 'features/picking_cluster/domain/usecases/send_product_odoo_use_case.dart'
    as _i984;
import 'features/picking_cluster/domain/usecases/set_cluster_batch_field_use_case.dart'
    as _i956;
import 'features/picking_cluster/domain/usecases/set_cluster_batch_product_field_use_case.dart'
    as _i915;
import 'features/picking_cluster/domain/usecases/view_product_image_usecase.dart'
    as _i149;
import 'features/picking_cluster/presentation/bloc/cluster_picking/cluster_picking_bloc.dart'
    as _i545;
import 'features/picking_cluster/presentation/bloc/lote_producto/lote_producto_bloc.dart'
    as _i573;
import 'features/user/data/datasources/user_local_data_source.dart' as _i232;
import 'features/user/data/datasources/user_remote_data_source.dart' as _i1071;
import 'features/user/data/repositories/user_repository_impl.dart' as _i39;
import 'features/user/domain/repositories/user_repository.dart' as _i180;
import 'features/user/domain/usecases/get_device_info.dart' as _i932;
import 'features/user/domain/usecases/get_user_configuration.dart' as _i280;
import 'features/user/domain/usecases/get_user_locations.dart' as _i247;
import 'features/user/domain/usecases/get_user_novelties.dart' as _i465;
import 'features/user/domain/usecases/register_device.dart' as _i902;
import 'features/user/presentation/bloc/user_bloc.dart' as _i565;
import 'features/websocket/presentation/bloc/websocket_bloc.dart' as _i676;
import 'injection_container.dart' as _i809;
import 'presentation/global/blocs/network/connection_status_cubit.dart'
    as _i146;
import 'src/api/api_request_service.dart' as _i319;
import 'src/presentation/providers/db/database.dart' as _i552;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i519.Client>(() => registerModule.httpClient);
    gh.lazySingleton<_i895.Connectivity>(() => registerModule.connectivity);
    gh.lazySingleton<_i552.DataBaseSqlite>(() => registerModule.database);
    gh.lazySingleton<_i319.ApiRequestService>(
        () => registerModule.apiRequestService);
    gh.lazySingleton<_i232.UserLocalDataSource>(
        () => _i232.UserLocalDataSourceImpl(gh<_i552.DataBaseSqlite>()));
    gh.lazySingleton<_i688.IAudioService>(() => _i927.AudioServiceImpl());
    gh.lazySingleton<_i130.PickingClusterLocalDataSource>(
        () => _i130.PickingClusterLocalDataSourceImpl());
    gh.lazySingleton<_i537.IVibrationService>(
        () => _i869.VibrationServiceImpl());
    gh.lazySingleton<_i359.HomeRemoteDataSource>(
        () => _i359.HomeRemoteDataSourceImpl(gh<_i319.ApiRequestService>()));
    gh.lazySingleton<_i311.IDeviceInfoService>(
        () => _i910.DeviceInfoServiceImpl());
    gh.lazySingleton<_i75.NetworkInfo>(
      () => _i75.NetworkInfoImpl(gh<_i895.Connectivity>()),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i791.AuthLocalDataSource>(
        () => _i791.AuthLocalDataSourceImpl());
    gh.lazySingleton<_i544.LoginLocalDataSource>(
        () => _i544.LoginLocalDataSourceImpl());
    gh.factory<_i146.ConnectionStatusCubit>(
        () => _i146.ConnectionStatusCubit(networkInfo: gh<_i75.NetworkInfo>()));
    gh.lazySingleton<_i1071.UserRemoteDataSource>(
        () => _i1071.UserRemoteDataSourceImpl(gh<_i319.ApiRequestService>()));
    gh.lazySingleton<_i615.INotificationService>(
        () => _i1011.NotificationService());
    gh.lazySingleton<_i918.EnterpriseRemoteDataSource>(() =>
        _i918.EnterpriseRemoteDataSourceImpl(gh<_i319.ApiRequestService>()));
    gh.lazySingleton<_i18.LoginRemoteDataSource>(
        () => _i18.LoginRemoteDataSourceImpl(gh<_i319.ApiRequestService>()));
    gh.lazySingleton<_i180.UserRepository>(() => _i39.UserRepositoryImpl(
          remoteDataSource: gh<_i1071.UserRemoteDataSource>(),
          localDataSource: gh<_i232.UserLocalDataSource>(),
        ));
    await gh.lazySingletonAsync<_i206.IStorageService>(
      () {
        final i = _i243.StorageService();
        return i.init().then((_) => i);
      },
      preResolve: true,
    );
    gh.lazySingleton<_i681.PickingClusterRemoteDataSource>(() =>
        _i681.PickingClusterRemoteDataSourceImpl(
            gh<_i319.ApiRequestService>()));
    gh.lazySingleton<_i1062.IWebSocketService>(() => _i1020.WebSocketService());
    gh.lazySingleton<_i854.EnterpriseLocalDataSource>(
        () => _i854.EnterpriseLocalDataSourceImpl(gh<_i552.DataBaseSqlite>()));
    gh.lazySingleton<_i309.EnterpriseRepository>(
        () => _i331.EnterpriseRepositoryImpl(
              remoteDataSource: gh<_i918.EnterpriseRemoteDataSource>(),
              localDataSource: gh<_i854.EnterpriseLocalDataSource>(),
            ));
    gh.lazySingleton<_i902.RegisterDevice>(
        () => _i902.RegisterDevice(gh<_i180.UserRepository>()));
    gh.lazySingleton<_i280.GetUserConfiguration>(
        () => _i280.GetUserConfiguration(gh<_i180.UserRepository>()));
    gh.lazySingleton<_i247.GetUserLocations>(
        () => _i247.GetUserLocations(gh<_i180.UserRepository>()));
    gh.lazySingleton<_i932.GetDeviceInfo>(
        () => _i932.GetDeviceInfo(gh<_i180.UserRepository>()));
    gh.lazySingleton<_i465.GetUserNovelties>(
        () => _i465.GetUserNovelties(gh<_i180.UserRepository>()));
    gh.lazySingleton<_i889.LoginRepository>(() => _i1059.LoginRepositoryImpl(
          remoteDataSource: gh<_i18.LoginRemoteDataSource>(),
          localDataSource: gh<_i544.LoginLocalDataSource>(),
          networkInfo: gh<_i75.NetworkInfo>(),
        ));
    gh.lazySingleton<_i932.IPickingClusterRepository>(
        () => _i110.PickingClusterRepositoryImpl(
              gh<_i681.PickingClusterRemoteDataSource>(),
              gh<_i130.PickingClusterLocalDataSource>(),
            ));
    gh.lazySingleton<_i205.HomeLocalDataSource>(
        () => _i205.HomeLocalDataSourceImpl(gh<_i552.DataBaseSqlite>()));
    gh.lazySingleton<_i138.SearchEnterprise>(
        () => _i138.SearchEnterprise(gh<_i309.EnterpriseRepository>()));
    gh.lazySingleton<_i91.GetRecentUrls>(
        () => _i91.GetRecentUrls(gh<_i309.EnterpriseRepository>()));
    gh.lazySingleton<_i747.SaveRecentUrl>(
        () => _i747.SaveRecentUrl(gh<_i309.EnterpriseRepository>()));
    gh.lazySingleton<_i552.DeleteRecentUrl>(
        () => _i552.DeleteRecentUrl(gh<_i309.EnterpriseRepository>()));
    gh.factory<_i676.WebSocketBloc>(() =>
        _i676.WebSocketBloc(webSocketService: gh<_i1062.IWebSocketService>()));
    gh.lazySingleton<_i1015.AuthRepository>(() => _i111.AuthRepositoryImpl(
        localDataSource: gh<_i791.AuthLocalDataSource>()));
    gh.lazySingleton<_i311.SaveUserSession>(
        () => _i311.SaveUserSession(gh<_i889.LoginRepository>()));
    gh.lazySingleton<_i792.AuthenticateUser>(
        () => _i792.AuthenticateUser(gh<_i889.LoginRepository>()));
    gh.lazySingleton<_i524.GetPickingClusterData>(() =>
        _i524.GetPickingClusterData(gh<_i932.IPickingClusterRepository>()));
    gh.lazySingleton<_i61.GetLocalBatchProductsData>(() =>
        _i61.GetLocalBatchProductsData(gh<_i932.IPickingClusterRepository>()));
    gh.lazySingleton<_i799.GetLotesProductoUseCase>(() =>
        _i799.GetLotesProductoUseCase(gh<_i932.IPickingClusterRepository>()));
    gh.lazySingleton<_i295.GetLocalPickingClusterData>(() =>
        _i295.GetLocalPickingClusterData(
            gh<_i932.IPickingClusterRepository>()));
    gh.lazySingleton<_i975.CrearLoteProductoUseCase>(() =>
        _i975.CrearLoteProductoUseCase(gh<_i932.IPickingClusterRepository>()));
    gh.lazySingleton<_i915.SetClusterBatchProductFieldUseCase>(() =>
        _i915.SetClusterBatchProductFieldUseCase(
            gh<_i932.IPickingClusterRepository>()));
    gh.lazySingleton<_i956.SetClusterBatchFieldUseCase>(() =>
        _i956.SetClusterBatchFieldUseCase(
            gh<_i932.IPickingClusterRepository>()));
    gh.lazySingleton<_i309.GetBarcodesProductUseCase>(() =>
        _i309.GetBarcodesProductUseCase(gh<_i932.IPickingClusterRepository>()));
    gh.lazySingleton<_i85.IncrementQuantitySeparateUseCase>(() =>
        _i85.IncrementQuantitySeparateUseCase(
            gh<_i932.IPickingClusterRepository>()));
    gh.lazySingleton<_i360.IncrementProductSeparateQtyUseCase>(() =>
        _i360.IncrementProductSeparateQtyUseCase(
            gh<_i932.IPickingClusterRepository>()));
    gh.lazySingleton<_i235.GetFieldTableProductsUseCase>(() =>
        _i235.GetFieldTableProductsUseCase(
            gh<_i932.IPickingClusterRepository>()));
    gh.lazySingleton<_i410.GetProductBatchUseCase>(() =>
        _i410.GetProductBatchUseCase(gh<_i932.IPickingClusterRepository>()));
    gh.lazySingleton<_i984.SendProductOdooUseCase>(() =>
        _i984.SendProductOdooUseCase(gh<_i932.IPickingClusterRepository>()));
    gh.lazySingleton<_i149.ViewProductImageUseCase>(() =>
        _i149.ViewProductImageUseCase(gh<_i932.IPickingClusterRepository>()));
    gh.factory<_i1070.LoginBloc>(() => _i1070.LoginBloc(
          authenticateUser: gh<_i792.AuthenticateUser>(),
          saveUserSession: gh<_i311.SaveUserSession>(),
        ));
    gh.lazySingleton<_i649.HomeRepository>(() => _i689.HomeRepositoryImpl(
          remoteDataSource: gh<_i359.HomeRemoteDataSource>(),
          localDataSource: gh<_i205.HomeLocalDataSource>(),
          networkInfo: gh<_i75.NetworkInfo>(),
        ));
    gh.factory<_i573.LoteProductoBloc>(() => _i573.LoteProductoBloc(
          getLotesProductoUseCase: gh<_i799.GetLotesProductoUseCase>(),
          crearLoteProductoUseCase: gh<_i975.CrearLoteProductoUseCase>(),
        ));
    gh.lazySingleton<_i312.GetAppVersion>(
        () => _i312.GetAppVersion(gh<_i649.HomeRepository>()));
    gh.lazySingleton<_i485.GetUserData>(
        () => _i485.GetUserData(gh<_i649.HomeRepository>()));
    gh.lazySingleton<_i698.GetUserConfigurations>(
        () => _i698.GetUserConfigurations(gh<_i649.HomeRepository>()));
    gh.factory<_i565.UserBloc>(() => _i565.UserBloc(
          getUserConfiguration: gh<_i280.GetUserConfiguration>(),
          getDeviceInfo: gh<_i932.GetDeviceInfo>(),
          getUserLocations: gh<_i247.GetUserLocations>(),
          getUserNovelties: gh<_i465.GetUserNovelties>(),
          registerDevice: gh<_i902.RegisterDevice>(),
        ));
    gh.factory<_i545.ClusterPickingBloc>(() => _i545.ClusterPickingBloc(
          getPickingClusterData: gh<_i524.GetPickingClusterData>(),
          getLocalPickingClusterData: gh<_i295.GetLocalPickingClusterData>(),
          getLocalBatchProductsData: gh<_i61.GetLocalBatchProductsData>(),
          getLotesProductoUseCase: gh<_i799.GetLotesProductoUseCase>(),
          getUserConfiguration: gh<_i280.GetUserConfiguration>(),
          setClusterBatchFieldUseCase: gh<_i956.SetClusterBatchFieldUseCase>(),
          setClusterBatchProductFieldUseCase:
              gh<_i915.SetClusterBatchProductFieldUseCase>(),
          getBarcodesProductUseCase: gh<_i309.GetBarcodesProductUseCase>(),
          incrementQuantitySeparateUseCase:
              gh<_i85.IncrementQuantitySeparateUseCase>(),
          incrementProductSeparateQtyUseCase:
              gh<_i360.IncrementProductSeparateQtyUseCase>(),
          getFieldTableProductsUseCase:
              gh<_i235.GetFieldTableProductsUseCase>(),
          getProductBatchUseCase: gh<_i410.GetProductBatchUseCase>(),
          sendProductOdooUseCase: gh<_i984.SendProductOdooUseCase>(),
          viewProductImageUseCase: gh<_i149.ViewProductImageUseCase>(),
          getUserNovelties: gh<_i465.GetUserNovelties>(),
        ));
    gh.factory<_i20.EnterpriseBloc>(() => _i20.EnterpriseBloc(
          searchEnterpriseUseCase: gh<_i138.SearchEnterprise>(),
          getRecentUrlsUseCase: gh<_i91.GetRecentUrls>(),
          saveRecentUrlUseCase: gh<_i747.SaveRecentUrl>(),
          deleteRecentUrlUseCase: gh<_i552.DeleteRecentUrl>(),
        ));
    gh.lazySingleton<_i52.ValidateSession>(
        () => _i52.ValidateSession(gh<_i1015.AuthRepository>()));
    gh.factory<_i123.HomeBloc>(() => _i123.HomeBloc(
          getUserData: gh<_i485.GetUserData>(),
          getAppVersion: gh<_i312.GetAppVersion>(),
          getUserConfigurations: gh<_i698.GetUserConfigurations>(),
        ));
    gh.factory<_i363.AuthBloc>(
        () => _i363.AuthBloc(validateSession: gh<_i52.ValidateSession>()));
    return this;
  }
}

class _$RegisterModule extends _i809.RegisterModule {}
