// Geçmiş analiz listesindeki özet kayıtları temsil eder.
// Liste ekranında ihtiyaç duyulan kimlik, tarih, nesne sayıları ve süre bilgilerini taşır.

class GecmisAnaliz {
  const GecmisAnaliz({
    required this.id,
    required this.vidaSayisi,
    required this.somunSayisi,
    required this.islemSuresiMs,
    this.tarih,
  });

  final int id;
  final int vidaSayisi;
  final int somunSayisi;
  final double islemSuresiMs;
  final DateTime? tarih;

  factory GecmisAnaliz.fromJson(Map<String, dynamic> json) {
    final rawDate = json['olusturma_zamani'] ?? json['tarih'];
    return GecmisAnaliz(
      id: _toInt(json['id'] ?? json['analiz_id']),
      vidaSayisi: _toInt(json['vida_sayisi']),
      somunSayisi: _toInt(json['somun_sayisi']),
      islemSuresiMs: _toDouble(json['islem_suresi_ms']),
      tarih: rawDate == null ? null : DateTime.tryParse(rawDate.toString()),
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
}
