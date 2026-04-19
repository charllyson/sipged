library;

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class SwitchChange extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String textOff;
  final String textOn;
  final Color colorOn;
  final Color colorOff;
  final double textSize;
  final Duration animationDuration;
  final IconData iconOn;
  final IconData iconOff;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onSwipe;

  const SwitchChange({
    super.key,
    this.value = false,
    this.textOff = 'OFF',
    this.textOn = 'ON',
    this.textSize = 12.0,
    this.colorOn = Colors.green,
    this.colorOff = Colors.red,
    this.iconOff = Icons.remove_circle_outline,
    this.iconOn = Icons.done,
    this.animationDuration = const Duration(milliseconds: 1),
    this.onTap,
    this.onDoubleTap,
    this.onSwipe,
    this.onChanged,
  });

  @override
  State<SwitchChange> createState() => _SwitchChangeState();
}

class _SwitchChangeState extends State<SwitchChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  late final Animation<double> animation;

  double value = 0.0;
  late bool turnState;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    );

    animationController.addListener(() {
      if (!mounted) return;
      setState(() {
        value = animation.value;
      });
    });

    turnState = widget.value;
    _determine();
  }

  @override
  void didUpdateWidget(covariant SwitchChange oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      turnState = widget.value;
      _determine(notify: false);
    }

    if (oldWidget.animationDuration != widget.animationDuration) {
      animationController.duration = widget.animationDuration;
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color? transitionColor =
    Color.lerp(widget.colorOff, widget.colorOn, value);

    return GestureDetector(
      onDoubleTap: () {
        _action();
        widget.onDoubleTap?.call();
      },
      onTap: () {
        _action();
        widget.onTap?.call();
      },
      onPanEnd: (_) {
        _action();
        widget.onSwipe?.call();
      },
      child: Container(
        padding: const EdgeInsets.only(left: 3),
        width: 70,
        height: 30,
        decoration: BoxDecoration(
          color: transitionColor,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Stack(
          children: <Widget>[
            Transform.translate(
              offset: Offset(10 * value, 0),
              child: Opacity(
                opacity: (1 - value).clamp(0.0, 1.0),
                child: Container(
                  padding: const EdgeInsets.only(right: 10),
                  alignment: Alignment.centerRight,
                  height: 30,
                  child: Text(
                    widget.textOff,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: widget.textSize,
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(10 * (1 - value), 0),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Container(
                  padding: const EdgeInsets.only(left: 5),
                  alignment: Alignment.centerLeft,
                  height: 30,
                  child: Text(
                    widget.textOn,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: widget.textSize,
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(38 * value, 0),
              child: Transform.rotate(
                angle: lerpDouble(0, 2 * pi, value) ?? 0.0,
                child: Container(
                  height: 30,
                  width: 25,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Stack(
                    children: <Widget>[
                      Center(
                        child: Opacity(
                          opacity: (1 - value).clamp(0.0, 1.0),
                          child: Icon(
                            widget.iconOff,
                            size: 25,
                            color: transitionColor,
                          ),
                        ),
                      ),
                      Center(
                        child: Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: Icon(
                            widget.iconOn,
                            size: 17,
                            color: transitionColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _action() {
    _determine(changeState: true);
  }

  void _determine({
    bool changeState = false,
    bool notify = true,
  }) {
    if (changeState) {
      turnState = !turnState;
    }

    if (turnState) {
      animationController.forward();
    } else {
      animationController.reverse();
    }

    if (notify) {
      widget.onChanged?.call(turnState);
    }
  }
}