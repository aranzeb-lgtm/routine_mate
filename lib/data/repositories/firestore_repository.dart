import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/group_model.dart';
import '../models/routine_model.dart';
import '../models/user_model.dart';

class FirestoreRepository {
  FirestoreRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<RoutineModel> getRoutine(String routineId) async {
    final doc = await _db.collection('routines').doc(routineId).get();
    if (!doc.exists) {
      throw StateError('루틴 문서를 찾을 수 없습니다: $routineId');
    }
    return RoutineModel.fromFirestore(doc);
  }

  Future<GroupModel> getGroup(String groupId) async {
    final doc = await _db.collection('groups').doc(groupId).get();
    if (!doc.exists) {
      throw StateError('그룹 문서를 찾을 수 없습니다: $groupId');
    }
    return GroupModel.fromFirestore(doc);
  }

  Future<UserModel> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) {
      throw StateError('사용자 문서를 찾을 수 없습니다: $userId');
    }
    return UserModel.fromFirestore(doc);
  }
}
