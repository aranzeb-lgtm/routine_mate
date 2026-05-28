import 'package:flutter/material.dart';

import 'auth_gate.dart';

class RoutineMateApp extends StatelessWidget {
  const RoutineMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Routine Mate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
