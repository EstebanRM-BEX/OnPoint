// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

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
import 'features/chat/data/datasources/chat_local_data_source.dart' as _i804;
import 'features/chat/data/repositories/chat_repository_impl.dart' as _i382;
import 'features/chat/domain/repositories/chat_repository.dart' as _i453;
import 'features/chat/domain/usecases/ensure_conversation.dart' as _i476;
import 'features/chat/domain/usecases/get_contacts.dart' as _i100;
import 'features/chat/domain/usecases/get_conversations.dart' as _i720;
import 'features/chat/domain/usecases/get_current_user.dart' as _i708;
import 'features/chat/domain/usecases/get_messages.dart' as _i537;
import 'features/chat/domain/usecases/send_message.dart' as _i422;
import 'features/chat/presentation/bloc/chat_bloc.dart' as _i1026;
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
import 'features/enterprise/domain/usecases/search_enterprise.dart' as _i138;
import 'features/enterprise/presentation/bloc/enterprise_bloc.dart' as _i20;
import 'features/expedition/data/datasources/expedition_local_data_source.dart'
    as _i486;
import 'features/expedition/data/datasources/expedition_remote_data_source.dart'
    as _i260;
import 'features/expedition/data/repositories/expedition_repository_impl.dart'
    as _i838;
import 'features/expedition/data/services/expedition_sync_coordinator.dart'
    as _i169;
import 'features/expedition/domain/repositories/expedition_repository.dart'
    as _i777;
import 'features/expedition/domain/usecases/asignar_responsable_usecase.dart'
    as _i598;
import 'features/expedition/domain/usecases/confirmar_pedido_usecase.dart'
    as _i868;
import 'features/expedition/domain/usecases/deshacer_item_suelto_usecase.dart'
    as _i888;
import 'features/expedition/domain/usecases/deshacer_paquete_usecase.dart'
    as _i502;
import 'features/expedition/domain/usecases/fetch_expediciones_usecase.dart'
    as _i913;
import 'features/expedition/domain/usecases/get_expedicion_detail_usecase.dart'
    as _i324;
import 'features/expedition/domain/usecases/get_expediciones_from_db_usecase.dart'
    as _i683;
import 'features/expedition/domain/usecases/validar_item_suelto_usecase.dart'
    as _i944;
import 'features/expedition/domain/usecases/validar_multiple_usecase.dart'
    as _i955;
import 'features/expedition/domain/usecases/validar_paquete_usecase.dart'
    as _i749;
import 'features/expedition/presentation/bloc/assignment/expedicion_assignment_bloc.dart'
    as _i522;
import 'features/expedition/presentation/bloc/confirm/expedicion_confirm_bloc.dart'
    as _i777;
import 'features/expedition/presentation/bloc/detail/expedicion_detail_bloc.dart'
    as _i45;
import 'features/expedition/presentation/bloc/list/expedition_list_bloc.dart'
    as _i239;
import 'features/expedition/presentation/bloc/scan/expedicion_scan_bloc.dart'
    as _i770;
import 'features/home/data/datasources/home_local_data_source.dart' as _i205;
import 'features/home/data/datasources/home_remote_data_source.dart' as _i359;
import 'features/home/data/repositories/home_repository_impl.dart' as _i689;
import 'features/home/domain/repositories/home_repository.dart' as _i649;
import 'features/home/domain/usecases/get_app_version.dart' as _i312;
import 'features/home/domain/usecases/get_user_configurations.dart' as _i698;
import 'features/home/domain/usecases/get_user_data.dart' as _i485;
import 'features/home/presentation/bloc/home_bloc.dart' as _i123;
import 'features/inventario/data/datasources/inventario_local_data_source.dart'
    as _i812;
import 'features/inventario/data/datasources/inventario_remote_data_source.dart'
    as _i592;
import 'features/inventario/data/repositories/inventario_repository_impl.dart'
    as _i426;
import 'features/inventario/domain/repositories/inventario_repository.dart'
    as _i925;
import 'features/inventario/domain/usecases/crear_lote_inventario.dart'
    as _i589;
import 'features/inventario/domain/usecases/enviar_producto_inventario.dart'
    as _i46;
import 'features/inventario/domain/usecases/get_all_barcodes_inventario.dart'
    as _i377;
import 'features/inventario/domain/usecases/get_barcodes_producto.dart'
    as _i125;
import 'features/inventario/domain/usecases/get_configuracion_usuario_inventario.dart'
    as _i476;
import 'features/inventario/domain/usecases/get_lotes_producto.dart' as _i704;
import 'features/inventario/domain/usecases/get_productos_count.dart' as _i892;
import 'features/inventario/domain/usecases/get_productos_local.dart' as _i627;
import 'features/inventario/domain/usecases/get_ubicaciones_local.dart'
    as _i970;
import 'features/inventario/domain/usecases/get_url_imagen_producto.dart'
    as _i616;
import 'features/inventario/domain/usecases/sync_productos_inventario.dart'
    as _i19;
import 'features/inventario/presentation/bloc/inventario_bloc.dart' as _i731;
import 'features/login/data/datasources/login_local_data_source.dart' as _i544;
import 'features/login/data/datasources/login_remote_data_source.dart' as _i18;
import 'features/login/data/repositories/login_repository_impl.dart' as _i1059;
import 'features/login/domain/repositories/login_repository.dart' as _i889;
import 'features/login/domain/usecases/authenticate_user.dart' as _i792;
import 'features/login/domain/usecases/save_user_session.dart' as _i311;
import 'features/login/presentation/bloc/login_bloc.dart' as _i1070;
import 'features/packaging_types/data/datasources/local/packaging_type_local_datasource.dart'
    as _i3;
import 'features/packaging_types/data/datasources/remote/packaging_type_remote_datasource.dart'
    as _i846;
import 'features/packaging_types/data/repositories/packaging_type_repository_impl.dart'
    as _i690;
import 'features/packaging_types/domain/repositories/packaging_type_repository.dart'
    as _i72;
import 'features/packaging_types/domain/usecases/get_local_packaging_types_usecase.dart'
    as _i762;
import 'features/packaging_types/domain/usecases/get_packaging_types_usecase.dart'
    as _i658;
import 'features/packaging_types/presentation/bloc/packaging_type_bloc.dart'
    as _i475;
import 'features/picking/data/datasources/pick_scan_local_data_source.dart'
    as _i380;
import 'features/picking/data/datasources/pick_scan_remote_data_source.dart'
    as _i335;
import 'features/picking/data/datasources/picking_components_local_data_source.dart'
    as _i161;
