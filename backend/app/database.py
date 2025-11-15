# backend/app/database.py
import sqlite3
from fastapi import HTTPException

class Database:
    def __init__(self, db_path="nilai.db"):
        # Koneksi ke database
        self.conn = sqlite3.connect(db_path, check_same_thread=False)
        self.cursor = self.conn.cursor()

        # 🔧 Optimasi performa untuk proses besar
        self.cursor.execute("PRAGMA journal_mode = WAL;")
        self.cursor.execute("PRAGMA synchronous = OFF;")
        self.cursor.execute("PRAGMA cache_size = 10000;")
        self.cursor.execute("PRAGMA temp_store = MEMORY;")
        self.cursor.execute("PRAGMA locking_mode = NORMAL;")

        self.create_tables()

    def create_tables(self):
        # === Tabel Mahasiswa ===
        self.cursor.execute("""
        CREATE TABLE IF NOT EXISTS mahasiswa (
            nim TEXT PRIMARY KEY,
            nama TEXT,
            email TEXT,
            department TEXT,
            password TEXT
        )
        """)

        # === Tabel Nilai ===
        self.cursor.execute("""
        CREATE TABLE IF NOT EXISTS nilai (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nim TEXT,
            matkul TEXT,
            nilai REAL,
            FOREIGN KEY (nim) REFERENCES mahasiswa (nim)
        )
        """)

        # === Tabel Performa Mahasiswa ===
        self.cursor.execute("""
        CREATE TABLE IF NOT EXISTS performa_mahasiswa (
            nim TEXT PRIMARY KEY,
            attendance REAL,
            midterm_score REAL,
            final_score REAL,
            assignments_avg REAL,
            quizzes_avg REAL,
            participation_score REAL,
            projects_score REAL,
            study_hours_per_week REAL,
            stress_level INTEGER,
            sleep_hours_per_night REAL,
            total_score REAL,
            grade TEXT,
            FOREIGN KEY (nim) REFERENCES mahasiswa (nim)
        )
        """)
        self.conn.commit()

    # =======================================================
    # 💡 ========== CRUD MAHASISWA ==========
    # =======================================================

    def add_mahasiswa(self, nim, nama, email, department, password):
        try:
            self.cursor.execute(
                "INSERT INTO mahasiswa (nim, nama, email, department, password) VALUES (?, ?, ?, ?, ?)",
                (nim, nama, email, department, password)
            )
            self.conn.commit()
            return {"message": "Mahasiswa berhasil didaftarkan"}
        except sqlite3.IntegrityError:
            raise HTTPException(status_code=400, detail="NIM sudah terdaftar")

    def bulk_insert_mahasiswa(self, mahasiswa_list):
        """
        ✅ Insert banyak mahasiswa sekaligus (lebih cepat dari looping biasa)
        mahasiswa_list: [(nim, nama, email, department, password), ...]
        """
        print(f"🚀 Memulai import {len(mahasiswa_list)} mahasiswa...")
        self.cursor.executemany(
            "INSERT OR IGNORE INTO mahasiswa (nim, nama, email, department, password) VALUES (?, ?, ?, ?, ?)",
            mahasiswa_list
        )
        self.conn.commit()
        print("✅ Import mahasiswa selesai!")

    def get_all_mahasiswa(self):
        self.cursor.execute("SELECT nim, nama, email, department FROM mahasiswa")
        results = self.cursor.fetchall()
        columns = [desc[0] for desc in self.cursor.description]
        return [dict(zip(columns, result)) for result in results]

    def verify_login(self, nim, password):
        self.cursor.execute("SELECT * FROM mahasiswa WHERE nim = ? AND password = ?", (nim, password))
        result = self.cursor.fetchone()
        if result:
            columns = [desc[0] for desc in self.cursor.description]
            return dict(zip(columns, result))
        return None

    def get_mahasiswa(self, nim):
        self.cursor.execute("SELECT * FROM mahasiswa WHERE nim = ?", (nim,))
        result = self.cursor.fetchone()
        if result:
            columns = [desc[0] for desc in self.cursor.description]
            return dict(zip(columns, result))
        return None

    # =======================================================
    # 💡 ========== CRUD NILAI ==========
    # =======================================================
    def add_nilai(self, nim, matkul, nilai):
        self.cursor.execute(
            "INSERT INTO nilai (nim, matkul, nilai) VALUES (?, ?, ?)",
            (nim, matkul, nilai)
        )
        self.conn.commit()
        return {"message": "Nilai berhasil disimpan"}

    def get_nilai(self, nim):
        self.cursor.execute("SELECT * FROM nilai WHERE nim = ?", (nim,))
        results = self.cursor.fetchall()
        columns = [desc[0] for desc in self.cursor.description]
        return [dict(zip(columns, result)) for result in results]

    # =======================================================
    # 💡 ========== CRUD PERFORMA ==========
    # =======================================================
    def add_performa(self, nim, performa_data):
        self.cursor.execute("""
            INSERT OR REPLACE INTO performa_mahasiswa 
            (nim, attendance, midterm_score, final_score, assignments_avg, quizzes_avg, 
             participation_score, projects_score, study_hours_per_week, stress_level,
             sleep_hours_per_night, total_score, grade)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                nim, performa_data['attendance'], performa_data['midterm_score'],
                performa_data['final_score'], performa_data['assignments_avg'],
                performa_data['quizzes_avg'], performa_data['participation_score'],
                performa_data['projects_score'], performa_data['study_hours_per_week'],
                performa_data['stress_level'], performa_data['sleep_hours_per_night'],
                performa_data['total_score'], performa_data['grade']
            ))
        self.conn.commit()
        return {"message": "Data performa berhasil disimpan"}

    def bulk_insert_performa(self, performa_list):
        """
        ✅ Bulk insert performa mahasiswa (super cepat)
        performa_list: [(nim, attendance, midterm, final, ..., grade), ...]
        """
        print(f"📊 Memasukkan {len(performa_list)} data performa mahasiswa...")
        self.cursor.executemany("""
            INSERT OR REPLACE INTO performa_mahasiswa 
            (nim, attendance, midterm_score, final_score, assignments_avg, quizzes_avg,
             participation_score, projects_score, study_hours_per_week, stress_level,
             sleep_hours_per_night, total_score, grade)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, performa_list)
        self.conn.commit()
        print("✅ Import performa selesai!")

    def get_performa(self, nim):
        self.cursor.execute("SELECT * FROM performa_mahasiswa WHERE nim = ?", (nim,))
        result = self.cursor.fetchone()
        if result:
            columns = [desc[0] for desc in self.cursor.description]
            return dict(zip(columns, result))
        return None

    def get_all_performa(self):
        cur = self.conn.cursor()
        cur.execute("SELECT * FROM performa_mahasiswa")
        cols = [c[0] for c in cur.description]
        rows = cur.fetchall()
        return [dict(zip(cols, r)) for r in rows]
