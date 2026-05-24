// lib/_blocs/system/notification/bell/notification_bell_state.dart

import 'package:equatable/equatable.dart';

import 'package:sipged/_blocs/system/notification/notification_data.dart';

class NotificationBellState extends Equatable {
  const NotificationBellState({
    this.systemNotifications = const <NotificationData>[],
    this.userBellNotifications = const <NotificationData>[],
    this.unreadUserNotifications = const <NotificationData>[],
    this.loading = false,
    this.error,
  });

  static const int maxUnreadBadgeCount = 99;

  final List<NotificationData> systemNotifications;

  /// Lista visual do sino.
  /// Contém notificações vistas e não vistas.
  final List<NotificationData> userBellNotifications;

  /// Lista usada somente para badge e destaque visual.
  /// Representa notificações não lidas.
  final List<NotificationData> unreadUserNotifications;

  final bool loading;
  final String? error;

  /// Total bruto carregado de notificações não lidas.
  ///
  /// Como o Cubit busca 100 itens quando o limite visual é 99,
  /// este valor permite saber quando deve exibir "+99".
  int get unreadUserCountRaw {
    return _deduplicateUserNotifications(unreadUserNotifications).length;
  }

  /// Quantidade numérica limitada para uso interno.
  ///
  /// Nunca passa de 99.
  int get unreadUserCount {
    final count = unreadUserCountRaw;

    if (count > maxUnreadBadgeCount) {
      return maxUnreadBadgeCount;
    }

    return count;
  }

  /// Indica se existem mais de 99 notificações não lidas.
  bool get hasUnreadOverflow {
    return unreadUserCountRaw > maxUnreadBadgeCount;
  }

  /// Texto que deve aparecer na bolinha vermelha.
  ///
  /// Exemplo:
  /// - 0
  /// - 1
  /// - 15
  /// - 99
  /// - +99
  String get unreadBadgeLabel {
    if (hasUnreadOverflow) return '+99';

    return unreadUserCount.toString();
  }

