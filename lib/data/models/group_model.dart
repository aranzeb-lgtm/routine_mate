import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  const GroupModel({
    required this.id,
    required this.groupName,
    required this.description,
    required this.routineType,
    required this.routineTime,
    required this.maxMembers,
    required this.memberIds,
    required this.todayCompletedCount,
    required this.isActive,
  });

  final String id;
  final String groupName;
  final String description;
  final String routineType;
  final String routineTime;
  final int maxMembers;
  final List<String> memberIds;
  final int todayCompletedCount;
  final bool isActive;

  int get memberCount => memberIds.length;

  factory GroupModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return GroupModel(
      id: doc.id,
      groupName: data['groupName'] as String? ?? '',
      description: data['description'] as String? ?? '',
      routineType: data['routineType'] as String? ?? '',
      routineTime: data['routineTime'] as String? ?? '',
      maxMembers: (data['maxMembers'] as num?)?.toInt() ?? 0,
      memberIds: (data['memberIds'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      todayCompletedCount:
          (data['todayCompletedCount'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? false,
    );
  }
}
