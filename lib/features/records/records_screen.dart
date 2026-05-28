import 'package:flutter/material.dart';

import '../../data/models/checkin_model.dart';
import '../../data/repositories/firestore_repository.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key, required this.currentUid});

  final String currentUid;

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final FirestoreRepository _repository = FirestoreRepository();
  late Stream<List<CheckinModel>> _stream;

  String get _userId => widget.currentUid;

  @override
  void initState() {
    super.initState();
    _stream = _repository.watchUserCheckins(_userId);
  }

  void _retry() {
    setState(() {
      _stream = _repository.watchUserCheckins(_userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('기록'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: StreamBuilder<List<CheckinModel>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorView(
                message: '기록을 불러오지 못했어요\n${snapshot.error}',
                onRetry: _retry,
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final checkins = snapshot.data ?? const <CheckinModel>[];
            return _RecordsContent(checkins: checkins);
          },
        ),
      ),
    );
  }
}

String _formatYmd(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String _growthMessage(int total) {
  if (total == 0) return '아직 첫 기록을 기다리고 있어요 🌱';
  if (total <= 3) return '루틴 씨앗이 자라기 시작했어요 🌱';
  if (total <= 7) return '루틴 나무가 조금씩 자라고 있어요 🌿';
  return '꾸준함이 단단하게 자라고 있어요 🌳';
}

class _RecordsContent extends StatelessWidget {
  const _RecordsContent({required this.checkins});

  final List<CheckinModel> checkins;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    final todayStr = _formatYmd(today);
    final mondayStr = _formatYmd(monday);
    final sundayStr = _formatYmd(sunday);

    final isCompletedToday = checkins.any((c) => c.date == todayStr);
    final weeklyCount = checkins
        .where(
          (c) =>
              c.date.compareTo(mondayStr) >= 0 &&
              c.date.compareTo(sundayStr) <= 0,
        )
        .length;
    final totalCount = checkins.length;
    final recent = checkins.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '나의 루틴 기록',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          _TodayStatusCard(isCompleted: isCompletedToday),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(label: '이번 주', count: weeklyCount),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(label: '전체 인증', count: totalCount),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '최근 인증 기록',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _RecentList(checkins: recent),
          const SizedBox(height: 24),
          _GrowthCard(message: _growthMessage(totalCount)),
        ],
      ),
    );
  }
}

class _TodayStatusCard extends StatelessWidget {
  const _TodayStatusCard({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.schedule_rounded,
                size: 32,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오늘',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCompleted ? '오늘 루틴 완료' : '오늘은 아직이에요',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$count',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '회',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.checkins});

  final List<CheckinModel> checkins;

  String _displayDate(String date) {
    final parts = date.split('-');
    if (parts.length != 3) return date;
    final m = int.tryParse(parts[1]) ?? 0;
    final d = int.tryParse(parts[2]) ?? 0;
    return '$m월 $d일';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (checkins.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            '아직 인증 기록이 없어요',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (int i = 0; i < checkins.length; i++) ...[
            _RecentTile(
              date: _displayDate(checkins[i].date),
              memo: checkins[i].memo,
            ),
            if (i != checkins.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.surface,
                indent: 16,
                endIndent: 16,
              ),
          ],
        ],
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.date, required this.memo});

  final String date;
  final String memo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 18,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (memo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    memo,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthCard extends StatelessWidget {
  const _GrowthCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.onSecondaryContainer.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🌱', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                message,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSecondaryContainer,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
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
