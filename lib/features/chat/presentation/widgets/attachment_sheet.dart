import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Acción elegida en la hoja de adjuntos.
enum ChatAttachmentAction { camera, gallery, audio }

/// Muestra la hoja inferior con opciones de adjunto y devuelve la elegida.
Future<ChatAttachmentAction?> showChatAttachmentSheet(BuildContext context) {
  return showModalBottomSheet<ChatAttachmentAction>(
    context: context,
    backgroundColor: white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: lightGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachmentOption(
                  icon: Icons.photo_camera_rounded,
                  color: primaryColorApp,
                  label: 'Cámara',
                  onTap: () =>
                      Navigator.pop(context, ChatAttachmentAction.camera),
                ),
                _AttachmentOption(
                  icon: Icons.photo_library_rounded,
                  color: green,
                  label: 'Galería',
                  onTap: () =>
                      Navigator.pop(context, ChatAttachmentAction.gallery),
                ),
                _AttachmentOption(
                  icon: Icons.mic_rounded,
                  color: red,
                  label: 'Audio',
                  onTap: () =>
                      Navigator.pop(context, ChatAttachmentAction.audio),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
