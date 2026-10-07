import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/diagnostics/route_stack_tracker.dart';
import 'package:wms_app/features/app_inspector/presentation/app_inspector_controller.dart';
import 'package:wms_app/features/app_inspector/presentation/widgets/app_inspector_dialog.dart';

/// Botón flotante pequeño y arrastrable (como el inspector del navegador)
/// que abre el [AppInspectorDialog]. Se muestra solo si el usuario lo activó
/// en Configuración. Va en `MaterialApp.builder`, por encima del Navigator.
class AppInspectorOverlay extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const AppInspectorOverlay({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<AppInspectorOverlay> createState() => _AppInspectorOverlayState();
}

class _AppInspectorOverlayState extends State<AppInspectorOverlay> {
  static const _size = 40.0;
  static const _margin = 4.0;

  Offset? _position;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    AppInspectorController.instance.load();
  }

  Future<void> _open() async {
    final ctx = widget.navigatorKey.currentContext;
    if (ctx == null || _dialogOpen) return;
    _dialogOpen = true;
    await showDialog<void>(
      context: ctx,
      routeSettings: const RouteSettings(name: kAppInspectorRouteName),
      builder: (_) => const AppInspectorDialog(),
    );
    _dialogOpen = false;
  }

  Offset _clamp(Offset d, Size screen) {
    final pad = MediaQuery.paddingOf(context);
    return Offset(
      d.dx.clamp(_margin, math.max(_margin, screen.width - _size - _margin)),
      d.dy.clamp(
        pad.top + _margin,
        math.max(pad.top + _margin, screen.height - _size - pad.bottom),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        widget.child,
        ListenableBuilder(
          listenable: AppInspectorController.instance,
          builder: (context, _) {
            if (!AppInspectorController.instance.visible) {
              return const SizedBox.shrink();
            }
            final pos = _clamp(
              _position ?? Offset(_margin, screen.height * 0.6),
              screen,
            );
            return Positioned(
              left: pos.dx,
              top: pos.dy,
              child: GestureDetector(
                onPanUpdate: (d) =>
                    setState(() => _position = _clamp(pos + d.delta, screen)),
                onTap: _open,
                child: Material(
                  color: primaryColorApp.withOpacity(0.85),
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: const SizedBox.square(
                    dimension: _size,
                    child: Icon(
                      Icons.account_tree_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
