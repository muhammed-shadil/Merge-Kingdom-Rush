import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A layered, depth-rich living scene: gradient sky, twinkling stars, drifting
/// aurora blobs, parallax mountain ridges, a castle silhouette and rising motes.
class AnimatedBackground extends StatefulWidget {
  final bool scenery;
  const AnimatedBackground({super.key, this.scenery = true});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  // Precomputed star + mote fields so they don't jump every frame.
  late final List<Offset> _stars;
  late final List<double> _starPhase;
  late final List<_Mote> _motes;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(7);
    _stars = List.generate(60, (_) => Offset(rnd.nextDouble(), rnd.nextDouble() * 0.7));
    _starPhase = List.generate(60, (_) => rnd.nextDouble());
    _motes = List.generate(
      18,
      (_) => _Mote(
        x: rnd.nextDouble(),
        speed: 0.05 + rnd.nextDouble() * 0.12,
        phase: rnd.nextDouble(),
        size: 1.5 + rnd.nextDouble() * 3,
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bg2, AppColors.bg1, AppColors.bg0],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _ScenePainter(
            t: _c.value,
            stars: _stars,
            starPhase: _starPhase,
            motes: _motes,
            scenery: widget.scenery,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Mote {
  final double x, speed, phase, size;
  _Mote({required this.x, required this.speed, required this.phase, required this.size});
}

class _ScenePainter extends CustomPainter {
  final double t;
  final List<Offset> stars;
  final List<double> starPhase;
  final List<_Mote> motes;
  final bool scenery;
  _ScenePainter({
    required this.t,
    required this.stars,
    required this.starPhase,
    required this.motes,
    required this.scenery,
  });

  void _blob(Canvas c, Size s, Color color, double phase, double r) {
    final a = (t + phase) * 2 * math.pi;
    final center = Offset(
      s.width * (0.5 + 0.42 * math.cos(a)),
      s.height * (0.35 + 0.28 * math.sin(a * 1.3)),
    );
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: r))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    c.drawCircle(center, r, paint);
  }

  void _ridge(Canvas c, Size s, double baseY, double amp, double step,
      Color color, double shift) {
    final path = Path()..moveTo(0, s.height);
    path.lineTo(0, baseY);
    for (double x = 0; x <= s.width; x += step) {
      final y = baseY - amp * (0.5 + 0.5 * math.sin(x / 90 + shift));
      path.lineTo(x, y);
    }
    path.lineTo(s.width, s.height);
    path.close();
    c.drawPath(path, Paint()..color = color);
  }

  @override
  void paint(Canvas c, Size s) {
    // Stars (upper region), gentle twinkle.
    final starPaint = Paint()..color = Colors.white;
    for (var i = 0; i < stars.length; i++) {
      final tw = 0.35 + 0.65 * (0.5 + 0.5 * math.sin((t + starPhase[i]) * 2 * math.pi));
      starPaint.color = Colors.white.withValues(alpha: 0.25 * tw);
      c.drawCircle(Offset(stars[i].dx * s.width, stars[i].dy * s.height), 1.4, starPaint);
    }

    // Aurora glow.
    _blob(c, s, AppColors.purple, 0.0, s.width * 0.55);
    _blob(c, s, AppColors.magenta, 0.35, s.width * 0.45);
    _blob(c, s, AppColors.cyan, 0.7, s.width * 0.5);

    if (scenery) {
      // Parallax mountain ridges + a little castle on the horizon.
      _ridge(c, s, s.height * 0.78, 46, 12, const Color(0xFF241150).withValues(alpha: 0.9), t * 2);
      _castle(c, s);
      _ridge(c, s, s.height * 0.86, 34, 12, const Color(0xFF160B34), t * 3 + 1);
    }

    // Rising light motes.
    final motePaint = Paint();
    for (final m in motes) {
      final prog = (t * m.speed * 8 + m.phase) % 1.0;
      final y = s.height * (1 - prog);
      final wob = math.sin((prog + m.phase) * 6.28) * 10;
      final alpha = (math.sin(prog * math.pi)).clamp(0.0, 1.0) * 0.5;
      motePaint.color = AppColors.cyan.withValues(alpha: alpha);
      c.drawCircle(Offset(m.x * s.width + wob, y), m.size, motePaint);
    }
  }

  void _castle(Canvas c, Size s) {
    final cx = s.width * 0.5;
    final baseY = s.height * 0.78;
    final col = Paint()..color = const Color(0xFF2E1A5E).withValues(alpha: 0.8);
    final w = s.width * 0.09;
    final h = s.height * 0.05;
    c.drawRect(Rect.fromLTWH(cx - w / 2, baseY - h, w, h), col);
    // battlements + towers
    for (final dx in [-w / 2, -w * 0.15, w * 0.35]) {
      c.drawRect(Rect.fromLTWH(cx + dx, baseY - h - 8, w * 0.16, 10), col);
    }
    // central spire
    final spire = Path()
      ..moveTo(cx - 8, baseY - h)
      ..lineTo(cx, baseY - h - 26)
      ..lineTo(cx + 8, baseY - h)
      ..close();
    c.drawPath(spire, Paint()..color = AppColors.magenta.withValues(alpha: 0.5));
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.t != t;
}

/// Frosted glass panel used for all HUD cards.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 22,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: (tint ?? Colors.white).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A juicy gradient button with a moving sheen and press-scale feedback.
class GlowButton extends StatefulWidget {
  final List<Color> gradient;
  final VoidCallback? onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GlowButton({
    super.key,
    required this.gradient,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  });

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();
  bool _down = false;

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.94 : 1,
        duration: const Duration(milliseconds: 90),
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.gradient),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: widget.gradient.last.withValues(alpha: enabled ? 0.5 : 0),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  widget.child,
                  if (enabled)
                    AnimatedBuilder(
                      animation: _sheen,
                      builder: (_, _) => Positioned(
                        left: -60 + _sheen.value * 260,
                        child: Transform.rotate(
                          angle: 0.4,
                          child: Container(
                            width: 34,
                            height: 120,
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                      ),
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

/// Number that smoothly rolls to its new value.
class AnimatedCounter extends StatelessWidget {
  final double value;
  final TextStyle style;
  const AnimatedCounter({super.key, required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: value, end: value),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (_, v, _) => Text(fmtLocal(v), style: style),
    );
  }

  static String fmtLocal(num n) {
    if (n >= 1e9) return '${(n / 1e9).toStringAsFixed(1)}B';
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}

/// One-shot radial particle burst (used on merge / summon).
class ParticleBurst extends StatefulWidget {
  final List<Color> colors;
  final VoidCallback? onDone;
  const ParticleBurst({super.key, required this.colors, this.onDone});

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final List<_P> _parts;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _parts = List.generate(14, (i) {
      final ang = (i / 14) * 2 * math.pi + rnd.nextDouble() * 0.4;
      return _P(
        angle: ang,
        speed: 26 + rnd.nextDouble() * 34,
        size: 3 + rnd.nextDouble() * 4,
        color: widget.colors[rnd.nextInt(widget.colors.length)],
      );
    });
    _c.forward().whenComplete(() => widget.onDone?.call());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) =>
            CustomPaint(painter: _BurstPainter(_parts, _c.value)),
      ),
    );
  }
}

class _P {
  final double angle, speed, size;
  final Color color;
  _P({required this.angle, required this.speed, required this.size, required this.color});
}

class _BurstPainter extends CustomPainter {
  final List<_P> parts;
  final double t;
  _BurstPainter(this.parts, this.t);

