import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/get_local_packaging_types_usecase.dart';
import '../../domain/usecases/get_packaging_types_usecase.dart';
import 'packaging_type_event.dart';
import 'packaging_type_state.dart';

@injectable
class PackagingTypeBloc extends Bloc<PackagingTypeEvent, PackagingTypeState> {
  final GetPackagingTypesUseCase getPackagingTypesUseCase;
  final GetLocalPackagingTypesUseCase getLocalPackagingTypesUseCase;

  PackagingTypeBloc({
    required this.getPackagingTypesUseCase,
    required this.getLocalPackagingTypesUseCase,
  }) : super(PackagingTypeInitial()) {
    on<GetLocalPackagingTypesEvent>(_onGetLocalPackagingTypes);
    on<SyncPackagingTypesEvent>(_onSyncPackagingTypes);
  }

  Future<void> _onGetLocalPackagingTypes(
    GetLocalPackagingTypesEvent event,
    Emitter<PackagingTypeState> emit,
  ) async {
    emit(PackagingTypesLoadInProgress());
    
    final result = await getLocalPackagingTypesUseCase();
    
    result.fold(
      (failure) => emit(PackagingTypeLoadFailure(message: failure.toString())),
      (packagingTypes) => emit(PackagingTypesLoadSuccess(packagingTypes: packagingTypes)),
    );
  }

  Future<void> _onSyncPackagingTypes(
    SyncPackagingTypesEvent event,
    Emitter<PackagingTypeState> emit,
  ) async {
    emit(PackagingTypesLoadInProgress());
    
    final result = await getPackagingTypesUseCase();
    
    result.fold(
      (failure) => emit(PackagingTypeLoadFailure(message: failure.toString())),
      (packagingTypes) => emit(PackagingTypesLoadSuccess(packagingTypes: packagingTypes)),
    );
  }
}
