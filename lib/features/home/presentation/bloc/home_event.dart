part of 'home_bloc.dart';

@immutable
sealed class HomeEvent {}

class HomeLoadData extends HomeEvent {}

class AppVersionEvent extends HomeEvent {}

class ClearDataEvent extends HomeEvent {}
