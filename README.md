# PartSense Tam Proje Paketi

> **Collaborative project:** PartSense was developed during our internship work at Gitek Vision by **Emre Mahir Elbasan** and **Büşra Akyüz**. This repository is a fork of the shared project repository [`EmreMhir/PartSense`](https://github.com/EmreMhir/PartSense) to preserve the original project attribution and history.

## My Contributions — Büşra Akyüz

My work on PartSense focused primarily on the computer vision, data preparation, model experimentation, and synthetic-data research stages:

- Conducted technical research on image processing, YOLO annotation formats, model metrics, and error analysis.
- Extracted video frames with OpenCV, cleaned image data, and applied different dataset-preparation approaches.
- Experimented with object detection and instance segmentation training pipelines and analyzed class-specific errors related to nut holes, touching objects, and challenging backgrounds.
- Prepared object crops and masks from YOLO polygon annotations.
- Conducted Conditional GAN, ACGAN, Projection cGAN, and StyleGAN2-ADA experiments for synthetic-data generation.
- Evaluated GAN outputs for mode collapse, geometric consistency, diversity, and data-leakage risks, and explored masked copy-paste as a more controlled augmentation strategy.

### Shared Work

The following stages were carried out collaboratively:

- Collection of real nut and screw images and planning of difficult scenes.
- Bounding-box and polygon annotation in Roboflow, class standardization, and annotation quality control.
- Dataset development and train/validation/test splitting.
- Evaluation of model outputs on real images and data-driven improvement decisions.
- End-to-end testing and consolidation of the project documentation.

---

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
