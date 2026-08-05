import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Resuelve el permiso de galería según la versión de Android:
/// - Android 13+ (API 33+): READ_MEDIA_IMAGES → [Permission.photos]
/// - Android ≤ 12: READ_EXTERNAL_STORAGE → [Permission.storage]
///
/// Usar el permiso equivocado hace que Android no muestre el prompt (era el
/// caso: en ≤12 `Permission.photos` no pedía nada).
Future<Permission> resolveGalleryPermission() async {
  if (Platform.isAndroid) {
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt >= 33 ? Permission.photos : Permission.storage;
  }
  return Permission.photos;
}

/// Lista de permisos del chat (micrófono, cámara y galería resuelta).
Future<List<Permission>> _chatPermissionsFor() async => [
      Permission.microphone,
      Permission.camera,
      await resolveGalleryPermission(),
    ];

/// Evita abrir el diálogo dos veces a la vez.
bool _showing = false;

/// Muestra el diálogo de permisos si falta alguno (micrófono/cámara/galería).
/// Pensado para llamarse al abrir el chat.
Future<void> maybeShowChatPermissions(BuildContext context) async {
  if (_showing) return;
  final permissions = await _chatPermissionsFor();
  final missing = <Permission>[];
  for (final p in permissions) {
    final status = await p.status;
    if (!status.isGranted && !status.isLimited) missing.add(p);
  }
  if (missing.isEmpty || !context.mounted) return;

  _showing = true;
  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ChatPermissionsDialog(),
    );
  } finally {
    _showing = false;
  }
}

/// Diálogo de "priming": explica y solicita los permisos de media del chat.
class ChatPermissionsDialog extends StatefulWidget {
  const ChatPermissionsDialog({super.key});

  @override
  State<ChatPermissionsDialog> createState() => _ChatPermissionsDialogState();
}

class _ChatPermissionsDialogState extends State<ChatPermissionsDialog> {
  final Map<Permission, PermissionStatus> _status = {};

  /// Permiso de galería resuelto por versión de Android (photos/storage).
  Permission _gallery = Permission.photos;
  bool _loading = true;
  bool _requesting = false;

  List<Permission> get _perms =>
      [Permission.microphone, Permission.camera, _gallery];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    _gallery = await resolveGalleryPermission();
    for (final p in _perms) {
      _status[p] = await p.status;
    }
    if (mounted) setState(() => _loading = false);
  }

  bool get _allGranted => _perms.every((p) =>
      (_status[p]?.isGranted ?? false) || (_status[p]?.isLimited ?? false));

  bool get _anyPermanentlyDenied =>
      _perms.any((p) => _status[p]?.isPermanentlyDenied ?? false);

  Future<void> _request() async {
    setState(() => _requesting = true);

    // Se solicitan EN LOTE (no en bucle): Android/permission_handler solo
    // procesa una solicitud a la vez, así que pedirlos uno por uno hacía que
    // solo el primero (cámara) respondiera. `List.request()` los encadena.
    final toRequest = _perms.where((p) {
      final s = _status[p];
      return !(s?.isGranted ?? false) && !(s?.isLimited ?? false);
    }).toList();

    if (toRequest.isNotEmpty) {
      final results = await toRequest.request();
      _status.addAll(results);
    }

    if (!mounted) return;
    setState(() => _requesting = false);
    if (_allGranted) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _openSettings() async {
    if (mounted) Navigator.of(context).pop();
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: _loading
            ? const SizedBox(
                height: 120,
                child: Center(
                    child:
                        CircularProgressIndicator(color: primaryColorApp)),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: primaryColorApp.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_moon_rounded,
                        color: primaryColorApp, size: 30),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Permisos del chat',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Para enviar notas de voz y fotos, el chat necesita acceso a:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.8, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  _PermissionRow(
                    icon: Icons.mic_rounded,
                    color: red,
                    title: 'Micrófono',
                    subtitle: 'Grabar notas de voz',
                    status: _status[Permission.microphone],
                  ),
                  _PermissionRow(
                    icon: Icons.photo_camera_rounded,
                    color: primaryColorApp,
                    title: 'Cámara',
                    subtitle: 'Tomar fotos',
                    status: _status[Permission.camera],
                  ),
                  _PermissionRow(
                    icon: Icons.photo_library_rounded,
                    color: green,
                    title: 'Galería',
                    subtitle: 'Enviar imágenes guardadas',
                    status: _status[_gallery],
                  ),
                  const SizedBox(height: 18),
                  _actions(),
                ],
              ),
      ),
    );
  }

  Widget _actions() {
    if (_allGranted) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.check_circle, size: 18),
          label: const Text('¡Listo!'),
          style: ElevatedButton.styleFrom(
            backgroundColor: green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }

    final primaryLabel =
        _anyPermanentlyDenied ? 'Abrir ajustes' : 'Permitir acceso';
    final primaryAction = _anyPermanentlyDenied ? _openSettings : _request;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _requesting ? null : primaryAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColorApp,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _requesting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(primaryLabel),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: Colors.black45),
          child: const Text('Ahora no'),
        ),
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final PermissionStatus? status;

  const _PermissionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  bool get _granted =>
      (status?.isGranted ?? false) || (status?.isLimited ?? false);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11.5, color: Colors.black45)),
              ],
            ),
          ),
          Icon(
            _granted ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: _granted ? green : lightGrey,
            size: 22,
          ),
        ],
      ),
    );
  }
}
