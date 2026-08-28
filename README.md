# PartSense Tam Proje Paketi

Bu paket, projenin teknik içeriğini ve kaynak kodlarını içerir. Dokümantasyon önce veri toplama ve etiketleme, ardından segmentasyon modeli, Jetson/FastAPI/Flutter sistemi ve en son GAN tabanlı hibrit veri artırma sürecini anlatır.

## Gizli veri seti

Roboflow görselleri, etiketleri ve veri yapılandırma dosyaları gizlilik nedeniyle bu depoda paylaşılmaz. `02_Roboflow_Verisi` klasöründe yalnızca bu durumu açıklayan README bulunur. Yetkili kullanıcılar veri setini yerel olarak eklemelidir.

## Ana sıralama
1. Proje hedefleri ve mimari
2. Veri toplama ve Roboflow etiketleme
3. YOLOv8 segmentasyon modeli
4. Model karşılaştırması
5. Jetson dağıtımı
6. Backend, alan hesabı ve uygulama
7. Sonuçlar ve sorunlar
8. GAN tabanlı veri artırma ve nihai hibrit model

## Nihai hibrit train seti
- 1.303 gerçek görüntü
- 300 StyleGAN2-ADA vida kompoziti
- 77 somun–somun deliği copy-paste
- Toplam 1.680 görüntü

## Nihai gerçek test sonucu
- Genel Mask mAP50-95: %55,7
- Somun: %52,3
- Somun deliği: %34,8
- Vida: %80,0
## Flutter mobil uygulaması

- `07_Flutter_Mobil_Uygulamasi/gitek-vision-flutter`: Çalıştırılabilir Flutter kaynak projesi.
- `07_Flutter_Mobil_Uygulamasi/PartSense_Flutter_Kaynak_Kodlari_Yorumlu.zip`: Aynı projenin temiz ve yorumlu ZIP arşivi.
- Derleme önbellekleri (`build`, `.dart_tool`, `.gradle`, `.idea`) teslim paketine alınmamıştır.
