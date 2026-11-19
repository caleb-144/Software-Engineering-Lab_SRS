import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Shows an animated logo while the app starts, then fades into [child].
/// It stays for at least [minimum] so the animation can play, and longer if the app is
/// still loading.
class SplashGate extends StatefulWidget {
  final Widget child;
  final Duration minimum;
  const SplashGate({super.key, required this.child, this.minimum = const Duration(milliseconds: 2400)});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _timeUp = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.minimum, () {
      if (mounted) setState(() => _timeUp = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = context.select<AppState, bool>((s) => s.ready);
    final showApp = ready && _timeUp;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: showApp
          ? KeyedSubtree(key: const ValueKey('app'), child: widget.child)
          : const _Splash(key: ValueKey('splash')),
    );
  }
}

class _Splash extends StatefulWidget {
  const _Splash({super.key});

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> with TickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  late final AnimationController _dots =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  late final Animation<double> _scale =
      CurvedAnimation(parent: _intro, curve: Curves.elasticOut);
  late final Animation<double> _fade =
      CurvedAnimation(parent: _intro, curve: const Interval(0, 0.5, curve: Curves.easeOut));
  late final Animation<double> _tagline =
      CurvedAnimation(parent: _intro, curve: const Interval(0.5, 1, curve: Curves.easeOut));

  @override
  void dispose() {
    _intro.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.cream,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: const Logo(height: 96),
              ),
            ),
            const SizedBox(height: 14),
            FadeTransition(
              opacity: _tagline,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
                    .animate(_tagline),
                child: const Text(
                  'Fresh  -  Sweet  -  Flavourful',
                  style: TextStyle(
                      color: Brand.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 36),
            AnimatedBuilder(
              animation: _dots,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Opacity(
                        opacity: _dotOpacity(i),
                        child: const CircleAvatar(radius: 5, backgroundColor: Brand.primary),
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

  /// Three dots that light up one after the other.
  double _dotOpacity(int i) {
    final t = (_dots.value - i * 0.2) % 1.0;
    return t < 0.4 ? 1.0 - (t / 0.4) * 0.65 : 0.35;
  }
}
