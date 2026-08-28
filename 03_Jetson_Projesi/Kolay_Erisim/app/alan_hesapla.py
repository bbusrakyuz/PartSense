"""Segmentasyon maskelerinden vida ve net somun alanı yardımcıları."""

import numpy as np


def maskeyi_hazirla(maske, yukseklik, genislik):
    if maske.shape != (yukseklik, genislik):
        import cv2

        maske = cv2.resize(
            maske,
            (genislik, yukseklik),
            interpolation=cv2.INTER_NEAREST,
        )
    return maske > 0.50


def _merkez(mask):
    yler, xler = np.nonzero(mask)
    if len(xler) == 0:
        return None
    return float(xler.mean()), float(yler.mean())


def delikleri_somunlarla_eslestir(somunlar, delikler):
    """Her delik maskesini en uygun tek somunla eşleştirir."""
    for delik in delikler:
        delik_alani = int(np.count_nonzero(delik["maske"]))
        delik_merkezi = _merkez(delik["maske"])
        if delik_alani == 0 or delik_merkezi is None:
            continue

        delik_x, delik_y = delik_merkezi
        adaylar = []
        for somun_index, somun in enumerate(somunlar):
            x1, y1, x2, y2 = somun["kutu"]
            kutu_icinde = x1 <= delik_x <= x2 and y1 <= delik_y <= y2
            kesisim = int(np.count_nonzero(delik["maske"] & somun["maske"]))
            kesisim_orani = kesisim / delik_alani

            kutu_genisligi = max(1.0, x2 - x1)
            kutu_yuksekligi = max(1.0, y2 - y1)
            dx = (delik_x - somun["merkez_x"]) / kutu_genisligi
            dy = (delik_y - somun["merkez_y"]) / kutu_yuksekligi
            normalize_uzaklik = float((dx * dx + dy * dy) ** 0.5)

            if kutu_icinde or kesisim_orani >= 0.50:
                adaylar.append(
                    (
                        not kutu_icinde,
                        -kesisim_orani,
                        normalize_uzaklik,
                        somun_index,
                    )
                )

        if adaylar:
            _, _, _, en_iyi_somun = min(adaylar)
            somunlar[en_iyi_somun]["delik_maskesi"] |= delik["maske"]


def net_somun_alanini_hesapla(
    somun,
    *,
    gorsel_yuksekligi,
    gorsel_genisligi,
):
    """Somun dış alanını, delik alanını ve net alanı döndürür."""
    dis_alani = int(np.count_nonzero(somun["maske"]))

    x1, y1, x2, y2 = somun["kutu"]
    x1 = max(0, min(gorsel_genisligi, int(np.floor(x1))))
    y1 = max(0, min(gorsel_yuksekligi, int(np.floor(y1))))
    x2 = max(0, min(gorsel_genisligi, int(np.ceil(x2))))
    y2 = max(0, min(gorsel_yuksekligi, int(np.ceil(y2))))

    delik_alani = int(
        np.count_nonzero(somun["delik_maskesi"][y1:y2, x1:x2])
    )
    delik_alani = min(delik_alani, dis_alani)
    net_alan = max(0, dis_alani - delik_alani)
    return dis_alani, delik_alani, net_alan
