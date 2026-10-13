import 'package:flutter/material.dart';

/// Colour tokens for both themes. Widgets read these with `context.pal`
/// instead of hard-coding colours, so dark and light stay consistent.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.credit,
    required this.debit,
    required this.warning,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color onAccent;
  final Color credit;
  final Color debit;
  final Color warning;

  /// "Fintech Black & #00E676" - the original KANJAM look.
  static const AppPalette dark = AppPalette(
    background: Color(0xFF000000),
    surface: Color(0xFF111111),
    surfaceAlt: Color(0xFF1B1B1B),
    border: Color(0xFF2A2A2A),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB8B8B8),
    textMuted: Color(0xFF7D7D7D),
    accent: Color(0xFF00E676),
    onAccent: Color(0xFF000000),
    credit: Color(0xFF00E676),
    debit: Color(0xFFFF5252),
    warning: Color(0xFFFFB300),
  );

  static const AppPalette light = AppPalette(
    background: Color(0xFFF4F7F5),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFE9F0EC),
    border: Color(0xFFD5DED8),
    textPrimary: Color(0xFF0B1410),
    textSecondary: Color(0xFF44524A),
    textMuted: Color(0xFF6B7970),
    accent: Color(0xFF008F45),
    onAccent: Color(0xFFFFFFFF),
    credit: Color(0xFF008F45),
    debit: Color(0xFFD32F2F),
    warning: Color(0xFFB36B00),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      credit: Color.lerp(credit, other.credit, t)!,
      debit: Color.lerp(debit, other.debit, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension PaletteContext on BuildContext {
  AppPalette get pal => Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);
  static ThemeData get light => _build(AppPalette.light, Brightness.light);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: p.accent,
      onSecondary: p.onAccent,
      error: p.debit,
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.textPrimary,
    );
    final base = ThemeData(useMaterial3: true, brightness: brightness);
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      dividerColor: p.border,
      extensions: <ThemeExtension<dynamic>>[p],
      textTheme: base.textTheme.apply(
        bodyColor: p.textPrimary,
        displayColor: p.textPrimary,
      ),
      iconTheme: IconThemeData(color: p.textSecondary),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionHandleColor: p.accent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected) ? p.onAccent : p.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected) ? p.accent : p.surfaceAlt,
        ),
        trackOutlineColor: WidgetStateProperty.all<Color?>(Colors.transparent),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.accent,
        unselectedItemColor: p.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
    );
  }
}
