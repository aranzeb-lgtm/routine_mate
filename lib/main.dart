import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/routine_mate_app.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/firestore_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final user = await AuthRepository().signInAnonymouslyIfNeeded();
    final firestore = FirestoreRepository();
    await firestore.ensureUserDocument(user.uid);
    await firestore.ensureBaseDocuments(user.uid);

    runApp(const RoutineMateApp());
  } catch (e, stackTrace) {
    debugPrint('Initialization failed: $e\n$stackTrace');
    runApp(_InitErrorApp(error: e));
  }
}

class _InitErrorApp extends StatelessWidget {
  const _InitErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Routine Mate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 56,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '앱을 시작하지 못했어요',
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '앱을 다시 실행해 주세요.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