  @override
  void paint(Canvas c, Size s) {
    final center = Offset(s.width / 2, s.height / 2);
    final eased = Curves.easeOut.transform(t);
    for (final p in parts) {
      final d = p.speed * eased;
      final pos = center + Offset(math.cos(p.angle) * d, math.sin(p.angle) * d);
      final paint = Paint()
        ..color = p.color.withValues(alpha: (1 - t).clamp(0, 1));
      c.drawCircle(pos, p.size * (1 - t * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

/// A damage/reward number that floats up and fades out.
class FloatingText extends StatefulWidget {
  final String text;
  final Color color;
  final double fontSize;
  final VoidCallback? onDone;
  const FloatingText({
    super.key,
    required this.text,
    required this.color,
    this.fontSize = 20,
    this.onDone,
  });

  @override
  State<FloatingText> createState() => _FloatingTextState();
}

class _FloatingTextState extends State<FloatingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() => widget.onDone?.call());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final v = _c.value;
          return Transform.translate(
            offset: Offset(0, -46 * Curves.easeOut.transform(v)),
            child: Opacity(
              opacity: (1 - v * v).clamp(0, 1),
              child: Transform.scale(
                scale: 0.6 + Curves.elasticOut.transform(v.clamp(0, 1)) * 0.5,
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w900,
                    color: widget.color,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
