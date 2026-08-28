import csv
import io
import logging
from pathlib import Path
from uuid import uuid4
from typing import Optional

import cv2
import numpy as np
from fastapi import FastAPI, File, Form, HTTPException, Query, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, Response
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas

from app.analiz import MODEL_SURUMU, analiz_et, get_sistem_bilgisi
from app.veritabani import (
    analiz_detayi_getir,
    analizi_kaydet,
    analizleri_listele,
    analiz_sil,
    geri_bildirim_ekle,
    veritabani_olustur,
)

logger = logging.getLogger("gitek_vision")

PROJE_KLASORU = Path(__file__).resolve().parents[1]
UPLOAD_KLASORU = PROJE_KLASORU / "uploads"
SONUC_KLASORU = PROJE_KLASORU / "results"
INDEX_DOSYASI = PROJE_KLASORU / "app" / "index.html"
UPLOAD_KLASORU.mkdir(parents=True, exist_ok=True)
SONUC_KLASORU.mkdir(parents=True, exist_ok=True)
IZIN_VERILEN_UZANTILAR = {".jpg", ".jpeg", ".png"}
MAKSIMUM_DOSYA_BOYUTU = 10 * 1024 * 1024
veritabani_olustur()

app = FastAPI(title="Gitek Vision API", version="2.1.0")

# Telefon uygulaması ve web paneli farklı origin'lerden (aynı Wi-Fi ağındaki
# farklı cihazlardan) istek atabildiği için CORS açık bırakılır.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/sonuclar", StaticFiles(directory=str(SONUC_KLASORU)), name="sonuclar")
app.mount("/yuklemeler", StaticFiles(directory=str(UPLOAD_KLASORU)), name="yuklemeler")


class GeriBildirim(BaseModel):
    aciklama: Optional[str] = None


async def _dosya_oku(dosya: UploadFile):
    uzanti = Path(dosya.filename or "").suffix.lower()
    if uzanti not in IZIN_VERILEN_UZANTILAR:
        raise HTTPException(400, "Yalnızca JPG, JPEG ve PNG yüklenebilir.")
    icerik = await dosya.read(MAKSIMUM_DOSYA_BOYUTU + 1)
    await dosya.close()
    if not icerik:
        raise HTTPException(400, "Yüklenen dosya boş.")
    if len(icerik) > MAKSIMUM_DOSYA_BOYUTU:
        raise HTTPException(413, "Dosya boyutu 10 MB sınırını aşıyor.")
    return uzanti, icerik


def kalite_olc(icerik):
    veri = np.frombuffer(icerik, dtype=np.uint8)
    gorsel = cv2.imdecode(veri, cv2.IMREAD_GRAYSCALE)

    if gorsel is None:
        raise HTTPException(400, "Görsel okunamadı.")

    yukseklik, genislik = gorsel.shape
    parlaklik = round(float(gorsel.mean()), 2)
    netlik = round(
        float(cv2.Laplacian(gorsel, cv2.CV_64F).var()),
        2,
    )

    uyarilar = []

    # Çözünürlük kontrolü
    if genislik < 640 or yukseklik < 480:
        uyarilar.append(
            "Fotoğrafın çözünürlüğü düşük. Daha yüksek kalitede tekrar çekin."
        )

    # Parlaklık kontrolü
    if parlaklik < 55:
        uyarilar.append(
            "Fotoğraf çok karanlık. Daha aydınlık bir ortamda tekrar çekin."
        )
    elif parlaklik > 220:
        uyarilar.append(
            "Fotoğraf aşırı parlak. Işığı azaltarak tekrar çekin."
        )

    # Bulanıklık kontrolü
    if netlik < 80:
        uyarilar.append(
            "Fotoğraf bulanık. Kamerayı sabit tutarak tekrar çekin."
        )

    return {
        "genislik": genislik,
        "yukseklik": yukseklik,
        "parlaklik": parlaklik,
        "netlik": netlik,
        "uygun": len(uyarilar) == 0,
        "uyarilar": uyarilar,
    }


