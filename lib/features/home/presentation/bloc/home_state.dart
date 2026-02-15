part of 'home_bloc.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoadingState extends HomeState {}

class HomeLoadedState extends HomeState {}

class HomeLoadErrorState extends HomeState {}

// App Version States
class AppVersionLoadingState extends HomeState {}

class AppVersionLoadedState extends HomeState {
  final AppVersion appVersion;
  AppVersionLoadedState(this.appVersion);
}

class AppVersionUpdateState extends HomeState {
  final AppVersion appVersion;
  AppVersionUpdateState(this.appVersion);
}

class AppVersionLoadErrorState extends HomeState {
  final String message;
  AppVersionLoadErrorState(this.message);
}

// Session Expired State
class SessionExpiredState extends HomeState {
  final String message;
  SessionExpiredState(this.message);
}

// Configuration States
class ConfigurationLoadedHomeState extends HomeState {
  final UserConfiguration configurations;
  ConfigurationLoadedHomeState(this.configurations);
}

class ConfigurationErrorHomeState extends HomeState {
  final String message;
  ConfigurationErrorHomeState(this.message);
}
