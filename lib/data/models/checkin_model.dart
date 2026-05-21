import 'package:cloud_firestore/cloud_firestore.dart';

class CheckinModel {
  const CheckinModel({
    this.id,
    required this.userId,
    required this.groupId,
    required this.routineId,
    required this.date,
    required this.memo,
    required this.status,
  });

  final String? id;
  final String userId;
  final String groupId;
  final String routineId;
  final String date;
  final String memo;
  final String status;

  Map<String, dynamic> toCreateMap() {
    return {
      'userId': userId,
      'groupId': groupId,
      'routineId': routineId,
      'date': date,
      'memo': memo,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory CheckinModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return CheckinModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      groupId: data['groupId'] as String? ?? '',
      routineId: data['routineId'] as String? ?? '',
      date: data['date'] as String? ?? '',
      memo: data['memo'] as String? ?? '',
      status: data['status'] as String? ?? '',
    );
  }
}
