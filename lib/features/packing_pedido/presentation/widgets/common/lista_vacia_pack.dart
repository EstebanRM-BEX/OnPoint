import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Mensaje centrado para listas vacías (scrolleable para el pull-to-refresh).
class ListaVaciaPack extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final bool cargando;

  const ListaVaciaPack({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.cargando = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: cargando
              ? const CircularProgressIndicator()
              : Column(
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(fontSize: 14, color: grey),
                    ),
                    if (subtitulo != null)
                      Text(
                        subtitulo!,
                        style: const TextStyle(fontSize: 12, color: grey),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
