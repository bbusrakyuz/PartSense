// Seçilen geçmiş analiz kaydının ayrıntılarını gösterir.
// Orijinal görsel, segmentasyon sonucu, nesne metrikleri ve PDF/CSV paylaşım akışını yönetir.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../config/api_config.dart';
import '../models/analiz_detayi.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/nesne_karti.dart';
import '../widgets/ozet_karti.dart';

class AnalizDetaySayfasi extends StatefulWidget {
  const AnalizDetaySayfasi({super.key, required this.analizId});

  final int analizId;

  @override
  State<AnalizDetaySayfasi> createState() => _AnalizDetaySayfasiState();
}

class _AnalizDetaySayfasiState extends State<AnalizDetaySayfasi> {
  final ApiService _apiService = const ApiService();
  late Future<AnalizDetayi> _future;
  String? _indirilenRapor;

  @override
  void initState() {
    super.initState();
    _future = _apiService.analizDetayiGetir(widget.analizId);
  }

  void _yenile() {
    setState(() {
      _future = _apiService.analizDetayiGetir(widget.analizId);
    });
  }

  String _tarih(DateTime? date) {
    if (date == null) return 'Tarih bilgisi yok';
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  Future<void> _raporuDisariAktar(String tur) async {
    if (_indirilenRapor != null) return;

    setState(() => _indirilenRapor = tur);
    try {
      final uri = ApiConfig.endpoint('/analizler/${widget.analizId}/$tur');
      final response = await http.get(uri).timeout(ApiConfig.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const ApiHatasi('Rapor sunucudan alınamadı.');
      }

      final dosya = File(
        '${Directory.systemTemp.path}/analiz_${widget.analizId}.$tur',
      );
      await dosya.writeAsBytes(response.bodyBytes, flush: true);

      final mimeType = tur == 'pdf' ? 'application/pdf' : 'text/csv';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(dosya.path, mimeType: mimeType)],
          text: 'Gitek Vision - Analiz #${widget.analizId}',
        ),
      );
    } on ApiHatasi catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.kullaniciMesaji)));
      }
    } catch (error, stackTrace) {
      debugPrint('Rapor dışa aktarma hatası: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapor dışa aktarılamadı.')),
        );
      }
    } finally {
      if (mounted) setState(() => _indirilenRapor = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Analiz #${widget.analizId}')),
      body: FutureBuilder<AnalizDetayi>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ApiHatasi
                ? (snapshot.error! as ApiHatasi).kullaniciMesaji
                : 'Analiz ayrıntıları alınamadı.';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 58),
                    const SizedBox(height: 14),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _yenile,
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            );
          }

          final detay = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              _yenile();
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  _tarih(detay.tarih),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (detay.orijinalDosyaAdi?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    detay.orijinalDosyaAdi!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 18),
                _Gorseller(detay: detay),
                const SizedBox(height: 6),
                Text(
                  'Dışa Aktar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _indirilenRapor == null
                          ? () => _raporuDisariAktar('pdf')
                          : null,
                      icon: _indirilenRapor == 'pdf'
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('PDF'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _indirilenRapor == null
                          ? () => _raporuDisariAktar('csv')
                          : null,
                      icon: _indirilenRapor == 'csv'
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.table_view_outlined),
                      label: const Text('CSV'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OzetKarti(
                        baslik: 'Vida',
                        deger: '${detay.vidaSayisi}',
                        icon: Icons.hardware,
                        renk: AppTheme.vidaRengi,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OzetKarti(
                        baslik: 'Somun',
                        deger: '${detay.somunSayisi}',
                        icon: Icons.settings,
                        renk: AppTheme.somunRengi,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OzetKarti(
                  baslik: 'Analiz Süresi',
                  deger:
                      '${(detay.islemSuresiMs / 1000).toStringAsFixed(2)} saniye',
                  icon: Icons.timer_outlined,
                  renk: AppTheme.basariRengi,
                ),
                const SizedBox(height: 22),
                Text(
                  'Tüm Metrikler',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                if (detay.tumNesneler.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Bu analizde kayıtlı nesne bulunmuyor.'),
                    ),
                  )
                else
                  ...detay.tumNesneler.map((nesne) => NesneKarti(nesne: nesne)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Gorseller extends StatelessWidget {
  const _Gorseller({required this.detay});

  final AnalizDetayi detay;

  @override
  Widget build(BuildContext context) {
    final images = <({String title, String? url})>[
      (title: 'Çekilen Fotoğraf', url: detay.orijinalGorselUrl),
      (title: 'Maskelenmiş Fotoğraf', url: detay.sonucGorseliUrl),
    ];

    return Column(
      children: images
          .map((image) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    image.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: image.url == null
                        ? const _GorselHatasi(text: 'Görsel kaydı bulunamadı.')
                        : Image.network(
                            image.url!,
                            height: 230,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) =>
                                progress == null
                                ? child
                                : const SizedBox(
                                    height: 230,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                            errorBuilder: (_, error, stackTrace) {
                              debugPrint(
                                'Geçmiş görsel yükleme hatası: '
                                '$error\n$stackTrace',
                              );
                              return const _GorselHatasi(
                                text: 'Görsel yüklenemedi.',
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _GorselHatasi extends StatelessWidget {
  const _GorselHatasi({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text(text),
    );
  }
}
