import 'package:equatable/equatable.dart';
import '../../domain/entities/packaging_type.dart';

abstract class PackagingTypeState extends Equatable {
  const PackagingTypeState();

  @override
  List<Object?> get props => [];
}

class PackagingTypeInitial extends PackagingTypeState {}

class PackagingTypesLoadInProgress extends PackagingTypeState {}

class PackagingTypesLoadSuccess extends PackagingTypeState {
  final List<PackagingType> packagingTypes;

  const PackagingTypesLoadSuccess({required this.packagingTypes});

  @override
  List<Object> get props => [packagingTypes];
}

class PackagingTypeLoadFailure extends PackagingTypeState {
  final String message;

  const PackagingTypeLoadFailure({required this.message});

  @override
  List<Object> get props => [message];
}
