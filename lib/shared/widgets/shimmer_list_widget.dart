import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton de carga para listas de cards (Por hacer / Mis asignados /
/// Terminados en recepción multiusuario) — reemplaza el spinner centrado
/// mientras se resuelve el fetch. Cada placeholder imita la forma real de
/// esas cards (título + botón, línea de código/barcode con ícono, dos
/// líneas de cantidad, badge).
///
/// La card blanca de fondo queda FUERA del [Shimmer.fromColors] a propósito:
/// ese widget recolorea con el degradé animado cualquier píxel opaco de su
/// hijo sin importar su color original, así que si el fondo de la card
/// también estuviera adentro (blanco, igual que las barras) ambos
/// terminarían pintados del mismo tono en cada instante y las barras
/// dejarían de distinguirse del fondo — por eso cada card envuelve solo sus
/// barras internas en su propio Shimmer, no la card entera.
class ShimmerListWidget extends StatelessWidget {
  const ShimmerListWidget({super.key, this.itemCount = 6});

  /// Cantidad de cards placeholder a mostrar.
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      itemCount: itemCount,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: _ShimmerCard(),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título + botón (imprimir/acción) a la derecha.
            Row(
              children: [
                const Expanded(child: _Bar(height: 14)),
                const SizedBox(width: 10),
                _Circle(size: 22),
              ],
            ),
            const SizedBox(height: 10),
            // Código + ícono barcode + valor.
            Row(
              children: [
                const _Bar(height: 11, width: 70),
                const SizedBox(width: 10),
                _Circle(size: 14),
                const SizedBox(width: 6),
                const Expanded(child: _Bar(height: 11)),
              ],
            ),
            const SizedBox(height: 10),
            // Dos líneas de cantidad.
            const _Bar(height: 11, width: 140),
            const SizedBox(height: 6),
            const _Bar(height: 11, width: 110),
            const SizedBox(height: 10),
            // Badge/estado al final.
            const _Pill(width: 130),
          ],
        ),
      ),
    );
  }
}

/// Barra rectangular redondeada — línea de texto placeholder.
class _Bar extends StatelessWidget {
  const _Bar({required this.height, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Círculo — placeholder de ícono/avatar.
class _Circle extends StatelessWidget {
  const _Circle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Pastilla — placeholder de badge/chip de estado.
class _Pill extends StatelessWidget {
  const _Pill({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
