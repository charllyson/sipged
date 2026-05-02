import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/notification/bell/notification_bell_cubit.dart';
import 'package:sipged/_blocs/system/notification/bell/notification_bell_state.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';

import 'package:sipged/_widgets/badge/badge_change.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_change.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tile.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({
    super.key,
    required this.userId,
    this.iconColor = Colors.white,
    this.badgeColor = const Color(0xFFD32F2F),
    this.menuWidth = 300,
    this.maxMenuHeight = 440,
    this.tooltip = 'Notificações',
  });

  final String? userId;

  final Color iconColor;
  final Color badgeColor;

  final double menuWidth;
  final double maxMenuHeight;

  final String tooltip;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  String? _watchingUserId;
  OverlayEntry? _overlayEntry;

  static const double _menuTopGap = 0;
  static const double _screenMargin = 8;

  String? get _resolvedUserId {
    final fromWidget = widget.userId?.trim();

    if (fromWidget != null && fromWidget.isNotEmpty) {
      return fromWidget;
    }

    final fromAuth = FirebaseAuth.instance.currentUser?.uid.trim();

    if (fromAuth != null && fromAuth.isNotEmpty) {
      return fromAuth;
    }

    return null;
  }

  bool get _hasResolvedUser {
    final id = _resolvedUserId;
    return id != null && id.trim().isNotEmpty;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startWatchingIfNeeded();
  }

  @override
  void didUpdateWidget(covariant NotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);

    final changedLayout = oldWidget.menuWidth != widget.menuWidth ||
        oldWidget.maxMenuHeight != widget.maxMenuHeight;

    final changedUser = oldWidget.userId != widget.userId;

    if (changedLayout || changedUser) {
      _removeOverlay();
    }

    _startWatchingIfNeeded();
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _startWatchingIfNeeded() {
    final nextUserId = _resolvedUserId;

    if (_watchingUserId == nextUserId) return;

    _watchingUserId = nextUserId;

    final cubit = context.read<NotificationBellCubit>();

    cubit.watchBellNotifications(
      userId: nextUserId ?? '',
    );
  }

  void _toggleMenu() {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    _openOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _openOverlay() {
    final targetObject = context.findRenderObject();

    if (targetObject is! RenderBox) return;

    final overlayState = Overlay.of(context);
    final overlayObject = overlayState.context.findRenderObject();

    if (overlayObject is! RenderBox) return;

    final cubit = context.read<NotificationBellCubit>();
    final resolvedUserId = _resolvedUserId;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeOverlay,
                child: const SizedBox.expand(),
              ),
            ),
            BlocProvider<NotificationBellCubit>.value(
              value: cubit,
              child: BlocBuilder<NotificationBellCubit, NotificationBellState>(
                buildWhen: (previous, current) {
                  return previous.unreadUserNotifications !=
                      current.unreadUserNotifications ||
                      previous.systemNotifications !=
                          current.systemNotifications ||
                      previous.loading != current.loading ||
                      previous.error != current.error;
                },
                builder: (context, state) {
                  final items = _buildBalloonItems(
                    context: context,
                    state: state,
                    userId: resolvedUserId,
                  );

                  final canMarkAllAsSeen = resolvedUserId != null &&
                      resolvedUserId.trim().isNotEmpty &&
                      state.unreadUserCount > 0;

                  return BalloonChange(
                    targetBox: targetObject,
                    overlayBox: overlayObject,
                    width: widget.menuWidth,
                    maxHeight: widget.maxMenuHeight,
                    topGap: _menuTopGap,
                    screenMargin: _screenMargin,
                    title: 'Notificações',
                    headerIcon: Icons.notifications_none_rounded,
                    actionLabel: 'Marcar todas como vistas',
                    showAction: canMarkAllAsSeen,
                    loading: state.loading,
                    error: state.error,
                    emptyIcon: Icons.notifications_off_outlined,
                    emptyMessage: 'Nenhuma notificação encontrada.',
                    items: items,
                    onAction: () async {
                      final id = resolvedUserId?.trim();

                      if (id == null || id.isEmpty) {
                        _removeOverlay();
                        return;
                      }

                      await context.read<NotificationBellCubit>().markAllAsSeen(
                        userId: id,
                      );

                      _removeOverlay();
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );

    overlayState.insert(_overlayEntry!);
  }

  List<BalloonTileData> _buildBalloonItems({
    required BuildContext context,
    required NotificationBellState state,
    required String? userId,
  }) {
    final items = state.bellNotifications;

    return items.map((notification) {
      final notificationId = notification.id;

      final isUnread = _isUnreadNotification(
        state: state,
        notification: notification,
      );

      return BalloonTileData(
        id: _tileId(notification),
        title: _friendlyTitle(notification),
        subtitle: _friendlySubtitle(notification),
        details: _friendlyDetails(notification),
        icon: notification.resolvedIcon,
        accentColor: notification.resolvedAccentColor,
        highlighted: isUnread,
        onTap: () async {
          await _handleNotificationTap(
            context: context,
            userId: userId,
            notificationId: notificationId,
            isUnread: isUnread,
            notification: notification,
          );
        },
      );
    }).toList();
  }

  Future<void> _handleNotificationTap({
    required BuildContext context,
    required String? userId,
    required String? notificationId,
    required bool isUnread,
    required NotificationData notification,
  }) async {
    final cleanUserId = userId?.trim();
    final cleanNotificationId = notificationId?.trim();

    if (cleanUserId != null &&
        cleanUserId.isNotEmpty &&
        cleanNotificationId != null &&
        cleanNotificationId.isNotEmpty &&
        isUnread) {
      await context.read<NotificationBellCubit>().markAsSeen(
        userId: cleanUserId,
        notificationId: cleanNotificationId,
      );
    }

    _removeOverlay();

    final route = _clean(notification.extra['route']?.toString());
    final module = _clean(notification.extra['module']?.toString());
    final contractId = _clean(notification.extra['contractId']?.toString());
    final processId = _clean(notification.extra['processId']?.toString());

    debugPrint('[NotificationBell] Notificação clicada.');
    debugPrint('[NotificationBell] route=$route');
    debugPrint('[NotificationBell] module=$module');
    debugPrint('[NotificationBell] contractId=$contractId');
    debugPrint('[NotificationBell] processId=$processId');
  }

  bool _isUnreadNotification({
    required NotificationBellState state,
    required NotificationData notification,
  }) {
    final notificationId = notification.id?.trim();

    if (notificationId == null || notificationId.isEmpty) {
      return false;
    }

    return state.unreadUserNotifications.any(
          (item) => item.id == notificationId,
    );
  }

  String _tileId(NotificationData notification) {
    final id = notification.id?.trim();

    if (id != null && id.isNotEmpty) return id;

    final createdAt = notification.createdAt?.millisecondsSinceEpoch;
    return '${notification.title}_${createdAt}_${notification.hashCode}';
  }

  String _friendlyTitle(NotificationData notification) {
    final title = notification.title.trim();

    if (title.isNotEmpty) return title;

    return 'Notificação';
  }

  String? _friendlySubtitle(NotificationData notification) {
    final subtitle = _clean(notification.subtitle);

    if (subtitle.isNotEmpty) return subtitle;

    final actorName = _clean(notification.extra['actorName']?.toString());
    final action = _clean(notification.extra['action']?.toString());

    if (actorName.isNotEmpty && action.isNotEmpty) {
      return '$actorName • $action';
    }

    if (actorName.isNotEmpty) return actorName;

    return null;
  }

  String? _friendlyDetails(NotificationData notification) {
    final extra = notification.extra;

    final contractSummary = _clean(extra['contractSummary']?.toString());
    final contractTitle = _clean(extra['contractTitle']?.toString());
    final processSummary = _clean(extra['processSummary']?.toString());
    final module = _clean(extra['module']?.toString());

    if (contractSummary.isNotEmpty) return contractSummary;
    if (contractTitle.isNotEmpty) return contractTitle;
    if (processSummary.isNotEmpty) return processSummary;

    final details = _clean(notification.details);

    if (details.isEmpty) {
      return module.isNotEmpty ? module : null;
    }

    final lower = details.toLowerCase();

    final looksLikeId = details.length >= 18 &&
        !details.contains(' ') &&
        RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(details);

    final looksLikeLongContractId =
        lower.startsWith('contrato ') && details.length > 25;

    if (looksLikeId || looksLikeLongContractId) {
      return module.isNotEmpty ? module : null;
    }

    return details;
  }

  String _clean(String? value) {
    return (value ?? '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBellCubit, NotificationBellState>(
      buildWhen: (previous, current) {
        return previous.unreadUserNotifications !=
            current.unreadUserNotifications ||
            previous.systemNotifications != current.systemNotifications ||
            previous.loading != current.loading ||
            previous.error != current.error;
      },
      builder: (context, state) {
        final unreadCount = _hasResolvedUser ? state.unreadUserCount : 0;

        return Tooltip(
          message: widget.tooltip,
          waitDuration: const Duration(milliseconds: 400),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: _toggleMenu,
            child: SizedBox.square(
              dimension: 40,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: widget.iconColor,
                    size: 24,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 4,
                      right: 3,
                      child: BadgeChange(
                        count: unreadCount,
                        color: widget.badgeColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}