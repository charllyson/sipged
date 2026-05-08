import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/system/notification/helpers/notification_contract_base.dart';
import 'package:sipged/_blocs/system/notification/notification_channel.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_source.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

enum NotificationPaymentKind {
  bulletin,
  adjustment,
  revision,
}

extension NotificationPaymentKindExtension on NotificationPaymentKind {
  String get sourceKey {
    switch (this) {
      case NotificationPaymentKind.bulletin:
        return NotificationSubSource.paymentsBulletin.key;
      case NotificationPaymentKind.adjustment:
        return NotificationSubSource.paymentsAdjustments.key;
      case NotificationPaymentKind.revision:
        return NotificationSubSource.paymentsRevision.key;
    }
  }

  String get label {
    switch (this) {
      case NotificationPaymentKind.bulletin:
        return 'Pagamento de medição';
      case NotificationPaymentKind.adjustment:
        return 'Pagamento de reajuste';
      case NotificationPaymentKind.revision:
        return 'Pagamento de revisão';
    }
  }

  String get measurementKind {
    switch (this) {
      case NotificationPaymentKind.bulletin:
        return 'bulletin';
      case NotificationPaymentKind.adjustment:
        return 'adjustment';
      case NotificationPaymentKind.revision:
        return 'revision';
    }
  }

  String get module {
    switch (this) {
      case NotificationPaymentKind.bulletin:
        return 'operation_measurements';
      case NotificationPaymentKind.adjustment:
        return 'operation_measurements_adjustments';
      case NotificationPaymentKind.revision:
        return 'operation_measurements_revisions';
    }
  }

  String get defaultSource {
    switch (this) {
      case NotificationPaymentKind.bulletin:
        return 'payment_measurement_notification';
      case NotificationPaymentKind.adjustment:
        return 'payment_adjustment_measurement_notification';
      case NotificationPaymentKind.revision:
        return 'payment_revision_measurement_notification';
    }
  }
}

class NotificationPayments {
  const NotificationPayments._();

  static Future<void> show({
    required BuildContext context,
    required ContractData contract,
    required String title,
    String? subtitle,
    String? details,
    String? leadingLabel,
    String? module,

    NotificationPaymentKind kind = NotificationPaymentKind.bulletin,

    NotificationStatus status = NotificationStatus.info,

    /// Compatibilidade com chamadas que ainda usam type.
    NotificationStatus? type,

    Duration duration = const Duration(seconds: 5),

    bool saveInBell = false,
    bool sendPush = false,

    NotificationDelivery? delivery,
    Set<NotificationChannel>? channels,

    String? actorId,
    String? actorName,
    Iterable<String> targetUserIds = const <String>[],
    bool includeCurrentUser = true,
    bool global = false,

    String? source,
    String? sourceKey,
    String? notificationSource,

    String? measurementId,
    String? measurementNumber,
    String? measurementOrder,
    DateTime? measurementDate,
    num? measurementValue,

    String? paymentId,
    String? paymentOrder,
    DateTime? paymentDate,
    num? paymentValue,
    num? paymentTotalValue,
    num? paymentNetValue,
    num? paymentGrossValue,

    String? paymentFundingSourceId,
    String? paymentFundingSourceLabel,

    num? inssPaymentValue,
    num? irpfPaymentValue,
    num? issPaymentValue,

    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    final resolvedSource = source?.trim().isNotEmpty == true
        ? source!.trim()
        : kind.defaultSource;

    final resolvedSourceKey = notificationSource?.trim().isNotEmpty == true
        ? notificationSource!.trim()
        : sourceKey?.trim().isNotEmpty == true
        ? sourceKey!.trim()
        : kind.sourceKey;

    final resolvedModule = module?.trim().isNotEmpty == true
        ? module!.trim()
        : kind.module;

    final resolvedLeadingLabel = leadingLabel?.trim().isNotEmpty == true
        ? leadingLabel!.trim()
        : kind.label;

    await NotificationContractBase.show(
      context: context,
      contract: contract,
      title: title,
      subtitle: subtitle,
      details: details,
      leadingLabel: resolvedLeadingLabel,
      module: resolvedModule,
      status: status,
      type: type,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      delivery: delivery,
      channels: channels,
      actorId: actorId,
      actorName: actorName,
      targetUserIds: targetUserIds,
      includeCurrentUser: includeCurrentUser,
      global: global,
      source: resolvedSource,
      sourceKey: resolvedSourceKey,
      defaultModule: kind.module,
      defaultLeadingLabel: kind.label,
      extra: <String, dynamic>{
        ...extra,

        'source': resolvedSource,
        'sourceKey': resolvedSourceKey,
        'subSource': resolvedSourceKey,
        'notificationSource': resolvedSourceKey,
        'module': resolvedModule,

        'paymentKind': kind.name,
        'paymentKindLabel': kind.label,

        'measurementKind': kind.measurementKind,
        'measurementKindLabel': kind.label,

        'measurementId': measurementId,
        'measurementNumber': measurementNumber,
        'measurementOrder': measurementOrder,
        'measurementDate': measurementDate?.toIso8601String(),
        'measurementValue': measurementValue,

        'paymentId': paymentId,
        'paymentOrder': paymentOrder,
        'paymentDate': paymentDate?.toIso8601String(),
        'paymentValue': paymentValue,
        'paymentTotalValue': paymentTotalValue,
        'paymentNetValue': paymentNetValue,
        'paymentGrossValue': paymentGrossValue,

        'paymentFundingSourceId': paymentFundingSourceId,
        'paymentFundingSourceLabel': paymentFundingSourceLabel,

        'inssPaymentValue': inssPaymentValue,
        'irpfPaymentValue': irpfPaymentValue,
        'issPaymentValue': issPaymentValue,
      },
    );
  }
}