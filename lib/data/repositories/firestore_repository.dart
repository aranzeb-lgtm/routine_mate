import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/checkin_model.dart';
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

  Future<String> createCheckin(CheckinModel checkin) async {
    final ref = await _db.collection('checkins').add(checkin.toCreateMap());
    return ref.id;
  }

  Future<bool> hasTodayCheckin({
    required String userId,
    required String groupId,
  }) async {
    final today = _todayDateString();
    final snap = await _db
        .collection('checkins')
        .where('userId', isEqualTo: userId)
        .where('groupId', isEqualTo: groupId)
        .where('date', isEqualTo: today)
        .where('status', isEqualTo: 'completed')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<List<GroupModel>> getUserGroups(List<String> groupIds) async {
    if (groupIds.isEmpty) return <GroupModel>[];
    final docs = await Future.wait(
      groupIds.map((id) => _db.collection('groups').doc(id).get()),
    );
    return docs
        .where((doc) => doc.exists)
        .map(GroupModel.fromFirestore)
        .toList();
  }

  Future<List<UserModel>> getGroupMembers(List<String> memberIds) async {
    if (memberIds.isEmpty) return <UserModel>[];
    final docs = await Future.wait(
      memberIds.map((id) => _db.collection('users').doc(id).get()),
    );
    return docs
        .where((doc) => doc.exists)
        .map(UserModel.fromFirestore)
        .toList();
  }

  Future<List<CheckinModel>> getUserCheckins(String userId) async {
    final snap = await _db
        .collection('checkins')
        .where('userId', isEqualTo: userId)
        .get();
    final checkins = snap.docs.map(CheckinModel.fromFirestore).toList();
    checkins.sort((a, b) => b.date.compareTo(a.date));
    return checkins;
  }

  Future<List<CheckinModel>> getTodayCheckins(String groupId) async {
    final today = _todayDateString();
    final snap = await _db
        .collection('checkins')
        .where('groupId', isEqualTo: groupId)
        .where('date', isEqualTo: today)
        .get();
    return snap.docs.map(CheckinModel.fromFirestore).toList();
  }

  String _todayDateString() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