@app.get("/", response_class=HTMLResponse)
def ana_sayfa():
    return INDEX_DOSYASI.read_text(encoding="utf-8")


@app.get("/saglik")
def saglik():
    """
    Flutter uygulamasındaki SistemBilgisi modeliyle eşleşmesi için
    'sistem' anahtarı zorunludur - eskiden bu alan hiç dönmüyordu ve
    telefon uygulaması sürekli 'Sistem bilgisi okunamadı' hatası alıyordu.
    """
    return {
        "durum": "hazır",
        "model_surumu": MODEL_SURUMU,
        "api_surumu": app.version,
        "sistem": get_sistem_bilgisi(),
    }


@app.post("/kalite-kontrol")
async def kalite_kontrol(dosya: UploadFile = File(...)):
    _, icerik = await _dosya_oku(dosya)
    return kalite_olc(icerik)


@app.get("/analizler")
def gecmis(tarih_baslangic: Optional[str] = None, tarih_bitis: Optional[str] = None,
           min_vida: Optional[int] = Query(None, ge=0),
           min_somun: Optional[int] = Query(None, ge=0)):
    return analizleri_listele(tarih_baslangic, tarih_bitis, min_vida, min_somun)


@app.get("/analizler/{analiz_id}")
def detay(analiz_id: int):
    sonuc = analiz_detayi_getir(analiz_id)
    if sonuc is None:
        raise HTTPException(404, "Analiz kaydı bulunamadı.")
    return sonuc


@app.delete("/analizler/{analiz_id}")
def analiz_sil_endpoint(analiz_id: int):
    dosyalar = analiz_sil(analiz_id)
    if dosyalar is None:
        raise HTTPException(404, "Analiz kaydı bulunamadı.")

    (UPLOAD_KLASORU / dosyalar["kayitli_dosya_adi"]).unlink(missing_ok=True)
    (SONUC_KLASORU / dosyalar["sonuc_gorseli"]).unlink(missing_ok=True)
    return {"durum": "silindi", "analiz_id": analiz_id}


@app.post("/analizler/{analiz_id}/geri-bildirim")
def geri_bildirim(analiz_id: int, veri: GeriBildirim):
    if not geri_bildirim_ekle(analiz_id, veri.aciklama):
        raise HTTPException(404, "Analiz kaydı bulunamadı.")
    return {"durum": "kaydedildi"}


def _csv_uret(d):
    out = io.StringIO()
    w = csv.writer(out)
    w.writerow(["Analiz", d["analiz_id"]])
    w.writerow(["Tarih", d["olusturma_zamani"]])
    w.writerow(["Model", d["model_surumu"]])
    w.writerow(["Ortalama güven", d["ortalama_guven"]])
    w.writerow(["Analiz süresi (ms)", d["islem_suresi_ms"]])
    w.writerow(["Vida sayısı", d["vida_sayisi"]])
    w.writerow(["Somun sayısı", d["somun_sayisi"]])
    w.writerow(["Toplam vida alanı (px²)", d["toplam_vida_alani"]])
    w.writerow(["Toplam somun alanı (px²)", d["toplam_somun_alani"]])
    w.writerow([])
    w.writerow([
        "Tür", "Sıra", "Net alan px²", "Dış alan px²",
        "Delik alanı px²", "Alan mm²", "Güven",
    ])
    for tur, liste in (("Vida", d["vidalar"]), ("Somun", d["somunlar"])):
        for n in liste:
            w.writerow([
                tur,
                n["sira_no"],
                n["alan"],
                n.get("dis_alan", ""),
                n.get("delik_alani", ""),
                n.get("alan_mm2", ""),
                n["guven"],
            ])
    return out.getvalue().encode("utf-8-sig")


@app.get("/analizler/{analiz_id}/csv")
def csv_indir(analiz_id: int):
    d = analiz_detayi_getir(analiz_id)
    if d is None:
        raise HTTPException(404, "Analiz kaydı bulunamadı.")
    return Response(_csv_uret(d), media_type="text/csv",
                    headers={"Content-Disposition": f'attachment; filename="analiz_{analiz_id}.csv"'})


