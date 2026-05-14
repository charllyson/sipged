// lib/_utils/debug/sipged_perf_log.dart

import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

class SipGedPerfLog {
  const SipGedPerfLog._();

  static bool enabled = kDebugMode;

  static T measure<T>(
      String label,
      T Function() action, {
        int warnAboveMs = 12,
      }) {
    if (!enabled) {
      return action();
    }

    final sw = Stopwatch()..start();

    try {
      return action();
    } finally {
      sw.stop();

      final ms = sw.elapsedMilliseconds;

      if (ms >= warnAboveMs) {
        debugPrint('⚠️ PERF [$label] ${ms}ms');
      }
    }
  }

  static Future<T> measureAsync<T>(
      String label,
      Future<T> Function() action, {
        int warnAboveMs = 80,
      }) async {
    if (!enabled) {
      return action();
    }

    final sw = Stopwatch()..start();

    try {
      return await action();
    } finally {
      sw.stop();

      final ms = sw.elapsedMilliseconds;

      if (ms >= warnAboveMs) {
        debugPrint('⚠️ PERF ASYNC [$label] ${ms}ms');
      }
    }
  }

  static void event(
      String label, {
        Map<String, Object?> data = const <String, Object?>{},
      }) {
    if (!enabled) return;

    dev.log(
      data.isEmpty ? label : '$label | $data',
      name: 'SIPGED_PERF',
    );
  }
}