"""
YOLOv8 segmentasyon etiketlerinden nesne crop'ları üretir.

Bu dosya, PartSense projesinde yapılan crop hazırlama işlemini
yeniden üretilebilir hale getirmek için hazırlanmış referans betiktir.
"""
from pathlib import Path  # Dosya ve klasör yollarını işletim sisteminden bağımsız yönetir.
import argparse  # Komut satırı parametrelerini okumak için kullanılır.
import cv2  # Görüntü okuma, maske ve yeniden boyutlandırma işlemlerini sağlar.
import numpy as np  # Polygon ve maske hesaplamalarında sayısal dizi işlemleri yapar.

SINIF_ADLARI = {0: "somun", 1: "somun_deligi", 2: "vida"}  # YOLO sınıf kimliklerini adlara eşler.

def yolo_polygon_to_pixels(values, width, height):
    """Normalize YOLO polygon koordinatlarını piksel koordinatlarına dönüştürür."""
    points = np.asarray(values, dtype=np.float32).reshape(-1, 2)  # Düz listeyi x-y çiftlerine dönüştürür.
    points[:, 0] *= width  # Normalize x değerlerini görüntü genişliği ile çarpar.
    points[:, 1] *= height  # Normalize y değerlerini görüntü yüksekliği ile çarpar.
    return np.round(points).astype(np.int32)  # Polygon noktalarını tam sayı piksel koordinatlarına çevirir.

def square_crop(image, mask, padding_ratio=0.12, output_size=256):
    """Maskenin çevresini padding ile kırpar, kareleştirir ve beyaz arka plan üretir."""
    ys, xs = np.nonzero(mask)  # Maskedeki nesne piksellerinin koordinatlarını bulur.
    if len(xs) == 0:  # Maskede nesne bulunmuyorsa geçersiz sonuç döndürür.
        return None  # Boş maskeyi atlar.
    x1, x2 = xs.min(), xs.max()  # Nesnenin yatay sınırlarını hesaplar.
    y1, y2 = ys.min(), ys.max()  # Nesnenin dikey sınırlarını hesaplar.
    side = max(x2 - x1 + 1, y2 - y1 + 1)  # Kare crop için en büyük kenarı seçer.
    pad = int(round(side * padding_ratio))  # Nesnenin çevresine eklenecek boşluğu hesaplar.
    cx, cy = (x1 + x2) // 2, (y1 + y2) // 2  # Nesnenin merkez koordinatını hesaplar.
    half = side // 2 + pad  # Kare crop'ın yarı boyutunu belirler.
    xa, xb = max(0, cx - half), min(image.shape[1], cx + half + 1)  # Yatay crop sınırlarını görüntüye sabitler.
    ya, yb = max(0, cy - half), min(image.shape[0], cy + half + 1)  # Dikey crop sınırlarını görüntüye sabitler.
    crop = image[ya:yb, xa:xb]  # Görüntünün ilgili bölgesini kırpar.
    crop_mask = mask[ya:yb, xa:xb]  # Aynı bölgedeki nesne maskesini kırpar.
    if crop.shape[0] < 20 or crop.shape[1] < 20:  # Çok küçük örneklerin kaliteyi bozmasını engeller.
        return None  # Küçük veya geçersiz crop'ı atlar.
    white = np.full_like(crop, 255)  # Crop boyutunda tamamen beyaz arka plan oluşturur.
    white[crop_mask > 0] = crop[crop_mask > 0]  # Yalnız nesne piksellerini beyaz arka plana taşır.
    h, w = white.shape[:2]  # Crop yüksekliği ve genişliğini okur.
    canvas_side = max(h, w)  # Kare tuval boyutunu belirler.
    canvas = np.full((canvas_side, canvas_side, 3), 255, dtype=np.uint8)  # Kare beyaz tuval oluşturur.
    oy, ox = (canvas_side - h) // 2, (canvas_side - w) // 2  # Crop'ı merkeze yerleştirmek için offset hesaplar.
    canvas[oy:oy+h, ox:ox+w] = white  # Crop'ı kare tuvalin merkezine yerleştirir.
    return cv2.resize(canvas, (output_size, output_size), interpolation=cv2.INTER_AREA)  # Çıktıyı hedef çözünürlüğe getirir.

