import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Degradado de marca detrás de "Bienvenido a OnPoint" en las pantallas de
/// acceso (servidor y login). Único punto de verdad para que ambas vistas
/// se vean iguales.
const RadialGradient authBrandGradient = RadialGradient(
  center: Alignment(0, -1),
  radius: 1.2,
  colors: [Color(0xFF38BDF8), primaryColorApp, Color(0xFF053B6D)],
  stops: [0, 0.45, 1],
);
