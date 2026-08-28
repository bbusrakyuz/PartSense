// Geçmişten açılan tek bir analizin ayrıntılı veri modelidir.
// API yanıtındaki nesne listelerini, görsel yollarını ve analiz özetini tip güvenli alanlara dönüştürür.

import '../config/api_config.dart';
import 'tespit_nesnesi.dart';

class AnalizDetayi {
  const AnalizDetayi({
    required this.id,
    required this.vidaSayisi,
    required this.somunSayisi,
    required this.islemSuresiMs,
    required this.vidalar,
    required this.somunlar,
    required this.orijinalGorsel,
    required this.sonucGorseli,
    this.orijinalDosyaAdi,
    this.tarih,
  });

  final int id;
  final int vidaSayisi;
  final int somunSayisi;
  final double islemSuresiMs;
  final List<TespitNesnesi> vidalar;
  final List<TespitNesnesi> somunlar;
  final String orijinalGorsel;
  final String sonucGorseli;
  final String? orijinalDosyaAdi;
  final DateTime? tarih;

  int get toplamNesne => vidaSayisi + somunSayisi;
  List<TespitNesnesi> get tumNesneler => [...vidalar, ...somunlar];

  String? get orijinalGorselUrl => orijinalGorsel.trim().isEmpty
      ? null
      : ApiConfig.uploadImageUrl(orijinalGorsel);

  String? get sonucGorseliUrl => sonucGorseli.trim().isEmpty
      ? null
      : ApiConfig.resultImageUrl(sonucGorseli);

  // Farklı backend alan adlarıyla uyumluluk için alternatif anahtarları da kabul eder.
  factory AnalizDetayi.fromJson(Map<String, dynamic> json) {
    return AnalizDetayi(
      id: _toInt(json['analiz_id'] ?? json['id']),
      vidaSayisi: _toInt(json['vida_sayisi']),
      somunSayisi: _toInt(json['somun_sayisi']),
      islemSuresiMs: _toDouble(json['islem_suresi_ms']),
      vidalar: _objects(json['vidalar'], NesneTuru.vida),
      somunlar: _objects(json['somunlar'], NesneTuru.somun),
      orijinalGorsel:
          (json['orijinal_gorsel'] ?? json['kayitli_dosya_adi'] ?? '')
              .toString(),
      sonucGorseli: (json['sonuc_gorseli'] ?? '').toString(),
      orijinalDosyaAdi: json['orijinal_dosya_adi']?.toString(),
      tarih: DateTime.tryParse(
        (json['olusturma_zamani'] ?? json['tarih'] ?? '').toString(),
      ),
    );
  }

  static List<TespitNesnesi> _objects(dynamic value, NesneTuru tur) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (item) =>
              TespitNesnesi.fromJson(Map<String, dynamic>.from(item), tur),
        )
        .toList(growable: false);
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
