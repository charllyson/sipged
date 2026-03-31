/*
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class GeoPerf {
  GeoPerf._();

  static bool enabled = kDebugMode;

  static final Map<String, Stopwatch> _timers = <String, Stopwatch>{};
  static final Map<String, int> _counters = <String, int>{};
  static final Map<String, Object?> _lastValues = <String, Object?>{};

  static bool _frameTrackingAttached = false;
  static TimingsCallback? _frameCallback;

  static const int _sampleEveryCount = 30;

  static void start(String key) {
    if (!enabled) return;
    _timers[key] = Stopwatch()..start();
  }

  static void end(String key, {String? details, double minMsToLog = 0.0}) {
    if (!enabled) return;

    final sw = _timers.remove(key);
    if (sw == null) return;

    sw.stop();
    final ms = sw.elapsedMicroseconds / 1000.0;
    if (ms < minMsToLog) return;

    dev.log(
      details == null
          ? '[PERF] $key: ${ms.toStringAsFixed(2)} ms'
          : '[PERF] $key: ${ms.toStringAsFixed(2)} ms | $details',
      name: 'GEO_PERF',
    );
  }

  static T measure<T>(
      String key,
      T Function() fn, {
        String? details,
        double minMsToLog = 0.0,
      }) {
    if (!enabled) return fn();

    final sw = Stopwatch()..start();
    final result = fn();
    sw.stop();

    final ms = sw.elapsedMicroseconds / 1000.0;
    if (ms >= minMsToLog) {
      dev.log(
        details == null
            ? '[PERF] $key: ${ms.toStringAsFixed(2)} ms'
            : '[PERF] $key: ${ms.toStringAsFixed(2)} ms | $details',
        name: 'GEO_PERF',
      );
    }

    return result;
  }

  static Future<T> measureAsync<T>(
      String key,
      Future<T> Function() fn, {
        String? details,
        double minMsToLog = 0.0,
      }) async {
    if (!enabled) return fn();

    final sw = Stopwatch()..start();
    final result = await fn();
    sw.stop();

    final ms = sw.elapsedMicroseconds / 1000.0;
    if (ms >= minMsToLog) {
      dev.log(
        details == null
            ? '[PERF] $key: ${ms.toStringAsFixed(2)} ms'
            : '[PERF] $key: ${ms.toStringAsFixed(2)} ms | $details',
        name: 'GEO_PERF',
      );
    }

    return result;
  }

  static void count(String key, {int increment = 1, bool sampled = true}) {
    if (!enabled) return;

    final next = (_counters[key] ?? 0) + increment;
    _counters[key] = next;

    if (!sampled || next % _sampleEveryCount == 0) {
      dev.log('[COUNT] $key: $next', name: 'GEO_PERF');
    }
  }

  static void mark(String message) {
    if (!enabled) return;
    dev.log('[MARK] $message', name: 'GEO_PERF');
  }

  static void value(String key, Object? value, {bool onlyIfChanged = true}) {
    if (!enabled) return;

    if (onlyIfChanged && _lastValues[key] == value) return;
    _lastValues[key] = value;

    dev.log('[VALUE] $key: $value', name: 'GEO_PERF');
  }

  static void attachFrameTimings() {
    if (!enabled || _frameTrackingAttached) return;

    _frameCallback = (List<FrameTiming> timings) {
      for (final timing in timings) {
        final buildMs = timing.buildDuration.inMicroseconds / 1000.0;
        final rasterMs = timing.rasterDuration.inMicroseconds / 1000.0;
        final totalMs = timing.totalSpan.inMicroseconds / 1000.0;

        if (totalMs >= 24) {
          dev.log(
            '[FRAME] total=${totalMs.toStringAsFixed(2)} ms | '
                'build=${buildMs.toStringAsFixed(2)} ms | '
                'raster=${rasterMs.toStringAsFixed(2)} ms',
            name: 'GEO_PERF',
          );
        }

        if (totalMs >= 40) {
          dev.log(
            '[JANK] frame_lenta total=${totalMs.toStringAsFixed(2)} ms | '
                'build=${buildMs.toStringAsFixed(2)} ms | '
                'raster=${rasterMs.toStringAsFixed(2)} ms',
            name: 'GEO_PERF',
          );
        }
      }
    };

    SchedulerBinding.instance.addTimingsCallback(_frameCallback!);
    _frameTrackingAttached = true;
    mark('FRAME_TIMINGS_ATTACHED');
  }

  static void detachFrameTimings() {
    if (!_frameTrackingAttached || _frameCallback == null) return;

    SchedulerBinding.instance.removeTimingsCallback(_frameCallback!);
    _frameTrackingAttached = false;
    _frameCallback = null;
    mark('FRAME_TIMINGS_DETACHED');
  }
}*/
