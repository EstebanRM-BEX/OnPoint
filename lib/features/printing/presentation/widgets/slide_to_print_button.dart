import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';
import '../../../../core/constants/colors.dart';

/// Botón de deslizar para confirmar la impresión (mismo estilo que la
/// selección de BD en enterprise). El ancho reducido acorta el recorrido.
class SlideToPrintButton extends StatelessWidget {
  final VoidCallback onSubmit;

  const SlideToPrintButton({super.key, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: SlideAction(
        onSubmit: () {
          onSubmit();
          return null;
        },
        height: 44,
        text: 'Imprimir',
        textStyle: const TextStyle(color: white, fontSize: 12),
        outerColor: primaryColorApp,
        innerColor: white,
        elevation: 0,
        sliderRotate: false,
        borderRadius: 20,
        sliderButtonIconPadding: 8,
        sliderButtonIconSize: 18,
        animationDuration: const Duration(milliseconds: 200),
        submittedIcon: const Icon(Icons.check, color: white, size: 18),
        sliderButtonIcon: const Icon(
          Icons.print_outlined,
          size: 18,
          color: primaryColorApp,
        ),
      ),
    );
  }
}
