import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

typedef SipgedPerfData = Map<String, Object?>;

class SipgedPerf {
  SipgedPerf._();

  static bool get enabled => kDebugMode;

  static T traceSync<T>(
      String label,
      T Function() action, {
        int warnMs = 8,
        SipgedPerfData? data,
        SipgedPerfData Function(T result)? resultData,
        bool logAlways = false,
      }) {
    if (!enabled) return action();

    final sw = Stopwatch()..start();
    var timelineStarted = false;

    try {
      developer.Timeline.startSync(label, arguments: data ?? const {});
      timelineStarted = true;

      final result = action();
      sw.stop();

      final elapsedMs = sw.elapsedMilliseconds;
      if (logAlways || elapsedMs >= warnMs) {
        final merged = <String, Object?>{
          if (data != null) ...data,
          if (resultData != null) ...resultData(result),
          'elapsedMs': elapsedMs,
        };

        debugPrint('[PERF] $label -> ${_formatData(merged)}');
      }

      return result;
    } catch (e, s) {
      sw.stop();

      final merged = <String, Object?>{
        if (data != null) ...data,
        'elapsedMs': sw.elapsedMilliseconds,
        'error': e.toString(),
      };

      debugPrint('[PERF][ERROR] $label -> ${_formatData(merged)}');
      debugPrint('$s');
      rethrow;
    } finally {
      if (timelineStarted) {
        try {
          developer.Timeline.finishSync();
        } catch (_) {
          // evita quebrar fluxo em debug
        }
      }
    }
  }

  static Future<T> traceAsync<T>(
      String label,
      Future<T> Function() action, {
        int warnMs = 8,
        SipgedPerfData? data,
        SipgedPerfData Function(T result)? resultData,
        bool logAlways = false,
      }) async {
    if (!enabled) return action();

    final sw = Stopwatch()..start();
    var timelineStarted = false;

    try {
      developer.Timeline.startSync(label, arguments: data ?? const {});
      timelineStarted = true;

      final result = await action();
      sw.stop();

      final elapsedMs = sw.elapsedMilliseconds;
      if (logAlways || elapsedMs >= warnMs) {
        final merged = <String, Object?>{
          if (data != null) ...data,
          if (resultData != null) ...resultData(result),
          'elapsedMs': elapsedMs,
        };

        debugPrint('[PERF] $label -> ${_formatData(merged)}');
      }

      return result;
    } catch (e, s) {
      sw.stop();

      final merged = <String, Object?>{
        if (data != null) ...data,
        'elapsedMs': sw.elapsedMilliseconds,
        'error': e.toString(),
      };

      debugPrint('[PERF][ERROR] $label -> ${_formatData(merged)}');
      debugPrint('$s');
      rethrow;
    } finally {
      if (timelineStarted) {
        try {
          developer.Timeline.finishSync();
        } catch (_) {
          // evita quebrar fluxo em debug
        }
      }
    }
  }

  static void log(
      String label, {
        SipgedPerfData? data,
      }) {
    if (!enabled) return;
    debugPrint(
      '[PERF] $label${data == null || data.isEmpty ? '' : ' -> ${_formatData(data)}'}',
    );
  }

  static void warn(
      String label, {
        SipgedPerfData? data,
      }) {
    if (!enabled) return;
    debugPrint(
      '[PERF][WARN] $label${data == null || data.isEmpty ? '' : ' -> ${_formatData(data)}'}',
    );
  }

  static void error(
      String label, {
        SipgedPerfData? data,
        Object? error,
        StackTrace? stackTrace,
      }) {
    if (!enabled) return;

    final merged = <String, Object?>{
      if (data != null) ...data,
      if (error != null) 'error': error.toString(),
    };

    debugPrint(
      '[PERF][ERROR] $label${merged.isEmpty ? '' : ' -> ${_formatData(merged)}'}',
    );

    if (stackTrace != null) {
      debugPrint('$stackTrace');
    }
  }

  static String _formatData(SipgedPerfData data) {
    if (data.isEmpty) return '{}';

    final keys = data.keys.toList()..sort();
    return keys.map((k) => '$k=${data[k]}').join(', ');
  }
}