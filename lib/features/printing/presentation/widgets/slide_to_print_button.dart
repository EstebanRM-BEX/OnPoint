import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';
import '../../../../core/constants/colors.dart';

/// Botón de deslizar para confirmar la impresión. El riel muestra flechas
/// animadas hacia la derecha para que sea evidente que se debe arrastrar la
/// perilla (no tocar).
class SlideToPrintButton extends StatefulWidget {
  final VoidCallback onSubmit;

  const SlideToPrintButton({super.key, required this.onSubmit});

  @override
  State<SlideToPrintButton> createState() => _SlideToPrintButtonState();
}

class _SlideToPrintButtonState extends State<SlideToPrintButton>
    with SingleTickerProviderStateMixin {
  static const double _height = 48;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: SlideAction(
        onSubmit: () {
          widget.onSubmit();
          return null;
        },
        height: _height,
        outerColor: primaryColorApp,
        innerColor: white,
        elevation: 2,
        sliderRotate: false,
        borderRadius: _height / 2,
        sliderButtonIconPadding: 9,
        sliderButtonIconSize: 18,
        animationDuration: const Duration(milliseconds: 200),
        submittedIcon: const Icon(Icons.check, color: white, size: 20),
        sliderButtonIcon: const Icon(
          Icons.print_outlined,
          size: 18,
          color: primaryColorApp,
        ),
        // Padding izquierdo para no quedar debajo de la perilla.
        child: Padding(
          padding: const EdgeInsets.only(left: _height, right: 8),
          child: Center(child: _AnimatedChevrons(animation: _controller)),
        ),
      ),
    );
  }
}

/// Tres chevrons que se encienden en secuencia indicando la dirección.
class _AnimatedChevrons extends StatelessWidget {
  final Animation<double> animation;

  const _AnimatedChevrons({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Cada chevron tiene su pico de opacidad desfasado.
            final phase = (animation.value - i * 0.2) % 1.0;
            final opacity = phase < 0.5 ? 0.3 + phase * 1.4 : 1.0 - (phase - 0.5) * 1.4;
            return Align(
              widthFactor: 0.55,
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: white.withValues(alpha: opacity.clamp(0.3, 1.0)),
              ),
            );
          }),
        );
      },
    );
  }
}
