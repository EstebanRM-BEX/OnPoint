// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

class ExpiryDateWidget extends StatelessWidget {
  final DateTime? expireDate;
  final Size size;
  final bool isDetaild;
  final bool isNoExpireDate;

  const ExpiryDateWidget({
    super.key,
    required this.expireDate,
    required this.size,
    required this.isDetaild,
    required this.isNoExpireDate,
  });

  @override
  Widget build(BuildContext context) {
    // Obtener la fecha actual
    DateTime now = DateTime.now();

    // Comprobar si la fecha de expiración está más de un mes vencida
    bool isExpired = expireDate != null && expireDate!.isBefore(now);
    bool isNearExpiry = expireDate != null &&
        expireDate!.isAfter(now) &&
        expireDate!.difference(now).inDays <= 30;

    // Calcular los días restantes
    int daysLeft = expireDate != null ? expireDate!.difference(now).inDays : 0;

    // Definir el color según la fecha
    Color textColor = black; // Color por defecto (normal)
    if (isExpired) {
      // Si la fecha de expiración ya ha vencido por más de un mes
      textColor = Colors.red;
    } else if (isNearExpiry) {
      // Si la fecha está cerca de vencer (dentro de un mes)
      textColor = Colors.orange;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDetaild ? 8 : 0),
      child: Row(
        children: [
          if (isDetaild)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Icon(
                Icons.calendar_month_rounded,
                color: primaryColorApp, // O cualquier otro color para el icono
                size: 15,
              ),
            ),
          Text(
            "Fecha caducidad: ",
            style: TextStyle(
              fontSize: isDetaild ? 12 : 13,
              color: isDetaild ? black : primaryColorApp,
            ),
          ),
          const SizedBox(width: 5),
          Visibility(
            visible: !isNoExpireDate,
            child: SizedBox(
              width: size.width * 0.4,
              child: Text(
                expireDate != null
                    ? "${expireDate!.toString().split(" ")[0]} (${daysLeft > 0 ? "$daysLeft días" : "Vencido"})"
                    : '',
                style: TextStyle(
                  fontSize: isDetaild ? 12 : 13,
                  color: textColor,
                ),
              ),
            ),
          ),
          Visibility(
            visible: isNoExpireDate,
            child: SizedBox(
              width: size.width * 0.4,
              child: Text(
                'Sin fecha de expiración',
                style: TextStyle(
                  fontSize: isDetaild ? 12 : 13,
                  color: red,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
