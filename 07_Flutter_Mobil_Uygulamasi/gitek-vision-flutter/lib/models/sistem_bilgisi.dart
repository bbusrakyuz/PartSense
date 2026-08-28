// Backend tarafından döndürülen çalışma birimi, cihaz ve model bilgilerini temsil eder.
// GPU durumunun arayüzde rozet olarak gösterilmesi için yardımcı getter içerir.

class SistemBilgisi {
  const SistemBilgisi({
    required this.calismaBirimi,
    required this.cihazAdi,
    required this.modelFormati,
    required this.modelDosyasi,
  });

  final String calismaBirimi;
  final String cihazAdi;
  final String modelFormati;
  final String modelDosyasi;

  bool get gpuAktif => calismaBirimi.toUpperCase() == 'GPU';

  factory SistemBilgisi.fromJson(Map<String, dynamic> json) {
    return SistemBilgisi(
      calismaBirimi: json['calisma_birimi']?.toString() ?? 'Bilinmiyor',
      cihazAdi: json['cihaz_adi']?.toString() ?? 'Bilinmiyor',
      modelFormati: json['model_formati']?.toString() ?? 'Bilinmiyor',
      modelDosyasi: json['model_dosyasi']?.toString() ?? '',
    );
  }
}
