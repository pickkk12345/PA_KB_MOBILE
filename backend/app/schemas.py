# backend/app/schemas.py
from pydantic import BaseModel

class LoginData(BaseModel):
    nim: str
    password: str

class MahasiswaData(BaseModel):
    nim: str
    nama: str
    email: str
    department: str
    password: str

class NilaiData(BaseModel):
    nim: str
    matkul: str
    nilai: float

class PerformaData(BaseModel):
    attendance: float
    midterm_score: float
    final_score: float
    assignments_avg: float
    quizzes_avg: float
    participation_score: float
    projects_score: float
    study_hours_per_week: float
    stress_level: int
    sleep_hours_per_night: float