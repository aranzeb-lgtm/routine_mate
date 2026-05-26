import 'package:flutter/foundation.dart';

import '../models/checkin_model.dart';
import '../repositories/firestore_repository.dart';

class CheckinsStore extends ChangeNotifier {
  CheckinsStore({
    FirestoreRepository? repository,
    required this.userId,
    required this.primaryGroupId,
  }) : _repository = repository ?? FirestoreRepository();

  final FirestoreRepository _repository;
  final String userId;
  final String primaryGroupId;

  List<CheckinModel> _userCheckins = const [];
  List<CheckinModel> _todayGroupCheckins = const [];
  bool _isLoading = false;
  Object? _error;

  List<CheckinModel> get userCheckins => _userCheckins;
  List<CheckinModel> get todayGroupCheckins => _todayGroupCheckins;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getUserCheckins(userId),
        _repository.getTodayCheckins(primaryGroupId),
      ]);
      _userCheckins = results[0];
      _todayGroupCheckins = results[1];
      _error = null;
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCheckin(CheckinModel checkin) async {
    await _repository.createCheckin(checkin);
    await load();
  }

  bool hasTodayCheckin({required String groupId, String? today}) {
    final t = today ?? _todayString();
    return _userCheckins.any(
      (c) =>
          c.userId == userId &&
          c.groupId == groupId &&
          c.date == t &&
          c.status == 'completed',
    );
  }

  static String _todayString() {
    final n = DateTime.now();
    final y = n.year.toString().padLeft(4, '0');
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
