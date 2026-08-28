import sqlite3
from pathlib import Path

PROJE_KLASORU = Path(__file__).resolve().parents[1]
VERI_KLASORU = PROJE_KLASORU / "data"
VERITABANI_YOLU = VERI_KLASORU / "analizler.db"
VERI_KLASORU.mkdir(parents=True, exist_ok=True)


def baglanti_ac():
    baglanti = sqlite3.connect(VERITABANI_YOLU)
    baglanti.row_factory = sqlite3.Row
    baglanti.execute("PRAGMA foreign_keys = ON")
    return baglanti


def _sutun_ekle(baglanti, tablo, sutun, tanim):
    mevcut = {s["name"] for s in baglanti.execute(f"PRAGMA table_info({tablo})")}
    if sutun not in mevcut:
        baglanti.execute(f"ALTER TABLE {tablo} ADD COLUMN {sutun} {tanim}")


def veritabani_olustur():
    with baglanti_ac() as b:
        b.execute("""CREATE TABLE IF NOT EXISTS analizler (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            orijinal_dosya_adi TEXT NOT NULL,
            kayitli_dosya_adi TEXT NOT NULL,
            sonuc_gorseli TEXT NOT NULL,
            islem_suresi_ms REAL NOT NULL,
            olusturma_zamani TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )""")
        for sutun, tanim in {
            "model_surumu": "TEXT NOT NULL DEFAULT 'bilinmiyor'",
            "mm2_per_px2": "REAL",
            "parlaklik": "REAL",
            "netlik": "REAL",
            "kalite_uyarisi": "TEXT"
        }.items():
            _sutun_ekle(b, "analizler", sutun, tanim)
        b.execute("""CREATE TABLE IF NOT EXISTS nesneler (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            analiz_id INTEGER NOT NULL,
            tur TEXT NOT NULL CHECK (tur IN ('vida','somun')),
            sira_no INTEGER NOT NULL,
            alan INTEGER NOT NULL,
            guven REAL NOT NULL,
            dis_alan INTEGER,
            delik_alani INTEGER,
            FOREIGN KEY (analiz_id) REFERENCES analizler(id) ON DELETE CASCADE
        )""")
        b.execute("""CREATE TABLE IF NOT EXISTS geri_bildirimler (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            analiz_id INTEGER NOT NULL,
            aciklama TEXT,
            olusturma_zamani TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (analiz_id) REFERENCES analizler(id) ON DELETE CASCADE
        )""")
        b.execute("CREATE INDEX IF NOT EXISTS idx_nesneler_analiz_id ON nesneler(analiz_id)")


def analizi_kaydet(orijinal_dosya, kaydedilen_dosya, sonuc_dosyasi,
                   islem_suresi_ms, vidalar, somunlar, model_surumu,
                   mm2_per_px2=None, parlaklik=None, netlik=None,
                   kalite_uyarisi=None):
    with baglanti_ac() as b:
        cur = b.execute("""INSERT INTO analizler
            (orijinal_dosya_adi,kayitli_dosya_adi,sonuc_gorseli,
             islem_suresi_ms,model_surumu,mm2_per_px2,parlaklik,netlik,kalite_uyarisi)
            VALUES (?,?,?,?,?,?,?,?,?)""",
            (orijinal_dosya, kaydedilen_dosya, sonuc_dosyasi,
             islem_suresi_ms, model_surumu, mm2_per_px2, parlaklik,
             netlik, kalite_uyarisi))
        analiz_id = cur.lastrowid
        for tur, liste in (("vida", vidalar), ("somun", somunlar)):
            for n in liste:
                b.execute("""INSERT INTO nesneler
                    (analiz_id,tur,sira_no,alan,guven,dis_alan,delik_alani)
                    VALUES (?,?,?,?,?,?,?)""",
                    (analiz_id, tur, n["sira_no"], n["alan"], n["guven"],
                     n.get("dis_alan"), n.get("delik_alani")))
    return {"analiz_id": analiz_id, "vidalar": vidalar, "somunlar": somunlar}


