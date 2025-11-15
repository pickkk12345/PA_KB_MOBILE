class Nilai {
  final double attendance;
  final double assignmentsAvg;
  final double quizzesAvg;
  final double projectsScore;
  final double participationScore;
  final double totalScore;

  Nilai({
    required this.attendance,
    required this.assignmentsAvg,
    required this.quizzesAvg,
    required this.projectsScore,
    required this.participationScore,
    required this.totalScore,
  });

  factory Nilai.fromJson(Map<String, dynamic> json) {
    return Nilai(
      attendance: json['attendance'].toDouble(),
      assignmentsAvg: json['assignments_avg'].toDouble(),
      quizzesAvg: json['quizzes_avg'].toDouble(),
      projectsScore: json['projects_score'].toDouble(),
      participationScore: json['participation_score'].toDouble(),
      totalScore: json['total_score'].toDouble(),
    );
  }
}
