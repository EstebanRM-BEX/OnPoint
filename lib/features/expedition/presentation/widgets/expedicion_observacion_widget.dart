import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Bloque de observación de la expedición: caja de nota con título, texto
/// limitado a 2 líneas y, solo si el texto no cabe, el botón "Ver más" que
/// dispara [onVerMas] (abre DialogObservacionExpedicionWidget).
class ExpedicionObservacionWidget extends StatelessWidget {
  final String observacion;
  final VoidCallback onVerMas;

  const ExpedicionObservacionWidget({
    super.key,
    required this.observacion,
    required this.onVerMas,
  });

  static const _textStyle = TextStyle(fontSize: 12, color: Color(0xFF334155));

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Medir con el mismo estilo efectivo que pinta el Text (hereda
          // fuente/altura del DefaultTextStyle del tema); con _textStyle a
          // secas la medición daba menos líneas y el "Ver más" no aparecía.
          final estilo = DefaultTextStyle.of(context).style.merge(_textStyle);
          final painter = TextPainter(
            text: TextSpan(text: observacion, style: estilo),
            maxLines: 2,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            locale: Localizations.maybeLocaleOf(context),
          )..layout(maxWidth: constraints.maxWidth);
          final excede = painter.didExceedMaxLines;
          painter.dispose();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Observación',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                  if (excede)
                    InkWell(
                      onTap: onVerMas,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryColorApp),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ver más',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: primaryColorApp,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.visibility_outlined,
                                size: 14, color: primaryColorApp),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                observacion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: estilo,
              ),
            ],
          );
        },
      ),
    );
  }
}