def analizleri_listele(tarih_baslangic=None, tarih_bitis=None,
                       min_vida=None, min_somun=None):
    kosullar, params = [], []
    if tarih_baslangic:
        kosullar.append("date(a.olusturma_zamani) >= date(?)")
        params.append(tarih_baslangic)
    if tarih_bitis:
        kosullar.append("date(a.olusturma_zamani) <= date(?)")
        params.append(tarih_bitis)
    where = "WHERE " + " AND ".join(kosullar) if kosullar else ""
    having, hparams = [], []
    if min_vida is not None:
        having.append("SUM(CASE WHEN n.tur='vida' THEN 1 ELSE 0 END) >= ?")
        hparams.append(min_vida)
    if min_somun is not None:
        having.append("SUM(CASE WHEN n.tur='somun' THEN 1 ELSE 0 END) >= ?")
        hparams.append(min_somun)
    hsql = "HAVING " + " AND ".join(having) if having else ""
    with baglanti_ac() as b:
        rows = b.execute(f"""SELECT a.id AS analiz_id,a.islem_suresi_ms,
            a.olusturma_zamani,a.model_surumu,
            SUM(CASE WHEN n.tur='vida' THEN 1 ELSE 0 END) AS vida_sayisi,
            SUM(CASE WHEN n.tur='somun' THEN 1 ELSE 0 END) AS somun_sayisi,
            COUNT(n.id) AS toplam_nesne
            FROM analizler a LEFT JOIN nesneler n ON n.analiz_id=a.id
            {where} GROUP BY a.id {hsql} ORDER BY a.id DESC""",
            params + hparams).fetchall()
    return [dict(r) for r in rows]


def analiz_detayi_getir(analiz_id):
    with baglanti_ac() as b:
        a = b.execute("SELECT * FROM analizler WHERE id=?", (analiz_id,)).fetchone()
        if a is None:
            return None
        rows = b.execute("""SELECT id AS nesne_id,tur,sira_no,alan,guven,
                            dis_alan,delik_alani
            FROM nesneler WHERE analiz_id=?
            ORDER BY CASE tur WHEN 'vida' THEN 0 ELSE 1 END,sira_no""",
            (analiz_id,)).fetchall()
    vidalar = [dict(r) for r in rows if r["tur"] == "vida"]
    somunlar = [dict(r) for r in rows if r["tur"] == "somun"]
    for n in vidalar + somunlar:
        n.pop("tur", None)
        if a["mm2_per_px2"]:
            n["alan_mm2"] = round(n["alan"] * a["mm2_per_px2"], 3)
    guvenler = [n["guven"] for n in vidalar + somunlar]
    sonuc = dict(a)
    sonuc.update({
        "analiz_id": a["id"], "orijinal_gorsel": a["kayitli_dosya_adi"],
        "vida_sayisi": len(vidalar), "somun_sayisi": len(somunlar),
        "toplam_nesne": len(rows), "vidalar": vidalar, "somunlar": somunlar,
        "ortalama_guven": round(sum(guvenler) / len(guvenler), 4) if guvenler else 0,
        "toplam_vida_alani": sum(n["alan"] for n in vidalar),
        "toplam_somun_alani": sum(n["alan"] for n in somunlar),
        "geri_bildirim_var": bool(geri_bildirim_var_mi(analiz_id))
    })
    if a["mm2_per_px2"]:
        sonuc["toplam_vida_alani_mm2"] = round(sonuc["toplam_vida_alani"] * a["mm2_per_px2"], 3)
        sonuc["toplam_somun_alani_mm2"] = round(sonuc["toplam_somun_alani"] * a["mm2_per_px2"], 3)
    return sonuc


def analiz_sil(analiz_id):
    """Kaydı transaction içinde siler ve ilişkili dosya adlarını döndürür."""
    with baglanti_ac() as b:
        analiz = b.execute(
            """SELECT kayitli_dosya_adi, sonuc_gorseli
               FROM analizler WHERE id=?""",
            (analiz_id,),
        ).fetchone()
        if analiz is None:
            return None
        b.execute("DELETE FROM analizler WHERE id=?", (analiz_id,))
        return dict(analiz)


def geri_bildirim_ekle(analiz_id, aciklama=None):
    with baglanti_ac() as b:
        if b.execute("SELECT 1 FROM analizler WHERE id=?", (analiz_id,)).fetchone() is None:
            return False
        b.execute("INSERT INTO geri_bildirimler (analiz_id,aciklama) VALUES (?,?)",
                  (analiz_id, aciklama))
    return True


def geri_bildirim_var_mi(analiz_id):
    with baglanti_ac() as b:
        return b.execute("SELECT 1 FROM geri_bildirimler WHERE analiz_id=? LIMIT 1",
                         (analiz_id,)).fetchone() is not None