import 'features/picking/data/datasources/picking_components_remote_data_source.dart'
    as _i682;
import 'features/picking/data/datasources/picking_local_data_source.dart'
    as _i860;
import 'features/picking/data/datasources/picking_remote_data_source.dart'
    as _i94;
import 'features/picking/data/repositories/pick_scan_repository_impl.dart'
    as _i334;
import 'features/picking/data/repositories/picking_components_repository_impl.dart'
    as _i355;
import 'features/picking/data/repositories/picking_repository_impl.dart' as _i8;
import 'features/picking/domain/repositories/pick_scan_repository.dart'
    as _i1048;
import 'features/picking/domain/repositories/picking_components_repository.dart'
    as _i268;
import 'features/picking/domain/repositories/picking_repository.dart' as _i661;
import 'features/picking/domain/usecases/assign_muelle_usecase.dart' as _i360;
import 'features/picking/domain/usecases/assign_user_to_pick_usecase.dart'
    as _i958;
import 'features/picking/domain/usecases/fetch_components_from_db_usecase.dart'
    as _i601;
import 'features/picking/domain/usecases/fetch_components_history_usecase.dart'
    as _i887;
import 'features/picking/domain/usecases/fetch_components_usecase.dart'
    as _i192;
import 'features/picking/domain/usecases/fetch_picks_history_usecase.dart'
    as _i924;
import 'features/picking/domain/usecases/fetch_picks_usecase.dart' as _i240;
import 'features/picking/domain/usecases/get_barcodes_product_usecase.dart'
    as _i696;
import 'features/picking/domain/usecases/get_muelles_usecase.dart' as _i351;
import 'features/picking/domain/usecases/get_pick_configurations_usecase.dart'
    as _i232;
import 'features/picking/domain/usecases/get_pick_with_products_usecase.dart'
    as _i266;
import 'features/picking/domain/usecases/get_product_image_usecase.dart'
    as _i592;
import 'features/picking/domain/usecases/get_products_for_edit_usecase.dart'
    as _i1058;
import 'features/picking/domain/usecases/get_scan_pick_with_products_usecase.dart'
    as _i141;
import 'features/picking/domain/usecases/increment_quantity_separate_usecase.dart'
    as _i936;
import 'features/picking/domain/usecases/mark_location_dest_ok_usecase.dart'
    as _i776;
import 'features/picking/domain/usecases/mark_location_ok_usecase.dart'
    as _i422;
import 'features/picking/domain/usecases/mark_pick_as_done_usecase.dart'
    as _i300;
import 'features/picking/domain/usecases/mark_product_ok_usecase.dart' as _i77;
import 'features/picking/domain/usecases/mark_quantity_ok_usecase.dart'
    as _i882;
import 'features/picking/domain/usecases/record_pick_time_usecase.dart' as _i23;
import 'features/picking/domain/usecases/send_product_to_odoo_usecase.dart'
    as _i617;
import 'features/picking/domain/usecases/start_stop_time_pick_usecase.dart'
    as _i95;
import 'features/picking/domain/usecases/update_quantity_separate_usecase.dart'
    as _i215;
import 'features/picking/domain/usecases/validate_confirm_pick_usecase.dart'
    as _i993;
import 'features/picking/domain/usecases/validate_transfer_usecase.dart'
    as _i820;
import 'features/picking/presentation/bloc/scan/pick_scan_bloc.dart' as _i989;
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
import 'features/picking_cluster/domain/usecases/end_time_pick_use_case.dart'
    as _i782;
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
import 'features/picking_cluster/domain/usecases/get_pending_send_products_use_case.dart'
    as _i542;
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
import 'features/picking_cluster/domain/usecases/set_cluster_batch_pedido_field_use_case.dart'
    as _i274;
import 'features/picking_cluster/domain/usecases/set_cluster_batch_product_field_use_case.dart'
    as _i915;
import 'features/picking_cluster/domain/usecases/start_time_pick_use_case.dart'
    as _i612;
import 'features/picking_cluster/domain/usecases/validate_pedido_usecase.dart'
    as _i1044;
import 'features/picking_cluster/domain/usecases/view_product_image_usecase.dart'
    as _i149;
import 'features/picking_cluster/presentation/bloc/cluster_picking/cluster_picking_bloc.dart'
    as _i545;
import 'features/picking_cluster/presentation/bloc/lote_producto/lote_producto_bloc.dart'
    as _i573;
import 'features/printing/data/repositories/printing_repository_impl.dart'
    as _i330;
import 'features/printing/domain/repositories/printing_repository.dart'
    as _i681;
import 'features/printing/domain/usecases/get_printers.dart' as _i277;
import 'features/printing/domain/usecases/print_report.dart' as _i152;
import 'features/printing/presentation/bloc/printing_bloc.dart' as _i335;
import 'features/recepcion_multiusuario/data/datasources/recepcion_multiusuario_local_data_source.dart'
    as _i330;
import 'features/recepcion_multiusuario/data/datasources/recepcion_multiusuario_remote_data_source.dart'
    as _i106;
import 'features/recepcion_multiusuario/data/repositories/recepcion_multiusuario_repository_impl.dart'
    as _i107;
import 'features/recepcion_multiusuario/domain/repositories/recepcion_multiusuario_repository.dart'
    as _i300;
import 'features/recepcion_multiusuario/domain/usecases/claim_recepcion_product_usecase.dart'
    as _i985;
import 'features/recepcion_multiusuario/domain/usecases/create_lote_usecase.dart'
    as _i667;
import 'features/recepcion_multiusuario/domain/usecases/fetch_lotes_producto_usecase.dart'
    as _i384;
import 'features/recepcion_multiusuario/domain/usecases/fetch_my_claims_usecase.dart'
    as _i546;
import 'features/recepcion_multiusuario/domain/usecases/fetch_recepcion_pool_usecase.dart'
    as _i102;
import 'features/recepcion_multiusuario/domain/usecases/fetch_recepcion_sessions_usecase.dart'
    as _i874;
import 'features/recepcion_multiusuario/domain/usecases/finish_claim_usecase.dart'
    as _i338;
import 'features/recepcion_multiusuario/domain/usecases/get_recepcion_pool_from_db_usecase.dart'
    as _i280;
import 'features/recepcion_multiusuario/domain/usecases/get_recepcion_sessions_from_db_usecase.dart'
    as _i231;
import 'features/recepcion_multiusuario/domain/usecases/release_claim_usecase.dart'
    as _i950;
import 'features/recepcion_multiusuario/domain/usecases/undo_claim_usecase.dart'
    as _i442;
