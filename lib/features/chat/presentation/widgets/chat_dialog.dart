import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:wms_app/features/chat/presentation/widgets/chat_avatar.dart';
import 'package:wms_app/features/chat/presentation/widgets/conversation_list_view.dart';
import 'package:wms_app/features/chat/presentation/widgets/chat_thread_view.dart';
import 'package:wms_app/features/chat/presentation/widgets/chat_permissions_dialog.dart';
import 'package:wms_app/main.dart' show navigatorKey;

/// Indica si el diálogo de chat está abierto. La burbuja global se oculta
/// mientras sea `true` (lista/contactos/hilo o sub-diálogos) y reaparece al
/// cerrarse todo.
final ValueNotifier<bool> chatDialogOpen = ValueNotifier<bool>(false);

/// Abre el diálogo de chat con una animación de expansión desde la burbuja
/// (esquina inferior derecha). Reutiliza el [ChatBloc] global.
///
/// La burbuja vive por encima del Navigator de la app (en el `builder` de
/// [GetMaterialApp]), por eso el diálogo se abre con el [navigatorKey] global.
Future<void> showChatDialog(BuildContext context, ChatBloc bloc) {
  // Oculta la burbuja global mientras el chat esté abierto.
  chatDialogOpen.value = true;
  final future = showGeneralDialog(
    context: navigatorKey.currentContext ?? context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar chat',
    barrierColor: Colors.black38,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => BlocProvider.value(
      value: bloc,
      child: const _ChatDialogFrame(),
    ),
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return Transform.scale(
        alignment: Alignment.bottomRight,
        scale: 0.7 + (0.3 * curved.value),
        child: Opacity(opacity: anim.value.clamp(0.0, 1.0), child: child),
      );
    },
  );

  // Al entrar al chat, solicita (una vez) los permisos de media si faltan.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) maybeShowChatPermissions(ctx);
  });

  // Al cerrarse el diálogo, vuelve a mostrar la burbuja.
  future.whenComplete(() => chatDialogOpen.value = false);

  return future;
}

/// Posiciona la tarjeta del chat (grande, ~90% de la pantalla). Al abrir el
/// teclado se acorta para quedar por encima de él.
class _ChatDialogFrame extends StatelessWidget {
  const _ChatDialogFrame();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final bottomInset = media.viewInsets.bottom;
    final topSafe = media.padding.top;

    // Ancho: casi toda la pantalla (con tope en tablets).
    final width = (size.width * 0.96).clamp(0.0, 640.0);

    // Alto objetivo 90%; si el teclado está abierto, se limita al espacio
    // disponible por encima de él (deja aire bajo la barra de estado).
    final target = size.height * 0.90;
    final available = size.height - bottomInset - topSafe - 12;
    final height = target < available ? target : available;

    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.only(
          right: 8,
          left: 8,
          bottom: 8 + bottomInset,
        ),
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: width,
            height: height,
            child: const ChatDialog(),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta del chat: header adaptativo + paneles lista/hilo.
class ChatDialog extends StatelessWidget {
  const ChatDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          const _AdaptiveHeader(),
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              buildWhen: (a, b) => a.view != b.view,
              builder: (context, state) {
                final isThread = state.view == ChatView.thread;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    final offset = Tween<Offset>(
                      begin: Offset(isThread ? 0.15 : -0.15, 0),
                      end: Offset.zero,
                    ).animate(animation);
                    return SlideTransition(
                      position: offset,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: isThread
                      ? const ChatThreadView(key: ValueKey('thread'))
                      : const ConversationListView(key: ValueKey('list')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Header que cambia entre "Mensajes" (lista) y datos del contacto (hilo),
/// con botón de cierre siempre presente.
class _AdaptiveHeader extends StatelessWidget {
  const _AdaptiveHeader();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ChatBloc>();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColorApp, primaryColorAppLigth],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      child: BlocBuilder<ChatBloc, ChatState>(
        buildWhen: (a, b) =>
            a.view != b.view ||
            a.activeConversation != b.activeConversation ||
            a.totalUnread != b.totalUnread,
        builder: (context, state) {
          final isThread = state.view == ChatView.thread;
          final convo = state.activeConversation;

          return Row(
            children: [
              if (isThread)
                IconButton(
                  onPressed: () => bloc.add(const ChatBackToList()),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Volver',
                )
              else
                const SizedBox(width: 10),
              if (isThread && convo != null) ...[
                ChatAvatar(contact: convo.contact, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        convo.contact.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        convo.contact.isOnline ? 'En línea' : convo.contact.role,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Icon(Icons.forum_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Mensajes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Cerrar',
              ),
            ],
          );
        },
      ),
    );
  }
}
