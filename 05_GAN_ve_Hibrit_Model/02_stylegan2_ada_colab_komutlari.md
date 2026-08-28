# StyleGAN2-ADA Colab / Linux Komutları

```bash
# Depoyu indir
git clone https://github.com/NVlabs/stylegan2-ada-pytorch.git
cd stylegan2-ada-pytorch

# Crop klasörünü StyleGAN veri setine dönüştür
python dataset_tool.py   --source=/content/vida_crops_256   --dest=/content/vida_stylegan_256.zip   --resolution=256x256

# Eğitimi başlat
python train.py   --outdir=/content/drive/MyDrive/partsense_stylegan_runs   --data=/content/vida_stylegan_256.zip   --gpus=1   --batch=8   --mirror=1   --cfg=auto   --snap=5
```

Not: Tesla T4 ortamında CUDA/PyTorch uyumluluğu kontrol edilmelidir. Eğitim çıktıları `network-snapshot-*.pkl`
dosyalarıdır. En son snapshot otomatik olarak en iyi model anlamına gelmez; gridler, çeşitlilik ve veri kopyalama
riski birlikte incelenmelidir.
