// FastAPI backend adresini ve istemci zaman aşımı değerlerini merkezi olarak yönetir.
// Sonuç ve yükleme görsellerinin sunucu URL'lerine güvenli biçimde dönüştürülmesini sağlar.

class ApiConfig {
  const ApiConfig._();

  // Telefon ve Jetson aynı yerel ağdayken kullanılacak backend kök adresi.
  static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

  static const Duration requestTimeout = Duration(seconds: 60);
  static const Duration healthTimeout = Duration(seconds: 5);

  // Endpoint yollarındaki baştaki eğik çizgileri temizleyerek geçerli URI üretir.
  static Uri endpoint(String path) {
    final cleanPath = path.trim().replaceFirst(RegExp(r'^/+'), '');
    return Uri.parse('$baseUrl/$cleanPath');
  }

  // Backend sonucundaki göreli veya mutlak sonuç görseli yolunu erişilebilir URL’ye dönüştürür.
  static String resultImageUrl(String path) {
    final value = path.trim();

    if (value.isEmpty) {
      return '';
    }

    final parsed = Uri.tryParse(value);

    if (parsed != null &&
        (parsed.scheme == 'http' || parsed.scheme == 'https')) {
      return value;
    }

    var cleanPath = value
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^/+'), '');

    if (cleanPath.startsWith('results/')) {
      cleanPath = cleanPath.substring('results/'.length);
    }

    if (cleanPath.startsWith('sonuclar/')) {
      cleanPath = cleanPath.substring('sonuclar/'.length);
    }

    final fileName = cleanPath.split('/').last.trim();

    if (fileName.isEmpty) {
      return '';
    }

    return '$baseUrl/sonuclar/${Uri.encodeComponent(fileName)}';
  }

  static String uploadImageUrl(String path) {
    final value = path.trim();

    if (value.isEmpty) {
      return '';
    }

    final parsed = Uri.tryParse(value);

    if (parsed != null &&
        (parsed.scheme == 'http' || parsed.scheme == 'https')) {
      return value;
    }

    var cleanPath = value
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^/+'), '');

    if (cleanPath.startsWith('uploads/')) {
      cleanPath = cleanPath.substring('uploads/'.length);
    }

    if (cleanPath.startsWith('yuklemeler/')) {
      cleanPath = cleanPath.substring('yuklemeler/'.length);
    }

    final fileName = cleanPath.split('/').last.trim();

    if (fileName.isEmpty) {
      return '';
    }

    return '$baseUrl/yuklemeler/${Uri.encodeComponent(fileName)}';
  }
}