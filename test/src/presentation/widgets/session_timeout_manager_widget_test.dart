import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms_app/core/services/interfaces/i_websocket_service.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/src/presentation/widgets/session_timeout_manager_widget.dart';
import 'package:wms_app/core/utils/prefs/pref_keys.dart';

class MockWebSocketService implements IWebSocketService {
  bool disconnected = false;

  @override
  Future<void> connect() async {}

  @override
  void disconnect() {
    disconnected = true;
  }

  @override
  Stream get messages => const Stream.empty();

  @override
  void sendMessage(dynamic data) {}

  @override
  void dispose() {}
}

void main() {
  setUp(() async {
    // Reset GetIt if necessary and register mock dependencies
    await getIt.reset();
    getIt
        .registerLazySingleton<IWebSocketService>(() => MockWebSocketService());
  });

  testWidgets('SessionTimeoutManager triggers onSessionExpired after duration',
      (WidgetTester tester) async {
    // 1. Setup mock SharedPreferences with initial values
    SharedPreferences.setMockInitialValues({
      PrefKeys.isLoggedIn: true,
    });

    bool sessionExpiredCalled = false;
    const timeoutDuration = Duration(seconds: 1);

    // 2. Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionTimeoutManager(
            duration: timeoutDuration,
            onSessionExpired: () {
              sessionExpiredCalled = true;
            },
            child: const Text('Content'),
          ),
        ),
      ),
    );

    // Initial check: session should not be expired
    expect(sessionExpiredCalled, false);

    // 3. Advance time by the duration exactly
    await tester.pump(timeoutDuration);

    // Trigger a frame to show the dialog
    await tester.pump();

    // Verify visibility of "Cerrando aplicación..." BEFORE the delay ends
    expect(find.text("Cerrando aplicación por inactividad..."), findsOneWidget);

    // 4. Advance time by the 2-second delay
    await tester.pump(const Duration(seconds: 2));

    // 5. Verify callback was triggered
    expect(sessionExpiredCalled, true);

    // Check if WebSocket was disconnected
    final ws = getIt<IWebSocketService>() as MockWebSocketService;
    expect(ws.disconnected, true);
  });
}
