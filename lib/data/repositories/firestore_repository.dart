import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  bool _isAuthTransitionError(Object e) {
    return e is FirebaseException &&
        e.code == 'permission-denied' &&
        FirebaseAuth.instance.currentUser == null;
  }

  StreamTransformer<T, T> _swallowAuthTransitionErrors<T>(
    String fn,
    T fallback,
  ) {
    return StreamTransformer<T, T>.fromHandlers(
      handleData: (data, sink) => sink.add(data),
      handleError: (error, stackTrace, sink) {
        if (_isAuthTransitionError(error)) {
          debugPrint(
            '[Firestore] $fn permission-denied during auth transition (currentUser=null), swallowing',
          );
          sink.add(fallback);
          return;
        }
        _logFirestoreError(fn, error, stackTrace);
        sink.addError(error, stackTrace);
      },
    );
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
      debugPrint('User document ready: $uid');
    } catch (e, stackTrace) {
      _logFirestoreError('ensureUserDocument', e, stackTrace);
      rethrow;
    }
  }

  Future<void> ensureBaseDocuments(String uid) async {
    debugPrint('[Firestore] ensureBaseDocuments start (uid: $uid)');
    try {
      final routineSnap =
          await _db.collection('routines').doc('routine_001').get();
      debugPrint(
        '[Firestore] routines/routine_001 exists: ${routineSnap.exists}',
      );

      final groupSnap =
          await _db.collection('groups').doc('group_001').get();
      debugPrint(
        '[Firestore] groups/group_001 exists: ${groupSnap.exists}',
      );

      debugPrint('Base documents checked');
    } catch (e, stackTrace) {
      _logFirestoreError('ensureBaseDocuments', e, stackTrace);
      debugPrint(
        '[Firestore] ensureBaseDocuments failed but app will continue. '
        'Base docs may need to be created manually in Firebase Console.',
      );
    }
  }

  Future<void> updateRoutineTime(String uid, String routineTime) async {
    debugPrint(
      '[Firestore] updateRoutineTime start (uid: $uid, routineTime: $routineTime)',
    );
    try {
      await _db.collection('users').doc(uid).set({
        'routineTime': routineTime,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[Firestore] updateRoutineTime success');
    } catch (e, stackTrace) {
      _logFirestoreError('updateRoutineTime', e, stackTrace);
      rethrow;
    }
  }

  Stream<UserModel?> watchUser(String uid) {
    if (uid.isEmpty) {
      debugPrint('[Firestore] watchUser: empty uid, returning empty stream');
      return Stream<UserModel?>.value(null);
    }
    debugPrint('[Firestore] watchUser start (uid: $uid)');
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null)
        .transform(_swallowAuthTransitionErrors<UserModel?>(
          'watchUser',
          null,
        ));
  }

  Future<void> updateNickname(String uid, String nickname) async {
    debugPrint(
      '[Firestore] updateNickname start (uid: $uid, nickname: $nickname)',
    );
    try {
      await _db.collection('users').doc(uid).set({
        'nickname': nickname,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[Firestore] updateNickname success');
    } catch (e, stackTrace) {
      _logFirestoreError('updateNickname', e, stackTrace);
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
    if (groupId.isEmpty) {
      debugPrint(
        '[Firestore] watchTodayCheckins: empty groupId, returning empty stream',
      );
      return Stream<List<CheckinModel>>.value(const <CheckinModel>[]);
    }
    debugPrint('[Firestore] watchTodayCheckins start (group: $groupId)');
    final today = _todayDateString();
    return _db
        .collection('checkins')
        .where('groupId', isEqualTo: groupId)
        .where('date', isEqualTo: today)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snap) => snap.docs.map(CheckinModel.fromFirestore).toList())
        .transform(_swallowAuthTransitionErrors<List<CheckinModel>>(
          'watchTodayCheckins',
          const <CheckinModel>[],
        ));
  }

  Stream<List<CheckinModel>> watchUserCheckins(String userId) {
    if (userId.isEmpty) {
      debugPrint(
        '[Firestore] watchUserCheckins: empty uid, returning empty stream',
      );
      return Stream<List<CheckinModel>>.value(const <CheckinModel>[]);
    }
    debugPrint('[Firestore] watchUserCheckins start (uid: $userId)');
    return _db
        .collection('checkins')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(CheckinModel.fromFirestore).toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        })
        .transform(_swallowAuthTransitionErrors<List<CheckinModel>>(
          'watchUserCheckins',
          const <CheckinModel>[],
        ));
  }

  Stream<CheckinModel?> watchUserTodayCheckin(
    String userId,
    String groupId,
  ) {
    if (userId.isEmpty || groupId.isEmpty) {
      debugPrint(
        '[Firestore] watchUserTodayCheckin: empty uid/groupId, returning empty stream',
      );
      return Stream<CheckinModel?>.value(null);
    }
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
        .map((snap) => snap.docs.isEmpty
            ? null
            : CheckinModel.fromFirestore(snap.docs.first))
        .transform(_swallowAuthTransitionErrors<CheckinModel?>(
          'watchUserTodayCheckin',
          null,
        ));
  }

  String _todayDateString() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