import 'features/recepcion_multiusuario/presentation/bloc/detail/recepcion_multiusuario_my_claims_bloc.dart'
    as _i91;
import 'features/recepcion_multiusuario/presentation/bloc/detail/recepcion_multiusuario_pool_bloc.dart'
    as _i544;
import 'features/recepcion_multiusuario/presentation/bloc/list/recepcion_multiusuario_list_bloc.dart'
    as _i101;
import 'features/recepcion_multiusuario/presentation/bloc/location_dest/recepcion_multiusuario_location_dest_bloc.dart'
    as _i195;
import 'features/recepcion_multiusuario/presentation/bloc/lote/recepcion_multiusuario_lote_bloc.dart'
    as _i994;
import 'features/recepcion_multiusuario/presentation/bloc/scan/recepcion_multiusuario_scan_bloc.dart'
    as _i381;
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
import 'src/presentation/views/transferencias/data/transferencias_repository.dart'
    as _i895;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.factory<_i195.RecepcionMultiusuarioLocationDestBloc>(
      () => _i195.RecepcionMultiusuarioLocationDestBloc(),
    );
    gh.lazySingleton<_i519.Client>(() => registerModule.httpClient);
    gh.lazySingleton<_i895.Connectivity>(() => registerModule.connectivity);
    gh.lazySingleton<_i552.DataBaseSqlite>(() => registerModule.database);
    gh.lazySingleton<_i319.ApiRequestService>(
      () => registerModule.apiRequestService,
    );
    gh.lazySingleton<_i895.TransferenciasRepository>(
      () => _i895.TransferenciasRepository(),
    );
    gh.lazySingleton<_i380.PickScanLocalDataSource>(
      () => _i380.PickScanLocalDataSourceImpl(),
    );
    gh.lazySingleton<_i232.UserLocalDataSource>(
      () => _i232.UserLocalDataSourceImpl(gh<_i552.DataBaseSqlite>()),
    );
    gh.lazySingleton<_i688.IAudioService>(() => _i927.AudioServiceImpl());
    gh.lazySingleton<_i130.PickingClusterLocalDataSource>(
      () => _i130.PickingClusterLocalDataSourceImpl(),
    );
    gh.lazySingleton<_i537.IVibrationService>(
      () => _i869.VibrationServiceImpl(),
    );
    gh.lazySingleton<_i486.ExpeditionLocalDataSource>(
      () => _i486.ExpeditionLocalDataSourceImpl(),
    );
    gh.lazySingleton<_i359.HomeRemoteDataSource>(
      () => _i359.HomeRemoteDataSourceImpl(gh<_i319.ApiRequestService>()),
    );
    gh.lazySingleton<_i311.IDeviceInfoService>(
      () => _i910.DeviceInfoServiceImpl(),
    );
    gh.lazySingleton<_i75.NetworkInfo>(
      () => _i75.NetworkInfoImpl(gh<_i895.Connectivity>()),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i791.AuthLocalDataSource>(
      () => _i791.AuthLocalDataSourceImpl(),
    );
    gh.lazySingleton<_i544.LoginLocalDataSource>(
      () => _i544.LoginLocalDataSourceImpl(),
    );
    gh.factory<_i146.ConnectionStatusCubit>(
      () => _i146.ConnectionStatusCubit(networkInfo: gh<_i75.NetworkInfo>()),
    );
    gh.lazySingleton<_i94.PickingRemoteDataSource>(
      () => _i94.PickingRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i1071.UserRemoteDataSource>(
      () => _i1071.UserRemoteDataSourceImpl(gh<_i319.ApiRequestService>()),
    );
    gh.lazySingleton<_i330.RecepcionMultiusuarioLocalDataSource>(
      () => _i330.RecepcionMultiusuarioLocalDataSourceImpl(),
    );
    gh.lazySingleton<_i161.PickingComponentsLocalDataSource>(
      () => _i161.PickingComponentsLocalDataSourceImpl(),
    );
    gh.lazySingleton<_i615.INotificationService>(
      () => _i1011.NotificationService(),
    );
    gh.lazySingleton<_i918.EnterpriseRemoteDataSource>(
      () => _i918.EnterpriseRemoteDataSourceImpl(gh<_i319.ApiRequestService>()),
    );
    gh.lazySingleton<_i260.ExpeditionRemoteDataSource>(
      () => _i260.ExpeditionRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i846.PackagingTypeRemoteDataSource>(
      () => _i846.PackagingTypeRemoteDataSourceImpl(
        gh<_i319.ApiRequestService>(),
      ),
    );
    gh.lazySingleton<_i106.RecepcionMultiusuarioRemoteDataSource>(
      () => _i106.RecepcionMultiusuarioRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i18.LoginRemoteDataSource>(
      () => _i18.LoginRemoteDataSourceImpl(gh<_i319.ApiRequestService>()),
    );
    gh.lazySingleton<_i860.PickingLocalDataSource>(
      () => _i860.PickingLocalDataSourceImpl(),
    );
    gh.lazySingleton<_i682.PickingComponentsRemoteDataSource>(
      () => _i682.PickingComponentsRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i180.UserRepository>(
      () => _i39.UserRepositoryImpl(
        remoteDataSource: gh<_i1071.UserRemoteDataSource>(),
        localDataSource: gh<_i232.UserLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i592.InventarioRemoteDataSource>(
      () => _i592.InventarioRemoteDataSourceImpl(gh<_i319.ApiRequestService>()),
    );
    await gh.lazySingletonAsync<_i206.IStorageService>(() {
      final i = _i243.StorageService();
      return i.init().then((_) => i);
    }, preResolve: true);
    gh.lazySingleton<_i804.ChatLocalDataSource>(
      () => _i804.ChatLocalDataSourceImpl(),
    );
    gh.lazySingleton<_i681.PickingClusterRemoteDataSource>(
      () => _i681.PickingClusterRemoteDataSourceImpl(
        gh<_i319.ApiRequestService>(),
      ),
    );
    gh.lazySingleton<_i1062.IWebSocketService>(() => _i1020.WebSocketService());
    gh.lazySingleton<_i854.EnterpriseLocalDataSource>(
      () => _i854.EnterpriseLocalDataSourceImpl(gh<_i552.DataBaseSqlite>()),
    );
    gh.lazySingleton<_i453.ChatRepository>(
      () => _i382.ChatRepositoryImpl(gh<_i804.ChatLocalDataSource>()),
    );
    gh.lazySingleton<_i476.EnsureConversation>(
      () => _i476.EnsureConversation(gh<_i453.ChatRepository>()),
    );
    gh.lazySingleton<_i100.GetContacts>(
      () => _i100.GetContacts(gh<_i453.ChatRepository>()),
    );
    gh.lazySingleton<_i720.GetConversations>(
      () => _i720.GetConversations(gh<_i453.ChatRepository>()),
    );
    gh.lazySingleton<_i708.GetCurrentUser>(
      () => _i708.GetCurrentUser(gh<_i453.ChatRepository>()),
    );
    gh.lazySingleton<_i537.GetMessages>(
      () => _i537.GetMessages(gh<_i453.ChatRepository>()),
    );
    gh.lazySingleton<_i422.SendMessage>(
      () => _i422.SendMessage(gh<_i453.ChatRepository>()),
    );
    gh.lazySingleton<_i777.ExpeditionRepository>(
      () => _i838.ExpeditionRepositoryImpl(
        remoteDataSource: gh<_i260.ExpeditionRemoteDataSource>(),
        localDataSource: gh<_i486.ExpeditionLocalDataSource>(),
        networkInfo: gh<_i75.NetworkInfo>(),
        transferRepository: gh<_i895.TransferenciasRepository>(),
      ),
    );
    gh.lazySingleton<_i932.GetDeviceInfo>(
      () => _i932.GetDeviceInfo(gh<_i180.UserRepository>()),
    );
    gh.lazySingleton<_i280.GetUserConfiguration>(
      () => _i280.GetUserConfiguration(gh<_i180.UserRepository>()),
    );
    gh.lazySingleton<_i247.GetUserLocations>(
      () => _i247.GetUserLocations(gh<_i180.UserRepository>()),
    );
    gh.lazySingleton<_i465.GetUserNovelties>(
      () => _i465.GetUserNovelties(gh<_i180.UserRepository>()),
    );
    gh.lazySingleton<_i902.RegisterDevice>(
      () => _i902.RegisterDevice(gh<_i180.UserRepository>()),
    );
    gh.lazySingleton<_i889.LoginRepository>(
      () => _i1059.LoginRepositoryImpl(
        remoteDataSource: gh<_i18.LoginRemoteDataSource>(),
        localDataSource: gh<_i544.LoginLocalDataSource>(),
        networkInfo: gh<_i75.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i661.PickingRepository>(
      () => _i8.PickingRepositoryImpl(
        remoteDataSource: gh<_i94.PickingRemoteDataSource>(),
        localDataSource: gh<_i860.PickingLocalDataSource>(),
        networkInfo: gh<_i75.NetworkInfo>(),
        transferRepository: gh<_i895.TransferenciasRepository>(),
      ),
    );
    gh.lazySingleton<_i958.AssignUserToPickUseCase>(
      () => _i958.AssignUserToPickUseCase(gh<_i661.PickingRepository>()),
    );
    gh.lazySingleton<_i924.FetchPicksHistoryUseCase>(
      () => _i924.FetchPicksHistoryUseCase(gh<_i661.PickingRepository>()),
    );
    gh.lazySingleton<_i240.FetchPicksUseCase>(
      () => _i240.FetchPicksUseCase(gh<_i661.PickingRepository>()),
    );
    gh.lazySingleton<_i232.GetPickConfigurationsUseCase>(
      () => _i232.GetPickConfigurationsUseCase(gh<_i661.PickingRepository>()),
    );
    gh.lazySingleton<_i266.GetPickWithProductsUseCase>(
      () => _i266.GetPickWithProductsUseCase(gh<_i661.PickingRepository>()),
    );
    gh.lazySingleton<_i95.StartStopTimePickUseCase>(
      () => _i95.StartStopTimePickUseCase(gh<_i661.PickingRepository>()),
    );
    gh.lazySingleton<_i932.IPickingClusterRepository>(
      () => _i110.PickingClusterRepositoryImpl(
        gh<_i681.PickingClusterRemoteDataSource>(),
        gh<_i130.PickingClusterLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i205.HomeLocalDataSource>(
      () => _i205.HomeLocalDataSourceImpl(gh<_i552.DataBaseSqlite>()),
    );
    gh.lazySingleton<_i169.ExpeditionSyncCoordinator>(
      () => _i169.ExpeditionSyncCoordinator(
        networkInfo: gh<_i75.NetworkInfo>(),
        remoteDataSource: gh<_i260.ExpeditionRemoteDataSource>(),
        localDataSource: gh<_i486.ExpeditionLocalDataSource>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i3.PackagingTypeLocalDataSource>(
      () => _i3.PackagingTypeLocalDataSourceImpl(gh<_i552.DataBaseSqlite>()),
    );
    gh.lazySingleton<_i681.PrintingRepository>(
      () => _i330.PrintingRepositoryImpl(
        apiService: gh<_i319.ApiRequestService>(),
      ),
    );
    gh.lazySingleton<_i812.InventarioLocalDataSource>(
      () => _i812.InventarioLocalDataSourceImpl(gh<_i552.DataBaseSqlite>()),
    );
    gh.factory<_i676.WebSocketBloc>(
      () =>
          _i676.WebSocketBloc(webSocketService: gh<_i1062.IWebSocketService>()),
    );
    gh.lazySingleton<_i309.EnterpriseRepository>(
      () => _i331.EnterpriseRepositoryImpl(
        remoteDataSource: gh<_i918.EnterpriseRemoteDataSource>(),
        localDataSource: gh<_i854.EnterpriseLocalDataSource>(),
        networkInfo: gh<_i75.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i1015.AuthRepository>(
      () => _i111.AuthRepositoryImpl(
        localDataSource: gh<_i791.AuthLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i792.AuthenticateUser>(
      () => _i792.AuthenticateUser(gh<_i889.LoginRepository>()),
    );
    gh.lazySingleton<_i311.SaveUserSession>(
      () => _i311.SaveUserSession(gh<_i889.LoginRepository>()),
    );
    gh.lazySingleton<_i975.CrearLoteProductoUseCase>(
      () =>
          _i975.CrearLoteProductoUseCase(gh<_i932.IPickingClusterRepository>()),
    );
    gh.lazySingleton<_i782.EndTimePickUseCase>(
      () => _i782.EndTimePickUseCase(gh<_i932.IPickingClusterRepository>()),
    );
    gh.lazySingleton<_i309.GetBarcodesProductUseCase>(
      () => _i309.GetBarcodesProductUseCase(
        gh<_i932.IPickingClusterRepository>(),
      ),
    );
    gh.lazySingleton<_i235.GetFieldTableProductsUseCase>(
      () => _i235.GetFieldTableProductsUseCase(
        gh<_i932.IPickingClusterRepository>(),
      ),
    );
    gh.lazySingleton<_i61.GetLocalBatchProductsData>(
      () =>
          _i61.GetLocalBatchProductsData(gh<_i932.IPickingClusterRepository>()),
    );
    gh.lazySingleton<_i295.GetLocalPickingClusterData>(
      () => _i295.GetLocalPickingClusterData(
        gh<_i932.IPickingClusterRepository>(),
      ),
    );
    gh.lazySingleton<_i799.GetLotesProductoUseCase>(
      () =>
          _i799.GetLotesProductoUseCase(gh<_i932.IPickingClusterRepository>()),
    );
    gh.lazySingleton<_i542.GetPendingSendProductsUseCase>(
      () => _i542.GetPendingSendProductsUseCase(
        gh<_i932.IPickingClusterRepository>(),
      ),
    );
    gh.lazySingleton<_i524.GetPickingClusterData>(
      () => _i524.GetPickingClusterData(gh<_i932.IPickingClusterRepository>()),
    );
    gh.lazySingleton<_i410.GetProductBatchUseCase>(
      () => _i410.GetProductBatchUseCase(gh<_i932.IPickingClusterRepository>()),
    );
    gh.lazySingleton<_i360.IncrementProductSeparateQtyUseCase>(
      () => _i360.IncrementProductSeparateQtyUseCase(
        gh<_i932.IPickingClusterRepository>(),
      ),
    );
    gh.lazySingleton<_i85.IncrementQuantitySeparateUseCase>(
      () => _i85.IncrementQuantitySeparateUseCase(
        gh<_i932.IPickingClusterRepository>(),
      ),
    );
    gh.lazySingleton<_i984.SendProductOdooUseCase>(
      () => _i984.SendProductOdooUseCase(gh<_i932.IPickingClusterRepository>()),
    );
    gh.lazySingleton<_i956.SetClusterBatchFieldUseCase>(
      () => _i956.SetClusterBatchFieldUseCase(
        gh<_i932.IPickingClusterRepository>(),
      ),
    );
    gh.lazySingleton<_i274.SetClusterBatchPedidoFieldUseCase>(
      () => _i274.SetClusterBatchPedidoFieldUseCase(
        gh<_i932.IPickingClusterRepository>(),
      ),
    );
    gh.lazySingleton<_i915.SetClusterBatchProductFieldUseCase>(
      () => _i915.SetClusterBatchProductFieldUseCase(
        gh<_i932.IPickingClusterRepository>(),
      ),
    );
    gh.lazySingleton<_i612.StartTimePickUseCase>(
      () => _i612.StartTimePickUseCase(gh<_i932.IPickingClusterRepository>()),
    );
    gh.lazySingleton<_i1044.ValidatePedidoUseCase>(
      () => _i1044.ValidatePedidoUseCase(gh<_i932.IPickingClusterRepository>()),
    );
    gh.lazySingleton<_i149.ViewProductImageUseCase>(
      () =>
          _i149.ViewProductImageUseCase(gh<_i932.IPickingClusterRepository>()),
    );
    gh.lazySingleton<_i268.PickingComponentsRepository>(
      () => _i355.PickingComponentsRepositoryImpl(
        remoteDataSource: gh<_i682.PickingComponentsRemoteDataSource>(),
        localDataSource: gh<_i161.PickingComponentsLocalDataSource>(),
        networkInfo: gh<_i75.NetworkInfo>(),
      ),
    );
    gh.factory<_i1070.LoginBloc>(
      () => _i1070.LoginBloc(authenticateUser: gh<_i792.AuthenticateUser>()),
    );
    gh.lazySingleton<_i925.InventarioRepository>(
      () => _i426.InventarioRepositoryImpl(
        remoteDataSource: gh<_i592.InventarioRemoteDataSource>(),
        localDataSource: gh<_i812.InventarioLocalDataSource>(),
        networkInfo: gh<_i75.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i300.RecepcionMultiusuarioRepository>(
      () => _i107.RecepcionMultiusuarioRepositoryImpl(
        remoteDataSource: gh<_i106.RecepcionMultiusuarioRemoteDataSource>(),
        localDataSource: gh<_i330.RecepcionMultiusuarioLocalDataSource>(),
        networkInfo: gh<_i75.NetworkInfo>(),
      ),
    );
    gh.factory<_i1026.ChatBloc>(
      () => _i1026.ChatBloc(
        getCurrentUser: gh<_i708.GetCurrentUser>(),
        getConversations: gh<_i720.GetConversations>(),
        getContacts: gh<_i100.GetContacts>(),
        getMessages: gh<_i537.GetMessages>(),
        sendMessage: gh<_i422.SendMessage>(),
        ensureConversation: gh<_i476.EnsureConversation>(),
      ),
    );
    gh.lazySingleton<_i649.HomeRepository>(
      () => _i689.HomeRepositoryImpl(
        remoteDataSource: gh<_i359.HomeRemoteDataSource>(),
        localDataSource: gh<_i205.HomeLocalDataSource>(),
        networkInfo: gh<_i75.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i598.AsignarResponsableUseCase>(
      () => _i598.AsignarResponsableUseCase(gh<_i777.ExpeditionRepository>()),
    );
    gh.lazySingleton<_i868.ConfirmarPedidoUseCase>(
      () => _i868.ConfirmarPedidoUseCase(gh<_i777.ExpeditionRepository>()),
    );
    gh.lazySingleton<_i888.DeshacerItemSueltoUseCase>(
      () => _i888.DeshacerItemSueltoUseCase(gh<_i777.ExpeditionRepository>()),
    );
    gh.lazySingleton<_i502.DeshacerPaqueteUseCase>(
      () => _i502.DeshacerPaqueteUseCase(gh<_i777.ExpeditionRepository>()),
    );
    gh.lazySingleton<_i913.FetchExpedicionesUseCase>(
      () => _i913.FetchExpedicionesUseCase(gh<_i777.ExpeditionRepository>()),
    );
    gh.lazySingleton<_i324.GetExpedicionDetailUseCase>(
      () => _i324.GetExpedicionDetailUseCase(gh<_i777.ExpeditionRepository>()),
    );
    gh.lazySingleton<_i683.GetExpedicionesFromDbUseCase>(
      () =>
          _i683.GetExpedicionesFromDbUseCase(gh<_i777.ExpeditionRepository>()),
    );
    gh.lazySingleton<_i944.ValidarItemSueltoUseCase>(
      () => _i944.ValidarItemSueltoUseCase(gh<_i777.ExpeditionRepository>()),
    );
    gh.lazySingleton<_i955.ValidarMultipleUseCase>(
      () => _i955.ValidarMultipleUseCase(gh<_i777.ExpeditionRepository>()),
    );
    gh.lazySingleton<_i749.ValidarPaqueteUseCase>(
      () => _i749.ValidarPaqueteUseCase(gh<_i777.ExpeditionRepository>()),
    );
    gh.factory<_i573.LoteProductoBloc>(
      () => _i573.LoteProductoBloc(
        getLotesProductoUseCase: gh<_i799.GetLotesProductoUseCase>(),
        crearLoteProductoUseCase: gh<_i975.CrearLoteProductoUseCase>(),
      ),
    );
    gh.lazySingleton<_i312.GetAppVersion>(
      () => _i312.GetAppVersion(gh<_i649.HomeRepository>()),
    );
    gh.lazySingleton<_i698.GetUserConfigurations>(
      () => _i698.GetUserConfigurations(gh<_i649.HomeRepository>()),
    );
    gh.lazySingleton<_i485.GetUserData>(
      () => _i485.GetUserData(gh<_i649.HomeRepository>()),
    );
    gh.factory<_i565.UserBloc>(
      () => _i565.UserBloc(
        getUserConfiguration: gh<_i280.GetUserConfiguration>(),
        getDeviceInfo: gh<_i932.GetDeviceInfo>(),
        getUserLocations: gh<_i247.GetUserLocations>(),
        getUserNovelties: gh<_i465.GetUserNovelties>(),
        registerDevice: gh<_i902.RegisterDevice>(),
        saveUserSession: gh<_i311.SaveUserSession>(),
      ),
    );
    gh.lazySingleton<_i985.ClaimRecepcionProductUseCase>(
      () => _i985.ClaimRecepcionProductUseCase(
        gh<_i300.RecepcionMultiusuarioRepository>(),
      ),
    );
    gh.lazySingleton<_i667.CreateLoteUseCase>(
      () =>
          _i667.CreateLoteUseCase(gh<_i300.RecepcionMultiusuarioRepository>()),
    );
    gh.lazySingleton<_i384.FetchLotesProductoUseCase>(
      () => _i384.FetchLotesProductoUseCase(
        gh<_i300.RecepcionMultiusuarioRepository>(),
      ),
    );
    gh.lazySingleton<_i546.FetchMyClaimsUseCase>(
      () => _i546.FetchMyClaimsUseCase(
        gh<_i300.RecepcionMultiusuarioRepository>(),
      ),
    );
    gh.lazySingleton<_i102.FetchRecepcionPoolUseCase>(
      () => _i102.FetchRecepcionPoolUseCase(
        gh<_i300.RecepcionMultiusuarioRepository>(),
      ),
    );
    gh.lazySingleton<_i874.FetchRecepcionSessionsUseCase>(
      () => _i874.FetchRecepcionSessionsUseCase(
        gh<_i300.RecepcionMultiusuarioRepository>(),
      ),
    );
    gh.lazySingleton<_i338.FinishClaimUseCase>(
      () =>
          _i338.FinishClaimUseCase(gh<_i300.RecepcionMultiusuarioRepository>()),
    );
    gh.lazySingleton<_i280.GetRecepcionPoolFromDbUseCase>(
      () => _i280.GetRecepcionPoolFromDbUseCase(
        gh<_i300.RecepcionMultiusuarioRepository>(),
      ),
    );
    gh.lazySingleton<_i231.GetRecepcionSessionsFromDbUseCase>(
      () => _i231.GetRecepcionSessionsFromDbUseCase(
        gh<_i300.RecepcionMultiusuarioRepository>(),
      ),
    );
    gh.lazySingleton<_i950.ReleaseClaimUseCase>(
      () => _i950.ReleaseClaimUseCase(
        gh<_i300.RecepcionMultiusuarioRepository>(),
      ),
    );
    gh.lazySingleton<_i442.UndoClaimUseCase>(
      () => _i442.UndoClaimUseCase(gh<_i300.RecepcionMultiusuarioRepository>()),
    );
    gh.lazySingleton<_i601.FetchComponentsFromDbUseCase>(
      () => _i601.FetchComponentsFromDbUseCase(
        gh<_i268.PickingComponentsRepository>(),
      ),
    );
    gh.lazySingleton<_i887.FetchComponentsHistoryUseCase>(
      () => _i887.FetchComponentsHistoryUseCase(
        gh<_i268.PickingComponentsRepository>(),
      ),
    );
    gh.lazySingleton<_i192.FetchComponentsUseCase>(
      () =>
          _i192.FetchComponentsUseCase(gh<_i268.PickingComponentsRepository>()),
    );
    gh.factory<_i91.RecepcionMultiusuarioMyClaimsBloc>(
      () => _i91.RecepcionMultiusuarioMyClaimsBloc(
        fetchMyClaimsUseCase: gh<_i546.FetchMyClaimsUseCase>(),
        releaseClaimUseCase: gh<_i950.ReleaseClaimUseCase>(),
      ),
    );
    gh.lazySingleton<_i72.PackagingTypeRepository>(
      () => _i690.PackagingTypeRepositoryImpl(
        remoteDataSource: gh<_i846.PackagingTypeRemoteDataSource>(),
        localDataSource: gh<_i3.PackagingTypeLocalDataSource>(),
      ),
    );
    gh.factory<_i994.RecepcionMultiusuarioLoteBloc>(
      () => _i994.RecepcionMultiusuarioLoteBloc(
        fetchLotesProductoUseCase: gh<_i384.FetchLotesProductoUseCase>(),
        createLoteUseCase: gh<_i667.CreateLoteUseCase>(),
      ),
    );
    gh.factory<_i522.ExpedicionAssignmentBloc>(
      () => _i522.ExpedicionAssignmentBloc(
        asignarResponsableUseCase: gh<_i598.AsignarResponsableUseCase>(),
      ),
    );
    gh.lazySingleton<_i277.GetPrinters>(
      () => _i277.GetPrinters(gh<_i681.PrintingRepository>()),
    );
    gh.lazySingleton<_i152.PrintReport>(
      () => _i152.PrintReport(gh<_i681.PrintingRepository>()),
    );
    gh.lazySingleton<_i552.DeleteRecentUrl>(
      () => _i552.DeleteRecentUrl(gh<_i309.EnterpriseRepository>()),
    );
    gh.lazySingleton<_i91.GetRecentUrls>(
      () => _i91.GetRecentUrls(gh<_i309.EnterpriseRepository>()),
    );
    gh.lazySingleton<_i138.SearchEnterprise>(
      () => _i138.SearchEnterprise(gh<_i309.EnterpriseRepository>()),
    );
    gh.factory<_i45.ExpedicionDetailBloc>(
      () => _i45.ExpedicionDetailBloc(
        getExpedicionDetailUseCase: gh<_i324.GetExpedicionDetailUseCase>(),
      ),
    );
    gh.lazySingleton<_i52.ValidateSession>(
      () => _i52.ValidateSession(gh<_i1015.AuthRepository>()),
    );
    gh.factory<_i20.EnterpriseBloc>(
      () => _i20.EnterpriseBloc(
        searchEnterpriseUseCase: gh<_i138.SearchEnterprise>(),
        getRecentUrlsUseCase: gh<_i91.GetRecentUrls>(),
        deleteRecentUrlUseCase: gh<_i552.DeleteRecentUrl>(),
      ),
    );
    gh.factory<_i770.ExpedicionScanBloc>(
      () => _i770.ExpedicionScanBloc(
        validarPaqueteUseCase: gh<_i749.ValidarPaqueteUseCase>(),
        validarItemSueltoUseCase: gh<_i944.ValidarItemSueltoUseCase>(),
        validarMultipleUseCase: gh<_i955.ValidarMultipleUseCase>(),
        deshacerPaqueteUseCase: gh<_i502.DeshacerPaqueteUseCase>(),
        deshacerItemSueltoUseCase: gh<_i888.DeshacerItemSueltoUseCase>(),
        syncCoordinator: gh<_i169.ExpeditionSyncCoordinator>(),
      ),
    );
    gh.factory<_i101.RecepcionMultiusuarioListBloc>(
      () => _i101.RecepcionMultiusuarioListBloc(
        fetchRecepcionSessionsUseCase:
            gh<_i874.FetchRecepcionSessionsUseCase>(),
        getRecepcionSessionsFromDbUseCase:
            gh<_i231.GetRecepcionSessionsFromDbUseCase>(),
      ),
    );
    gh.factory<_i545.ClusterPickingBloc>(
      () => _i545.ClusterPickingBloc(
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
        getFieldTableProductsUseCase: gh<_i235.GetFieldTableProductsUseCase>(),
        getProductBatchUseCase: gh<_i410.GetProductBatchUseCase>(),
        sendProductOdooUseCase: gh<_i984.SendProductOdooUseCase>(),
        getUserNovelties: gh<_i465.GetUserNovelties>(),
        getPendingSendProductsUseCase:
            gh<_i542.GetPendingSendProductsUseCase>(),
        networkInfo: gh<_i75.NetworkInfo>(),
      ),
    );
    gh.factory<_i239.ExpedicionListBloc>(
      () => _i239.ExpedicionListBloc(
        fetchExpedicionesUseCase: gh<_i913.FetchExpedicionesUseCase>(),
        getExpedicionesFromDbUseCase: gh<_i683.GetExpedicionesFromDbUseCase>(),
      ),
    );
    gh.lazySingleton<_i589.CrearLoteInventario>(
      () => _i589.CrearLoteInventario(gh<_i925.InventarioRepository>()),
    );
    gh.lazySingleton<_i46.EnviarProductoInventario>(
      () => _i46.EnviarProductoInventario(gh<_i925.InventarioRepository>()),
    );
    gh.lazySingleton<_i377.GetAllBarcodesInventario>(
      () => _i377.GetAllBarcodesInventario(gh<_i925.InventarioRepository>()),
    );
    gh.lazySingleton<_i125.GetBarcodesProducto>(
      () => _i125.GetBarcodesProducto(gh<_i925.InventarioRepository>()),
    );
    gh.lazySingleton<_i476.GetConfiguracionUsuarioInventario>(
      () => _i476.GetConfiguracionUsuarioInventario(
        gh<_i925.InventarioRepository>(),
      ),
    );
    gh.lazySingleton<_i704.GetLotesProducto>(
      () => _i704.GetLotesProducto(gh<_i925.InventarioRepository>()),
    );
    gh.lazySingleton<_i892.GetProductosCount>(
      () => _i892.GetProductosCount(gh<_i925.InventarioRepository>()),
    );
    gh.lazySingleton<_i627.GetProductosLocal>(
      () => _i627.GetProductosLocal(gh<_i925.InventarioRepository>()),
    );
    gh.lazySingleton<_i970.GetUbicacionesLocal>(
      () => _i970.GetUbicacionesLocal(gh<_i925.InventarioRepository>()),
    );
    gh.lazySingleton<_i616.GetUrlImagenProducto>(
      () => _i616.GetUrlImagenProducto(gh<_i925.InventarioRepository>()),
    );
    gh.lazySingleton<_i19.SyncProductosInventario>(
      () => _i19.SyncProductosInventario(gh<_i925.InventarioRepository>()),
    );
    gh.factory<_i123.HomeBloc>(
      () => _i123.HomeBloc(
        getUserData: gh<_i485.GetUserData>(),
        getAppVersion: gh<_i312.GetAppVersion>(),
        getUserConfigurations: gh<_i698.GetUserConfigurations>(),
      ),
    );
    gh.factory<_i335.PrintingBloc>(
      () => _i335.PrintingBloc(
        getPrinters: gh<_i277.GetPrinters>(),
        printReport: gh<_i152.PrintReport>(),
      ),
    );
    gh.factory<_i777.ExpedicionConfirmBloc>(
      () => _i777.ExpedicionConfirmBloc(
        confirmarPedidoUseCase: gh<_i868.ConfirmarPedidoUseCase>(),
      ),
    );
    gh.factory<_i381.RecepcionMultiusuarioScanBloc>(
      () => _i381.RecepcionMultiusuarioScanBloc(
        claimRecepcionProductUseCase: gh<_i985.ClaimRecepcionProductUseCase>(),
      ),
    );
    gh.factory<_i363.AuthBloc>(
      () => _i363.AuthBloc(validateSession: gh<_i52.ValidateSession>()),
    );
    gh.lazySingleton<_i762.GetLocalPackagingTypesUseCase>(
      () => _i762.GetLocalPackagingTypesUseCase(
        gh<_i72.PackagingTypeRepository>(),
      ),
    );
    gh.lazySingleton<_i658.GetPackagingTypesUseCase>(
      () => _i658.GetPackagingTypesUseCase(gh<_i72.PackagingTypeRepository>()),
    );
    gh.factory<_i544.RecepcionMultiusuarioPoolBloc>(
      () => _i544.RecepcionMultiusuarioPoolBloc(
        fetchRecepcionPoolUseCase: gh<_i102.FetchRecepcionPoolUseCase>(),
        getRecepcionPoolFromDbUseCase:
            gh<_i280.GetRecepcionPoolFromDbUseCase>(),
      ),
    );
    gh.factory<_i475.PackagingTypeBloc>(
      () => _i475.PackagingTypeBloc(
        getPackagingTypesUseCase: gh<_i658.GetPackagingTypesUseCase>(),
        getLocalPackagingTypesUseCase:
            gh<_i762.GetLocalPackagingTypesUseCase>(),
      ),
    );
    gh.factory<_i731.InventarioBloc>(
      () => _i731.InventarioBloc(
        syncProductosInventario: gh<_i19.SyncProductosInventario>(),
        getProductosLocal: gh<_i627.GetProductosLocal>(),
        getProductosCount: gh<_i892.GetProductosCount>(),
        getUbicacionesLocal: gh<_i970.GetUbicacionesLocal>(),
        getLotesProducto: gh<_i704.GetLotesProducto>(),
        enviarProductoInventario: gh<_i46.EnviarProductoInventario>(),
        crearLoteInventario: gh<_i589.CrearLoteInventario>(),
        getBarcodesProducto: gh<_i125.GetBarcodesProducto>(),
        getAllBarcodesInventario: gh<_i377.GetAllBarcodesInventario>(),
        getConfiguracionUsuarioInventario:
            gh<_i476.GetConfiguracionUsuarioInventario>(),
      ),
    );
    gh.lazySingleton<_i335.PickScanRemoteDataSource>(
      () =>
          _i335.PickScanRemoteDataSourceImpl(gh<_i616.GetUrlImagenProducto>()),
    );
    gh.lazySingleton<_i1048.PickScanRepository>(
      () => _i334.PickScanRepositoryImpl(
        remoteDataSource: gh<_i335.PickScanRemoteDataSource>(),
        localDataSource: gh<_i380.PickScanLocalDataSource>(),
        networkInfo: gh<_i75.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i360.AssignMuelleUseCase>(
      () => _i360.AssignMuelleUseCase(gh<_i1048.PickScanRepository>()),
    );
    gh.lazySingleton<_i696.GetBarcodesProductUseCase>(
      () => _i696.GetBarcodesProductUseCase(gh<_i1048.PickScanRepository>()),
    );
    gh.lazySingleton<_i351.GetMuellesUseCase>(
      () => _i351.GetMuellesUseCase(gh<_i1048.PickScanRepository>()),
    );
    gh.lazySingleton<_i592.GetProductImageUseCase>(
      () => _i592.GetProductImageUseCase(gh<_i1048.PickScanRepository>()),
    );
    gh.lazySingleton<_i1058.GetProductsForEditUseCase>(
      () => _i1058.GetProductsForEditUseCase(gh<_i1048.PickScanRepository>()),
    );
    gh.lazySingleton<_i141.GetScanPickWithProductsUseCase>(
      () =>
          _i141.GetScanPickWithProductsUseCase(gh<_i1048.PickScanRepository>()),
    );
    gh.lazySingleton<_i936.IncrementQuantitySeparateUseCase>(
      () => _i936.IncrementQuantitySeparateUseCase(
        gh<_i1048.PickScanRepository>(),
      ),
    );
    gh.lazySingleton<_i776.MarkLocationDestOkUseCase>(
      () => _i776.MarkLocationDestOkUseCase(gh<_i1048.PickScanRepository>()),
    );
    gh.lazySingleton<_i422.MarkLocationOkUseCase>(
      () => _i422.MarkLocationOkUseCase(gh<_i1048.PickScanRepository>()),
    );
    gh.lazySingleton<_i300.MarkPickAsDoneUseCase>(
      () => _i300.MarkPickAsDoneUseCase(gh<_i1048.PickScanRepository>()),
    );
    gh.lazySingleton<_i77.MarkProductOkUseCase>(
      () => _i77.MarkProductOkUseCase(gh<_i1048.PickScanRepository>()),
    );
    gh.lazySingleton<_i882.MarkQuantityOkUseCase>(
      () => _i882.MarkQuantityOkUseCase(gh<_i1048.PickScanRepository>()),
    );
    gh.lazySingleton<_i23.RecordPickTimeUseCase>(
      () => _i23.RecordPickTimeUseCase(gh<_i1048.PickScanRepository>()),
    );
    gh.lazySingleton<_i617.SendProductToOdooUseCase>(
      () => _i617.SendProductToOdooUseCase(gh<_i1048.PickScanRepository>()),
    );
    gh.lazySingleton<_i215.UpdateQuantitySeparateUseCase>(
      () =>
          _i215.UpdateQuantitySeparateUseCase(gh<_i1048.PickScanRepository>()),
    );
    gh.lazySingleton<_i993.ValidateConfirmPickUseCase>(
      () => _i993.ValidateConfirmPickUseCase(gh<_i1048.PickScanRepository>()),
    );
    gh.lazySingleton<_i820.ValidateTransferUseCase>(
      () => _i820.ValidateTransferUseCase(gh<_i1048.PickScanRepository>()),
    );
    gh.factory<_i989.PickScanBloc>(
      () => _i989.PickScanBloc(
        markLocationOkUseCase: gh<_i422.MarkLocationOkUseCase>(),
        markLocationDestOkUseCase: gh<_i776.MarkLocationDestOkUseCase>(),
        markProductOkUseCase: gh<_i77.MarkProductOkUseCase>(),
        markQuantityOkUseCase: gh<_i882.MarkQuantityOkUseCase>(),
        updateQuantitySeparateUseCase:
            gh<_i215.UpdateQuantitySeparateUseCase>(),
        incrementQuantitySeparateUseCase:
            gh<_i936.IncrementQuantitySeparateUseCase>(),
        getScanPickWithProductsUseCase:
            gh<_i141.GetScanPickWithProductsUseCase>(),
        getBarcodesProductUseCase: gh<_i696.GetBarcodesProductUseCase>(),
        getProductsForEditUseCase: gh<_i1058.GetProductsForEditUseCase>(),
        getMuellesUseCase: gh<_i351.GetMuellesUseCase>(),
        getProductImageUseCase: gh<_i592.GetProductImageUseCase>(),
        validateConfirmPickUseCase: gh<_i993.ValidateConfirmPickUseCase>(),
        validateTransferUseCase: gh<_i820.ValidateTransferUseCase>(),
        markPickAsDoneUseCase: gh<_i300.MarkPickAsDoneUseCase>(),
        recordPickTimeUseCase: gh<_i23.RecordPickTimeUseCase>(),
        sendProductToOdooUseCase: gh<_i617.SendProductToOdooUseCase>(),
        assignMuelleUseCase: gh<_i360.AssignMuelleUseCase>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i809.RegisterModule {}
