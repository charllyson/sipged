// lib/_blocs/system/notification/notification_delivery.dart

import 'notification_channel.dart';

class NotificationDelivery {
  const NotificationDelivery({
    required this.channels,
  });

  final Set<NotificationChannel> channels;

  static const NotificationDelivery localOnly = NotificationDelivery(
    channels: {
      NotificationChannel.local,
    },
  );

  static const NotificationDelivery bellOnly = NotificationDelivery(
    channels: {
      NotificationChannel.bell,
    },
  );

  static const NotificationDelivery pushOnly = NotificationDelivery(
    channels: {
      NotificationChannel.push,
    },
  );

  static const NotificationDelivery emailOnly = NotificationDelivery(
    channels: {
      NotificationChannel.email,
    },
  );

  static const NotificationDelivery smsOnly = NotificationDelivery(
    channels: {
      NotificationChannel.sms,
    },
  );

  static const NotificationDelivery localAndBell = NotificationDelivery(
    channels: {
      NotificationChannel.local,
      NotificationChannel.bell,
    },
  );

  static const NotificationDelivery localAndPush = NotificationDelivery(
    channels: {
      NotificationChannel.local,
      NotificationChannel.push,
    },
  );

  static const NotificationDelivery bellAndPush = NotificationDelivery(
    channels: {
      NotificationChannel.bell,
      NotificationChannel.push,
    },
  );

  static const NotificationDelivery localBellAndPush = NotificationDelivery(
    channels: {
      NotificationChannel.local,
      NotificationChannel.bell,
      NotificationChannel.push,
    },
  );

  /// Compatibilidade com nomenclatura antiga.
  static const NotificationDelivery remoteOnly = bellOnly;

  /// Compatibilidade com nomenclatura antiga.
  static const NotificationDelivery localAndRemote = localAndBell;

  bool get showLocal => channels.contains(NotificationChannel.local);

  bool get saveInBell => channels.contains(NotificationChannel.bell);

  bool get sendPush => channels.contains(NotificationChannel.push);

  bool get sendEmail => channels.contains(NotificationChannel.email);

  bool get sendSms => channels.contains(NotificationChannel.sms);

  /// Compatibilidade com código antigo.
  bool get sendRemote => saveInBell;

  bool get hasRemoteChannel {
    return saveInBell || sendPush || sendEmail || sendSms;
  }

  bool get isEmpty => channels.isEmpty;

  bool get isNotEmpty => channels.isNotEmpty;

  NotificationDelivery copyWith({
    Set<NotificationChannel>? channels,
  }) {
    return NotificationDelivery(
      channels: channels ?? this.channels,
    );
  }

  NotificationDelivery add(NotificationChannel channel) {
    return NotificationDelivery(
      channels: {
        ...channels,
        channel,
      },
    );
  }

  NotificationDelivery addAll(Iterable<NotificationChannel> values) {
    return NotificationDelivery(
      channels: {
        ...channels,
        ...values,
      },
    );
  }

  NotificationDelivery remove(NotificationChannel channel) {
    return NotificationDelivery(
      channels: {
        ...channels.where((item) => item != channel),
      },
    );
  }

  NotificationDelivery withoutLocal() {
    return NotificationDelivery(
      channels: {
        ...channels.where((item) => item != NotificationChannel.local),
      },
    );
  }

  NotificationDelivery onlyLocal() {
    return const NotificationDelivery(
      channels: {
        NotificationChannel.local,
      },
    );
  }

  List<String> toListString() {
    final values = channels.map((item) => item.key).toList()..sort();

    return values;
  }

  Map<String, bool> toMap() {
    return NotificationChannelExtension.toMapFromSet(channels);
  }

  factory NotificationDelivery.fromChannels(
      Iterable<NotificationChannel> channels,
      ) {
    return NotificationDelivery(
      channels: channels.toSet(),
    );
  }

  factory NotificationDelivery.fromStrings(
      Iterable<String> values,
      ) {
    final channels = values
        .map(NotificationChannelExtension.tryFromString)
        .whereType<NotificationChannel>()
        .toSet();

    return NotificationDelivery(
      channels: channels,
    );
  }

  factory NotificationDelivery.fromMap(
      Map<String, dynamic>? map,
      ) {
    return NotificationDelivery(
      channels: NotificationChannelExtension.enabledSetFromMap(map),
    );
  }
}