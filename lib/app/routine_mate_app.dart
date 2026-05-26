import 'package:flutter/material.dart';

import '../data/stores/checkins_scope.dart';
import '../data/stores/checkins_store.dart';
import 'main_tab_screen.dart';

class RoutineMateApp extends StatefulWidget {
  const RoutineMateApp({super.key});

  static const String defaultUserId = 'test_user_001';
  static const String defaultGroupId = 'group_001';

  @override
  State<RoutineMateApp> createState() => _RoutineMateAppState();
}

class _RoutineMateAppState extends State<RoutineMateApp> {
  late final CheckinsStore _checkinsStore;

  @override
  void initState() {
    super.initState();
    _checkinsStore = CheckinsStore(
      userId: RoutineMateApp.defaultUserId,
      primaryGroupId: RoutineMateApp.defaultGroupId,
    );
    _checkinsStore.load();
  }

  @override
  void dispose() {
    _checkinsStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CheckinsScope(
      notifier: _checkinsStore,
      child: MaterialApp(
        title: 'Routine Mate',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          useMaterial3: true,
        ),
        home: const MainTabScreen(),
      ),
    );
  }
}
