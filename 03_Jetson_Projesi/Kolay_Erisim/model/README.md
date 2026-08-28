# Model Dosyası

Bu klasör, PartSense projesinde kullanılan eğitilmiş YOLO segmentasyon modelinin saklanması için ayrılmıştır.

## Model Dosyası

Uygulamanın çalışabilmesi için eğitilmiş model dosyasının aşağıdaki isimle bu klasöre yerleştirilmesi gerekir:

```text
best.pt
```

Beklenen dosya yolu:

```text
03_Jetson_Projesi/Kolay_Erisim/model/best.pt
```

## Modelin Depoda Bulunmama Nedeni

Eğitilmiş model dosyası, yüksek dosya boyutu ve depo yönetimini kolaylaştırmak amacıyla GitHub kaynak kod deposuna dahil edilmemiştir.

Model dosyası:

* Proje sorumlusundan temin edilebilir.
* GitHub Releases bölümünden indirilebilir.
* Eğitim işlemi tekrar çalıştırılarak üretilebilir.

## Modeli Yerleştirme

İndirilen veya eğitilen `best.pt` dosyasını bu klasörün içerisine kopyalayın:

```bash
cp /modelin/bulundugu/dizin/best.pt \
03_Jetson_Projesi/Kolay_Erisim/model/best.pt
```

Windows için:

```powershell
Copy-Item "C:\model\best.pt" `
"03_Jetson_Projesi\Kolay_Erisim\model\best.pt"
```

## Dosya Kontrolü

Uygulama çalıştırılmadan önce aşağıdaki yapının mevcut olduğundan emin olun:

```text
model/
├── README.md
└── best.pt
```

Model dosyası bulunmadığında tahmin ve segmentasyon işlemleri çalışmayacaktır.

## Model Bilgileri

Model, vida ve somun parçalarının görüntü üzerinde tespit edilmesi ve segmentasyon maskelerinin oluşturulması amacıyla eğitilmiştir.

Modelin desteklediği sınıflar:

```text
somun
somun_deligi
vida
```

Model dosyasının adı veya konumu değiştirilirse uygulama içerisindeki model yolu da güncellenmelidir.
