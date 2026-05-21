import 'package:flutter/material.dart';

import '../checkin/checkin_screen.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  static const String _groupName = '퇴근 후 스트레칭 그룹';
  static const String _groupDescription = '퇴근 후 10분, 같이 몸을 풀어요';

  static const List<_Member> _members = [
    _Member(name: '리체', isCompleted: true),
    _Member(name: '민준', isCompleted: true),
    _Member(name: '대표님', isCompleted: false),
    _Member(name: '지연', isCompleted: false),
    _Member(name: '수아', isCompleted: false),
  ];

  static const List<_Reaction> _reactions = [
    _Reaction(emoji: '👏', label: '수고했어요'),
    _Reaction(emoji: '🔥', label: '같이 가요'),
    _Reaction(emoji: '💪', label: '오늘도 성공'),
  ];

  void _onReactionTap(BuildContext context, _Reaction reaction) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${reaction.emoji} ${reaction.label} 응원을 보냈어요!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _goToCheckin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckinScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _members.where((m) => m.isCompleted).length;
    final totalCount = _members.length;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('그룹'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GroupHeaderCard(
                name: _groupName,
                description: _groupDescription,
                completed: completedCount,
                total: totalCount,
                progress: progress,
              ),
              const SizedBox(height: 24),
              Text(
                '오늘의 멤버',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _MemberList(members: _members),
              const SizedBox(height: 24),
              Text(
                '응원 보내기',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _ReactionRow(
                reactions: _reactions,
                onTap: (reaction) => _onReactionTap(context, reaction),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _goToCheckin(context),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('내 루틴 인증하러 가기'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  textStyle: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Member {
  const _Member({required this.name, required this.isCompleted});

  final String name;
  final bool isCompleted;
}

class _Reaction {
  const _Reaction({required this.emoji, required this.label});

  final String emoji;
  final String label;
}

class _GroupHeaderCard extends StatelessWidget {
  const _GroupHeaderCard({
    required this.name,
    required this.description,
    required this.completed,
    required this.total,
    required this.progress,
  });

  final String name;
  final String description;
  final int completed;
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
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.groups_rounded,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '오늘 참여 현황',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
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
        ),
      ),
    );
  }
}

class _MemberList extends StatelessWidget {
  const _MemberList({required this.members});

  final List<_Member> members;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (int i = 0; i < members.length; i++) ...[
            _MemberTile(member: members[i]),
            if (i != members.length - 1)
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

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final _Member member;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              member.name.characters.first,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              member.name,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          _StatusBadge(isCompleted: member.isCompleted),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Color bg = isCompleted
        ? colorScheme.primary.withValues(alpha: 0.12)
        : colorScheme.surface;
    final Color fg = isCompleted
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final IconData icon = isCompleted
        ? Icons.check_circle
        : Icons.schedule;
    final String label = isCompleted ? '완료' : '아직';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionRow extends StatelessWidget {
  const _ReactionRow({required this.reactions, required this.onTap});

  final List<_Reaction> reactions;
  final ValueChanged<_Reaction> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < reactions.length; i++) ...[
          Expanded(
            child: _ReactionButton(
              reaction: reactions[i],
              onTap: () => onTap(reactions[i]),
            ),
          ),
          if (i != reactions.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({required this.reaction, required this.onTap});

  final _Reaction reaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(reaction.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              reaction.label,
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
