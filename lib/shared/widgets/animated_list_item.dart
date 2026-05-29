import 'package:flutter/material.dart';

/// Staggered fade + slide from left for list rows (runs once per mount).
class AnimatedListItem extends StatefulWidget {
  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.delayStepMs = 28,
    this.maxDelayMs = 168,
    this.slideOffset = 22,
    this.durationMs = 260,
  });

  final int index;
  final Widget child;
  final int delayStepMs;
  final int maxDelayMs;
  final double slideOffset;
  final int durationMs;

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _dx;
  var _showChild = false;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.65, curve: Curves.easeOut),
    );
    _dx = Tween<double>(begin: -widget.slideOffset, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _scheduleAnimation();
  }

  void _scheduleAnimation() {
    final delayMs = (widget.index * widget.delayStepMs)
        .clamp(0, widget.maxDelayMs)
        .toInt();

    if (!_animationsEnabled) {
      _showChild = true;
      _controller.value = 1.0;
      return;
    }

    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      if (!_animationsEnabled) {
        setState(() {
          _showChild = true;
          _controller.value = 1.0;
        });
        return;
      }
      _controller.forward();
    });

    Future<void>.delayed(
      Duration(milliseconds: delayMs + widget.durationMs + 80),
      () {
        if (!mounted || _controller.isCompleted) return;
        setState(() {
          _showChild = true;
          _controller.value = 1.0;
        });
      },
    );
  }

  bool get _animationsEnabled => TickerMode.valuesOf(context).enabled;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showChild || _controller.isCompleted) {
      return widget.child;
    }

    if (!_animationsEnabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(_dx.value, 0),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Wraps [children] with staggered entrance — use for static lists.
class AnimatedListColumn extends StatelessWidget {
  const AnimatedListColumn({
    super.key,
    required this.children,
    this.delayStepMs = 28,
    this.maxDelayMs = 168,
  });

  final List<Widget> children;
  final int delayStepMs;
  final int maxDelayMs;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++)
          AnimatedListItem(
            index: i,
            delayStepMs: delayStepMs,
            maxDelayMs: maxDelayMs,
            child: children[i],
          ),
      ],
    );
  }
}
