import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/game_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MergeKingdomApp());
}

class MergeKingdomApp extends StatelessWidget {
  const MergeKingdomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Merge Kingdom Rush',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const GameScreen(),
    );
  }
}
