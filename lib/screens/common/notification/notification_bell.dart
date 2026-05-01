import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/notification/local/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/local/notification_data.dart';
import 'package:sipged/_blocs/system/notification/local/notification_state.dart';
import 'package:sipged/_widgets/badge/badge_change.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_change.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tile.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({
    super.key,
    required this.userId,
    this.iconColor = Colors.white,
    this.badgeColor = const Color(0xFFD32F2F),
    this.menuWidth = 270,
    this.maxMenuHeight = 420,
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startWatchingIfNeeded();
  }

  @override
  void didUpdateWidget(covariant NotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);

    _startWatchingIfNeeded();

    if (oldWidget.menuWidth != widget.menuWidth ||
        oldWidget.maxMenuHeight != widget.maxMenuHeight ||
        oldWidget.userId != widget.userId) {
      _removeOverlay();
    }
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

    final cubit = context.read<NotificationCubit>();

    if (nextUserId == null || nextUserId.isEmpty) {
      cubit.watchSystemNotifications();
      return;
    }

    cubit.watchBellNotifications(userId: nextUserId);
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
    final renderObject = context.findRenderObject();

    if (renderObject is! RenderBox) return;

    final overlayState = Overlay.of(context);
    final overlayObject = overlayState.context.findRenderObject();

    if (overlayObject is! RenderBox) return;

    final cubit = context.read<NotificationCubit>();
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
            BlocProvider.value(
              value: cubit,
              child: BlocBuilder<NotificationCubit, NotificationState>(
                builder: (context, state) {
                  final items = _buildBalloonItems(
                    context: context,
                    state: state,
                    userId: resolvedUserId,
                  );

                  return BalloonChange(
                    targetBox: renderObject,
                    overlayBox: overlayObject,
                    width: widget.menuWidth,
                    maxHeight: widget.maxMenuHeight,
                    topGap: _menuTopGap,
                    screenMargin: _screenMargin,
                    title: 'Notificações',
                    headerIcon: Icons.notifications_none_rounded,
                    actionLabel: 'Marcar vistas',
                    showAction: state.unreadUserCount > 0,
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

                      await context.read<NotificationCubit>().markAllAsSeen(
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
    required NotificationState state,
    required String? userId,
  }) {
    return state.bellNotifications.map((notification) {
      final notificationId = notification.id;

      final isUnread = _isUnreadNotification(
        state: state,
        notification: notification,
      );

      return BalloonTileData(
        id: notificationId ??
            '${notification.title}_${notification.createdAt?.millisecondsSinceEpoch ?? notification.hashCode}',
        title: notification.title,
        subtitle: notification.subtitle,
        details: _friendlyDetails(notification),
        icon: notification.resolvedIcon,
        accentColor: notification.resolvedAccentColor,
        highlighted: isUnread,
        onTap: () async {
          final id = userId?.trim();

          if (id != null &&
              id.isNotEmpty &&
              notificationId != null &&
              notificationId.isNotEmpty &&
              isUnread) {
            await context.read<NotificationCubit>().markAsSeen(
              userId: id,
              notificationId: notificationId,
            );
          }

          _removeOverlay();
        },
      );
    }).toList();
  }

  bool _isUnreadNotification({
    required NotificationState state,
    required NotificationData notification,
  }) {
    final notificationId = notification.id;

    if (notificationId == null || notificationId.isEmpty) {
      return false;
    }

    return state.unreadUserNotifications.any(
          (item) => item.id == notificationId,
    );
  }

  String _clean(String? value) {
    return (value ?? '').trim();
  }

  String? _friendlyDetails(NotificationData notification) {
    final extra = notification.extra;

    final contractSummary = _clean(extra['contractSummary']?.toString());
    final contractTitle = _clean(extra['contractTitle']?.toString());

    if (contractSummary.isNotEmpty) return contractSummary;
    if (contractTitle.isNotEmpty) return contractTitle;

    final details = _clean(notification.details);

    if (details.isEmpty) return null;

    final lower = details.toLowerCase();

    final looksLikeId = details.length >= 18 &&
        !details.contains(' ') &&
        RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(details);

    final looksLikeLongContractId =
        lower.startsWith('contrato ') && details.length > 25;

    if (looksLikeId || looksLikeLongContractId) {
      return null;
    }

    return details;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      buildWhen: (previous, current) {
        return previous.unreadUserNotifications !=
            current.unreadUserNotifications ||
            previous.systemNotifications != current.systemNotifications ||
            previous.loading != current.loading ||
            previous.error != current.error;
      },
      builder: (context, state) {
        final unreadCount = state.unreadUserCount;

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