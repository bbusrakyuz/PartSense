// Backend'deki analiz geçmişini listeler ve yenileme/silme/ayrıntı açma işlemlerini yönetir.
// Ağ veya veri hatalarını kullanıcıya okunabilir mesajlarla bildirir.

import 'package:flutter/material.dart';

import '../models/gecmis_analiz.dart';
import '../services/api_service.dart';
import 'analiz_detay_sayfasi.dart';

class GecmisSayfasi extends StatefulWidget {
  const GecmisSayfasi({super.key});

  @override
  State<GecmisSayfasi> createState() => _GecmisSayfasiState();
}

class _GecmisSayfasiState extends State<GecmisSayfasi> {
  final ApiService _apiService = const ApiService();
  late Future<List<GecmisAnaliz>> _future;

  @override
  void initState() {
    super.initState();
    _future = _apiService.analizleriGetir();
  }

  void _yenile() {
    setState(() => _future = _apiService.analizleriGetir());
  }

  String _tarih(DateTime? date) {
    if (date == null) return 'Tarih bilgisi yok';
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş Analizler'),
        actions: [
          IconButton(
            onPressed: _yenile,
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<GecmisAnaliz>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiHatasi
                ? (snapshot.error! as ApiHatasi).kullaniciMesaji
                : 'Geçmiş analizler alınamadı.';
            return _EmptyState(
              icon: Icons.cloud_off_outlined,
              title: message,
              buttonLabel: 'Tekrar Dene',
              onPressed: _yenile,
            );
          }

          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const _EmptyState(
              icon: Icons.history,
              title: 'Henüz kayıtlı analiz bulunmuyor.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _yenile();
              await _future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  elevation: 0,
                  child: ListTile(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AnalizDetaySayfasi(analizId: item.id),
                        ),
                      );
                    },
                    contentPadding: const EdgeInsets.all(14),
                    leading: CircleAvatar(child: Text('${item.id}')),
                    title: Text(
                      'Analiz #${item.id}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${_tarih(item.tarih)}\n'
                        'Vida: ${item.vidaSayisi}  •  Somun: ${item.somunSayisi}',
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(item.islemSuresiMs / 1000).toStringAsFixed(2)} sn',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    this.buttonLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center),
            if (buttonLabel != null && onPressed != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onPressed, child: Text(buttonLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
