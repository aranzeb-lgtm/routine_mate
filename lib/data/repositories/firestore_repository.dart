import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/checkin_model.dart';
import '../models/group_model.dart';
import '../models/routine_model.dart';
import '../models/user_model.dart';

class FirestoreRepository {
  FirestoreRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  void _logFirestoreError(String fn, Object e, StackTrace stackTrace) {
    debugPrint('[Firestore] $fn error: $e');
    debugPrint('[Firestore] $fn stackTrace: $stackTrace');
    if (e is FirebaseException) {
      debugPrint('[Firestore] FirebaseException code: ${e.code}');
      debugPrint('[Firestore] FirebaseException message: ${e.message}');
    }
  }

  Future<RoutineModel> getRoutine(String routineId) async {
    debugPrint('[Firestore] getRoutine start (id: $routineId)');
    try {
      final doc =
          await _db.collection('routines').doc(routineId).get();
      if (!doc.exists) {
        throw StateError('루틴 문서를 찾을 수 없습니다: $routineId');
      }
      debugPrint('[Firestore] getRoutine success');
      return RoutineModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      _logFirestoreError('getRoutine', e, stackTrace);
      rethrow;
    }
  }

  Future<GroupModel> getGroup(String groupId) async {
    debugPrint('[Firestore] getGroup start (id: $groupId)');
    try {
      final doc = await _db.collection('groups').doc(groupId).get();
      if (!doc.exists) {
        throw StateError('그룹 문서를 찾을 수 없습니다: $groupId');
      }
      debugPrint('[Firestore] getGroup success');
      return GroupModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      _logFirestoreError('getGroup', e, stackTrace);
      rethrow;
    }
  }