  List<NotificationData> get bellNotifications {
    final visibleItems = _deduplicateUserNotifications([
      ...userBellNotifications,
      ...systemNotifications,
    ]);

    visibleItems.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bDate.compareTo(aDate);
    });

    return visibleItems;
  }

  NotificationBellState copyWith({
    List<NotificationData>? systemNotifications,
    List<NotificationData>? userBellNotifications,
    List<NotificationData>? unreadUserNotifications,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationBellState(
      systemNotifications: systemNotifications ?? this.systemNotifications,
      userBellNotifications:
      userBellNotifications ?? this.userBellNotifications,
      unreadUserNotifications:
      unreadUserNotifications ?? this.unreadUserNotifications,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
    );
  }

  static List<NotificationData> _deduplicateUserNotifications(
      List<NotificationData> items,
      ) {
    final validItems = items.where(_isValidUserNotification).toList();

    final unique = <String, NotificationData>{};

    for (final item in validItems) {
      final key = _dedupKey(item);
      final current = unique[key];

      if (current == null) {
        unique[key] = item;
        continue;
      }

      unique[key] = _preferBestNotification(
        current: current,
        next: item,
      );
    }

    return unique.values.toList();
  }

  static bool _isValidUserNotification(NotificationData item) {
    final title = _clean(item.title);
    final subtitle = _clean(item.subtitle);
    final details = _clean(item.details);
    final extra = item.extra;

    final action = _clean(extra['action']?.toString());
    final actorId = _clean(extra['actorId']?.toString());
    final actorName = _clean(extra['actorName']?.toString());

    final contractId = _clean(extra['contractId']?.toString());
    final contractSummary = _clean(extra['contractSummary']?.toString());
    final contractTitle = _clean(extra['contractTitle']?.toString());
    final nomeDemanda = _clean(extra['nomeDemanda']?.toString());
    final descricaoObjeto = _clean(extra['descricaoObjeto']?.toString());

    final measurementId = _clean(extra['measurementId']?.toString());
    final paymentId = _clean(extra['paymentId']?.toString());

    final notificationSource = _clean(
      extra['notificationSource']?.toString(),
    );

    final hasText = title.isNotEmpty ||
        subtitle.isNotEmpty ||
        details.isNotEmpty ||
        contractSummary.isNotEmpty ||
        contractTitle.isNotEmpty ||
        nomeDemanda.isNotEmpty ||
        descricaoObjeto.isNotEmpty;

    final hasMetadata = action.isNotEmpty ||
        actorId.isNotEmpty ||
        actorName.isNotEmpty ||
        contractId.isNotEmpty ||
        measurementId.isNotEmpty ||
        paymentId.isNotEmpty ||
        notificationSource.isNotEmpty;

    if (!hasText && !hasMetadata) return false;

    final isGenericTitle =
        title.isEmpty || title.toLowerCase() == 'notificação';

    if (isGenericTitle && !hasMetadata && details.isEmpty) {
      return false;
    }

    return true;
  }

  static String _dedupKey(NotificationData item) {
    final id = item.id?.trim();

    if (id != null && id.isNotEmpty) {
      return 'id|$id';
    }

    final extra = item.extra;

    final action = _clean(extra['action']?.toString());

    final contractId = _clean(extra['contractId']?.toString());

    final measurementId = _clean(extra['measurementId']?.toString());
    final measurementOrder = _clean(extra['measurementOrder']?.toString());

    final paymentId = _clean(extra['paymentId']?.toString());
    final paymentOrder = _clean(extra['paymentOrder']?.toString());

    final validityId = _clean(extra['validityId']?.toString());
    final additiveId = _clean(extra['additiveId']?.toString());
    final apostilleId = _clean(extra['apostilleId']?.toString());
    final revisionId = _clean(extra['revisionId']?.toString());
    final adjustmentId = _clean(extra['adjustmentId']?.toString());

    final source = _clean(
      (extra['notificationSource'] ??
          extra['sourceKey'] ??
          extra['subSource'] ??
          extra['source'])
          ?.toString(),
    );

    if (source.isNotEmpty && action.isNotEmpty && paymentId.isNotEmpty) {
      return '$source|$action|$paymentId';
    }

    if (source.isNotEmpty && action.isNotEmpty && measurementId.isNotEmpty) {
      return '$source|$action|$measurementId';
    }

    if (source.isNotEmpty && action.isNotEmpty && validityId.isNotEmpty) {
      return '$source|$action|$validityId';
    }

    if (source.isNotEmpty && action.isNotEmpty && additiveId.isNotEmpty) {
      return '$source|$action|$additiveId';
    }

    if (source.isNotEmpty && action.isNotEmpty && apostilleId.isNotEmpty) {
      return '$source|$action|$apostilleId';
    }

    if (source.isNotEmpty && action.isNotEmpty && revisionId.isNotEmpty) {
      return '$source|$action|$revisionId';
    }

    if (source.isNotEmpty && action.isNotEmpty && adjustmentId.isNotEmpty) {
      return '$source|$action|$adjustmentId';
    }

    if (source.isNotEmpty &&
        action.isNotEmpty &&
        contractId.isNotEmpty &&
        measurementId.isNotEmpty &&
        paymentOrder.isNotEmpty) {
      return '$source|$action|$contractId|$measurementId|$paymentOrder';
    }

    if (source.isNotEmpty &&
        action.isNotEmpty &&
        contractId.isNotEmpty &&
        measurementOrder.isNotEmpty) {
      return '$source|$action|$contractId|$measurementOrder';
    }

    final createdAt = item.createdAt?.millisecondsSinceEpoch ?? 0;
    final title = _clean(item.title);
    final subtitle = _clean(item.subtitle);
    final details = _clean(item.details);

    return 'fallback|$title|$subtitle|$details|$createdAt';
  }

  static NotificationData _preferBestNotification({
    required NotificationData current,
    required NotificationData next,
  }) {
    final currentScore = _qualityScore(current);
    final nextScore = _qualityScore(next);

    if (nextScore > currentScore) return next;
    if (currentScore > nextScore) return current;

    final currentDate = current.createdAt;
    final nextDate = next.createdAt;

    if (currentDate == null && nextDate != null) return next;
    if (currentDate != null && nextDate == null) return current;

    if (currentDate != null && nextDate != null) {
      return nextDate.isAfter(currentDate) ? next : current;
    }

    return current;
  }

  static int _qualityScore(NotificationData item) {
    final extra = item.extra;

    var score = 0;

    final title = _clean(item.title);
    final subtitle = _clean(item.subtitle);
    final details = _clean(item.details);

    final action = _clean(extra['action']?.toString());
    final actorId = _clean(extra['actorId']?.toString());
    final actorName = _clean(extra['actorName']?.toString());

    final contractId = _clean(extra['contractId']?.toString());
    final contractSummary = _clean(extra['contractSummary']?.toString());
    final contractTitle = _clean(extra['contractTitle']?.toString());
    final nomeDemanda = _clean(extra['nomeDemanda']?.toString());
    final descricaoObjeto = _clean(extra['descricaoObjeto']?.toString());

    final measurementId = _clean(extra['measurementId']?.toString());

    final paymentId = _clean(extra['paymentId']?.toString());
    final paymentValue = _clean(extra['paymentValue']?.toString());
    final paymentTotalValue = _clean(extra['paymentTotalValue']?.toString());
    final paymentFundingSourceLabel = _clean(
      extra['paymentFundingSourceLabel']?.toString(),
    );

    if (title.isNotEmpty && title.toLowerCase() != 'notificação') score += 10;
    if (subtitle.isNotEmpty) score += 5;
    if (details.isNotEmpty) score += 4;

    if (action.isNotEmpty) score += 4;
    if (actorId.isNotEmpty) score += 8;
    if (actorName.isNotEmpty) score += 6;

    if (contractId.isNotEmpty) score += 4;
    if (contractSummary.isNotEmpty) score += 7;
    if (contractTitle.isNotEmpty) score += 5;
    if (nomeDemanda.isNotEmpty) score += 8;
    if (descricaoObjeto.isNotEmpty) score += 8;

    if (measurementId.isNotEmpty) score += 4;

    if (paymentId.isNotEmpty) score += 5;
    if (paymentValue.isNotEmpty) score += 3;
    if (paymentTotalValue.isNotEmpty) score += 3;
    if (paymentFundingSourceLabel.isNotEmpty) score += 3;

    return score;
  }

  static String _clean(String? value) {
    return (value ?? '').trim();
  }

  @override
  List<Object?> get props => [
    systemNotifications,
    userBellNotifications,
    unreadUserNotifications,
    loading,
    error,
  ];
}