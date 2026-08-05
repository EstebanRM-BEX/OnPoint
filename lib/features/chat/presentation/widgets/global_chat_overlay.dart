import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:wms_app/features/chat/presentation/widgets/chat_dialog.dart';
import 'package:wms_app/features/chat/presentation/widgets/chat_launcher_bubble.dart';
import 'package:wms_app/injection_container.dart';

/// Envuelve la app y superpone la burbuja de chat global (arrastrable) en la
/// esquina inferior derecha. Provee el [ChatBloc] singleton para que tanto la
/// burbuja (badge) como el diálogo compartan el mismo estado.
///
/// Se coloca en el `builder` de [GetMaterialApp], por encima del Navigator.
class GlobalChatOverlay extends StatelessWidget {
  final Widget child;
  const GlobalChatOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatBloc>(
      create: (_) => getIt<ChatBloc>()..add(const ChatStarted()),
      child: _ChatOverlayView(child: child),
    );
  }
}

class _ChatOverlayView extends StatefulWidget {
  final Widget child;
  const _ChatOverlayView({required this.child});

  @override
  State<_ChatOverlayView> createState() => _ChatOverlayViewState();
}

class _ChatOverlayViewState extends State<_ChatOverlayView> {
  static const double _bubble = 56;
  static const double _margin = 14;

  /// Posición (esquina superior-izquierda de la burbuja). Se calcula la 1ª vez
  /// desde el tamaño disponible (abajo-derecha por defecto).
  Offset? _pos;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxX = constraints.maxWidth - _bubble - _margin;
        final maxY = constraints.maxHeight - _bubble - _margin;
        _pos ??= Offset(maxX, maxY - 24);
        // Reclampa si cambió el tamaño (rotación/teclado).
        final pos = Offset(
          _pos!.dx.clamp(_margin, maxX <= _margin ? _margin : maxX),
          _pos!.dy.clamp(_margin, maxY <= _margin ? _margin : maxY),
        );

        return Stack(
          children: [
            widget.child,
            Positioned(
              left: pos.dx,
              top: pos.dy,
              // Se oculta (y deja de recibir toques) mientras el chat u otro
              // diálogo esté abierto; reaparece al cerrarse todo.
              child: ValueListenableBuilder<bool>(
                valueListenable: chatDialogOpen,
                builder: (context, hidden, child) => IgnorePointer(
                  ignoring: hidden,
                  child: AnimatedOpacity(
                    opacity: hidden ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedScale(
                      scale: hidden ? 0.3 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: child,
                    ),
                  ),
                ),
                child: GestureDetector(
                  onPanStart: (_) => setState(() => _dragging = true),
                  onPanUpdate: (d) => setState(() {
                    _pos = Offset(
                      (pos.dx + d.delta.dx).clamp(_margin, maxX),
                      (pos.dy + d.delta.dy).clamp(_margin, maxY),
                    );
                  }),
                  onPanEnd: (_) => setState(() {
                    _dragging = false;
                    // Imán al borde más cercano (izq/der).
                    final snapX =
                        (pos.dx + _bubble / 2) < constraints.maxWidth / 2
                            ? _margin
                            : maxX;
                    _pos = Offset(snapX, _pos!.dy.clamp(_margin, maxY));
                  }),
                  child: AnimatedScale(
                    scale: _dragging ? 1.12 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: ChatLauncherBubble(
                      size: _bubble,
                      onTap: () => showChatDialog(
                        context,
                        context.read<ChatBloc>(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
