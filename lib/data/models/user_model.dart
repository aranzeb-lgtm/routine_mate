import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.uid,
    required this.nickname,
    required this.email,
    required this.routineTime,
    required this.streakCount,
    required this.joinedGroupIds,
  });

  final String id;
  final String uid;
  final String nickname;
  final String email;
  final String routineTime;
  final int streakCount;
  final List<String> joinedGroupIds;

  factory UserModel.unknown(String id) {
    return UserModel(
      id: id,
      uid: id,
      nickname: '알 수 없는 사용자',
      email: '',
      routineTime: '',
      streakCount: 0,
      joinedGroupIds: const [],
    );
  }

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserModel(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      nickname: data['nickname'] as String? ?? '',
      email: data['email'] as String? ?? '',
      routineTime: data['routineTime'] as String? ?? '',
      streakCount: (data['streakCount'] as num?)?.toInt() ?? 0,
      joinedGroupIds:
          (data['joinedGroupIds'] as List<dynamic>? ?? <dynamic>[])
              .map((e) => e.toString())
              .toList(),
    );
  }
}
