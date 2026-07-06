import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Slow-moving aurora blobs behind everything for a premium, alive background.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

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
          colors: [AppColors.bg1, AppColors.bg0],
        ),
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) =>
            CustomPaint(painter: _AuroraPainter(_c.value), size: Size.infinite),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t;
  _AuroraPainter(this.t);

  void _blob(Canvas c, Size s, Color color, double phase, double r) {
    final a = (t + phase) * 2 * math.pi;
    final center = Offset(
      s.width * (0.5 + 0.42 * math.cos(a)),
      s.height * (0.4 + 0.32 * math.sin(a * 1.3)),
    );
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: r))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    c.drawCircle(center, r, paint);
  }

  @override
  void paint(Canvas c, Size s) {
    _blob(c, s, AppColors.purple, 0.0, s.width * 0.55);
    _blob(c, s, AppColors.magenta, 0.35, s.width * 0.45);
    _blob(c, s, AppColors.cyan, 0.7, s.width * 0.5);
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t;
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
