import 'package:flutter/material.dart';

import '../../data/models/checkin_model.dart';
import '../../data/models/group_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/firestore_repository.dart';
import '../checkin/checkin_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  static const String _groupId = 'group_001';

  static const List<_Reaction> _reactions = [
    _Reaction(emoji: '👏', label: '수고했어요'),
    _Reaction(emoji: '🔥', label: '같이 가요'),
    _Reaction(emoji: '💪', label: '오늘도 성공'),
  ];

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final FirestoreRepository _repository = FirestoreRepository();
  late Future<_GroupData> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _loadGroupData();
  }

  Future<_GroupData> _loadGroupData() async {
    final group = await _repository.getGroup(GroupsScreen._groupId);
    final results = await Future.wait([
      _repository.getGroupMembers(group.memberIds),
      _repository.getTodayCheckins(group.id),
    ]);
    return _GroupData(
      group: group,
      members: results[0] as List<UserModel>,
      todayCheckins: results[1] as List<CheckinModel>,
    );
  }

  void _reload() {
    setState(() {
      _futureData = _loadGroupData();
    });
  }

  void _onReactionTap(_Reaction reaction) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${reaction.emoji} ${reaction.label} 응원을 보냈어요!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _goToCheckin() async {
    final didSave = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CheckinScreen()),
    );
    if (!mounted) return;
    if (didSave == true) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('그룹'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: FutureBuilder<_GroupData>(
          future: _futureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorView(
                message: '그룹 정보를 불러오지 못했어요\n${snapshot.error}',
                onRetry: _reload,
              );
            }
            return _GroupContent(
              data: snapshot.data!,
              reactions: GroupsScreen._reactions,
              onReactionTap: _onReactionTap,
              onCheckinTap: _goToCheckin,
            );
          },
        ),
      ),
    );
  }
}

class _GroupData {
  const _GroupData({
    required this.group,
    required this.members,
    required this.todayCheckins,
  });

  final GroupModel group;
  final List<UserModel> members;
  final List<CheckinModel> todayCheckins;
}

class _Reaction {
  const _Reaction({required this.emoji, required this.label});

  final String emoji;
  final String label;
}

class _MemberView {
  const _MemberView({required this.name, required this.isCompleted});

  final String name;
  final bool isCompleted;
}

class _GroupContent extends StatelessWidget {
  const _GroupContent({
    required this.data,
    required this.reactions,
    required this.onReactionTap,
    required this.onCheckinTap,
  });

  final _GroupData data;
  final List<_Reaction> reactions;
  final ValueChanged<_Reaction> onReactionTap;
  final VoidCallback onCheckinTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final group = data.group;
    final completedUserIds =
        data.todayCheckins.map((c) => c.userId).toSet();

    bool isUserCompleted(UserModel u) {
      if (completedUserIds.contains(u.id)) return true;
      if (u.uid.isNotEmpty && completedUserIds.contains(u.uid)) return true;
      return false;
    }

    final memberViews = data.members
        .map(
          (u) => _MemberView(
            name: u.nickname.isEmpty ? u.id : u.nickname,
            isCompleted: isUserCompleted(u),
          ),
        )
        .toList();

    final totalCount = memberViews.length;
    final completedCount =
        memberViews.where((m) => m.isCompleted).length;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GroupHeaderCard(
            name: group.groupName,
            description: group.description,
            routineTime: group.routineTime,
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
          _MemberList(members: memberViews),
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
            reactions: reactions,
            onTap: onReactionTap,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCheckinTap,
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

class _GroupHeaderCard extends StatelessWidget {
  const _GroupHeaderCard({
    required this.name,
    required this.description,
    required this.routineTime,
    required this.completed,
    required this.total,
    required this.progress,
  });

  final String name;
  final String description;
  final String routineTime;
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
            if (routineTime.isNotEmpty) ...[
              const SizedBox(height: 18),
              _InfoChip(
                icon: Icons.nightlight_round,
                label: '루틴 시간 $routineTime',
              ),
            ],
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

class _MemberList extends StatelessWidget {
  const _MemberList({required this.members});

  final List<_MemberView> members;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (members.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            '아직 멤버가 없어요',
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

  final _MemberView member;

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
