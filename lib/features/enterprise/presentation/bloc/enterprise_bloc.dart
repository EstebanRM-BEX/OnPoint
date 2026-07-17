import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/delete_recent_url.dart';
import '../../domain/usecases/get_recent_urls.dart';
import '../../domain/usecases/search_enterprise.dart';
import 'enterprise_event.dart';
import 'enterprise_state.dart';

@injectable
class EnterpriseBloc extends Bloc<EnterpriseEvent, EnterpriseState> {
  final SearchEnterprise searchEnterpriseUseCase;
  final GetRecentUrls getRecentUrlsUseCase;
  final DeleteRecentUrl deleteRecentUrlUseCase;

  EnterpriseBloc({
    required this.searchEnterpriseUseCase,
    required this.getRecentUrlsUseCase,
    required this.deleteRecentUrlUseCase,
  }) : super(const EnterpriseState()) {
    on<SearchEnterpriseEvent>(_onSearchEnterprise);
    on<GetRecentUrlsEvent>(_onGetRecentUrls);
    on<DeleteRecentUrlEvent>(_onDeleteRecentUrl);
    on<SelectDatabaseEvent>(_onSelectDatabase);
  }

  Future<void> _onSearchEnterprise(
    SearchEnterpriseEvent event,
    Emitter<EnterpriseState> emit,
  ) async {
    emit(state.copyWith(status: EnterpriseStatus.searching));
    final result =
        await searchEnterpriseUseCase(SearchEnterpriseParams(url: event.url));

    result.fold(
      (failure) => emit(state.copyWith(
        status: EnterpriseStatus.failure,
        errorMessage: failure.message,
      )),
      (enterpriseInfo) {
        emit(state.copyWith(
          status: EnterpriseStatus.success,
          enterpriseInfo: enterpriseInfo,
          url: event.url,
        ));
        // La búsqueda exitosa agrega la URL al historial (lo hace el
        // repositorio); refrescamos la lista visible.
        add(const GetRecentUrlsEvent());
      },
    );
  }

  Future<void> _onGetRecentUrls(
    GetRecentUrlsEvent event,
    Emitter<EnterpriseState> emit,
  ) async {
    final result = await getRecentUrlsUseCase(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: EnterpriseStatus.failure,
        errorMessage: failure.message,
      )),
      (recentUrls) => emit(state.copyWith(recentUrls: recentUrls)),
    );
  }

  Future<void> _onDeleteRecentUrl(
    DeleteRecentUrlEvent event,
    Emitter<EnterpriseState> emit,
  ) async {
    await deleteRecentUrlUseCase(DeleteRecentUrlParams(url: event.url));
    add(const GetRecentUrlsEvent());
  }

  void _onSelectDatabase(
    SelectDatabaseEvent event,
    Emitter<EnterpriseState> emit,
  ) {
    emit(state.copyWith(
      status: EnterpriseStatus.databaseSelected,
      selectedDatabase: event.database,
      url: event.url,
    ));
  }
}
