import '../models/checkin_model.dart';

String _formatYmd(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

int computeCurrentStreak(List<CheckinModel> checkins, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);

  final completed = checkins
      .where((c) => c.status == 'completed')
      .map((c) => c.date)
      .toSet();

  if (completed.isEmpty) return 0;

  DateTime cursor;
  if (completed.contains(_formatYmd(today))) {
    cursor = today;
  } else {
    final yesterday = today.subtract(const Duration(days: 1));
    if (completed.contains(_formatYmd(yesterday))) {
      cursor = yesterday;
    } else {
      return 0;
    }
  }

  int streak = 0;
  while (completed.contains(_formatYmd(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}
