import os
import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from .database import Database
from .model import RecommendationModel
from .schemas import LoginData, NilaiData, PerformaData

app = FastAPI(title="API Rekomendasi Matkul")

# --- CORS (izinkan Flutter & ngrok mengakses) ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Inisialisasi Database & Model ---
db = Database()
model = RecommendationModel()

# --- Tentukan path CSV ---
base_dir = os.path.dirname(os.path.abspath(__file__))
csv_path = os.path.normpath(os.path.join(base_dir, '..', 'data', 'Students Performance Dataset.csv'))
print(f"📁 Path CSV dataset: {csv_path}")

# --- Load / Train Model ---
if not model.load_saved_model():
    print("⚙️ Model tidak ditemukan. Melatih model baru...")
    model.load_data(csv_path)
    model.preprocess_data()
    model.train_model()
else:
    print("✅ Model berhasil dimuat.")
    model.load_data(csv_path)
    model.preprocess_data()

# --- Import Data Mahasiswa & Performa dari CSV ---
try:
    csv_data = pd.read_csv(csv_path)
    print("🔄 Mengimpor data mahasiswa dan performa dari CSV...")

    for _, row in csv_data.iterrows():
        nim = str(row["Student_ID"]).strip()
        nama = f"{row['First_Name']} {row['Last_Name']}"
        email = str(row["Email"]).strip()
        department = str(row["Department"]).strip()
        password = "12345"  # default password, hanya untuk login

        # Tambahkan ke tabel mahasiswa jika belum ada
        try:
            db.add_mahasiswa(nim, nama, email, department, password)
        except Exception:
            pass  # abaikan jika sudah ada

        # Tambahkan data performa ke tabel performa_mahasiswa
        performa_data = {
            "attendance": float(row["Attendance (%)"]),
            "midterm_score": float(row["Midterm_Score"]),
            "final_score": float(row["Final_Score"]),
            "assignments_avg": float(row["Assignments_Avg"]),
            "quizzes_avg": float(row["Quizzes_Avg"]),
            "participation_score": float(row["Participation_Score"]),
            "projects_score": float(row["Projects_Score"]),
            "study_hours_per_week": float(row["Study_Hours_per_Week"]),
            "stress_level": int(row["Stress_Level (1-10)"]),
            "sleep_hours_per_night": float(row["Sleep_Hours_per_Night"]),
            "total_score": float(row["Total_Score"]),
            "grade": str(row["Grade"]),
        }
        db.add_performa(nim, performa_data)

    print("✅ Import CSV selesai! Semua mahasiswa & performa tersimpan.")
except Exception as e:
    print(f"⚠️ Gagal mengimpor CSV: {e}")

# --- ROUTES API --- #

@app.get("/")
def read_root():
    return {"message": "API Rekomendasi Mata Kuliah berjalan!"}


@app.post("/login")
def login(data: LoginData):
    user = db.verify_login(data.nim, data.password)
    if user:
        user.pop('password', None)
        return {"status": "success", "data": user}
    raise HTTPException(status_code=401, detail="NIM atau Password salah")


@app.get("/mahasiswa/{nim}")
def get_mahasiswa_by_nim(nim: str):
    mahasiswa = db.get_mahasiswa(nim)
    if not mahasiswa:
        raise HTTPException(status_code=404, detail="Mahasiswa tidak ditemukan")
    mahasiswa.pop('password', None)
    return mahasiswa


@app.get("/nilai/{nim}")
def get_nilai(nim: str):
    # Nilai per-matkul (jika tabel nilai diisi). Untuk metrik agregat gunakan /performa/{nim}
    return db.get_nilai(nim)


# ✅ BARU: expose metrik agregat performa dari tabel performa_mahasiswa
@app.get("/performa/{nim}")
def get_performa_by_nim(nim: str):
    data = db.get_performa(nim)
    if not data:
        raise HTTPException(status_code=404, detail="Performa tidak ditemukan")
    return data


# ♻️ Standarisasi output rekomendasi ke list of object (bukan list string)
@app.get("/recommend/{nim}")
def get_recommendations(nim: str):
    mhs = db.get_mahasiswa(nim)
    if not mhs:
        raise HTTPException(status_code=404, detail="Mahasiswa tidak ditemukan")

    items = model.recommend_courses(nim, mhs['department'])
    # pastikan items menjadi list of dict
    rekom = []
    for x in items:
        if isinstance(x, str):
            rekom.append({"kode": "", "nama": x, "sks": 3, "sumber": "model"})
        elif isinstance(x, dict):
            # normalisasi minimal kunci
            rekom.append({
                "kode": x.get("kode", ""),
                "nama": x.get("nama", x.get("title", "")),
                "sks": x.get("sks", 3),
                "sumber": x.get("sumber", "model"),
                "dosen": x.get("dosen", ""),
                "alasan": x.get("alasan", ""),
            })
    return {
        "nim": nim,
        "nama": mhs["nama"],
        "department": mhs["department"],
        "rekomendasi": rekom,
    }


# ⚠️ Perbaiki atau nonaktifkan: db.get_all_performa() belum ada
@app.get("/sleep_performance")
def get_sleep_performance():
    try:
        data = db.get_all_performa()  # implement di Database, lihat catatan di bawah
        sleep_perf = [
            {
                "sleep_hours": float(p['sleep_hours_per_night']),
                "total_score": float(p['total_score'])
            } for p in data
        ]
        return sleep_perf
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
