// Segmentasyon sonucunda bulunan tek bir vida veya somunun veri modelidir.
// Alan, güven, sıra numarası ve somuna özel dış/delik alanlarını taşır.

enum NesneTuru { vida, somun }

class TespitNesnesi {
  const TespitNesnesi({
    required this.siraNo,
    required this.tur,
    required this.alan,
    required this.guven,
    this.disAlan,
    this.delikAlani,
  });

  final int siraNo;
  final NesneTuru tur;
  final double alan;
  final double guven;
  final double? disAlan;
  final double? delikAlani;

  factory TespitNesnesi.fromJson(Map<String, dynamic> json, NesneTuru tur) {
    return TespitNesnesi(
      siraNo: _toInt(json['sira_no']),
      tur: tur,
      alan: _toDouble(json['alan']),
      guven: _toDouble(json['guven']),
      disAlan: _nullableDouble(json['dis_alan']),
      delikAlani: _nullableDouble(json['delik_alani']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) return null;
    return _toDouble(value);
  }
}
