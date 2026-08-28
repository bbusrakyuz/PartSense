# BigGAN / Conditional GAN Stabilizasyon Notları

İlk denemede görülen problemler:

- `D_loss=nan`
- `G_loss=nan`
- DataLoader worker çökmesi
- Conditional BatchNorm boyut uyuşmazlığı
- Vida sınıfında tekrarlı ve bozuk örnekler

Uygulanan düzeltmeler:

1. `num_workers=0` kullanıldı.
2. Generator ve discriminator learning rate değerleri düşürüldü.
3. Her optimizasyon adımında gradient clipping uygulandı.
4. Kanal sayıları azaltılarak daha küçük model kullanıldı.
5. Conditional BatchNorm içindeki sınıf embedding boyutları düzeltildi.
6. Giriş görüntüleri normalize edilerek değer aralığı `[-1, 1]` yapıldı.
7. Bozuk veya çok küçük crop'lar eğitimden çıkarıldı.
8. Sınıflar dengelenerek 4.722 örneklik eğitim havuzu oluşturuldu.
9. Kayıplar NaN/Inf kontrolünden geçirildi ve sorunlu batch durumunda eğitim güvenli biçimde durduruldu.

Bu deneysel modelin çıktıları, gerçek test kümesinde YOLO segmentasyon başarısını artırdığı kanıtlanmadan
üretim veri setine eklenmemelidir.
