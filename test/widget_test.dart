import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/core/services/interfaces/i_websocket_service.dart';
import 'package:wms_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wms_app/features/enterprise/presentation/bloc/enterprise_bloc.dart';
import 'package:wms_app/features/enterprise/presentation/bloc/enterprise_event.dart';
import 'package:wms_app/features/enterprise/presentation/bloc/enterprise_state.dart';
import 'package:wms_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:wms_app/features/login/presentation/bloc/login_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/main.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockConnectionStatusCubit extends MockCubit<ConnectionStatus>
    implements ConnectionStatusCubit {}

class MockUserBloc extends MockBloc<UserEvent, UserState> implements UserBloc {}

class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

class MockLoginBloc extends MockBloc<LoginEvent, LoginState>
    implements LoginBloc {}

class MockEnterpriseBloc extends MockBloc<EnterpriseEvent, EnterpriseState>
    implements EnterpriseBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockWebSocketService extends Mock implements IWebSocketService {
  @override
  Future<void> connect() async {}
}

void main() {
  setUpAll(() {
    // Register fallbacks for mocktail if needed
    registerFallbackValue(AuthInitial());
    registerFallbackValue(const GetRecentUrlsEvent());
  });

  setUp(() async {
    await getIt.reset();

    // AuthBloc Mock
    final mockAuth = MockAuthBloc();
    when(() => mockAuth.state).thenReturn(AuthInitial());
    getIt.registerLazySingleton<AuthBloc>(() => mockAuth);

    // ConnectionStatusCubit Mock
    final mockConn = MockConnectionStatusCubit();
    when(() => mockConn.state).thenReturn(ConnectionStatus.online);
    getIt.registerLazySingleton<ConnectionStatusCubit>(() => mockConn);

    // UserBloc Mock
    final mockUser = MockUserBloc();
    when(() => mockUser.state).thenReturn(UserInitial());
    getIt.registerLazySingleton<UserBloc>(() => mockUser);

    // HomeBloc Mock
    final mockHome = MockHomeBloc();
    when(() => mockHome.state).thenReturn(HomeInitial());
    getIt.registerLazySingleton<HomeBloc>(() => mockHome);

    // LoginBloc Mock
    final mockLogin = MockLoginBloc();
    when(() => mockLogin.state).thenReturn(LoginInitial());
    getIt.registerLazySingleton<LoginBloc>(() => mockLogin);

    // EnterpriseBloc Mock
    final mockEnt = MockEnterpriseBloc();
    when(() => mockEnt.state).thenReturn(EnterpriseInitial());
    getIt.registerLazySingleton<EnterpriseBloc>(() => mockEnt);

    // WebSocket Mock
    getIt
        .registerLazySingleton<IWebSocketService>(() => MockWebSocketService());
  });

  testWidgets('App starts with CheckAuthPage showing loading indicator',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app starts with a loading indicator in CheckAuthPage
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
