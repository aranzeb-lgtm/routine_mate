import 'package:cloud_firestore/cloud_firestore.dart';

class RoutineModel {
  const RoutineModel({
    required this.id,
    required this.routineName,
    required this.routineType,
    required this.durationMinutes,
    required this.description,
    required this.difficulty,
  });

  final String id;
  final String routineName;
  final String routineType;
  final int durationMinutes;
  final String description;
  final String difficulty;

  factory RoutineModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return RoutineModel(
      id: doc.id,
      routineName: data['routineName'] as String? ?? '',
      routineType: data['routineType'] as String? ?? '',
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
      description: data['description'] as String? ?? '',
      difficulty: data['difficulty'] as String? ?? '',
    );
  }
}
