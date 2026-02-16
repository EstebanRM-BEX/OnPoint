import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
// Asegúrate de importar tus colores si usas constantes personalizadas
// import 'package:wms_app/src/core/constants/colors.dart';

class ExpirationBadgeWidget extends StatelessWidget {
  final dynamic expirationDate;

  // Colores por defecto (por si no tienes el archivo de constantes a mano)
  // Si ya tienes tu archivo colors.dart importado, puedes borrar estas líneas.

  const ExpirationBadgeWidget({
    super.key,
    required this.expirationDate,
  });

  @override
  Widget build(BuildContext context) {
    // 1. LÓGICA DE CÁLCULO
    bool isExpired = false;
    bool isToday = false;
    int daysDifference = 0;
    bool hasValidDate = false;

    // Convertimos a string para validaciones seguras
    String dateStr = expirationDate?.toString() ?? "";

    // Validamos si la fecha es válida (no es null, ni "", ni "false")
    if (expirationDate != null &&
        dateStr.isNotEmpty &&
        expirationDate != false &&
        dateStr != "false") {
      final dateParsed = DateTime.tryParse(dateStr);

      if (dateParsed != null) {
        hasValidDate = true;
        final now = DateTime.now();

        // Normalizamos fechas (quitamos horas/minutos)
        final expiration =
            DateTime(dateParsed.year, dateParsed.month, dateParsed.day);
        final today = DateTime(now.year, now.month, now.day);

        // Calculamos la diferencia
        final difference = expiration.difference(today).inDays;

        if (difference < 0) {
          isExpired = true;
          daysDifference = difference.abs();
        } else if (difference == 0) {
          isToday = true;
          daysDifference = 0;
        } else {
          isExpired = false;
          daysDifference = difference;
        }
      }
    }

    // 2. INTERFAZ VISUAL
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Fecha caducidad: ',
                style: TextStyle(fontSize: 13, color: primaryColorApp),
              ),
              Text(
                (!hasValidDate) ? "No controla caducidad" : dateStr,
                style: TextStyle(
                  fontSize: 13,
                  color: (isExpired || !hasValidDate) ? red : black,
                ),
              ),
            ],
          ),
          if (hasValidDate)
            Builder(
              builder: (context) {
                Color bgColor;
                Color borderColor;
                Color textColor;
                IconData icon;
                String textLabel;

                if (isExpired) {
                  // --- VENCIDO ---
                  bgColor = Colors.red[50]!;
                  borderColor = Colors.red.shade300;
                  textColor = Colors.red[900]!;
                  icon = Icons.warning_amber_rounded;
                  textLabel = "Vencido hace $daysDifference días";
                } else if (isToday) {
                  // --- VENCE HOY ---
                  bgColor = Colors.orange[100]!;
                  borderColor = Colors.orange.shade400;
                  textColor = Colors.orange[900]!;
                  icon = Icons.priority_high_rounded;
                  textLabel = "¡Vence hoy!";
                } else if (daysDifference < 15) {
                  // --- POR VENCER (< 15 días) ---
                  bgColor = Colors.orange[50]!;
                  borderColor = Colors.orange.shade300;
                  textColor = Colors.orange[800]!;
                  icon = Icons.av_timer;
                  textLabel = "Vence en $daysDifference días";
                } else {
                  // --- SEGURO (> 15 días) ---
                  bgColor = Colors.blue[50]!;
                  borderColor = Colors.blue.shade200;
                  textColor = Colors.blue[800]!;
                  icon = Icons.check_circle_outline;
                  textLabel = "Vence en $daysDifference días";
                }

                return Container(
                  margin: const EdgeInsets.only(top: 5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: textColor, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        textLabel,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
