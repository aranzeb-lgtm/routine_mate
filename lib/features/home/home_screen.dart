import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../data/models/checkin_model.dart';
import '../../data/models/group_model.dart';
import '../../data/models/routine_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/firestore_repository.dart';
import '../../data/utils/streak.dart';
import '../checkin/checkin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String _routineId = 'routine_001';
  static const String _groupId = 'group_001';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreRepository _repository = FirestoreRepository();
  final AuthRepository _auth = AuthRepository();
  late final String _userId;
  late Future<_HomeBaseData> _futureData;
  late Stream<UserModel?> _userStream;
  late Stream<List<CheckinModel>> _todayGroupCheckinsStream;
  late Stream<List<CheckinModel>> _userCheckinsStream;

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUserId!;
    _futureData = _loadBaseData();
    _userStream = _repository.watchUser(_userId);
    _todayGroupCheckinsStream =
        _repository.watchTodayCheckins(HomeScreen._groupId);
    _userCheckinsStream = _repository.watchUserCheckins(_userId);
  }

  Future<_HomeBaseData> _loadBaseData() async {
    final errors = <String>[];

    RoutineModel? routine;
    try {
      routine = await _repository.getRoutine(HomeScreen._routineId);
    } catch (e) {
      debugPrint('[Home] getRoutine failed: $e');
      errors.add('루틴: ${_describeError(e)}');
    }

    GroupModel? group;
    try {
      group = await _repository.getGroup(HomeScreen._groupId);
    } catch (e) {
      debugPrint('[Home] getGroup failed: $e');
      errors.add('그룹: ${_describeError(e)}');
    }

    return _HomeBaseData(
      routine: routine,
      group: group,
      errors: errors,
    );
  }

  void _reload() {
    setState(() {
      _futureData = _loadBaseData();
    });
  }

  Future<void> _handleCheckin() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckinScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('홈'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: FutureBuilder<_HomeBaseData>(
          future: _futureData,
          builder: (context, baseSnap) {
            if (baseSnap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final base = baseSnap.data ??
                const _HomeBaseData(
                  routine: null,
                  group: null,
                  errors: ['데이터 로드 실패'],
                );

            return StreamBuilder<UserModel?>(
              stream: _userStream,
              builder: (context, userDocSnap) {
                if (userDocSnap.connectionState == ConnectionState.waiting &&
                    !userDocSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final user = userDocSnap.data;
                final userDocError = userDocSnap.error;

                return StreamBuilder<List<CheckinModel>>(
                  stream: _todayGroupCheckinsStream,
                  builder: (context, todaySnap) {
                    if (todaySnap.connectionState == ConnectionState.waiting &&
                        !todaySnap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    final todayCheckins =
                        todaySnap.data ?? const <CheckinModel>[];
                    final todayCheckinsError = todaySnap.error;

                    return StreamBuilder<List<CheckinModel>>(
                      stream: _userCheckinsStream,
                      builder: (context, userCheckinsSnap) {
                        if (userCheckinsSnap.connectionState ==
                                ConnectionState.waiting &&
                            !userCheckinsSnap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final userCheckins =
                            userCheckinsSnap.data ?? const <CheckinModel>[];
                        final extraErrors = <String>[
                          ...base.errors,
                          if (userDocError != null)
                            '사용자: ${_describeError(userDocError)}',
                          if (todayCheckinsError != null)
                            '오늘 인증: ${_describeError(todayCheckinsError)}',
                          if (userCheckinsSnap.error != null)
                            '내 인증 기록: ${_describeError(userCheckinsSnap.error!)}',
                        ];

                        return _HomeContent(
                          data: base,
                          user: user,
                          todayCheckins: todayCheckins,
                          userCheckins: userCheckins,
                          errors: extraErrors,
                          onCheckinPressed: _handleCheckin,
                          onRetry: _reload,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

String _describeError(Object e) {
  if (e is FirebaseException) {
    return 'FirebaseException(${e.code}): ${e.message ?? '메시지 없음'}';
  }
  return '$e';
}

class _HomeBaseData {
  const _HomeBaseData({
    required this.routine,
    required this.group,
    required this.errors,
  });

  final RoutineModel? routine;
  final GroupModel? group;
  final List<String> errors;
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.data,
    required this.user,
    required this.todayCheckins,
    required this.userCheckins,
    required this.errors,
    required this.onCheckinPressed,
    required this.onRetry,
  });

  final _HomeBaseData data;
  final UserModel? user;
  final List<CheckinModel> todayCheckins;
  final List<CheckinModel> userCheckins;
  final List<String> errors;
  final VoidCallback onCheckinPressed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final routineName = data.routine?.routineName ?? '퇴근 후 스트레칭';
    final durationMinutes = data.routine?.durationMinutes ?? 10;
    final scheduledTime = user?.routineTime ?? '22:00';

    final totalMembers = data.group?.memberCount ?? 5;
    final completedMembers =
        todayCheckins.map((c) => c.userId).toSet().length;
    final streakDays = computeCurrentStreak(userCheckins);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errors.isNotEmpty) ...[
            _ErrorBanner(errors: errors, onRetry: onRetry),
            const SizedBox(height: 16),
          ],
          Text(
            '오늘도 $durationMinutes분만 같이 해볼까요?',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          _RoutineCard(
            routineName: routineName,
            duration: '$durationMinutes분',
            scheduledTime: scheduledTime,
            completedMembers: completedMembers,
            totalMembers: totalMembers,
            streakDays: streakDays,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('루틴 시작하기'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              textStyle: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onCheckinPressed,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('완료 인증하기'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              textStyle: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.errors, required this.onRetry});

  final List<String> errors;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasPermissionIssue = errors.any(
      (m) => m.contains('permission-denied'),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasPermissionIssue
                      ? 'Firestore 권한 문제입니다'
                      : '일부 데이터를 불러오지 못해 임시값을 사용 중이에요',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                child: const Text('다시 시도'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final e in errors)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '· $e',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.routineName,
    required this.duration,
    required this.scheduledTime,
    required this.completedMembers,
    required this.totalMembers,
    required this.streakDays,
  });

  final String routineName;
  final String duration;
  final String scheduledTime;
  final int completedMembers;
  final int totalMembers;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = totalMembers == 0 ? 0.0 : completedMembers / totalMembers;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.self_improvement,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '오늘의 루틴',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        routineName,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.schedule,
                  label: duration,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.nightlight_round,
                  label: scheduledTime,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ProgressRow(
              completed: completedMembers,
              total: totalMembers,
              progress: progress,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  size: 20,
                  color: Colors.deepOrange.shade400,
                ),
                const SizedBox(width: 6),
                Text(
                  '$streakDays일 연속 진행 중',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.completed,
    required this.total,
    required this.progress,
  });

  final int completed;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.groups_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '그룹 완료 현황',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Text(
              '$total명 중 $completed명 완료',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: colorScheme.surface,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