  Future<void> ensureUserDocument(String uid) async {
    debugPrint('[Firestore] ensureUserDocument start (uid: $uid)');
    try {
      final docRef = _db.collection('users').doc(uid);
      final snap = await docRef.get();
      if (!snap.exists) {
        await docRef.set({
          'uid': uid,
          'nickname': '대표님',
          'email': '',
          'routineTime': '22:00',
          'streakCount': 0,
          'joinedGroupIds': ['group_001'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await docRef.set({
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      debugPrint('[Firestore] ensureUserDocument success');
    } catch (e, stackTrace) {
      _logFirestoreError('ensureUserDocument', e, stackTrace);
      rethrow;
    }
  }

  Future<void> ensureBaseDocuments(String uid) async {
    debugPrint('[Firestore] ensureBaseDocuments start (uid: $uid)');
    try {
      final routineRef = _db.collection('routines').doc('routine_001');
      final routineSnap = await routineRef.get();
      if (!routineSnap.exists) {
        debugPrint('[Firestore] Creating routines/routine_001');
        await routineRef.set({
          'routineName': '퇴근 후 스트레칭',
          'routineType': 'stretching',
          'durationMinutes': 10,
          'description': '목과 어깨를 가볍게 풀어주는 루틴',
          'difficulty': 'easy',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      final groupRef = _db.collection('groups').doc('group_001');
      final groupSnap = await groupRef.get();
      if (!groupSnap.exists) {
        debugPrint('[Firestore] Creating groups/group_001');
        await groupRef.set({
          'groupName': '퇴근 후 스트레칭 그룹',
          'description': '퇴근 후 10분, 같이 몸을 풀어요',
          'routineType': 'stretching',
          'routineTime': '22:00',
          'maxMembers': 5,
          'memberIds': [uid],
          'todayCompletedCount': 0,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        final data = groupSnap.data() ?? <String, dynamic>{};
        final memberIds = (data['memberIds'] as List<dynamic>? ?? <dynamic>[])
            .map((e) => e.toString())
            .toList();
        if (!memberIds.contains(uid)) {
          debugPrint('[Firestore] Adding $uid to group_001.memberIds');
          await groupRef.set({
            'memberIds': FieldValue.arrayUnion([uid]),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
      debugPrint('[Firestore] ensureBaseDocuments success');
    } on FirebaseException catch (e, stackTrace) {
      _logFirestoreError('ensureBaseDocuments', e, stackTrace);
      if (e.code == 'permission-denied') {
        debugPrint(
          '[Firestore] ensureBaseDocuments skipped due to permission-denied. '
          'Base docs may need to be created manually in Firebase Console.',
        );
        return;
      }
      rethrow;
    } catch (e, stackTrace) {
      _logFirestoreError('ensureBaseDocuments', e, stackTrace);
      rethrow;
    }
  }

  Future<UserModel> getUser(String userId) async {
    debugPrint('[Firestore] getUser start (uid: $userId)');
    try {
      final docRef = _db.collection('users').doc(userId);
      final doc = await docRef.get();
      if (doc.exists) {
        debugPrint('[Firestore] getUser success');
        return UserModel.fromFirestore(doc);
      }
      debugPrint('[Firestore] getUser: doc missing, calling ensureUserDocument');
      await ensureUserDocument(userId);
      final retryDoc = await docRef.get();
      if (!retryDoc.exists) {
        throw StateError(
          '사용자 정보를 준비하지 못했어요. 잠시 후 다시 시도해 주세요.',
        );
      }
      debugPrint('[Firestore] getUser success (after self-heal)');
      return UserModel.fromFirestore(retryDoc);
    } catch (e, stackTrace) {
      _logFirestoreError('getUser', e, stackTrace);
      rethrow;
    }
  }

  Future<String> createCheckin(CheckinModel checkin) async {
    debugPrint(
      '[Firestore] createCheckin start (userId: ${checkin.userId}, '
      'groupId: ${checkin.groupId}, date: ${checkin.date})',
    );
    try {
      final ref =
          await _db.collection('checkins').add(checkin.toCreateMap());
      debugPrint('[Firestore] createCheckin success (id: ${ref.id})');
      return ref.id;
    } catch (e, stackTrace) {
      _logFirestoreError('createCheckin', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> hasTodayCheckin({
    required String userId,
    required String groupId,
  }) async {
    debugPrint(
      '[Firestore] hasTodayCheckin start (uid: $userId, group: $groupId)',
    );
    try {
      final today = _todayDateString();
      final snap = await _db
          .collection('checkins')
          .where('userId', isEqualTo: userId)
          .where('groupId', isEqualTo: groupId)
          .where('date', isEqualTo: today)
          .where('status', isEqualTo: 'completed')
          .limit(1)
          .get();
      final exists = snap.docs.isNotEmpty;
      debugPrint('[Firestore] hasTodayCheckin success (result: $exists)');
      return exists;
    } catch (e, stackTrace) {
      _logFirestoreError('hasTodayCheckin', e, stackTrace);
      rethrow;
    }
  }

  Future<List<GroupModel>> getUserGroups(List<String> groupIds) async {
    debugPrint(
      '[Firestore] getUserGroups start (${groupIds.length} groupIds)',
    );
    try {
      if (groupIds.isEmpty) {
        debugPrint('[Firestore] getUserGroups success (empty input)');
        return <GroupModel>[];
      }
      final docs = await Future.wait(
        groupIds.map((id) => _db.collection('groups').doc(id).get()),
      );
      final result = docs
          .where((doc) => doc.exists)
          .map(GroupModel.fromFirestore)
          .toList();
      debugPrint(
        '[Firestore] getUserGroups success (${result.length}/${groupIds.length} found)',
      );
      return result;
    } catch (e, stackTrace) {
      _logFirestoreError('getUserGroups', e, stackTrace);
      rethrow;
    }
  }

  Future<List<UserModel>> getGroupMembers(List<String> memberIds) async {
    debugPrint(
      '[Firestore] getGroupMembers start (${memberIds.length} memberIds)',
    );
    try {
      if (memberIds.isEmpty) {
        debugPrint('[Firestore] getGroupMembers success (empty input)');
        return <UserModel>[];
      }
      final docs = await Future.wait(
        memberIds.map((id) => _db.collection('users').doc(id).get()),
      );
      final result = [
        for (var i = 0; i < docs.length; i++)
          if (docs[i].exists)
            UserModel.fromFirestore(docs[i])
          else
            UserModel.unknown(memberIds[i]),
      ];
      final missing = result.where((m) => m.nickname == '알 수 없는 사용자').length;
      debugPrint(
        '[Firestore] getGroupMembers success (${result.length} total, $missing missing)',
      );
      return result;
    } catch (e, stackTrace) {
      _logFirestoreError('getGroupMembers', e, stackTrace);
      rethrow;
    }
  }

  Future<List<CheckinModel>> getUserCheckins(String userId) async {
    debugPrint('[Firestore] getUserCheckins start (uid: $userId)');
    try {
      final snap = await _db
          .collection('checkins')
          .where('userId', isEqualTo: userId)
          .get();
      final checkins =
          snap.docs.map(CheckinModel.fromFirestore).toList();
      checkins.sort((a, b) => b.date.compareTo(a.date));
      debugPrint(
        '[Firestore] getUserCheckins success (${checkins.length} docs)',
      );
      return checkins;
    } catch (e, stackTrace) {
      _logFirestoreError('getUserCheckins', e, stackTrace);
      rethrow;
    }
  }

  Future<List<CheckinModel>> getTodayCheckins(String groupId) async {
    debugPrint('[Firestore] getTodayCheckins start (group: $groupId)');
    try {
      final today = _todayDateString();
      final snap = await _db
          .collection('checkins')
          .where('groupId', isEqualTo: groupId)
          .where('date', isEqualTo: today)
          .get();
      final result =
          snap.docs.map(CheckinModel.fromFirestore).toList();
      debugPrint(
        '[Firestore] getTodayCheckins success (${result.length} docs)',
      );
      return result;
    } catch (e, stackTrace) {
      _logFirestoreError('getTodayCheckins', e, stackTrace);
      rethrow;
    }
  }

  Stream<List<CheckinModel>> watchTodayCheckins(String groupId) {
    debugPrint('[Firestore] watchTodayCheckins start (group: $groupId)');
    final today = _todayDateString();
    return _db
        .collection('checkins')
        .where('groupId', isEqualTo: groupId)
        .where('date', isEqualTo: today)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snap) {
          debugPrint(
            '[Firestore] watchTodayCheckins success (${snap.docs.length} docs)',
          );
          return snap.docs.map(CheckinModel.fromFirestore).toList();
        })
        .handleError((Object e, StackTrace stackTrace) {
          _logFirestoreError('watchTodayCheckins', e, stackTrace);
          throw e;
        });
  }

  Stream<List<CheckinModel>> watchUserCheckins(String userId) {
    debugPrint('[Firestore] watchUserCheckins start (uid: $userId)');
    return _db
        .collection('checkins')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snap) {
          debugPrint(
            '[Firestore] watchUserCheckins success (${snap.docs.length} docs)',
          );
          final list = snap.docs.map(CheckinModel.fromFirestore).toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        })
        .handleError((Object e, StackTrace stackTrace) {
          _logFirestoreError('watchUserCheckins', e, stackTrace);
          throw e;
        });
  }

  Stream<CheckinModel?> watchUserTodayCheckin(
    String userId,
    String groupId,
  ) {
    debugPrint(
      '[Firestore] watchUserTodayCheckin start (uid: $userId, group: $groupId)',
    );
    final today = _todayDateString();
    return _db
        .collection('checkins')
        .where('userId', isEqualTo: userId)
        .where('groupId', isEqualTo: groupId)
        .where('date', isEqualTo: today)
        .where('status', isEqualTo: 'completed')
        .limit(1)
        .snapshots()
        .map((snap) {
          debugPrint(
            '[Firestore] watchUserTodayCheckin success (${snap.docs.length} docs)',
          );
          return snap.docs.isEmpty
              ? null
              : CheckinModel.fromFirestore(snap.docs.first);
        })
        .handleError((Object e, StackTrace stackTrace) {
          _logFirestoreError('watchUserTodayCheckin', e, stackTrace);
          throw e;
        });
  }

  String _todayDateString() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
