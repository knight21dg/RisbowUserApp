import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/l10n/app_localizations.dart';

class Particle {
  Offset position;
  Offset velocity;
  Color color;
  double radius;
  double life;
  double maxLife;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.radius,
    required this.life,
  }) : maxLife = life;
}

class CustomCircularProgressIndicator extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final bool isLarge;
  final String? loadingText;
  final Color? color;
  final Animation<Color>? valueColor;

  const CustomCircularProgressIndicator({
    super.key,
    this.size = 30.0,
    this.strokeWidth = 3.5,
    this.isLarge = false,
    this.loadingText,
    this.color,
    this.valueColor,
  });

  @override
  State<CustomCircularProgressIndicator> createState() =>
      _CustomCircularProgressIndicatorState();
}

class _CustomCircularProgressIndicatorState
    extends State<CustomCircularProgressIndicator> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _rotationAngle = 0.0;
  double _speedMultiplier = 1.0;
  final List<Particle> _particles = [];
  int _currentTipIndex = 0;
  Timer? _tipTimer;

  static const List<String> _loadingTips = [
    "Picking the freshest greens from local farms...",
    "Securing hot deals from neighboring vendors...",
    "Summoning the speediest rider in your sector...",
    "Baking fresh goods from the closest bakery...",
    "Double checking expiry dates for your safety...",
    "Mapping out the fastest delivery corridors...",
    "Unlocking exclusive nearby store discounts...",
    "Verifying stock availability in real-time...",
  ];

  @override
  void initState() {
    super.initState();

    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      if (_lastElapsed == Duration.zero) {
        _lastElapsed = elapsed;
        return;
      }
      final double dt = (elapsed - _lastElapsed).inMilliseconds / 1000.0;
      _lastElapsed = elapsed;

      setState(() {
        // Rotate the spinner base speed + multiplier
        _rotationAngle += _speedMultiplier * dt * 2.0 * pi;
        if (_rotationAngle > 2 * pi) {
          _rotationAngle -= 2 * pi;
        }

        // Decay speed boost back to base speed (1.0)
        if (_speedMultiplier > 1.0) {
          _speedMultiplier -= dt * 4.0;
          if (_speedMultiplier < 1.0) {
            _speedMultiplier = 1.0;
          }
        }

        // Update particle life and positions
        for (int i = _particles.length - 1; i >= 0; i--) {
          final p = _particles[i];
          p.position += p.velocity * dt;
          p.life -= dt;
          if (p.life <= 0) {
            _particles.removeAt(i);
          }
        }
      });
    });
    _ticker.start();

    if (widget.isLarge) {
      _tipTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
        if (mounted) {
          setState(() {
            _currentTipIndex = (_currentTipIndex + 1) % _loadingTips.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tipTimer?.cancel();
    super.dispose();
  }

  void _triggerTapEffect() {
    HapticFeedback.lightImpact();
    setState(() {
      _speedMultiplier = 6.0; // Boost speed
      if (widget.isLarge) {
        // Cycle tip on tap
        _currentTipIndex = (_currentTipIndex + 1) % _loadingTips.length;
      }

      // Spawn colorful floating particles
      final random = Random();
      final colors = [
        AppTheme.primaryColor,
        AppTheme.orangeColor,
        Colors.tealAccent,
        Colors.purpleAccent,
        Colors.pinkAccent,
        Colors.amberAccent,
      ];
      final double maxRadius = widget.isLarge ? 5.0 : 3.0;

      for (int i = 0; i < 15; i++) {
        final angle = random.nextDouble() * 2 * pi;
        final speed = 30.0 + random.nextDouble() * 70.0;
        _particles.add(
          Particle(
            position: Offset.zero,
            velocity: Offset(cos(angle) * speed, sin(angle) * speed),
            color: colors[random.nextInt(colors.length)],
            radius: 1.5 + random.nextDouble() * maxRadius,
            life: 0.3 + random.nextDouble() * 0.4,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final spinnerColor = widget.color ?? widget.valueColor?.value ?? AppTheme.primaryColor;

    Widget spinner = SizedBox(
      width: widget.isLarge ? widget.size * 1.8 : widget.size,
      height: widget.isLarge ? widget.size * 1.8 : widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner pulsing image/icon
          Transform.scale(
            scale: 0.65 + (sin(_rotationAngle) * 0.15),
            child: Opacity(
              opacity: 0.8 + (cos(_rotationAngle) * 0.2),
              child: Image.asset(
                'assets/images/app_logos/app-logo-light.png',
                width: widget.isLarge ? widget.size : widget.size * 0.65,
                height: widget.isLarge ? widget.size : widget.size * 0.65,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.shopping_bag_outlined,
                  color: spinnerColor,
                  size: widget.isLarge ? widget.size : widget.size * 0.65,
                ),
              ),
            ),
          ),
          // Outer spinning ring and particles
          CustomPaint(
            size: Size(
              widget.isLarge ? widget.size * 1.8 : widget.size,
              widget.isLarge ? widget.size * 1.8 : widget.size,
            ),
            painter: SpinnerPainter(
              rotationAngle: _rotationAngle,
              particles: _particles,
              strokeWidth: widget.isLarge ? widget.strokeWidth * 1.3 : widget.strokeWidth,
              spinnerColor: spinnerColor,
            ),
          ),
        ],
      ),
    );

    if (widget.isLarge) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white.withValues(alpha: 0.85)
                : Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _triggerTapEffect,
                behavior: HitTestBehavior.opaque,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      spinner,
                      const SizedBox(height: 20),
                      Text(
                        widget.loadingText ?? AppLocalizations.of(context)?.loading ?? 'Loading...',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                height: 40,
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.3),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    _loadingTips[_currentTipIndex],
                    key: ValueKey<int>(_currentTipIndex),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _triggerTapEffect,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flash_on_rounded,
                      size: 13,
                      color: AppTheme.orangeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Tap spinner to boost speed! ⚡",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.orangeColor,
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

    return Center(
      child: GestureDetector(
        onTap: _triggerTapEffect,
        behavior: HitTestBehavior.opaque,
        child: spinner,
      ),
    );
  }
}

class SpinnerPainter extends CustomPainter {
  final double rotationAngle;
  final List<Particle> particles;
  final double strokeWidth;
  final Color spinnerColor;

  SpinnerPainter({
    required this.rotationAngle,
    required this.particles,
    required this.strokeWidth,
    required this.spinnerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    if (radius <= 0) return;

    // Draw glowing neon rotation ring
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          spinnerColor.withValues(alpha: 0.0),
          spinnerColor.withValues(alpha: 0.5),
          spinnerColor,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(rotationAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);

    // Draw particle explosions
    for (final p in particles) {
      final pPaint = Paint()
        ..color = p.color.withValues(alpha: p.life / p.maxLife)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center + p.position, p.radius, pPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SpinnerPainter oldDelegate) {
    return true; // Keep repainting while animated or active particles
  }
}
