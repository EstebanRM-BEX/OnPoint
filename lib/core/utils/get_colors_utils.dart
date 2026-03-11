import 'package:flutter/material.dart';

Color getColorForPercentage(dynamic percentage) {
  //convertir el string en un double
  double parsedPercentage = double.tryParse(percentage.toString()) ?? 0.0;
  if (parsedPercentage >= 100) {
    return Colors.green; // Verde para 100%
  } else if (parsedPercentage < 20) {
    return Colors.red; // Rojo para menos del 20%
  } else if (parsedPercentage < 50) {
    return Colors.orange; // Naranja para menos del 50%
  } else {
    return const Color.fromARGB(
        255, 211, 190, 1); // Amarillo para entre 50% y 100%
  }
}
