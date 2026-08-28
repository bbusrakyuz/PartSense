#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/../03_Jetson_Projesi/Kolay_Erisim"
python3 -m venv venv_yeni
source venv_yeni/bin/activate
python -m pip install --upgrade pip
python -m pip install -r ../../06_Kurulum_ve_Calistirma/requirements.txt
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
