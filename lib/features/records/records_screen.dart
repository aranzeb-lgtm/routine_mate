import 'package:flutter/material.dart';

enum _DayStatus { completed, missed, upcoming }

class _DayRecord {
  const _DayRecord({required this.label, required this.status});

  final String label;
  final _DayStatus status;
}

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  static const int _streakDays = 3;
  static const int _weeklyTotal = 5;
  static const int _weeklyDone = 3;
  static const String _growthMessage = '오늘의 루틴 나무가 조금 자랐어요 🌱';

  static const List<_DayRecord> _week = [
    _DayRecord(label: '월', status: _DayStatus.completed),
    _DayRecord(label: '화', status: _DayStatus.completed),
    _DayRecord(label: '수', status: _DayStatus.missed),
    _DayRecord(label: '목', status: _DayStatus.completed),
    _DayRecord(label: '금', status: _DayStatus.upcoming),
    _DayRecord(label: '토', status: _DayStatus.upcoming),
    _DayRecord(label: '일', status: _DayStatus.upcoming),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = _weeklyTotal == 0 ? 0.0 : _weeklyDone / _weeklyTotal;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('기록'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
              _StreakCard(days: _streakDays),
              const SizedBox(height: 16),
              _WeeklySummaryCard(
                done: _weeklyDone,
                total: _weeklyTotal,
                progress: progress,
              ),
              const SizedBox(height: 24),
              Text(
                '이번 주 캘린더',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _WeeklyCalendar(week: _week),
              const SizedBox(height: 12),
              const _LegendRow(),
              const SizedBox(height: 24),
              _GrowthCard(message: _growthMessage),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.days});

  final int days;

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
              child: const Text('🔥', style: TextStyle(fontSize: 30)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '연속 기록',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$days일 연속 진행 중',
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

class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard({
    required this.done,
    required this.total,
    required this.progress,
  });

  final int done;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '이번 주 완료 현황',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '$total일 중 $done일 성공',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: colorScheme.surface,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyCalendar extends StatelessWidget {
  const _WeeklyCalendar({required this.week});

  final List<_DayRecord> week;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final day in week)
          Expanded(child: _DayCell(record: day)),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.record});

  final _DayRecord record;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Color bg;
    final Color fg;
    final Widget marker;

    switch (record.status) {
      case _DayStatus.completed:
        bg = colorScheme.primary;
        fg = colorScheme.onPrimary;
        marker = Icon(Icons.check_rounded, size: 18, color: fg);
        break;
      case _DayStatus.missed:
        bg = colorScheme.surfaceContainerHighest;
        fg = colorScheme.onSurfaceVariant;
        marker = Icon(Icons.close_rounded, size: 18, color: fg);
        break;
      case _DayStatus.upcoming:
        bg = colorScheme.surface;
        fg = colorScheme.onSurfaceVariant;
        marker = Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: colorScheme.outlineVariant,
            shape: BoxShape.circle,
          ),
        );
        break;
    }

    final BoxBorder? border = record.status == _DayStatus.upcoming
        ? Border.all(color: colorScheme.outlineVariant, width: 1)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          Text(
            record.label,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: border,
            ),
            alignment: Alignment.center,
            child: marker,
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget legend(Color color, String label, {bool outlined = false}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: outlined ? colorScheme.surface : color,
              shape: BoxShape.circle,
              border: outlined
                  ? Border.all(color: colorScheme.outlineVariant)
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        legend(colorScheme.primary, '완료'),
        legend(colorScheme.surfaceContainerHighest, '미완료'),
        legend(colorScheme.surface, '예정', outlined: true),
      ],
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
