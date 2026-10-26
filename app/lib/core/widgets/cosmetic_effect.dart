import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Decorative effects remain outside the avatar's face and title text.
class CosmeticEffect extends StatefulWidget {
  const CosmeticEffect({super.key, required this.child, required this.color, this.circular = false});
  final Widget child;
  final Color color;
  final bool circular;
  @override
  State<CosmeticEffect> createState() => _CosmeticEffectState();
}

class _CosmeticEffectState extends State<CosmeticEffect> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion = AnimationController(vsync: this, duration: const Duration(seconds: 4));
  Timer? _pause;
  bool _enabled = false;
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _motion.addStatusListener((status) {
      if (status == AnimationStatus.completed && _enabled && _foreground) {
        _pause = Timer(const Duration(seconds: 2), () {
          if (mounted && _enabled && _foreground) _motion.forward(from: 0);
        });
      }
    });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _enabled = !MediaQuery.disableAnimationsOf(context) && TickerMode.valuesOf(context).enabled;
    _sync();
  }
  void _sync() {
    _pause?.cancel();
    if (_enabled && _foreground) {
      _motion.forward(from: 0);
    } else {
      _motion.stop();
      _motion.value = 0;
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pause?.cancel();
    _motion.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => RepaintBoundary(child: CustomPaint(
    foregroundPainter: _AuraPainter(_motion, widget.color, widget.circular),
    child: widget.child,
  ));
}

class _AuraPainter extends CustomPainter {
  _AuraPainter(this.motion, this.color, this.circular) : super(repaint: motion);
  final Animation<double> motion;
  final Color color;
  final bool circular;
  @override
  void paint(Canvas canvas, Size size) {
    final t = motion.value;
    if (t <= 0 || t >= 1 || size.isEmpty) return;
    final fade = math.sin(math.pi * t);
    final center = size.center(Offset.zero);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4;
    if (circular) {
      final radius = size.shortestSide * .35;
      final rect = Rect.fromCircle(center: center, radius: radius);
      for (var i = 0; i < 2; i++) {
        final angle = t * math.pi * 2 + i * math.pi;
        paint.shader = SweepGradient(
          startAngle: 0, endAngle: math.pi * 2,
          colors: [color.withValues(alpha: 0), Colors.white.withValues(alpha: .85 * fade), color.withValues(alpha: 0)],
          stops: const [0, .16, .32], transform: GradientRotation(angle),
        ).createShader(rect);
        canvas.drawArc(rect, angle, 1.05, false, paint);
        paint.shader = null;
        final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
        _spark(canvas, point, size.shortestSide * .025, fade);
      }
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 2 + .5;
        final pulse = fade * (.5 + .5 * math.sin(t * math.pi * 4 + i));
        _spark(canvas, center + Offset(math.cos(a), math.sin(a)) * (radius * 1.18), size.shortestSide * .018, pulse);
      }
    } else {
      final rect = Offset.zero & size;
      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)));
      // Light travels along the metal edges, never across the label.
      final x = size.width * (t * 1.4 - .2);
      final p = Paint()..shader = RadialGradient(colors: [Colors.white.withValues(alpha: .9 * fade), color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: Offset(x, 2), radius: 26));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 3), p);
      p.shader = RadialGradient(colors: [Colors.white.withValues(alpha: .7 * fade), color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: Offset(size.width-x, size.height-2), radius: 24));
      canvas.drawRect(Rect.fromLTWH(0, size.height-3, size.width, 3), p);
      canvas.restore();
    }
  }
  void _spark(Canvas canvas, Offset p, double r, double alpha) {
    final path = Path()..moveTo(p.dx, p.dy-r*2)..lineTo(p.dx+r*.45,p.dy-r*.4)..lineTo(p.dx+r*1.5,p.dy)..lineTo(p.dx+r*.45,p.dy+r*.4)..lineTo(p.dx,p.dy+r*2)..lineTo(p.dx-r*.45,p.dy+r*.4)..lineTo(p.dx-r*1.5,p.dy)..lineTo(p.dx-r*.45,p.dy-r*.4)..close();
    canvas.drawCircle(p, r*2, Paint()..color=color.withValues(alpha: alpha*.35)..maskFilter=const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawPath(path, Paint()..color=Colors.white.withValues(alpha: alpha.clamp(0,1)));
  }
  @override
  bool shouldRepaint(covariant _AuraPainter old) => old.color != color || old.circular != circular || old.motion != motion;
}
