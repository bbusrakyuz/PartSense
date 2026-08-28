# Gitek Vision — Flutter

Flutter uygulaması Jetson/Ubuntu üzerinde çalışan Gitek Vision FastAPI
backend'ine bağlanır.

## Backend adresi

Telefon ve Jetson aynı ağda olmalıdır. Jetson IP adresini şu dosyada düzenleyin:

```text
lib/config/api_config.dart
```

Örnek:

```dart
flutter run --dart-define=API_BASE_URL=http://JETSON_IP_ADRESI:8000```

## Kurulum ve çalıştırma

```bash
flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter run
```

## Uygulama davranışı

- Kamera veya galeriden görsel seçer.
- Görseli `POST /tahmin` ile `dosya` alanında gönderir.
- Vida ve somun sayılarını gösterir.
- Vida alanını segmentasyon maskesinden gelen değerle gösterir.
- Somun için backend'in hesapladığı net alanı gösterir.
- Somunun dış alanı ve delik alanı mevcutsa detay kartında gösterir.
- İşaretlenmiş sonuç görselini gösterir.
- CPU/GPU ve `PT` model formatı rozetini gösterir.
- Geçmiş analizleri ve analiz detaylarını gösterir.
- PDF/CSV raporlarını indirip paylaşır.

Süre kartında yalnızca “Analiz süresi” vardır. Bu değer HTTP GET/POST süresi
değil, Jetson'daki YOLO `model.predict(...)` süresidir. Ağ ve kalan backend
süreleri ölçülmez veya ekranda gösterilmez.
