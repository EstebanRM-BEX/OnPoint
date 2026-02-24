import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/delete_recent_url.dart';
import '../../domain/usecases/get_recent_urls.dart';
import '../../domain/usecases/save_recent_url.dart';
import '../../domain/usecases/search_enterprise.dart';
import 'enterprise_event.dart';
import 'enterprise_state.dart';

@injectable
class EnterpriseBloc extends Bloc<EnterpriseEvent, EnterpriseState> {
  final SearchEnterprise searchEnterpriseUseCase;
  final GetRecentUrls getRecentUrlsUseCase;
  final SaveRecentUrl saveRecentUrlUseCase;
  final DeleteRecentUrl deleteRecentUrlUseCase;

  EnterpriseBloc({
    required this.searchEnterpriseUseCase,
    required this.getRecentUrlsUseCase,
    required this.saveRecentUrlUseCase,
    required this.deleteRecentUrlUseCase,
  }) : super(EnterpriseInitial()) {
    on<SearchEnterpriseEvent>(_onSearchEnterprise);
    on<GetRecentUrlsEvent>(_onGetRecentUrls);
    on<SaveRecentUrlEvent>(_onSaveRecentUrl);
    on<DeleteRecentUrlEvent>(_onDeleteRecentUrl);
    on<SelectDatabaseEvent>(_onSelectDatabase);
  }

  Future<void> _onSearchEnterprise(
    SearchEnterpriseEvent event,
    Emitter<EnterpriseState> emit,
  ) async {
    emit(EnterpriseLoading());
    final result =
        await searchEnterpriseUseCase(SearchEnterpriseParams(url: event.url));

    result.fold(
      (failure) => emit(EnterpriseFailure(failure.message)),
      (enterpriseInfo) => emit(EnterpriseSuccess(
        enterpriseInfo: enterpriseInfo,
        url: event.url,
      )),
    );
  }

  Future<void> _onGetRecentUrls(
    GetRecentUrlsEvent event,
    Emitter<EnterpriseState> emit,
  ) async {
    print('EVENT GetRecentUrlsEvent ');
    emit(EnterpriseLoading());
    final result = await getRecentUrlsUseCase(NoParams());

    result.fold(
      (failure) => emit(EnterpriseFailure(failure.message)),
      (recentUrls) => emit(RecentUrlsLoaded(recentUrls)),
    );
  }

  Future<void> _onSaveRecentUrl(
    SaveRecentUrlEvent event,
    Emitter<EnterpriseState> emit,
  ) async {
    await saveRecentUrlUseCase(SaveRecentUrlParams(recentUrl: event.recentUrl));
    add(const GetRecentUrlsEvent());
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
    emit(DatabaseSelectedState(database: event.database, url: event.url));
  }
}