@app.get("/analizler/{analiz_id}/pdf")
def pdf_indir(analiz_id: int):
    d = analiz_detayi_getir(analiz_id)
    if d is None:
        raise HTTPException(404, "Analiz kaydı bulunamadı.")
    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=A4)
    y = 800
    for satir in [f"Gitek Vision - Analiz #{analiz_id}", f"Tarih: {d['olusturma_zamani']}",
                  f"Model: {d['model_surumu']}", f"Vida: {d['vida_sayisi']}   Somun: {d['somun_sayisi']}",
                  f"Ortalama guven: %{d['ortalama_guven'] * 100:.2f}",
                  f"Analiz suresi: {d['islem_suresi_ms']:.2f} ms",
                  f"Toplam vida alani: {d['toplam_vida_alani']} px2",
                  f"Toplam somun alani: {d['toplam_somun_alani']} px2"]:
        c.drawString(50, y, satir); y -= 24
    y -= 10
    for tur, liste in (("Vida", d["vidalar"]), ("Somun", d["somunlar"])):
        for n in liste:
            c.drawString(50, y, f"{tur} {n['sira_no']}: {n['alan']} px2  guven %{n['guven']*100:.2f}")
            y -= 20
            if y < 50: c.showPage(); y = 800
    c.save()
    return Response(buf.getvalue(), media_type="application/pdf",
                    headers={"Content-Disposition": f'attachment; filename="analiz_{analiz_id}.pdf"'})


@app.post("/tahmin")
async def tahmin(
    dosya: UploadFile = File(...),
    referans_gercek_alan_mm2: Optional[float] = Form(None),
    referans_piksel_alani: Optional[float] = Form(None),
):
    orijinal_ad = dosya.filename or "gorsel.jpg"
    uzanti, icerik = await _dosya_oku(dosya)
    kalite = kalite_olc(icerik)

    if not kalite["uygun"]:
        raise HTTPException(
            status_code=422,
            detail={
                "kod": "KALITESIZ_GORSEL",
                "mesaj": "Fotoğraf analiz için yeterli kalitede değil.",
                "parlaklik": kalite["parlaklik"],
                "netlik": kalite["netlik"],
                "uyarilar": kalite["uyarilar"],
            },
        )

    mm2_per_px2 = None
    kalibrasyon_degerleri = (
        referans_gercek_alan_mm2,
        referans_piksel_alani,
    )

    if any(deger is not None for deger in kalibrasyon_degerleri):
        if not all(deger is not None for deger in kalibrasyon_degerleri):
            raise HTTPException(
                400,
                "Kalibrasyon için iki referans alanı birlikte gönderilmelidir.",
            )

        if referans_gercek_alan_mm2 <= 0 or referans_piksel_alani <= 0:
            raise HTTPException(
                400,
                "Referans alanları sıfırdan büyük olmalıdır.",
            )

        mm2_per_px2 = (
            referans_gercek_alan_mm2 / referans_piksel_alani
        )

    ad = f"{uuid4().hex}{uzanti}"
    yol = UPLOAD_KLASORU / ad
    yol.write_bytes(icerik)

    try:
        a = analiz_et(yol)

        db = analizi_kaydet(
            orijinal_ad,
            ad,
            a["sonuc_gorseli"],
            a["analiz_suresi_ms"],
            a["vidalar"],
            a["somunlar"],
            MODEL_SURUMU,
            mm2_per_px2,
            kalite["parlaklik"],
            kalite["netlik"],
            ", ".join(kalite["uyarilar"]) or None,
        )
    except HTTPException:
        yol.unlink(missing_ok=True)
        raise
    except Exception:
        logger.exception(
            "Tahmin isteği işlenirken beklenmeyen hata oluştu"
        )
        yol.unlink(missing_ok=True)
        raise HTTPException(
            500,
            "Analiz sırasında sunucu hatası oluştu.",
        )

    detay = analiz_detayi_getir(db["analiz_id"])
    detay["durum"] = "basarili"
    detay["sistem"] = get_sistem_bilgisi()
    detay["analiz_suresi_ms"] = a["analiz_suresi_ms"]
    return detay
