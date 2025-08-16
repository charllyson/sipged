import 'package:flutter/material.dart';

class SlideTransitionToast extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const SlideTransitionToast({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<SlideTransitionToast> createState() => _SlideTransitionToastState();
}

class _SlideTransitionToastState extends State<SlideTransitionToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 400),
    );

    _animation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    Future.delayed(widget.duration, () async {
      if (mounted) {
        await _controller.reverse();
        if (mounted) Navigator.of(context).pop();
      }
    });
  }

  void _dismissManually() async {
    if (mounted) {
      await _controller.reverse();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _dismissManually(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.close, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: _dismissManually,
        child: SlideTransition(
          position: _animation,
          child: widget.child,
        ),
      ),
    );
  }
}