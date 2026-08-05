import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Burbuja de imagen para el hilo. Soporta ruta local (mock/cámara/galería) o
/// URL. Toca para abrir a pantalla completa con zoom.
class ImageMessageBubble extends StatelessWidget {
  final String source;
  final String? caption;
  final bool isSentByMe;

  const ImageMessageBubble({
    super.key,
    required this.source,
    this.caption,
    required this.isSentByMe,
  });

  bool get _isNetwork => source.startsWith('http');

  ImageProvider get _provider =>
      _isNetwork ? NetworkImage(source) : FileImage(File(source));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onTap: () => _openFullScreen(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 240,
                  maxHeight: 280,
                  minWidth: 120,
                ),
                child: Image(
                  image: _provider,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 200,
                    height: 140,
                    color: lightGrey,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined,
                        color: grey, size: 32),
                  ),
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : Container(
                          width: 200,
                          height: 140,
                          color: lightGrey,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                              strokeWidth: 2, color: primaryColorApp),
                        ),
                ),
              ),
              if (caption != null && caption!.trim().isNotEmpty)
                Container(
                  color: isSentByMe ? primaryColorApp : secondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    caption!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSentByMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullScreenImage(provider: _provider),
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final ImageProvider provider;
  const _FullScreenImage({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Image(image: provider),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
