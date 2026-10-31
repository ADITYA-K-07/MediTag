import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Fades and lifts each child in, one after another (matches the website's .mt-stagger).
class Stagger extends StatelessWidget {
  const Stagger({super.key, required this.children, this.gap = 14, this.step = const Duration(milliseconds: 60)});

  final List<Widget> children;
  final double gap;
  final Duration step;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          reduce ? children[i] : _Rise(delay: step * i, child: children[i]),
        ],
      ],
    );
  }
}

class _Rise extends StatefulWidget {
  const _Rise({required this.delay, required this.child});
  final Duration delay;
  final Widget child;

  @override
  State<_Rise> createState() => _RiseState();
}

class _RiseState extends State<_Rise> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final _t = CurvedAnimation(parent: _c, curve: MtMotion.easing);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () => mounted ? _c.forward() : null);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _t,
        child: SlideTransition(position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(_t), child: widget.child),
      );
}

/// Expanding rings behind the scan button while the reader is listening.
class PulseRings extends StatefulWidget {
  const PulseRings({super.key, required this.color, this.size = 150, this.rings = 3});
  final Color color;
  final double size;
  final int rings;

  @override
  State<PulseRings> createState() => _PulseRingsState();
}

class _PulseRingsState extends State<PulseRings> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < widget.rings; i++)
              Builder(builder: (context) {
                final t = (_c.value + i / widget.rings) % 1;
                return Transform.scale(
                  scale: 0.45 + t * 1.05,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.color.withValues(alpha: 0.6 * (1 - t)), width: 2),
                    ),
                  ),
                );
              }),
          ],
        ),
      );
}
