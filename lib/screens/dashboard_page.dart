import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'rekomendasi_page.dart';
import 'analysis_page.dart';
import 'profile_page.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const DashboardPage({super.key, required this.userData});

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? performa;
  List<Map<String, dynamic>> rekomendasi = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      // Ambil performa agregat dari backend
      performa = await ApiService.getPerforma(widget.userData['nim']);

      // Ambil rekomendasi (list of object)
      rekomendasi = await ApiService.getRecommendations(widget.userData['nim']);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  double hitungIPK(dynamic totalScore) {
    final score = (totalScore is num) ? totalScore.toDouble() : 0.0;
    return (score / 100) * 4;
  }

  String getGrade(double ipk) {
    if (ipk >= 3.5) return 'A';
    if (ipk >= 3.0) return 'B';
    if (ipk >= 2.5) return 'C';
    if (ipk >= 2.0) return 'D';
    return 'E';
  }

  Color getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return const Color(0xFFFF9800);
      case 'B':
        return const Color(0xFF4CAF50);
      case 'C':
        return const Color(0xFF2196F3);
      default:
        return Colors.grey;
    }
  }

  String getStressLevel(num? stressLevel) {
    final v = (stressLevel ?? 0).toDouble();
    if (v <= 3) return 'Low';
    if (v <= 6) return 'Medium';
    return 'High';
  }

  Color getStressColor(String level) {
    switch (level) {
      case 'Low':
        return const Color(0xFF4CAF50);
      case 'Medium':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFFF44336);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userData;
    const tealColor = Color(0xFF2D7F7B);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: fetchData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Halo, ${user['nama']?.split(' ')[0] ?? 'User'}!',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ),
                            
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Error message jika ada
                        if (errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Gagal memuat data: $errorMessage',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Card Total Skor
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [tealColor, Color(0xFF1E5F5B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: tealColor.withValues(alpha:0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: performa != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Skor Semester Ini',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          (performa!['total_score'] ?? 0).toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: getGradeColor(
                                              getGrade(hitungIPK(performa!['total_score'])),
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            getGrade(hitungIPK(performa!['total_score'])),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Data tidak tersedia',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                        const SizedBox(height: 20),

                        // Grid Statistik (menggunakan field yang sesuai dataset)
                        if (performa != null) ...[
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.1,
                            children: [
                              // Kehadiran
                              _buildStatCard(
                                title: 'Kehadiran',
                                value: '${performa!['attendance'] ?? 0}%',
                                showProgress: true,
                                progressValue: ((performa!['attendance'] ?? 0) as num).toDouble() / 100,
                                progressColor: const Color(0xFF4CAF50),
                              ),
                              // Jam Belajar per Minggu
                              _buildStatCard(
                                title: 'Jam Belajar',
                                value: ((performa!['study_hours_per_week'] ?? 0) as num)
                                    .toDouble()
                                    .toStringAsFixed(1),
                                suffix: 'j/mg',
                              ),
                              // Level Stres (1-10)
                              _buildStatCard(
                                title: 'Level Stres',
                                value:
                                    '${((performa!['stress_level'] ?? 0) as num).toDouble().toStringAsFixed(1)}/10',
                                subtitle: getStressLevel(
                                  (performa!['stress_level'] as num?) ?? 0,
                                ),
                                subtitleColor: getStressColor(
                                  getStressLevel((performa!['stress_level'] as num?) ?? 0),
                                ),
                              ),
                              // Jam Tidur per Malam
                              _buildStatCard(
                                title: 'Jam Tidur',
                                value: ((performa!['sleep_hours_per_night'] ?? 0) as num)
                                    .toDouble()
                                    .toStringAsFixed(1),
                                suffix: 'j/mlm',
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Rekomendasi Section
                        const Text(
                          'Rekomendasi Untukmu',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (rekomendasi.isNotEmpty)
                          ...rekomendasi.take(3).map((r) => _buildRecommendationCard(r))
                        else
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text('Belum ada rekomendasi'),
                            ),
                          ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? suffix,
    String? subtitle,
    Color? subtitleColor,
    bool showProgress = false,
    double progressValue = 0,
    Color progressColor = Colors.green,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 2),
                  child: Text(
                    suffix,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (showProgress)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 6,
              ),
            ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: subtitleColor ?? Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    final nama = recommendation['nama']?.toString() ?? 'Mata Kuliah';
    final kode = recommendation['kode']?.toString() ?? '';
    final sks = recommendation['sks'] ?? 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF2D7F7B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.book_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kode.isNotEmpty)
                  Text(
                    kode,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                Text(
                  nama,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$sks SKS',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4F4DD),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'REKOMENDASI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D7F7B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----- Navigation (tetap di sini) -----
class MainNavigation extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String nim;

  const MainNavigation({
    super.key,
    required this.userData,
    required this.nim,
  });

  // BENAR
    @override
    State<MainNavigation> createState() => _MainNavigationState();

}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Halaman yang diatur oleh nav bar bawah
    final List<Widget> pages = [
      DashboardPage(userData: widget.userData),
      RekomendasiPage(nim: widget.nim),
      AnalysisPage(nim: widget.nim),
      ProfilePage(userData: widget.userData),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: const Color(0xFF02796C), // hijau khas kamu
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Rekomendasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analisis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
