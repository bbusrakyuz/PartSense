// Uygulamanın ana analiz ekranıdır.
// Kamera/galeri seçimi, backend'e görsel gönderme, bağlantı durumu, sonuç kartları
// ve segmentasyon görselinin kullanıcıya sunulması bu ekran tarafından yönetilir.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/analiz_sonucu.dart';
import '../models/sistem_bilgisi.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/nesne_karti.dart';
import '../widgets/ozet_karti.dart';
import 'gecmis_sayfasi.dart';

// Stateful yapı; seçilen dosya, yüklenme durumu, sonuç ve bağlantı bilgisini ekranda korur.
class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = const ApiService();

  XFile? _secilenGorsel;
  AnalizSonucu? _sonuc;
  SistemBilgisi? _sistem;

  bool _analizEdiliyor = false;
  Timer? _sistemZamanlayici;

  @override
  void initState() {
    super.initState();
    _sistemBilgisiniYukle();

    /*
     * Bağlantı durumu (GPU/CPU rozeti) yalnızca uygulama açılışında
     * bir kez okunursa, Jetson bağlantısı sonradan koparsa bile eski
     * (artık geçersiz) bilgi ekranda kalmaya devam eder. Bu yüzden
     * belirli aralıklarla /saglik tekrar sorgulanır; bağlantı koparsa
     * rozet "Bağlanıyor" durumuna döner.
     */
    _sistemZamanlayici = Timer.periodic(
      const Duration(seconds: 8),
          (_) {
        if (!_analizEdiliyor) {
          _sistemBilgisiniYukle();
        }
      },
    );
  }

  @override
  void dispose() {
    _sistemZamanlayici?.cancel();
    super.dispose();
  }

  Future<void> _sistemBilgisiniYukle() async {
    try {
      final sistem = await _apiService.sistemBilgisiGetir();

      if (!mounted) return;

      setState(() {
        _sistem = sistem;
      });
    } on ApiHatasi catch (error) {
      debugPrint(
        'Sistem bilgisi alınamadı: '
            '${error.kullaniciMesaji}',
      );

      /*
       * Bağlantı koptuğunda eski (yanıltıcı) sistem bilgisini
       * ekranda tutmak yerine temizliyoruz; rozet tekrar
       * "Bağlanıyor" durumunu gösterir.
       */
      if (mounted) {
        setState(() {
          _sistem = null;
        });
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Beklenmeyen sistem bilgisi hatası: '
            '$error\n$stackTrace',
      );

      if (mounted) {
        setState(() {
          _sistem = null;
        });
      }
    }
  }

  Future<void> _gorselSec(ImageSource source) async {
    if (_analizEdiliyor) return;

    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 2048,
      );

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        _secilenGorsel = image;
        _sonuc = null;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'Fotoğraf seçme hatası: '
            '$error\n$stackTrace',
      );

      if (mounted) {
        _mesaj(
          'Fotoğraf seçilemedi. Kamera ve galeri '
              'izinlerini kontrol edin.',
        );
      }
    }
  }

  Future<void> _analizEt() async {
    final image = _secilenGorsel;

    if (image == null) {
      _mesaj('Önce bir fotoğraf seçin.');
      return;
    }

    if (_analizEdiliyor) return;

    setState(() {
      _analizEdiliyor = true;
      _sonuc = null;
    });

    try {
      final result = await _apiService.analizEt(
        dosyaYolu: image.path,
        dosyaAdi: image.name,
      );

      if (!mounted) return;

      setState(() {
        _sonuc = result;
        _sistem = result.sistem;
      });
    } on ApiHatasi catch (error) {
      if (mounted) {
        _mesaj(error.kullaniciMesaji);
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Beklenmeyen analiz hatası: '
            '$error\n$stackTrace',
      );

      if (mounted) {
        _mesaj(
          'Analiz sırasında beklenmeyen bir '
              'hata oluştu.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _analizEdiliyor = false;
        });
      }
    }
  }

  void _mesaj(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _gecmisiAc() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const GecmisSayfasi()));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gitek Vision'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: _SystemBadge(sistem: _sistem),
          ),
          IconButton(
            onPressed: () => setState(ThemeController.dongu),
            tooltip: ThemeController.etiket,
            icon: Icon(ThemeController.icon),
          ),
          IconButton(
            onPressed: _analizEdiliyor ? null : _gecmisiAc,
            tooltip: 'Geçmiş',
            icon: const Icon(Icons.history),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
          children: [
            _HeaderCard(scheme: scheme),
            const SizedBox(height: 18),
            _ImagePanel(image: _secilenGorsel),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _analizEdiliyor
                        ? null
                        : () => _gorselSec(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Kameradan Çek'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _analizEdiliyor
                        ? null
                        : () => _gorselSec(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeriden Seç'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _analizEdiliyor ? null : _analizEt,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Analiz Et'),
            ),
            if (_analizEdiliyor) ...[
              const SizedBox(height: 26),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              const Text(
                'Görsel analiz ediliyor...',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            if (_sonuc != null && !_analizEdiliyor) ...[
              const SizedBox(height: 28),
              _Results(result: _sonuc!),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.16),
            scheme.primary.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.auto_awesome_outlined, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vida ve somun analizi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fotoğrafı seçin, Jetson üzerindeki YOLO modeli '
                      'nesneleri analiz etsin.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePanel extends StatelessWidget {
  const _ImagePanel({required this.image});

  final XFile? image;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 240,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: image == null
          ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 66,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            'Henüz fotoğraf seçilmedi',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      )
          : Image.file(
        File(image!.path),
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.result});

  final AnalizSonucu result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Analiz Sonucu',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              OzetKarti(
                baslik: 'Vida Sayısı',
                deger: '${result.vidaSayisi}',
                icon: Icons.hardware,
                renk: AppTheme.vidaRengi,
              ),
              OzetKarti(
                baslik: 'Somun Sayısı',
                deger: '${result.somunSayisi}',
                icon: Icons.settings,
                renk: AppTheme.somunRengi,
              ),
            ];

            if (constraints.maxWidth < 380) {
              return Column(
                children: [cards[0], const SizedBox(height: 10), cards[1]],
              );
            }

            return Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 10),
                Expanded(child: cards[1]),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        _TimingCard(result: result),
        if (result.sonucGorseliUrl != null) ...[
          const SizedBox(height: 22),
          Text(
            'İşaretlenmiş Görsel',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              result.sonucGorseliUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }

                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint(
                  'Sonuç görseli '
                      'yüklenemedi: '
                      '$error\n$stackTrace',
                );

                return const SizedBox(
                  height: 130,
                  child: Card(
                    child: Center(
                      child: Text(
                        'Sonuç görseli '
                            'yüklenemedi.',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Tespit Edilen Nesneler',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        if (result.tumNesneler.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Görselde vida veya somun '
                    'tespit edilmedi.',
              ),
            ),
          )
        else
          ...result.tumNesneler.map((item) => NesneKarti(nesne: item)),
      ],
    );
  }
}

class _SystemBadge extends StatelessWidget {
  const _SystemBadge({required this.sistem});

  final SistemBilgisi? sistem;

  @override
  Widget build(BuildContext context) {
    final data = sistem;
    final gpu = data?.gpuAktif == true;

    final color = data == null
        ? Theme.of(context).colorScheme.outline
        : gpu
        ? AppTheme.basariRengi
        : AppTheme.uyariRengi;

    return Container(
      constraints: const BoxConstraints(maxWidth: 145),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            gpu ? Icons.memory : Icons.developer_board_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              data == null
                  ? 'Bağlanıyor'
                  : '${data.calismaBirimi} '
                  '• '
                  '${data.modelFormati}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimingCard extends StatelessWidget {
  const _TimingCard({required this.result});

  final AnalizSonucu result;

  String _saniye(double milliseconds) {
    final saniye = milliseconds / 1000.0;

    return '${saniye.toStringAsFixed(3).replaceAll('.', ',')} sn';
  }

  @override
  Widget build(BuildContext context) {
    final analizMs = result.islemSuresiMs;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Analiz Süresi',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Analiz süresi',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    _saniye(analizMs),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Yalnızca Jetson üzerindeki YOLO modelinin görüntüyü '
                  'işleme süresidir.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
