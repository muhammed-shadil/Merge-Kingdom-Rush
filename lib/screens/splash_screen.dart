import 'package:flutter/material.dart';
import '../models/game_data.dart';
import '../services/audio_service.dart';
import '../services/save_service.dart';
import '../theme/app_theme.dart';
import '../widgets/effects.dart';
import 'menu_screen.dart';

/// Animated logo splash. Loads the save + settings, computes offline earnings,
/// then hands off to the menu.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final results = await Future.wait([
      SaveService.load(),
      SaveService.loadSfx(),
      Future.delayed(const Duration(milliseconds: 1600)),
    ]);
    final data = results[0] as GameData;
    Sfx.enabled = results[1] as bool;

    final offline = SaveService.offlineGold(data);
    if (offline > 0) data.gold += offline;
    // Persist immediately so the offline window closes.
    await SaveService.save(data);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, a, _) => FadeTransition(
          opacity: a,
          child: MenuScreen(data: data, offlineGold: offline),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _logo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          AnimatedBuilder(
            animation: _logo,
            builder: (_, _) {
              final pop = Curves.elasticOut.transform(_logo.value.clamp(0, 1));
              final fade = Curves.easeIn.transform(_logo.value.clamp(0, 1));
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: pop,
                    child: Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.purple, AppColors.magenta],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.magenta.withValues(alpha: 0.6),
                            blurRadius: 40,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Text('👑', style: TextStyle(fontSize: 64)),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Opacity(
                    opacity: fade,
                    child: const Text(
                      'MERGE KINGDOM',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Opacity(
                    opacity: fade * 0.8,
                    child: const Text(
                      'RUSH',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 10,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Opacity(
                    opacity: fade * 0.7,
                    child: const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
