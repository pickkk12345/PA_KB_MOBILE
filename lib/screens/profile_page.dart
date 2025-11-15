import 'package:flutter/material.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProfilePage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final String name = userData["nama"] ?? "User";
    final String nim = userData["nim"] ?? "-";
    final String major = userData["department"] ?? "-";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ================= HEADER PROFIL =================
            CircleAvatar(
              radius: 55,
              backgroundColor: const Color(0xFF2E7D72),
              child: Text(
                name.isNotEmpty ? name.substring(0, 2).toUpperCase() : "US",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text("NIM: $nim"),
            Text(major),

            const SizedBox(height: 30),

            // ================= LIST MENU (SCROLLABLE) =================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  menuTile(
                    context,
                    icon: Icons.person_outline,
                    title: "Informasi Pribadi",
                    page: PersonalInfoPage(
                      name: name,
                      nim: nim,
                      major: major,
                    ),
                  ),
                  const SizedBox(height: 12),
                  menuTile(
                    context,
                    icon: Icons.info_outline,
                    title: "Tentang Aplikasi",
                    page: AboutAppPage(),
                  ),
                ],
              ),
            ),

            // ================= LOGOUT FIXED DI PALING BAWAH =================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 5, 20, 25),
              child: InkWell(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.logout, color: Colors.red, size: 26),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "Keluar",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.red),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================== MENU TILE ==========================
  Widget menuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget page,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.teal, size: 26),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

//
// ======================== INFORMASI PRIBADI ========================
//
class PersonalInfoPage extends StatelessWidget {
  final String name;
  final String nim;
  final String major;

  const PersonalInfoPage({
    super.key,
    required this.name,
    required this.nim,
    required this.major,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Informasi Pribadi")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            infoRow("Nama", name),
            infoRow("NIM", nim),
            infoRow("Jurusan", major),
          ],
        ),
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }
}

//
// ======================== TENTANG APLIKASI ========================
//
class AboutAppPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const String aboutText = """
Aplikasi ini dibuat sebagai solusi untuk membantu mahasiswa dalam mengakses, mengelola, dan memahami data akademik secara cepat dan efisien. Dengan tampilan antarmuka yang sederhana serta navigasi yang intuitif, aplikasi ini diharapkan mampu memberikan pengalaman yang lebih nyaman dalam penggunaan sehari-hari.

Proses pengembangan aplikasi ini merupakan hasil kerja sama antara mahasiswa yang memiliki minat kuat di bidang teknologi informasi, desain antarmuka, serta pengembangan perangkat lunak. Setiap fitur yang disediakan merupakan bentuk implementasi dari konsep perkuliahan yang diterapkan secara langsung dalam proyek nyata.

Tim pengembang aplikasi:
- Muhammad Azmy Hafidh (NIM 2309106118)
- Muhammad Akhyat Tariq Razan (NIM 2309106119)
- Taufiqurrahman Al Baihaqi (NIM 2309106114)

Aplikasi ini menjadi bukti nyata kolaborasi, kreativitas, dan upaya untuk menghadirkan solusi digital yang bermanfaat bagi mahasiswa.
""";

    return Scaffold(
      appBar: AppBar(title: const Text("Tentang Aplikasi")),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          aboutText,
          style: TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}