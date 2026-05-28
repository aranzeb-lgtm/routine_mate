import 'package:flutter/material.dart';

import '../../data/models/checkin_model.dart';
import '../../data/models/group_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/firestore_repository.dart';
import '../../data/utils/streak.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const String _profileDescription = '오늘도 루틴을 이어가는 중이에요';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreRepository _repository = FirestoreRepository();
  final AuthRepository _auth = AuthRepository();
  late final String _userId;
  late Future<_ProfileData> _futureData;
  late Stream<List<CheckinModel>> _userCheckinsStream;

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUserId!;
    _futureData = _loadProfileData();
    _userCheckinsStream = _repository.watchUserCheckins(_userId);
  }

  Future<_ProfileData> _loadProfileData() async {
    final user = await _repository.getUser(_userId);
    final groups = await _repository.getUserGroups(user.joinedGroupIds);
    return _ProfileData(user: user, groups: groups);
  }

  void _reload() {
    setState(() {
      _futureData = _loadProfileData();
    });
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label 기능은 준비 중입니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _editNickname(String currentNickname) async {
    final didSave = await showDialog<bool>(
      context: context,
      builder: (_) => _NicknameDialog(
        currentNickname: currentNickname,
        userId: _userId,
        repository: _repository,
      ),
    );
    if (!mounted || didSave != true) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('닉네임이 변경됐어요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('마이'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: FutureBuilder<_ProfileData>(
          future: _futureData,
          builder: (context, baseSnap) {
            if (baseSnap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (baseSnap.hasError) {
              return _ErrorView(
                message: '프로필을 불러오지 못했어요\n${baseSnap.error}',
                onRetry: _reload,
              );
            }
            return StreamBuilder<List<CheckinModel>>(
              stream: _userCheckinsStream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return _ErrorView(
                    message: '인증 기록을 불러오지 못했어요\n${snap.error}',
                    onRetry: _reload,
                  );
                }
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final checkins = snap.data ?? const <CheckinModel>[];
                return _ProfileContent(
                  data: baseSnap.data!,
                  userCheckins: checkins,
                  description: ProfileScreen._profileDescription,
                  onSettingTap: _showComingSoon,
                  onEditNickname: _editNickname,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProfileData {
  const _ProfileData({
    required this.user,
    required this.groups,
  });

  final UserModel user;
  final List<GroupModel> groups;
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.data,
    required this.userCheckins,
    required this.description,
    required this.onSettingTap,
    required this.onEditNickname,
  });

  final _ProfileData data;
  final List<CheckinModel> userCheckins;
  final String description;
  final ValueChanged<String> onSettingTap;
  final ValueChanged<String> onEditNickname;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final user = data.user;
    final nickname = user.nickname.isEmpty ? user.id : user.nickname;
    final streakDays = computeCurrentStreak(userCheckins);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileHeader(
            nickname: nickname,
            description: description,
          ),
          const SizedBox(height: 24),
          _SectionLabel(text: '루틴 시간'),
          const SizedBox(height: 10),
          _InfoCard(
            icon: Icons.nightlight_round,
            title: user.routineTime.isEmpty
                ? '아직 시간이 설정되지 않았어요'
                : user.routineTime,
            subtitle: '매일 이 시간에 루틴을 시작해요',
          ),
          const SizedBox(height: 16),
          _SectionLabel(text: '연속 기록'),
          const SizedBox(height: 10),
          _InfoCard(
            icon: Icons.local_fire_department,
            iconColor: Colors.deepOrange.shade400,
            title: '$streakDays일 연속 진행 중',
            subtitle: '꾸준히 이어가고 있어요',
          ),
          const SizedBox(height: 28),
          _SectionLabel(text: '참여 중인 그룹'),
          const SizedBox(height: 10),
          _GroupSection(groups: data.groups),
          const SizedBox(height: 28),
          _SectionLabel(text: '설정'),
          const SizedBox(height: 10),
          _SettingsList(
            items: [
              _SettingsItem(
                icon: Icons.notifications_outlined,
                label: '알림 설정',
                onTap: () => onSettingTap('알림 설정'),
              ),
              _SettingsItem(
                icon: Icons.edit_outlined,
                label: '닉네임 수정',
                onTap: () => onEditNickname(nickname),
              ),
              _SettingsItem(
                icon: Icons.logout_rounded,
                label: '로그아웃',
                isDestructive: true,
                onTap: () => onSettingTap('로그아웃'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Routine Mate',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.nickname,
    required this.description,
  });

  final String nickname;
  final String description;

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
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor:
                  colorScheme.onPrimaryContainer.withValues(alpha: 0.12),
              child: Text(
                nickname.characters.first,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.85),
                      height: 1.4,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Text(
      text,
      style: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: iconColor ?? colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.groups});

  final List<GroupModel> groups;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (groups.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            '아직 참여 중인 그룹이 없어요',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < groups.length; i++) ...[
          _GroupItemCard(group: groups[i]),
          if (i != groups.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _GroupItemCard extends StatelessWidget {
  const _GroupItemCard({required this.group});

  final GroupModel group;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.groupName,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (group.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      group.description,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (group.routineTime.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.nightlight_round,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            group.routineTime,
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
}

class _SettingsList extends StatelessWidget {
  const _SettingsList({required this.items});

  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _SettingsTile(item: items[i]),
            if (i != items.length - 1)
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.item});

  final _SettingsItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Color contentColor = item.isDestructive
        ? colorScheme.error
        : colorScheme.onSurface;

    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(item.icon, size: 22, color: contentColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: contentColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _NicknameDialog extends StatefulWidget {
  const _NicknameDialog({
    required this.currentNickname,
    required this.userId,
    required this.repository,
  });

  final String currentNickname;
  final String userId;
  final FirestoreRepository repository;

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentNickname);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_isSaving) return;
    final newNickname = _controller.text.trim();
    if (newNickname.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('닉네임을 입력해주세요'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.repository.updateNickname(widget.userId, newNickname);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('저장에 실패했어요: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('닉네임 수정'),
      content: TextField(
        controller: _controller,
        enabled: !_isSaving,
        autofocus: true,
        maxLength: 20,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _onSave(),
        decoration: InputDecoration(
          labelText: '닉네임',
          hintText: '새 닉네임을 입력해주세요',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _onSave,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('저장'),
        ),
      ],
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
