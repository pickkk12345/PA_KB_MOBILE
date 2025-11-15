class Rekomendasi {
  final String namaMataKuliah;

  Rekomendasi({required this.namaMataKuliah});

  factory Rekomendasi.fromJson(Map<String, dynamic> json) {
    return Rekomendasi(namaMataKuliah: json['nama_mata_kuliah']);
  }
}
