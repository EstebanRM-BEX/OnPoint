import 'package:equatable/equatable.dart';

abstract class PackagingTypeEvent extends Equatable {
  const PackagingTypeEvent();

  @override
  List<Object> get props => [];
}

/// Dispara la obtención de datos locales. Muy rápido para UI inmediata.
class GetLocalPackagingTypesEvent extends PackagingTypeEvent {}

/// Dispara la sincronización con el servidor y actualización de datos locales.
class SyncPackagingTypesEvent extends PackagingTypeEvent {}
