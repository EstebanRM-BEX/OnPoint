import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/chat/presentation/bloc/chat_bloc.dart';

/// Burbuja flotante (FAB) que abre el chat. Muestra el badge de no leídos
/// leyendo el [ChatBloc] global.
class ChatLauncherBubble extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const ChatLauncherBubble({
    super.key,
    required this.onTap,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primaryColorApp, primaryColorAppLigth],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.chat_rounded, color: Colors.white, size: 26),
            ),
            Positioned(
              right: -2,
              top: -2,
              child: BlocBuilder<ChatBloc, ChatState>(
                buildWhen: (a, b) => a.totalUnread != b.totalUnread,
                builder: (context, state) {
                  if (state.totalUnread <= 0) return const SizedBox.shrink();
                  return Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: red,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: white, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      state.totalUnread > 99 ? '99+' : '${state.totalUnread}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
