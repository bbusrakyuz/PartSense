// Uygulamanın başlangıç noktasıdır.
// Tema denetleyicisini dinleyerek açık, koyu veya sistem temasını uygular
// ve ana ekranı MaterialApp altında başlatır.

import 'package:flutter/material.dart';

import 'screens/ana_sayfa.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SomunVidaUygulamasi());
}

class SomunVidaUygulamasi extends StatelessWidget {
  const SomunVidaUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Gitek Vision',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const AnaSayfa(),
        );
      },
    );
  }
}
