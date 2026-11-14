import 'package:flutter/material.dart';

class AppColors {
  // Cores Principais (Identidade Varejo & Supermercado)
  static const Color primary = Color(0xFF059669); // Verde Fresco / Esmeralda
  static const Color primaryDark = Color(0xFF047857);
  static const Color primaryLight = Color(0xFFD1FAE5);

  // Cores Secundárias & Destaque (Clube de Benefícios & Ofertas)
  static const Color secondary = Color(0xFFF59E0B); // Ouro / Laranja Quente
  static const Color secondaryLight = Color(0xFFFEF3C7);
  static const Color accent = Color(0xFF2563EB); // Azul Confiança

  // Status & Alertas
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444); // Vermelho Desconto / Alerta
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF0284C7);
  static const Color infoLight = Color(0xFFE0F2FE);
  static const Color error = danger;

  // Superfícies & Fundos
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFF1F5F9);

  // Textos & Neutros
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Aliases de Design System
  static const Color neutralDark = textPrimary;
  static const Color neutralMedium = textSecondary;
  static const Color neutralLight = surfaceElevated;
}
