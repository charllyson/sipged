// lib/_blocs/system/connectivity/connectivity_platform_web.dart

import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<bool?> browserOnlineStatus() async {
  return web.window.navigator.onLine;
}

Stream<bool> browserOnlineChanges() {
  late final StreamController<bool> controller;

  JSExportedDartFunction? onlineCallback;
  JSExportedDartFunction? offlineCallback;

  controller = StreamController<bool>.broadcast(
    onListen: () {
      onlineCallback = (() {
        if (!controller.isClosed) {
          controller.add(true);
        }
      }).toJS;

      offlineCallback = (() {
        if (!controller.isClosed) {
          controller.add(false);
        }
      }).toJS;

      web.window.addEventListener(
        'online',
        onlineCallback,
      );

      web.window.addEventListener(
        'offline',
        offlineCallback,
      );
    },
    onCancel: () {
      final online = onlineCallback;
      final offline = offlineCallback;

      if (online != null) {
        web.window.removeEventListener(
          'online',
          online,
        );
      }

      if (offline != null) {
        web.window.removeEventListener(
          'offline',
          offline,
        );
      }

      onlineCallback = null;
      offlineCallback = null;
    },
  );

  return controller.stream;
}