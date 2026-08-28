// POST /tahmin yanıtını temsil eden ana sonuç modelidir.
// Vida/somun listelerini, analiz süresini, sonuç görselini ve sistem bilgisini tek yapıda toplar.

import '../config/api_config.dart';
import 'sistem_bilgisi.dart';
import 'tespit_nesnesi.dart';

class AnalizSonucu {
  const AnalizSonucu({
    required this.durum,
    required this.analizId,
    required this.vidaSayisi,
    required this.somunSayisi,
    required this.vidalar,
    required this.somunlar,
    required this.islemSuresiMs,
    required this.sonucGorseli,
    required this.sistem,
  });

  final String durum;
  final int analizId;
  final int vidaSayisi;
  final int somunSayisi;
  final List<TespitNesnesi> vidalar;
  final List<TespitNesnesi> somunlar;
  final double islemSuresiMs;
  final String sonucGorseli;
  final SistemBilgisi sistem;

  double get islemSuresiSaniye => islemSuresiMs / 1000;
  String? get sonucGorseliUrl => sonucGorseli.trim().isEmpty
      ? null
      : ApiConfig.resultImageUrl(sonucGorseli);
  List<TespitNesnesi> get tumNesneler => [...vidalar, ...somunlar];

  // Backend JSON alanlarını güvenli varsayılanlarla uygulama modeline dönüştürür.
  factory AnalizSonucu.fromJson(Map<String, dynamic> json) {
    return AnalizSonucu(
      durum: json['durum']?.toString() ?? '',
      analizId: _toInt(json['analiz_id']),
      vidaSayisi: _toInt(json['vida_sayisi']),
      somunSayisi: _toInt(json['somun_sayisi']),
      vidalar: _objects(json['vidalar'], NesneTuru.vida),
      somunlar: _objects(json['somunlar'], NesneTuru.somun),
      islemSuresiMs: _toDouble(
        json['analiz_suresi_ms'] ?? json['islem_suresi_ms'],
      ),
      sonucGorseli: json['sonuc_gorseli']?.toString() ?? '',
      sistem: SistemBilgisi.fromJson(_object(json['sistem'])),
    );
  }

  static Map<String, dynamic> _object(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
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
