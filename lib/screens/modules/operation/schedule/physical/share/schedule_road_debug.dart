import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class ScheduleRoadDebug {
  static const bool enabled = true;

  /// Use true se quiser ver rebuilds.
  static const bool enableRebuildLogs = true;

  /// Use false para silenciar GridRow, que gera MUITO log.
  static const bool enableGridRowLogs = false;

  /// Use false para silenciar Grid.
  static const bool enableGridLogs = true;

  /// Use false para silenciar Map.
  static const bool enableMapLogs = true;

  /// Use false para silenciar Board.
  static const bool enableBoardLogs = true;

  static int _seq = 0;

  static bool _shouldLogScope(String scope) {
    final normalized = scope.trim().toLowerCase();

    if (normalized == 'gridrow') return enableGridRowLogs;
    if (normalized == 'grid') return enableGridLogs;
    if (normalized == 'map') return enableMapLogs;
    if (normalized == 'board') return enableBoardLogs;
    if (normalized == 'boardgridview') return enableBoardLogs;

    return true;
  }

  static void log(String scope, String message) {
    if (!enabled) return;
    if (!_shouldLogScope(scope)) return;

    final text = '[ScheduleRoad][$scope] $message';

    // Evita duplicar no console.
    if (kDebugMode) {
      debugPrint(text);
      return;
    }

    developer.log(text, name: 'ScheduleRoad');
  }

  static void rebuild(String scope, String message) {
    if (!enableRebuildLogs) return;
    log(scope, 'rebuild => $message');
  }

  static int start(String scope, String message) {
    final id = ++_seq;
    log(scope, 'START #$id $message');
    return id;
  }

  static void end(
      String scope,
      int id,
      String message, {
        Stopwatch? watch,
      }) {
    final took = watch != null ? ' (${watch.elapsedMilliseconds} ms)' : '';
    log(scope, 'END   #$id $message$took');
  }

  static Future<T> trackAsync<T>(
      String scope,
      String message,
      Future<T> Function() action,
      ) async {
    final id = start(scope, message);
    final sw = Stopwatch()..start();
    try {
      return await action();
    } finally {
      sw.stop();
      end(scope, id, message, watch: sw);
    }
  }

  static T trackSync<T>(
      String scope,
      String message,
      T Function() action,
      ) {
    final id = start(scope, message);
    final sw = Stopwatch()..start();
    try {
      return action();
    } finally {
      sw.stop();
      end(scope, id, message, watch: sw);
    }
  }
}