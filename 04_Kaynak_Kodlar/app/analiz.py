
# Bu modül YOLOv8n-seg modelini tek sefer yükler, GPU/CPU seçimini otomatik yapar,
# segmentasyon maskelerini işleyerek alan bilgilerini üretir ve sonuç görselini kaydeder.
# Güncel görsel çıktı yalnız segmentasyon maskelerini gösterir; bounding box, sınıf etiketi
# ve güven oranı kullanıcı arayüzünden kaldırılmıştır. Vida maskeleri kırmızı renkte gösterilir.
# Üretimde kullanılan model, 300 StyleGAN2-ADA vida kompoziti ve 77 somun-delik copy-paste
# örneğiyle desteklenmiş hibrit YOLOv8n-seg best.pt dosyasıdır.

from hashlib import sha256
import platform
from pathlib import Path
from time import perf_counter

import cv2
import numpy as np
import torch
from ultralytics import YOLO

from app.alan_hesapla import (
    delikleri_somunlarla_eslestir,
    maskeyi_hazirla,
    net_somun_alanini_hesapla,
)

PROJE_KLASORU = Path(__file__).resolve().parents[1]
MODEL_YOLU = PROJE_KLASORU / "model" / "best.pt"
SONUC_KLASORU = PROJE_KLASORU / "results"

SONUC_KLASORU.mkdir(parents=True, exist_ok=True)

if not MODEL_YOLU.exists():
    raise FileNotFoundError(
        f"Model dosyası bulunamadı: {MODEL_YOLU}\n"
        "Eğitilmiş 'best.pt' dosyasını 'model/' klasörüne kopyalayın."
    )


def _model_surumu():
    ozet = sha256(MODEL_YOLU.read_bytes()).hexdigest()[:10]
    return f"{MODEL_YOLU.stem}-{ozet}"


def _cihaz_bilgisi():
    """
    Jetson/Ubuntu cihazında CUDA (GPU) var mı diye otomatik tespit eder.
    GPU bulunamazsa modeli CPU üzerinde çalıştırır; böylece uygulama
    GPU'suz makinelerde de (ör. geliştirme bilgisayarı) çökmeden ayağa kalkar.
    """
    if torch.cuda.is_available():
        return {
            "calisma_birimi": "GPU",
            "cihaz_adi": torch.cuda.get_device_name(0),
        }
    return {
        "calisma_birimi": "CPU",
        "cihaz_adi": platform.processor() or platform.machine() or "CPU",
    }


MODEL_SURUMU = _model_surumu()
_CIHAZ = _cihaz_bilgisi()
GPU_AKTIF = _CIHAZ["calisma_birimi"] == "GPU"
CIHAZ_PARAMETRESI = 0 if GPU_AKTIF else "cpu"

model = YOLO(str(MODEL_YOLU))

ZORUNLU_SINIFLAR = {"somun", "vida", "somun_deligi"}
_SINIF_ADLARI = (
    model.names.values()
    if isinstance(model.names, dict)
    else model.names
)
MODEL_SINIFLARI = {
    str(sinif_adi).strip().lower()
    for sinif_adi in _SINIF_ADLARI
}
EKSIK_SINIFLAR = ZORUNLU_SINIFLAR - MODEL_SINIFLARI
if EKSIK_SINIFLAR:
    raise RuntimeError(
        "best.pt modelinde zorunlu sınıflar eksik: "
        + ", ".join(sorted(EKSIK_SINIFLAR))
        + ". Beklenen sınıflar: somun, vida, somun_deligi."
    )


def get_sistem_bilgisi():
    """Flutter uygulamasındaki SistemBilgisi modeliyle birebir eşleşir."""
    return {
        "calisma_birimi": _CIHAZ["calisma_birimi"],
        "cihaz_adi": _CIHAZ["cihaz_adi"],
        "model_formati": (MODEL_YOLU.suffix.lstrip(".").upper() or "PT"),
        "model_dosyasi": MODEL_YOLU.name,
        "model_surumu": MODEL_SURUMU,
        "siniflar": sorted(MODEL_SINIFLARI),
    }


