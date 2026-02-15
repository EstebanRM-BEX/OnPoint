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
  }) : super(HomeInitial()) {
    on<HomeLoadData>(_onHomeLoadData);
    on<AppVersionEvent>(_onAppVersionEvent);
    on<ClearDataEvent>(_onClearDataEvent);

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
        print('Error loading user data: ${failure.message}');
        emit(HomeLoadErrorState());
      },
      (userData) {
        userName = userData.name;
        userEmail = userData.email;
        userRol = userData.rol;
        emit(HomeLoadedState());
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
        print('Error loading app version: ${failure.message}');

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

        print(
            'Current version: $currentVersion, Server version: $serverVersion');

        // Compare versions
        if (currentVersion == serverVersion) {
          print('App is up to date: $currentVersion');
          emit(AppVersionLoadedState(appVersionData));
        } else if (currentVersion.compareTo(serverVersion) > 0) {
          print('App is newer than server: $currentVersion');
          emit(AppVersionLoadedState(appVersionData));
        } else if (currentVersion.compareTo(serverVersion) < 0) {
          print('Update available: $serverVersion');
          emit(AppVersionUpdateState(appVersionData));
        }
      },
    );
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
