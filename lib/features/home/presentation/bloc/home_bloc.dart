// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/user/domain/entities/user_configuration.dart';
import 'package:wms_app/features/home/domain/entities/app_version.dart';
import 'package:wms_app/features/home/domain/usecases/get_app_version.dart';
import 'package:wms_app/features/home/domain/usecases/get_user_data.dart';
import 'package:wms_app/features/home/domain/usecases/get_user_configurations.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';

part 'home_event.dart';
part 'home_state.dart';

/// Home BLoC with dependency injection and Clean Architecture.
///
/// This BLoC manages the home screen state including user data,
/// app version checking, and user configurations.
@injectable
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetUserData getUserData;
  final GetAppVersion getAppVersion;
  final GetUserConfigurations getUserConfigurations;

  String userName = "";
  String userEmail = "";
  String userRol = "";

  //* User configurations/permissions
  UserConfiguration configurations = UserConfiguration();

  //* App version info (for backward compatibility)
  AppVersion appVersion = AppVersion();

  HomeBloc({
    required this.getUserData,
    required this.getAppVersion,
    required this.getUserConfigurations,
  }) : super(HomeInitial()) {
    on<HomeLoadData>(_onHomeLoadData);
    on<AppVersionEvent>(_onAppVersionEvent);
    on<ClearDataEvent>(_onClearDataEvent);
    on<LoadConfigurationsEvent>(_onLoadConfigurations);

    // Auto-load user data on initialization
    add(HomeLoadData());
  }

  Future<void> _onHomeLoadData(
    HomeLoadData event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoadingState());

    final result = await getUserData(NoParams());

    result.fold(
      (failure) {
        emit(HomeLoadErrorState());
      },
      (userData) {
        userName = userData.name;
        userEmail = userData.email;
        userRol = userData.rol;
        emit(HomeLoadedState());

        // Also load configurations after user data is loaded
        add(LoadConfigurationsEvent());
      },
    );
  }

  Future<void> _onAppVersionEvent(
    AppVersionEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(AppVersionLoadingState());

    final result = await getAppVersion(NoParams());

    await result.fold(
      (failure) async {
        debugPrint('Error loading app version: ${failure.message}');

        // Emit specific state for session expired
        if (failure.runtimeType.toString() == 'SessionExpiredFailure') {
          emit(SessionExpiredState(failure.message));
        } else {
          emit(AppVersionLoadErrorState(failure.message));
        }
      },
      (appVersionData) async {
        if (appVersionData.result == null) {
          emit(AppVersionLoadErrorState(appVersionData.message));
          return;
        }

        // Store app version for backward compatibility
        appVersion = appVersionData;

        // Get current app version
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;
        final serverVersion = appVersionData.result?.result?.version ?? '';

        debugPrint(
            'Current version: $currentVersion, Server version: $serverVersion');

        // Compare versions
        if (currentVersion == serverVersion) {
          debugPrint('App is up to date: $currentVersion');
          emit(AppVersionLoadedState(appVersionData));
        } else if (currentVersion.compareTo(serverVersion) > 0) {
          debugPrint('App is newer than server: $currentVersion');
          emit(AppVersionLoadedState(appVersionData));
        } else if (currentVersion.compareTo(serverVersion) < 0) {
          debugPrint('Update available: $serverVersion');
          emit(AppVersionUpdateState(appVersionData));
        }
      },
    );
  }

  Future<void> _onLoadConfigurations(
    LoadConfigurationsEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      // Get user ID from preferences
      final userId = await PrefUtils.getUserId();

      if (userId == null || userId == 0) {
        debugPrint('⚠️ No user ID found, cannot load configurations');
        return;
      }

      debugPrint('🔄 Loading configurations for user ID: $userId');

      final result = await getUserConfigurations(userId);

      result.fold(
        (failure) {
          debugPrint('❌ Error loading configurations: ${failure.message}');
          emit(ConfigurationErrorHomeState(failure.message));
        },
        (config) {
          configurations = config;
          debugPrint('✅ Configurations loaded successfully');
          debugPrint(
              '   accessProductionModule: ${config.result?.result?.accessProductionModule}');
          emit(ConfigurationLoadedHomeState(config));
        },
      );
    } catch (e) {
      debugPrint('❌ Exception loading configurations: $e');
      emit(ConfigurationErrorHomeState(e.toString()));
    }
  }

  void _onClearDataEvent(
    ClearDataEvent event,
    Emitter<HomeState> emit,
  ) {
    // Reset all state fields
    userName = "";
    userEmail = "";
    userRol = "";
    configurations = UserConfiguration();
    appVersion = AppVersion();
    emit(HomeInitial());
  }
}
