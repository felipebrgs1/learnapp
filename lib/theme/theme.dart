import 'package:flutter/widgets.dart';

/// Paleta inspirada no Geist: superfícies neutras, bordas finas, um único
/// acento azul e tons de status reservados para callouts.
@immutable
class AppColors {
  const AppColors({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfacePressed,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.success,
    required this.successSoft,
    required this.codeString,
    required this.codeNumber,
  });

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfacePressed;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accentSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color success;
  final Color successSoft;
  final Color codeString;
  final Color codeNumber;

  static const light = AppColors(
    brightness: Brightness.light,
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFAFAFA),
    surfacePressed: Color(0xFFF2F2F2),
    border: Color(0xFFEBEBEB),
    borderStrong: Color(0xFFD4D4D4),
    text: Color(0xFF171717),
    textSecondary: Color(0xFF4D4D4D),
    textMuted: Color(0xFF8F8F8F),
    accent: Color(0xFF0068D6),
    accentSoft: Color(0xFFEBF5FF),
    warning: Color(0xFFAA4D00),
    warningSoft: Color(0xFFFFF6E5),
    danger: Color(0xFFCB2A2F),
    dangerSoft: Color(0xFFFFEBEB),
    success: Color(0xFF107D32),
    successSoft: Color(0xFFEBFAEF),
    codeString: Color(0xFF107D32),
    codeNumber: Color(0xFFAA4D00),
  );

  static const dark = AppColors(
    brightness: Brightness.dark,
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    surfacePressed: Color(0xFF1A1A1A),
    border: Color(0xFF242424),
    borderStrong: Color(0xFF3D3D3D),
    text: Color(0xFFEDEDED),
    textSecondary: Color(0xFFA1A1A1),
    textMuted: Color(0xFF707070),
    accent: Color(0xFF52A8FF),
    accentSoft: Color(0xFF0A1A2E),
    warning: Color(0xFFFFB224),
    warningSoft: Color(0xFF2A1C04),
    danger: Color(0xFFFF6166),
    dangerSoft: Color(0xFF2E0B0D),
    success: Color(0xFF62C073),
    successSoft: Color(0xFF0B2211),
    codeString: Color(0xFF62C073),
    codeNumber: Color(0xFFFFB224),
  );
}

enum ThemePreference { system, light, dark }

class AppTheme extends InheritedWidget {
  const AppTheme({
    super.key,
    required this.colors,
    required this.preference,
    required this.onPreferenceChanged,
    required super.child,
  });

  final AppColors colors;
  final ThemePreference preference;
  final ValueChanged<ThemePreference> onPreferenceChanged;

  static AppTheme of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppTheme>()!;

  @override
  bool updateShouldNotify(AppTheme oldWidget) =>
      colors != oldWidget.colors || preference != oldWidget.preference;
}

extension ThemeContext on BuildContext {
  AppColors get colors => AppTheme.of(this).colors;
}

/// Escala tipográfica. Cores são aplicadas no ponto de uso via `copyWith`.
abstract final class AppText {
  static const sans = 'Geist';
  static const mono = 'GeistMono';

  static const display = TextStyle(
    fontFamily: sans,
    fontSize: 34,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.4,
    height: 1.08,
  );
  static const h1 = TextStyle(
    fontFamily: sans,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.0,
    height: 1.15,
  );
  static const h2 = TextStyle(
    fontFamily: sans,
    fontSize: 21,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.6,
    height: 1.25,
  );
  static const h3 = TextStyle(
    fontFamily: sans,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.35,
  );
  static const body = TextStyle(
    fontFamily: sans,
    fontSize: 15.5,
    fontWeight: FontWeight.w400,
    height: 1.65,
  );
  static const small = TextStyle(
    fontFamily: sans,
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const label = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
  static const code = TextStyle(
    fontFamily: mono,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.65,
  );
  static const eyebrow = TextStyle(
    fontFamily: mono,
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    height: 1.3,
  );
}
