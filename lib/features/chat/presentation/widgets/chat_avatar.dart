import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/chat/domain/entities/chat_contact.dart';

/// Avatar reutilizable: imagen si existe, si no iniciales sobre un color
/// derivado del id. Opcionalmente pinta el punto de presencia en línea.
class ChatAvatar extends StatelessWidget {
  final ChatContact contact;
  final double size;
  final bool showPresence;

  const ChatAvatar({
    super.key,
    required this.contact,
    this.size = 46,
    this.showPresence = true,
  });

  Color get _bg {
    const palette = [
      primaryColorApp,
      green,
      yellow,
      blue,
      primaryColorAppLigth,
    ];
    return palette[contact.id.hashCode.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = contact.avatarUrl != null && contact.avatarUrl!.isNotEmpty;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _bg,
              image: hasImage
                  ? DecorationImage(
                      image: NetworkImage(contact.avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: hasImage
                ? null
                : Text(
                    contact.initials,
                    style: TextStyle(
                      color: white,
                      fontWeight: FontWeight.bold,
                      fontSize: size * 0.38,
                    ),
                  ),
          ),
          if (showPresence && contact.isOnline)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: green,
                  shape: BoxShape.circle,
                  border: Border.all(color: white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
