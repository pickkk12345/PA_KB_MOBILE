import 'package:flutter/material.dart';

import '../services/api_service.dart';

class RekomendasiPage extends StatefulWidget {
  final String nim;
  const RekomendasiPage({super.key, required this.nim});

  @override
  RekomendasiPageState createState() => RekomendasiPageState();
}

class RekomendasiPageState extends State<RekomendasiPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> rekomendasi = [];
  bool loading = true;
  String? error;

  TabController? _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeTabController();
    fetchRekomendasi();
  }

  void _initializeTabController() {
    _tabController = TabController(length: 3, vsync: this);
    _tabController?.addListener(() {
      if (_tabController?.indexIsChanging == false) {
        setState(() {
          _selectedTabIndex = _tabController?.index ?? 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> fetchRekomendasi() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await ApiService.getRecommendations(widget.nim);
      setState(() {
        rekomendasi = data; // langsung dari API (tanpa dummy)
      });
    } catch (e) {
      error = e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat rekomendasi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Rekomendasi Mata Kuliah'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchRekomendasi,
            tooltip: 'Muat ulang',
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header dengan Background Putih
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rekomendasi Mata\nKuliah',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total: ${rekomendasi.length} matkul',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Tab Pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTabPill('Semua', 0),
                            const SizedBox(width: 12),
                            _buildTabPill('Peminatan', 1),
                            const SizedBox(width: 12),
                            _buildTabPill('Beban Ringan', 2),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCourseList(_getFilteredCourses(0)),
                      _buildCourseList(_getFilteredCourses(1)),
                      _buildCourseList(_getFilteredCourses(2)),
                    ],
                  ),
                ),

                if (error != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Catatan: $error',
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildTabPill(String text, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        _tabController?.animateTo(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D7F7B) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFF2D7F7B) : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredCourses(int tabIndex) {
    if (tabIndex == 0) return rekomendasi;

    if (tabIndex == 1) {
      // Peminatan: heuristik sederhana berbasis nama matkul
      final keywords = ['ai', 'machine', 'data', 'vision', 'nlp', 'deep', 'cloud'];
      return rekomendasi.where((c) {
        final name = (c['nama'] ?? '').toString().toLowerCase();
        return keywords.any((k) => name.contains(k));
      }).toList();
    }

    if (tabIndex == 2) {
      // Beban ringan: sks <= 2 (fallback ke 3 jika tidak ada field)
      return rekomendasi.where((c) {
        final sks = (c['sks'] ?? 3);
        if (sks is num) return sks <= 2;
        return false;
      }).toList();
    }

    return rekomendasi;
  }

  Widget _buildCourseList(List<Map<String, dynamic>> courses) {
    if (courses.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada rekomendasi untuk kategori ini',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchRekomendasi,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final c = courses[index];
          final kode = c['kode']?.toString() ?? '';
          final nama = c['nama']?.toString() ?? 'Mata Kuliah';
          final sks = (c['sks'] ?? 3).toString();
          final sumber = c['sumber']?.toString(); // bisa null
          final dosen = c['dosen']?.toString();   // bisa null
          final alasan = c['alasan']?.toString(); // bisa null

          final badgeText = (sumber ?? 'rekomendasi').toUpperCase();

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${kode.isNotEmpty ? '$kode - ' : ''}$nama',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2D7F7B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Badge & dosen (opsional)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4F4DD),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$sks SKS',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D7F7B),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F7F1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D7F7B),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (dosen != null && dosen.isNotEmpty)
                        Expanded(
                          child: Text(
                            dosen,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Alasan (opsional, fallback ramah)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF2D7F7B).withValues(alpha:0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          size: 18,
                          color: Color(0xFF2D7F7B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            alasan ??
                                (sumber != null
                                    ? 'Direkomendasikan berdasarkan $sumber.'
                                    : 'Direkomendasikan untuk meningkatkan capaian studi.'),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