def analiz_et(gorsel_yolu):
    gorsel_yolu = Path(gorsel_yolu)

    # Kullanıcıya gösterilen "Analiz süresi" yalnızca YOLO modelinin
    # görüntüyü işlediği predict çağrısıdır. Dosya okuma/yazma, ağ,
    # kalite kontrolü, maske alan hesabı ve veritabanı bu süreye dahil
    # edilmez.
    if GPU_AKTIF:
        torch.cuda.synchronize()
    tahmin_baslangic = perf_counter()
    results = model.predict(
        source=str(gorsel_yolu),
        conf=0.50,
        imgsz=512,
        device=CIHAZ_PARAMETRESI,
        half=GPU_AKTIF,
        verbose=False,
    )
    if GPU_AKTIF:
        torch.cuda.synchronize()
    tahmin_suresi_ms = round((perf_counter() - tahmin_baslangic) * 1000, 2)

    sonuc = results[0]
    yukseklik, genislik = sonuc.orig_shape

    vidalar_ham = []
    somunlar_ham = []
    delikler_ham = []

    if sonuc.masks is not None:
        maskeler = sonuc.masks.data.cpu().numpy()
        siniflar = sonuc.boxes.cls.int().cpu().tolist()
        guvenler = sonuc.boxes.conf.cpu().tolist()
        kutular = sonuc.boxes.xyxy.cpu().numpy()

        for maske, sinif_id, guven, kutu in zip(
            maskeler, siniflar, guvenler, kutular
        ):
            maske = maskeyi_hazirla(maske, yukseklik, genislik)
            sinif_adi = str(model.names[int(sinif_id)]).strip().lower()

            merkez_x = float((kutu[0] + kutu[2]) / 2)
            merkez_y = float((kutu[1] + kutu[3]) / 2)

            nesne = {
                "maske": maske,
                "guven": round(float(guven), 4),
                "merkez_x": merkez_x,
                "merkez_y": merkez_y,
                "kutu": tuple(float(deger) for deger in kutu),
            }

            if sinif_adi == "vida":
                vidalar_ham.append(nesne)
            elif sinif_adi == "somun":
                nesne["delik_maskesi"] = np.zeros((yukseklik, genislik), dtype=bool)
                somunlar_ham.append(nesne)
            elif sinif_adi == "somun_deligi":
                delikler_ham.append(nesne)

    vidalar_ham.sort(key=lambda nesne: (nesne["merkez_x"], nesne["merkez_y"]))
    somunlar_ham.sort(key=lambda nesne: (nesne["merkez_x"], nesne["merkez_y"]))

    delikleri_somunlarla_eslestir(somunlar_ham, delikler_ham)

    vidalar = []
    for sira_no, vida in enumerate(vidalar_ham, start=1):
        vidalar.append({
            "sira_no": sira_no,
            "alan": int(np.count_nonzero(vida["maske"])),
            "guven": vida["guven"],
        })

    somunlar = []
    for sira_no, somun in enumerate(somunlar_ham, start=1):
        dis_alani, delik_alani, somun_alani = net_somun_alanini_hesapla(
            somun,
            gorsel_yuksekligi=yukseklik,
            gorsel_genisligi=genislik,
        )

        somunlar.append({
            "sira_no": sira_no,
            "alan": somun_alani,
            "dis_alan": dis_alani,
            "delik_alani": delik_alani,
            "guven": somun["guven"],
        })

    sonuc_dosya_adi = f"{gorsel_yolu.stem}_sonuc.jpg"
    sonuc_yolu = SONUC_KLASORU / sonuc_dosya_adi

    # YOLO sonucunu CPU'ya taşı
    sonuc_cpu = sonuc.cpu()

    del results
    del sonuc

    if GPU_AKTIF:
        torch.cuda.empty_cache()

        # Segmentasyon maskelerini CPU üzerinde çiz
    isaretli_gorsel = sonuc_cpu.plot(
        boxes=False,
        labels=False,
        conf=False,
        color_mode="class",
    )

    # Yalnızca vida maskelerini kırmızı renkle yeniden boya.
    if sonuc_cpu.masks is not None:
        maskeler = sonuc_cpu.masks.data.cpu().numpy()
        siniflar = sonuc_cpu.boxes.cls.int().cpu().tolist()

        for maske, sinif_id in zip(maskeler, siniflar):
            sinif_adi = str(model.names[int(sinif_id)]).strip().lower()

            if sinif_adi == "vida":
                maske = maskeyi_hazirla(
                    maske,
                    yukseklik,
                    genislik,
                )

                isaretli_gorsel[maske] = (
                    isaretli_gorsel[maske] * 0.30
                    + np.array([0, 0, 255]) * 0.70
                ).astype(np.uint8)

    if not cv2.imwrite(str(sonuc_yolu), isaretli_gorsel):
        raise RuntimeError(f"Sonuç görseli kaydedilemedi: {sonuc_yolu}")

    return {
        "vidalar": vidalar,
        "somunlar": somunlar,
        "somun_deligi_sayisi": len(delikler_ham),
        "analiz_suresi_ms": tahmin_suresi_ms,
        "sonuc_gorseli": sonuc_dosya_adi,
    }
