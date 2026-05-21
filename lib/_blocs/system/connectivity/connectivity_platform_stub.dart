// lib/_blocs/system/connectivity/connectivity_platform_stub.dart

import 'dart:async';

Future<bool?> browserOnlineStatus() async {
  return null;
}

Stream<bool> browserOnlineChanges() {
  return const Stream<bool>.empty();
}