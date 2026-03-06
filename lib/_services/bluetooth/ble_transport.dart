import 'ble_transport_stub.dart'
if (dart.library.html) 'ble_transport_web.dart'
if (dart.library.io) 'ble_transport_native.dart' as impl;

import 'ble_transport_iface.dart';

LabelBleTransport createBleTransport() => impl.createBleTransport();