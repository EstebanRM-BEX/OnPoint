import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/chat/domain/entities/chat_contact.dart';
import 'package:wms_app/features/chat/presentation/widgets/chat_avatar.dart';

/// Tira horizontal de contactos para iniciar una conversación con un toque.
class ContactsStrip extends StatelessWidget {
  final List<ChatContact> contacts;
  final ValueChanged<ChatContact> onContactTap;

  const ContactsStrip({
    super.key,
    required this.contacts,
    required this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: contacts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = contacts[i];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onContactTap(c),
            child: SizedBox(
              width: 58,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChatAvatar(contact: c, size: 48),
                  const SizedBox(height: 4),
                  Text(
                    c.name.split(' ').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Encabezado de sección reutilizable dentro del listado.
class ChatSectionHeader extends StatelessWidget {
  final String title;
  const ChatSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.6,
            fontWeight: FontWeight.bold,
            color: primaryColorApp,
          ),
        ),
      );
}
