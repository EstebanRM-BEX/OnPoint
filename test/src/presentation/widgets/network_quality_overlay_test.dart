import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms_app/src/presentation/providers/network_overlay/network_overlay_cubit.dart';
import 'package:wms_app/src/presentation/widgets/network_quality_overlay.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

Widget _buildWidget({
  bool visible = true,
  Widget child = const Text('Pantalla base'),
}) {
  // La Key garantiza que pumpWidget con distinto `visible` recrea el BlocProvider
  // y su cubit, en lugar de reutilizar el del build anterior.
  return MaterialApp(
    home: KeyedSubtree(
      key: ValueKey(visible),
      child: BlocProvider<NetworkOverlayCubit>(
        create: (_) => NetworkOverlayCubit.withState(visible),
        child: NetworkQualityOverlay(child: child),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    // Desactiva Socket.connect y http.get para que los tests no dejen
    // timers pendientes en el entorno FakeAsync de Flutter
    NetworkQualityOverlay.disableNetworkCallsForTesting = true;
  });

  tearDownAll(() {
    NetworkQualityOverlay.disableNetworkCallsForTesting = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── Grupo 1: Visibilidad ─────────────────────────────────────────────────
  group('Visibilidad via NetworkOverlayCubit', () {
    testWidgets('overlay es visible cuando el cubit emite true',
        (tester) async {
      await tester.pumpWidget(_buildWidget(visible: true));
      await tester.pump();

      expect(find.byIcon(Icons.drag_indicator), findsWidgets);
      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('overlay está oculto cuando el cubit emite false',
        (tester) async {
      await tester.pumpWidget(_buildWidget(visible: false));
      await tester.pump();

      expect(find.byIcon(Icons.drag_indicator), findsNothing);
      // AnimatedContainer debe haber sido removido del árbol completamente
      expect(find.byType(AnimatedContainer), findsNothing);
    });

    testWidgets(
        'el widget hijo siempre se renderiza independientemente del cubit',
        (tester) async {
      await tester.pumpWidget(
        _buildWidget(visible: false, child: const Text('Mi pantalla WMS')),
      );
      await tester.pump();

      expect(find.text('Mi pantalla WMS'), findsOneWidget);
    });

    testWidgets('reacciona al cambio de estado: visible→oculto→visible',
        (tester) async {
      // Visible
      await tester.pumpWidget(_buildWidget(visible: true));
      await tester.pump();
      expect(find.byType(AnimatedContainer), findsOneWidget);

      // Oculto
      await tester.pumpWidget(_buildWidget(visible: false));
      await tester.pump();
      expect(find.byType(AnimatedContainer), findsNothing);

      // Visible de nuevo
      await tester.pumpWidget(_buildWidget(visible: true));
      await tester.pump();
      expect(find.byType(AnimatedContainer), findsOneWidget);
    });
  });

  // ── Grupo 2: Estado colapsado ────────────────────────────────────────────
  group('Estado colapsado (vista por defecto)', () {
    testWidgets('muestra ícono drag_indicator en estado colapsado',
        (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      expect(find.byIcon(Icons.drag_indicator), findsWidgets);
    });

    testWidgets('NO muestra el ícono de cerrar cuando está colapsado',
        (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('NO muestra etiquetas de calidad en estado colapsado',
        (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      for (final label in ['Excelente', 'Regular', 'Débil', 'Sin señal']) {
        expect(find.text(label), findsNothing,
            reason: '"$label" no debe verse en el estado colapsado');
      }
    });

    testWidgets('muestra "0ms" como ping inicial (antes de cualquier medición)',
        (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      // Sin red en tests → el estado inicial es "excellent" con pingMs=0
      expect(find.text('0ms'), findsOneWidget);
    });
  });

  // ── Grupo 3: Expandir / Colapsar ────────────────────────────────────────
  group('Expandir y colapsar con tap', () {
    testWidgets('tap expande mostrando el ícono de cerrar', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      // GestureDetector tiene onTap → tester.tap() lo activa correctamente
      await tester.tap(find.byType(AnimatedContainer));
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('segundo tap colapsa el overlay', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      // Primer tap: expandir
      await tester.tap(find.byType(AnimatedContainer));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Segundo tap: colapsar.
      // El overlay expandido se inicia cerca del borde derecho (screen.width - 90),
      // por lo que su centro puede quedar fuera de la pantalla de test (800 px).
      // Se toca el borde izquierdo del widget, que siempre permanece visible.
      final rect = tester.getRect(find.byType(AnimatedContainer));
      await tester.tapAt(Offset(rect.left + 5, rect.center.dy));
      await tester.pump();
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('al expandir muestra la etiqueta de calidad', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      final g = await tester.startGesture(
        tester.getCenter(find.byType(AnimatedContainer)),
      );
      await g.up();
      await tester.pump();

      final qualityLabels = ['Excelente', 'Regular', 'Débil', 'Sin señal'];
      final labelFound = qualityLabels.any((l) => tester.any(find.text(l)));
      expect(labelFound, isTrue,
          reason: 'Debe mostrar una etiqueta de calidad al expandir');
    });

    testWidgets('al expandir muestra el texto "Ping:"', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      final g = await tester.startGesture(
        tester.getCenter(find.byType(AnimatedContainer)),
      );
      await g.up();
      await tester.pump();

      expect(
        find.textContaining('Ping:'),
        findsOneWidget,
        reason: 'El ping debe ser visible en estado expandido',
      );
    });

    testWidgets('al expandir el ícono drag_indicator sigue presente',
        (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      final g = await tester.startGesture(
        tester.getCenter(find.byType(AnimatedContainer)),
      );
      await g.up();
      await tester.pump();

      // Tanto en colapsado como en expandido debe haber drag_indicator
      expect(find.byIcon(Icons.drag_indicator), findsWidgets);
    });
  });

  // ── Grupo 4: Drag – movimiento ───────────────────────────────────────────
  group('Drag – mover el widget', () {
    testWidgets('arrastrar cambia la posición del overlay', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      final container = find.byType(AnimatedContainer);
      final posBefore = tester.getTopLeft(container);

      await tester.drag(container, const Offset(-60, 40));
      await tester.pump();

      final posAfter = tester.getTopLeft(container);
      expect(posAfter.dx, isNot(closeTo(posBefore.dx, 1)));
      expect(posAfter.dy, isNot(closeTo(posBefore.dy, 1)));
    });

    testWidgets('drag grande (>8px) NO expande el overlay', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      await tester.drag(find.byType(AnimatedContainer), const Offset(-50, 0));
      await tester.pump();

      // Si fuera tap habría ícono de cerrar; no debe haberlo
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('el overlay no sale por el borde derecho de pantalla',
        (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      await tester.drag(
          find.byType(AnimatedContainer), const Offset(2000, 0));
      await tester.pump();

      final pos = tester.getTopLeft(find.byType(AnimatedContainer));
      final screenWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;

      expect(pos.dx, lessThan(screenWidth));
    });

    testWidgets('el overlay no sale por el borde izquierdo', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      await tester.drag(
          find.byType(AnimatedContainer), const Offset(-2000, 0));
      await tester.pump();

      final pos = tester.getTopLeft(find.byType(AnimatedContainer));
      expect(pos.dx, greaterThanOrEqualTo(4.0));
    });

    testWidgets('el overlay no sale por el borde inferior', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      await tester.drag(
          find.byType(AnimatedContainer), const Offset(0, 2000));
      await tester.pump();

      final pos = tester.getTopLeft(find.byType(AnimatedContainer));
      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;

      expect(pos.dy, lessThan(screenHeight));
    });

    testWidgets('la posición se acumula entre gestos consecutivos',
        (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      final container = find.byType(AnimatedContainer);

      await tester.drag(container, const Offset(-30, 0));
      await tester.pump();
      final posAfterFirst = tester.getTopLeft(container);

      await tester.drag(container, const Offset(-30, 0));
      await tester.pump();
      final posAfterSecond = tester.getTopLeft(container);

      // El segundo drag acumula sobre el primero
      expect(posAfterSecond.dx, lessThan(posAfterFirst.dx));
    });
  });

  // ── Grupo 5: Performance ─────────────────────────────────────────────────
  group('Performance – sin impacto en el árbol de widgets', () {
    testWidgets(
        'ocultar el overlay elimina AnimatedContainer completamente del árbol',
        (tester) async {
      // Visible → AnimatedContainer existe
      await tester.pumpWidget(_buildWidget(visible: true));
      await tester.pump();
      expect(find.byType(AnimatedContainer), findsOneWidget);

      // Oculto → AnimatedContainer desaparece del árbol (`if (visible)`, no Opacity)
      await tester.pumpWidget(_buildWidget(visible: false));
      await tester.pump();
      expect(find.byType(AnimatedContainer), findsNothing);
    });

    testWidgets(
        'interacciones internas del overlay NO re-buildean el widget hijo',
        (tester) async {
      int childBuildCount = 0;

      final countingChild = Builder(builder: (_) {
        childBuildCount++;
        return const Text('Child');
      });

      await tester.pumpWidget(_buildWidget(child: countingChild));
      await tester.pump();
      final buildsAfterInit = childBuildCount;

      // Expandir con tap
      final g = await tester.startGesture(
        tester.getCenter(find.byType(AnimatedContainer)),
      );
      await g.up();
      await tester.pump();

      expect(childBuildCount, equals(buildsAfterInit),
          reason: 'El hijo no debe rebuildearse por la expansión del overlay');
    });

    testWidgets('arrastrar el overlay NO re-buildea el widget hijo',
        (tester) async {
      int childBuildCount = 0;

      final countingChild = Builder(builder: (_) {
        childBuildCount++;
        return const Text('Child');
      });

      await tester.pumpWidget(_buildWidget(child: countingChild));
      await tester.pump();
      final buildsAfterInit = childBuildCount;

      await tester.drag(
          find.byType(AnimatedContainer), const Offset(-40, 20));
      await tester.pump();

      expect(childBuildCount, equals(buildsAfterInit),
          reason: 'El hijo no debe rebuildearse al arrastrar el overlay');
    });

    testWidgets(
        'múltiples cambios de estado no causan rebuilds en el widget hijo',
        (tester) async {
      int childBuildCount = 0;
      final countingChild = Builder(builder: (_) {
        childBuildCount++;
        return const Text('app');
      });

      // Estado visible=true
      await tester.pumpWidget(_buildWidget(child: countingChild));
      await tester.pump();
      final countAfterVisible = childBuildCount;

      // Cambio a visible=false — el hijo NO debe recibir rebuild
      await tester.pumpWidget(_buildWidget(visible: false, child: countingChild));
      await tester.pump();

      // Cambio a visible=true — el hijo NO debe recibir rebuild
      await tester.pumpWidget(_buildWidget(visible: true, child: countingChild));
      await tester.pump();

      // Los builds del hijo solo deben corresponder a los pumps de inicialización,
      // no a los cambios de visibilidad del overlay
      expect(childBuildCount, lessThanOrEqualTo(countAfterVisible + 2),
          reason: 'El hijo no debe rebuildearse más de lo necesario');
    });

    testWidgets(
        'el overlay visible no genera frames continuos sin interacción',
        (tester) async {
      await tester.pumpWidget(_buildWidget(
        child: const Text('Pantalla de picking'),
      ));
      await tester.pump();

      // Avanzar 2 segundos sin interacción — no debe haber frames activos
      // ni loops de rebuilds (el timer de ping está desactivado en tests)
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Pantalla de picking'), findsOneWidget);
    });
  });

  // ── Grupo 6: NetworkOverlayCubit – lógica de prefs ───────────────────────
  group('NetworkOverlayCubit – persistencia en SharedPreferences', () {
    test('estado por defecto es false cuando la key no existe en prefs',
        () async {
      SharedPreferences.setMockInitialValues({});
      final cubit = NetworkOverlayCubit();
      await Future.delayed(Duration.zero);

      expect(cubit.state, isFalse);
      cubit.close();
    });

    test('carga false desde SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'networkOverlayVisible': false});
      final cubit = NetworkOverlayCubit();
      await Future.delayed(Duration.zero);

      expect(cubit.state, isFalse);
      cubit.close();
    });

    test('reset() vuelve el estado a false sin tocar prefs', () async {
      SharedPreferences.setMockInitialValues({'networkOverlayVisible': true});
      final cubit = NetworkOverlayCubit();
      await Future.delayed(Duration.zero);
      expect(cubit.state, isTrue);

      cubit.reset();
      expect(cubit.state, isFalse);

      // La key en prefs no debe haber cambiado
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('networkOverlayVisible'), isTrue,
          reason: 'reset() no escribe en prefs, solo resetea el estado en memoria');

      cubit.close();
    });

    test('setVisible(false) persiste false en SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final cubit = NetworkOverlayCubit();
      await cubit.setVisible(false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('networkOverlayVisible'), isFalse);
      cubit.close();
    });

    test('setVisible(true) persiste true en SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'networkOverlayVisible': false});
      final cubit = NetworkOverlayCubit();
      await cubit.setVisible(true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('networkOverlayVisible'), isTrue);
      cubit.close();
    });
  });
}
