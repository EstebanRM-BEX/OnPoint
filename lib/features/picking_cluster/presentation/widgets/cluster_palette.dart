import 'package:flutter/material.dart';

/// Tokens del diseño Stitch "OnPoint - Pick Cluster y Selección de Batches".
abstract final class ClusterPalette {
  static const brand50 = Color(0xFFF0F7FF);
  static const brand100 = Color(0xFFE0EFFE);
  static const brand500 = Color(0xFF0284C7);
  static const brand600 = Color(0xFF0066B2);
  static const brand700 = Color(0xFF03538F);
  static const brand800 = Color(0xFF074574);

  static const surface = Color(0xFFF4F7FB);
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);

  static const emerald500 = Color(0xFF10B981);
  static const amber500 = Color(0xFFF59E0B);

  static const headerGradient = LinearGradient(colors: [brand600, brand500]);

  static const cardShadow = [
    BoxShadow(
      color: Color(0x120C3A5F),
      blurRadius: 18,
      spreadRadius: -2,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 6,
      spreadRadius: -1,
      offset: Offset(0, 2),
    ),
  ];
}
