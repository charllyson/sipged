// lib/_blocs/system/connectivity/connectivity_platform_web.dart

import 'dart:async';
import 'dart:html' as html;

Future<bool?> browserOnlineStatus() async {
  return html.window.navigator.onLine;
}

Stream<bool> browserOnlineChanges() {
  final controller = StreamController<bool>.broadcast();

  StreamSubscription<html.Event>? onlineSub;
  StreamSubscription<html.Event>? offlineSub;

  controller.onListen = () {
    onlineSub = html.window.onOnline.listen((_) {
      controller.add(true);
    });

    offlineSub = html.window.onOffline.listen((_) {
      controller.add(false);
    });
  };

  controller.onCancel = () async {
    await onlineSub?.cancel();
    await offlineSub?.cancel();

    onlineSub = null;
    offlineSub = null;
  };

  return controller.stream;
}