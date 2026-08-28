// Analiz ekranındaki özet metrikleri kompakt kart biçiminde gösteren yeniden kullanılabilir widget'tır.
// Başlık, değer, ikon ve vurgu rengi dışarıdan verilir.

import 'package:flutter/material.dart';

class OzetKarti extends StatelessWidget {
  const OzetKarti({
    super.key,
    required this.baslik,
    required this.deger,
    required this.icon,
    required this.renk,
  });

  final String baslik;
  final String deger;
  final IconData icon;
  final Color renk;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: renk.withValues(alpha: 0.09),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: renk.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: renk),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baslik, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    deger,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: renk,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
