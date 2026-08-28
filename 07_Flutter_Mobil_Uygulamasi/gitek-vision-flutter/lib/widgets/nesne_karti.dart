// Tek bir vida veya somun için sıra numarası, güven ve alan bilgisini gösteren karttır.
// Nesne türüne göre ikon ve vurgu rengini otomatik seçer.

import 'package:flutter/material.dart';

import '../models/tespit_nesnesi.dart';
import '../theme/app_theme.dart';

class NesneKarti extends StatelessWidget {
  const NesneKarti({super.key, required this.nesne});

  final TespitNesnesi nesne;

  String _alan(double value) => '${value.toStringAsFixed(0)} px²';

  @override
  Widget build(BuildContext context) {
    final vida = nesne.tur == NesneTuru.vida;
    final color = vida ? AppTheme.vidaRengi : AppTheme.somunRengi;
    final title = vida ? 'Vida' : 'Somun';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: color.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  foregroundColor: color,
                  child: Icon(vida ? Icons.hardware : Icons.settings),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$title ${nesne.siraNo}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '%${(nesne.guven * 100).toStringAsFixed(2)}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            _row(
              context,
              vida ? 'Vida Alanı' : 'Somun Alanı',
              _alan(nesne.alan),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
