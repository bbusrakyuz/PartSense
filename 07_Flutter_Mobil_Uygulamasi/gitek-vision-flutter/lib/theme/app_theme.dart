// Uygulamanın tema modu, marka renkleri ve Material 3 bileşen stillerini tanımlar.
// Görsel tutarlılık için renkler ve widget temaları tek noktadan yönetilir.

import 'package:flutter/material.dart';

/// Uygulama genelinde tema modunu (açık/koyu/sistem) yönetir.
///
/// `main.dart` bu değeri dinleyip [MaterialApp.themeMode] değerini günceller,
/// ekranlardaki tema düğmesi ise değeri değiştirir.
class ThemeController {
  ThemeController._();

  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  static void dongu() {
    switch (mode.value) {
      case ThemeMode.system:
        mode.value = ThemeMode.light;
        break;
      case ThemeMode.light:
        mode.value = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        mode.value = ThemeMode.system;
        break;
    }
  }

  static IconData get icon {
    switch (mode.value) {
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
    }
  }

  static String get etiket {
    switch (mode.value) {
      case ThemeMode.system:
        return 'Sistem teması';
      case ThemeMode.light:
        return 'Açık tema';
      case ThemeMode.dark:
        return 'Koyu tema';
    }
  }
}

/// Gitek Vision marka renkleri ve bileşen temaları.
class AppTheme {
  AppTheme._();

  // Marka rengi: mor. Vida/somun aksan renkleri ekranlarda ayrıca kullanılır.
  static const Color _tohumRenk = Color(0xFF7C3AED);

  static const Color vidaRengi = Color(0xFF2563EB);
  static const Color somunRengi = Color(0xFF7C3AED);
  static const Color basariRengi = Color(0xFF059669);
  static const Color uyariRengi = Color(0xFFEA580C);

  static ThemeData get light => _themeFrom(
    scheme: ColorScheme.fromSeed(
      seedColor: _tohumRenk,
      brightness: Brightness.light,
    ),
    scaffoldRengi: const Color(0xFFF6F8FC),
    kartRengi: Colors.white,
  );

  static ThemeData get dark => _themeFrom(
    scheme: ColorScheme.fromSeed(
      seedColor: _tohumRenk,
      brightness: Brightness.dark,
    ),
    scaffoldRengi: const Color(0xFF0E1220),
    kartRengi: const Color(0xFF171C2C),
  );

  static ThemeData _themeFrom({
    required ColorScheme scheme,
    required Color scaffoldRengi,
    required Color kartRengi,
  }) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: scaffoldRengi,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldRengi,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: scheme.surfaceContainerHigh,
          foregroundColor: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: kartRengi,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        space: 1,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainerHigh,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