def process_split(dataset_root, split, output_root, output_size):
    """Bir YOLO split'indeki tüm görüntü ve polygon etiketlerini işler."""
    image_dir = dataset_root / split / "images"  # Split görüntü klasörünü belirler.
    label_dir = dataset_root / split / "labels"  # Split etiket klasörünü belirler.
    counters = {name: 0 for name in SINIF_ADLARI.values()}  # Her sınıf için çıktı sayacını başlatır.
    skipped = 0  # Atlanan geçersiz örnek sayısını tutar.
    for label_path in sorted(label_dir.glob("*.txt")):  # Tüm YOLO etiket dosyalarını sırayla gezer.
        candidates = list(image_dir.glob(label_path.stem + ".*"))  # Etikete karşılık gelen görüntüyü arar.
        if not candidates:  # Görüntü bulunamazsa bu etiketi atlar.
            skipped += 1  # Atlanan dosya sayısını artırır.
            continue  # Sonraki etikete geçer.
        image = cv2.imread(str(candidates[0]))  # Görüntüyü BGR biçiminde yükler.
        if image is None:  # Görüntü okunamazsa işlemi atlar.
            skipped += 1  # Hata sayacını artırır.
            continue  # Sonraki dosyaya geçer.
        height, width = image.shape[:2]  # Görüntünün piksel boyutlarını alır.
        for object_index, line in enumerate(label_path.read_text().splitlines()):  # Her nesne etiketini okur.
            parts = line.split()  # Etiket satırını boşluklardan ayırır.
            if len(parts) < 7:  # Polygon için yeterli koordinat yoksa geçersiz kabul eder.
                skipped += 1  # Atlanan nesne sayısını artırır.
                continue  # Sonraki nesneye geçer.
            class_id = int(parts[0])  # İlk değerden sınıf kimliğini okur.
            class_name = SINIF_ADLARI.get(class_id)  # Sınıf kimliğini okunabilir ada dönüştürür.
            if class_name is None:  # Bilinmeyen sınıfları işlem dışı bırakır.
                skipped += 1  # Atlanan nesne sayısını artırır.
                continue  # Sonraki nesneye geçer.
            polygon = yolo_polygon_to_pixels(parts[1:], width, height)  # Normalize polygonu piksele çevirir.
            mask = np.zeros((height, width), dtype=np.uint8)  # Görüntü boyutunda boş maske oluşturur.
            cv2.fillPoly(mask, [polygon], 255)  # Polygonun içini beyaz doldurarak nesne maskesi üretir.
            crop = square_crop(image, mask, output_size=output_size)  # Maskeli kare crop üretir.
            if crop is None:  # Crop üretilemediyse nesneyi atlar.
                skipped += 1  # Atlanan nesne sayısını artırır.
                continue  # Sonraki nesneye geçer.
            target_dir = output_root / class_name  # Sınıfa özel çıktı klasörünü belirler.
            target_dir.mkdir(parents=True, exist_ok=True)  # Çıktı klasörünü gerekirse oluşturur.
            counters[class_name] += 1  # Sınıf sayacını artırır.
            out_name = f"{split}_{label_path.stem}_{object_index:03d}.png"  # Benzersiz çıktı dosya adı üretir.
            cv2.imwrite(str(target_dir / out_name), crop)  # Crop görüntüsünü PNG olarak kaydeder.
    return counters, skipped  # Üretilen ve atlanan örnek sayılarını döndürür.

def main():
    """Komut satırı girişlerini okur ve tüm split'leri işler."""
    parser = argparse.ArgumentParser()  # Parametre okuyucuyu oluşturur.
    parser.add_argument("--dataset", type=Path, required=True)  # YOLO veri seti kökünü zorunlu parametre yapar.
    parser.add_argument("--output", type=Path, required=True)  # Crop çıktı klasörünü zorunlu parametre yapar.
    parser.add_argument("--size", type=int, default=256)  # Varsayılan çıktı boyutunu 256x256 olarak belirler.
    args = parser.parse_args()  # Komut satırı parametrelerini ayrıştırır.
    totals = {name: 0 for name in SINIF_ADLARI.values()}  # Tüm split'ler için toplam sayaçları başlatır.
    skipped_total = 0  # Toplam atlanan örnek sayısını başlatır.
    for split in ("train", "valid", "test"):  # Veri setindeki üç standard split'i sırayla işler.
        counters, skipped = process_split(args.dataset, split, args.output, args.size)  # Split crop'larını üretir.
        for name, count in counters.items():  # Split sonuçlarını toplam sayaca ekler.
            totals[name] += count  # İlgili sınıfın toplamını artırır.
        skipped_total += skipped  # Atlanan örnekleri toplar.
    print("Üretilen crop sayıları:", totals)  # Sonuç sayılarını terminale yazar.
    print("Atlanan örnek:", skipped_total)  # Atlanan örnek sayısını terminale yazar.

if __name__ == "__main__":  # Dosya doğrudan çalıştırıldığında ana fonksiyonu çağırır.
    main()  # Crop üretim sürecini başlatır.
