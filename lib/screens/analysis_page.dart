import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class AnalysisPage extends StatefulWidget {
  final String nim;
  const AnalysisPage({super.key, required this.nim});

  @override
  AnalysisPageState createState() => AnalysisPageState();
}

class AnalysisPageState extends State<AnalysisPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? performa;
  bool loading = true;
  String? error;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _fetchPerforma();
  }

  Future<void> _fetchPerforma() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await ApiService.getPerforma(widget.nim);
      if (!mounted) return;
      setState(() => performa = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  double _num(dynamic v) => (v is num) ? v.toDouble() : 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisis Performa Anda'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tab,
          labelColor: const Color(0xFF2D7F7B),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2D7F7B),
          tabs: const [
            Tab(text: 'Akademik'),
            Tab(text: 'Gaya Hidup'),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : (performa == null)
              ? Center(child: Text(error ?? 'Data performa tidak tersedia'))
              : RefreshIndicator(
                  onRefresh: _fetchPerforma,
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _academicTab(context),
                      _lifestyleTab(context),
                    ],
                  ),
                ),
    );
  }

  // ====================== AKADEMIK ==========================
  Widget _academicTab(BuildContext context) {
    final midterm = _num(performa?['midterm_score']);
    final finalScore = _num(performa?['final_score']);
    final assignments = _num(performa?['assignments_avg']);
    final quizzes = _num(performa?['quizzes_avg']);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCard(
          title: 'Perbandingan Skor Akademik',
          child: Column(
            children: [
              SizedBox(
                height: 220,
                child: _lineChart(midterm, finalScore, assignments, quizzes),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _miniStat('Midterm', midterm),
                  _miniStat('Final', finalScore),
                  _miniStat('Assignments', assignments),
                  _miniStat('Quizzes', quizzes),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildInsight(assignments, quizzes),
      ],
    );
  }

  LineChart _lineChart(
    double midterm,
    double finalScore,
    double assignments,
    double quizzes,
  ) {
    final spots = [
      FlSpot(0, midterm),
      FlSpot(1, finalScore),
      FlSpot(2, assignments),
      FlSpot(3, quizzes),
    ];
    const labels = ['Midterm', 'Final', 'Assignments', 'Quizzes'];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 3,
        minY: 0,
        maxY: 100,
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, _) =>
                  Padding(padding: const EdgeInsets.only(top: 6), child: Text(labels[v.toInt()])),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: const Color(0xFF2D7F7B),
            barWidth: 3,
            spots: spots,
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, double value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value.toStringAsFixed(0),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D7F7B),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  Widget _buildInsight(double assignments, double quizzes) {
    String insight;
    if (assignments > quizzes) {
      insight =
          'Skor tugas Anda rata-rata ${(assignments - quizzes).toStringAsFixed(1)} lebih tinggi dari kuis. '
          'Anda unggul dalam pengerjaan jangka panjang. Perbanyak latihan untuk kuis agar lebih seimbang.';
    } else {
      insight =
          'Nilai kuis Anda lebih tinggi dari tugas. Ini menunjukkan pemahaman cepat, tapi perlu latihan dalam tugas yang lebih lama.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFFFF9800)),
          const SizedBox(width: 10),
          Expanded(child: Text(insight)),
        ],
      ),
    );
  }

  // ====================== GAYA HIDUP ==========================
  Widget _lifestyleTab(BuildContext context) {
    final sleepHours = _num(performa?['sleep_hours_per_night']);
    final totalScore = _num(performa?['total_score']);
    final stress = _num(performa?['stress_level']);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCard(
          title: 'Korelasi Jam Tidur & Performa',
          child: SizedBox(height: 220, child: _scatterPlot(sleepHours, totalScore)),
        ),
        const SizedBox(height: 16),
        _buildAdvice(sleepHours),
        const SizedBox(height: 16),
        _buildStressBar(stress),
      ],
    );
  }

  ScatterChart _scatterPlot(double sleepHours, double totalScore) {
    final double sx = sleepHours.clamp(0, 10).toDouble();
    final double sy = totalScore.clamp(0, 100).toDouble();

    return ScatterChart(
      ScatterChartData(
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 100,
        gridData: FlGridData(show: true),
        scatterSpots: [
          ScatterSpot(
            sx,
            sy,
            show: true,
            dotPainter: FlDotCirclePainter(
              radius: 6,
              color: const Color(0xFF2D7F7B),
              strokeColor: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvice(double sleepHours) {
    String msg;
    if (sleepHours < 6) {
      msg =
          'Rata-rata tidur Anda ${sleepHours.toStringAsFixed(1)} jam. Coba tingkatkan menjadi 7–8 jam untuk peningkatan fokus.';
    } else {
      msg = 'Jam tidur Anda sudah cukup baik (${sleepHours.toStringAsFixed(1)} jam). Pertahankan!';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('😊 ', style: TextStyle(fontSize: 18)),
          Expanded(child: Text(msg)),
        ],
      ),
    );
  }

  Widget _buildStressBar(double stress) {
    String label = (stress <= 3)
        ? 'Rendah'
        : (stress <= 6)
            ? 'Sedang'
            : 'Tinggi';
    Color color = (stress <= 3)
        ? const Color(0xFF4CAF50)
        : (stress <= 6)
            ? const Color(0xFFFF9800)
            : const Color(0xFFF44336);

    return _buildCard(
      title: 'Stress Level',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${stress.toStringAsFixed(0)}/10 ($label)'),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (stress / 10).clamp(0, 1),
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }
}