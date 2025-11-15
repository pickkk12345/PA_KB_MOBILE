class Mahasiswa {
  final String nim;
  final String nama;
  final String department;

  Mahasiswa({required this.nim, required this.nama, required this.department});

  factory Mahasiswa.fromJson(Map<String, dynamic> json) {
    return Mahasiswa(
      nim: json['nim'],
      nama: json['nama'],
      department: json['department'],
    );
  }
}
