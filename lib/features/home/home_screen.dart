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
  late Stream<List<CheckinModel>> _todayGroupCheckinsStream;
  late Stream<List<CheckinModel>> _userCheckinsStream;

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUserId!;
    _futureData = _loadBaseData();
    _todayGroupCheckinsStream =
        _repository.watchTodayCheckins(HomeScreen._groupId);
    _userCheckinsStream = _repository.watchUserCheckins(_userId);
  }

  Future<_HomeBaseData> _loadBaseData() async {
    final results = await Future.wait([
      _repository.getRoutine(HomeScreen._routineId),
      _repository.getGroup(HomeScreen._groupId),
      _repository.getUser(_userId),
    ]);
    return _HomeBaseData(
      routine: results[0] as RoutineModel,
      group: results[1] as GroupModel,
      user: results[2] as UserModel,
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
            if (baseSnap.hasError) {
              return _ErrorView(
                message: '데이터를 불러오지 못했어요\n${baseSnap.error}',
                onRetry: _reload,
              );
            }
            return StreamBuilder<List<CheckinModel>>(
              stream: _todayGroupCheckinsStream,
              builder: (context, todaySnap) {
                if (todaySnap.hasError) {
                  return _ErrorView(
                    message: '오늘 인증을 불러오지 못했어요\n${todaySnap.error}',
                    onRetry: _reload,
                  );
                }
                if (todaySnap.connectionState == ConnectionState.waiting &&
                    !todaySnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final todayCheckins =
                    todaySnap.data ?? const <CheckinModel>[];

                return StreamBuilder<List<CheckinModel>>(
                  stream: _userCheckinsStream,
                  builder: (context, userSnap) {
                    if (userSnap.hasError) {
                      return _ErrorView(
                        message: '내 인증 기록을 불러오지 못했어요\n${userSnap.error}',
                        onRetry: _reload,
                      );
                    }
                    if (userSnap.connectionState ==
                            ConnectionState.waiting &&
                        !userSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final userCheckins =
                        userSnap.data ?? const <CheckinModel>[];

                    return _HomeContent(
                      data: baseSnap.data!,
                      todayCheckins: todayCheckins,
                      userCheckins: userCheckins,
                      onCheckinPressed: _handleCheckin,
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

class _HomeBaseData {
  const _HomeBaseData({
    required this.routine,
    required this.group,
    required this.user,
  });

  final RoutineModel routine;
  final GroupModel group;
  final UserModel user;
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.data,
    required this.todayCheckins,
    required this.userCheckins,
    required this.onCheckinPressed,
  });

  final _HomeBaseData data;
  final List<CheckinModel> todayCheckins;
  final List<CheckinModel> userCheckins;
  final VoidCallback onCheckinPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final routine = data.routine;
    final group = data.group;
    final user = data.user;

    final totalMembers = group.memberCount;
    final completedMembers =
        todayCheckins.map((c) => c.userId).toSet().length;
    final streakDays = computeCurrentStreak(userCheckins);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '오늘도 ${routine.durationMinutes}분만 같이 해볼까요?',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          _RoutineCard(
            routineName: routine.routineName,
            duration: '${routine.durationMinutes}분',
            scheduledTime: user.routineTime,
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
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
