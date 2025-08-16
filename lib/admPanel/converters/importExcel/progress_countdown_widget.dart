import 'dart:async';
import 'package:flutter/material.dart';

class ProgressCountdownWidget extends StatefulWidget {
  final int durationSeconds; // duração total
  final void Function()? onFinish;

  const ProgressCountdownWidget({
    super.key,
    required this.durationSeconds,
    this.onFinish,
  });

  @override
  State<ProgressCountdownWidget> createState() => _ProgressCountdownWidgetState();
}

class _ProgressCountdownWidgetState extends State<ProgressCountdownWidget> {
  late Timer _timer;
  late int _remainingSeconds;
  late double _progressValue;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _remainingSeconds = widget.durationSeconds;
    _progressValue = 1.0;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        _progressValue = _remainingSeconds / widget.durationSeconds;

        if (_remainingSeconds <= 0) {
          _timer.cancel();
          _progressValue = 0;
          if (widget.onFinish != null) widget.onFinish!();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(
          value: _progressValue,
          minHeight: 8,
          backgroundColor: Colors.grey.shade300,
          color: Colors.blueAccent,
        ),
        const SizedBox(height: 8),
        Text(
          'Tempo restante: $_remainingSeconds s',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
