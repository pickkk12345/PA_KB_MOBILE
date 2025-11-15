import pandas as pd
import numpy as np
import os
import pickle
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import matplotlib.pyplot as plt
import seaborn as sns

class RecommendationModel:
    def _init_(self):
        self.df = None
        self.model = None
        self.scaler = StandardScaler()
        self.label_encoders = {}
        self.feature_columns = []
        self.df_processed = None
        self.accuracy = None
        self.report = None

    # === 1️⃣ Data Loading ===
    def load_data(self, csv_path):
        self.df = pd.read_csv(csv_path)
        print(f"✅ Data loaded: {self.df.shape[0]} rows, {self.df.shape[1]} columns")
        return self.df

    # === 2️⃣ Data Preprocessing ===
    def preprocess_data(self):
        df_processed = self.df.copy()

        # Encode kolom kategori
        categorical_cols = ['Gender', 'Department', 'Parent_Education_Level', 'Family_Income_Level']
        for col in categorical_cols:
            le = LabelEncoder()
            df_processed[f'{col}_encoded'] = le.fit_transform(df_processed[col])
            self.label_encoders[col] = le

        # Normalisasi kolom numerik
        numerical_cols = [
            'Age', 'Attendance (%)', 'Midterm_Score', 'Final_Score',
            'Assignments_Avg', 'Quizzes_Avg', 'Participation_Score',
            'Projects_Score', 'Study_Hours_per_Week', 'Stress_Level (1-10)',
            'Sleep_Hours_per_Night'
        ]
        df_processed[numerical_cols] = self.scaler.fit_transform(df_processed[numerical_cols])

        # Simpan kolom fitur
        encoded_cols = [f'{col}_encoded' for col in categorical_cols]
        self.feature_columns = numerical_cols + encoded_cols
        self.df_processed = df_processed

        print(f"🔧 Preprocessing selesai. Total fitur: {len(self.feature_columns)}")
        return df_processed

    # === 3️⃣ Model Training + Evaluation ===
    def train_model(self):
        X = self.df_processed[self.feature_columns]
        y = self.df_processed['Grade']

        # Bagi data train-test
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

        # Model Random Forest
        self.model = RandomForestClassifier(n_estimators=100, random_state=42)
        self.model.fit(X_train, y_train)

        # Evaluasi model
        y_pred = self.model.predict(X_test)
        self.accuracy = accuracy_score(y_test, y_pred)
        self.report = classification_report(y_test, y_pred, output_dict=True)

        print(f"📊 Akurasi Model: {self.accuracy:.2f}")
        print("📄 Classification Report:")
        print(classification_report(y_test, y_pred))

        # Simpan confusion matrix
        cm = confusion_matrix(y_test, y_pred)
        plt.figure(figsize=(6, 5))
        sns.heatmap(cm, annot=True, cmap='Blues', fmt='g')
        plt.title('Confusion Matrix')
        plt.xlabel('Predicted')
        plt.ylabel('Actual')
        os.makedirs('model_files', exist_ok=True)
        plt.savefig('model_files/confusion_matrix.png')
        plt.close()

        # Simpan model, scaler, dan encoder
        with open('model_files/model.pkl', 'wb') as f:
            pickle.dump(self.model, f)
        with open('model_files/scaler.pkl', 'wb') as f:
            pickle.dump(self.scaler, f)
        with open('model_files/encoders.pkl', 'wb') as f:
            pickle.dump(self.label_encoders, f)

        # Simpan laporan hasil evaluasi
        eval_report = {
            "accuracy": float(self.accuracy),
            "report": self.report
        }
        with open('model_files/evaluation.json', 'wb') as f:
            pickle.dump(eval_report, f)

        print("✅ Model dilatih, dievaluasi, dan disimpan.")
        return {"accuracy": self.accuracy, "message": "Model berhasil dilatih dan disimpan"}

    # === 4️⃣ Load Model dari File ===
    def load_saved_model(self):
        if os.path.exists('model_files/model.pkl'):
            with open('model_files/model.pkl', 'rb') as f:
                self.model = pickle.load(f)
            with open('model_files/scaler.pkl', 'rb') as f:
                self.scaler = pickle.load(f)
            with open('model_files/encoders.pkl', 'rb') as f:
                self.label_encoders = pickle.load(f)
            print("✅ Model berhasil dimuat dari file.")
            return True
        print("⚠ Model belum ditemukan, perlu dilatih ulang.")
        return False

    # === 5️⃣ Rekomendasi Berdasarkan Departemen ===
    def recommend_courses(self, nim, department, top_n=5):
        courses_map = {
            'Mathematics': [
                'Kalkulus Lanjutan', 'Aljabar Linear', 'Statistika Matematika', 
                'Metode Numerik', 'Persamaan Diferensial'
            ],
            'Engineering': [
                'Mekanika Teknik', 'Thermodynamika', 'Desain Sistem', 
                'Elektronika Dasar', 'Rangkaian Listrik'
            ],
            'CS': [
                'Struktur Data', 'Algoritma', 'Machine Learning', 
                'Keamanan Jaringan', 'Pemrograman Berorientasi Objek'
            ],
            'Business': [
                'Manajemen Strategis', 'Analisis Bisnis', 'Kewirausahaan', 
                'Pemasaran Digital', 'Akuntansi Manajerial'
            ]
        }
        rekomendasi = courses_map.get(department, ["Mata Kuliah Umum 1", "Mata Kuliah Umum 2"])[:top_n]
        return rekomendasi