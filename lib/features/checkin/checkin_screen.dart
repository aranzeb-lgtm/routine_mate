import 'package:flutter/material.dart';

import '../../data/models/checkin_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/firestore_repository.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  static const String _groupId = 'group_001';
  static const String _routineId = 'routine_001';

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final TextEditingController _memoController = TextEditingController();
  final FirestoreRepository _repository = FirestoreRepository();
  final AuthRepository _auth = AuthRepository();
  late final String _userId;
  late final Stream<CheckinModel?> _todayCheckinStream;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUserId!;
    _todayCheckinStream = _repository.watchUserTodayCheckin(
      _userId,
      CheckinScreen._groupId,
    );
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  String _todayDateString() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _onSubmit() async {
    if (_isSaving) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final checkin = CheckinModel(
        userId: _userId,
        groupId: CheckinScreen._groupId,
        routineId: CheckinScreen._routineId,
        date: _todayDateString(),
        memo: _memoController.text.trim(),
        status: 'completed',
      );

      await _repository.createCheckin(checkin);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('오늘 루틴 인증이 저장됐어요'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      Navigator.pop(context);
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
    const routineName = '퇴근 후 스트레칭 10분';
    const guideText = '오늘도 해냈어요! 짧게라도 움직인 것만으로 충분해요.';

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('오늘 루틴 완료'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: StreamBuilder<CheckinModel?>(
          stream: _todayCheckinStream,
          builder: (context, snap) {
            if (snap.hasError) {
              return _ErrorView(
                message: '인증 상태를 확인할 수 없어요\n${snap.error}',
              );
            }
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final alreadyDone = snap.data != null;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 72,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    routineName,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    alreadyDone
                        ? '오늘은 이미 인증을 마쳤어요. 내일도 함께해요!'
                        : guideText,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '한 줄 메모',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _memoController,
                    maxLength: 50,
                    enabled: !_isSaving && !alreadyDone,
                    textInputAction: TextInputAction.done,
                    onSubmitted: alreadyDone ? null : (_) => _onSubmit(),
                    decoration: InputDecoration(
                      hintText: '오늘의 기분이나 느낀 점을 남겨보세요',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: (_isSaving || alreadyDone) ? null : _onSubmit,
                    icon: alreadyDone
                        ? const Icon(Icons.check_circle)
                        : _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                    label: Text(
                      alreadyDone
                          ? '오늘은 이미 인증 완료'
                          : _isSaving
                              ? '저장 중...'
                              : '인증 완료하기',
                    ),
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
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

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
          ],
        ),
      ),
    );
  }
}
