import 'package:cloud_firestore/cloud_firestore.dart';
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
    this.menuWidth = 320,
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

class _NotificationBellState extends State<NotificationBell>
    with WidgetsBindingObserver {
  String? _watchingUserId;
  OverlayEntry? _overlayEntry;

  final ValueNotifier<int> _positionTick = ValueNotifier<int>(0);

  ScrollPosition? _scrollPosition;

  static const double _menuTopGap = 0;
  static const double _screenMargin = 8;

  final Map<String, _NotificationActorProfile> _actorProfileCache =
  <String, _NotificationActorProfile>{};

  final Set<String> _loadingActorIds = <String>{};

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _startWatchingIfNeeded();
    _attachToNearestScrollPosition();
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
    _attachToNearestScrollPosition();
  }

  @override
  void didChangeMetrics() {
    _requestBalloonPositionUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detachFromScrollPosition();
    _removeOverlay();
    _positionTick.dispose();
    super.dispose();
  }

  void _attachToNearestScrollPosition() {
    final scrollableState = Scrollable.maybeOf(context);
    final nextPosition = scrollableState?.position;

    if (identical(_scrollPosition, nextPosition)) return;

    _detachFromScrollPosition();

    _scrollPosition = nextPosition;
    _scrollPosition?.addListener(_requestBalloonPositionUpdate);
  }

  void _detachFromScrollPosition() {
    _scrollPosition?.removeListener(_requestBalloonPositionUpdate);
    _scrollPosition = null;
  }

  void _requestBalloonPositionUpdate() {
    if (_overlayEntry == null) return;

    _positionTick.value++;
    _overlayEntry?.markNeedsBuild();
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
    if (!targetObject.attached) return;

    final overlayState = Overlay.of(context);
    final overlayObject = overlayState.context.findRenderObject();

    if (overlayObject is! RenderBox) return;
    if (!overlayObject.attached) return;

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
                  return previous.userBellNotifications !=
                      current.userBellNotifications ||
                      previous.unreadUserNotifications !=
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
                    rebuildListenable: _positionTick,
                    width: widget.menuWidth,
                    maxHeight: widget.maxMenuHeight,
                    topGap: _menuTopGap,
                    screenMargin: _screenMargin,
                    title: 'Notificações',
                    headerIcon: Icons.notifications_none_rounded,
                    actionLabel: 'Marcar como vistas',
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

                      _requestBalloonPositionUpdate();
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestBalloonPositionUpdate();
    });
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

      final title = _friendlyTitle(notification);
      final subtitle = _friendlyDemandName(notification);
      final details = _friendlyActionDetails(notification);
      final info = _friendlyCreatedAt(notification.createdAt);

      final actorId = _notificationActorId(notification);
      final actorName = _notificationActorName(notification);

      if (actorId != null && actorId.isNotEmpty) {
        _loadActorProfileIfNeeded(actorId);
      }

      return BalloonTileData(
        id: _tileId(notification),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subtitle == null || subtitle.trim().isEmpty
            ? null
            : Text(
          subtitle.trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        details: details == null || details.trim().isEmpty
            ? null
            : Text(
          details.trim(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        info: info == null || info.trim().isEmpty
            ? null
            : Text(
          info.trim(),
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        icon: notification.resolvedIcon,
        leading: _buildActorLeading(
          actorId: actorId,
          actorName: actorName,
          notificationPhotoUrl: _notificationActorPhotoUrl(notification),
          fallbackIcon: notification.resolvedIcon,
          accentColor: notification.resolvedAccentColor,
        ),
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

  Widget _buildActorLeading({
    required String? actorId,
    required String? actorName,
    required IconData fallbackIcon,
    required Color accentColor,
    String? notificationPhotoUrl,
  }) {
    final cleanActorId = actorId?.trim();

    final profile = cleanActorId == null || cleanActorId.isEmpty
        ? null
        : _actorProfileCache[cleanActorId];

    final photoUrlFromProfile = profile?.photoUrl.trim() ?? '';
    final photoUrlFromNotification = notificationPhotoUrl?.trim() ?? '';

    final photoUrl = photoUrlFromProfile.isNotEmpty
        ? photoUrlFromProfile
        : photoUrlFromNotification;

    final name = (profile?.displayName.trim().isNotEmpty == true)
        ? profile!.displayName.trim()
        : (actorName ?? '').trim();

    final initials = _initialsFromName(name);

    return _ActorPhotoLeading(
      photoUrl: photoUrl,
      initials: initials,
      fallbackIcon: fallbackIcon,
      accentColor: accentColor,
    );
  }

  void _loadActorProfileIfNeeded(String actorId) {
    final cleanActorId = actorId.trim();

    if (cleanActorId.isEmpty) return;
    if (_actorProfileCache.containsKey(cleanActorId)) return;
    if (_loadingActorIds.contains(cleanActorId)) return;

    _loadingActorIds.add(cleanActorId);

    FirebaseFirestore.instance
        .collection('users')
        .doc(cleanActorId)
        .get()
        .then((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;

      final name = _clean(data['name']?.toString());
      final surname = _clean(data['surname']?.toString());

      final fullName = _clean(
        (data['fullName'] ??
            data['displayName'] ??
            data['nameComplete'] ??
            data['nomeCompleto'])
            ?.toString(),
      );

      final displayName = fullName.isNotEmpty
          ? fullName
          : [name, surname]
          .where((item) => item.trim().isNotEmpty)
          .join(' ')
          .trim();

      final email = _clean(data['email']?.toString());

      final photoUrl = _clean(
        (data['urlPhoto'] ??
            data['photoUrl'] ??
            data['photoURL'] ??
            data['profilePhotoUrl'] ??
            data['photo'] ??
            data['avatar'] ??
            data['avatarUrl'] ??
            data['imageUrl'])
            ?.toString(),
      );

      if (!mounted) return;

      _actorProfileCache[cleanActorId] = _NotificationActorProfile(
        uid: cleanActorId,
        displayName: displayName.isNotEmpty ? displayName : email,
        photoUrl: photoUrl,
      );

      if (photoUrl.isNotEmpty) {
        precacheImage(
          NetworkImage(photoUrl),
          context,
        ).catchError((_) {});
      }

      setState(() {});

      _requestBalloonPositionUpdate();
    }).catchError((Object error, StackTrace stack) {
      debugPrint('Falha ao carregar usuário da notificação: $error');
      debugPrintStack(stackTrace: stack);
    }).whenComplete(() {
      _loadingActorIds.remove(cleanActorId);
    });
  }

  String? _notificationActorId(NotificationData notification) {
    final extra = notification.extra;

    final actorId = _clean(extra['actorId']?.toString());

    if (actorId.isNotEmpty) return actorId;

    return null;
  }

  String? _notificationActorName(NotificationData notification) {
    final extra = notification.extra;

    final actorName = _clean(extra['actorName']?.toString());

    if (actorName.isNotEmpty) return actorName;

    return null;
  }

  String? _notificationActorPhotoUrl(NotificationData notification) {
    final extra = notification.extra;

    final candidates = <String>[
      _clean(extra['actorPhotoUrl']?.toString()),
      _clean(extra['photoUrl']?.toString()),
      _clean(extra['photoURL']?.toString()),
      _clean(extra['profilePhotoUrl']?.toString()),
      _clean(extra['urlPhoto']?.toString()),
      _clean(extra['avatarUrl']?.toString()),
      _clean(extra['imageUrl']?.toString()),
    ];

    for (final value in candidates) {
      if (value.isNotEmpty) return value;
    }

    return null;
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

      _requestBalloonPositionUpdate();
    }
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

    if (title.isNotEmpty && title.toLowerCase() != 'notificação') {
      return title;
    }

    final action = _clean(notification.extra['action']?.toString());

    if (action.isNotEmpty) {
      return _actionToFriendlyTitle(action);
    }

    return 'Notificação';
  }

  String? _friendlyDemandName(NotificationData notification) {
    final extra = notification.extra;

    final candidates = <String>[
      _clean(notification.subtitle),
      _clean(extra['nomeDemanda']?.toString()),
      _clean(extra['demandaNome']?.toString()),
      _clean(extra['demandName']?.toString()),
      _clean(extra['descricaoObjeto']?.toString()),
      _clean(extra['summarySubjectContract']?.toString()),
      _clean(extra['contractSummary']?.toString()),
      _clean(extra['contractTitle']?.toString()),
      _clean(extra['processSummary']?.toString()),
    ];

    for (final value in candidates) {
      if (_isUsefulDemandName(value)) return value;
    }

    return null;
  }

  String? _friendlyActionDetails(NotificationData notification) {
    final extra = notification.extra;

    final details = _clean(notification.details);

    if (_isUsefulDetails(details) && !_sameAsDemand(notification, details)) {
      return details;
    }

    final actorName = _clean(extra['actorName']?.toString());
    final action = _clean(extra['action']?.toString());

    final friendlyAction = _actionToFriendlyVerb(action);

    if (actorName.isNotEmpty && friendlyAction.isNotEmpty) {
      return '$friendlyAction por $actorName';
    }

    if (actorName.isNotEmpty) {
      return 'Por $actorName';
    }

    if (friendlyAction.isNotEmpty) {
      return friendlyAction;
    }

    return null;
  }

  String? _friendlyCreatedAt(DateTime? createdAt) {
    if (createdAt == null) return null;

    final now = DateTime.now();
    final local = createdAt.toLocal();

    final sameDay = now.year == local.year &&
        now.month == local.month &&
        now.day == local.day;

    final yesterday = DateTime(now.year, now.month, now.day).subtract(
      const Duration(days: 1),
    );

    final isYesterday = yesterday.year == local.year &&
        yesterday.month == local.month &&
        yesterday.day == local.day;

    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    if (sameDay) {
      return 'Hoje\n$hour:$minute';
    }

    if (isYesterday) {
      return 'Ontem\n$hour:$minute';
    }

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month\n$hour:$minute';
  }

  String _actionToFriendlyTitle(String action) {
    final clean = action.trim().toLowerCase();

    switch (clean) {
      case 'dfd_created':
        return 'DFD criado';
      case 'dfd_updated':
        return 'DFD atualizado';
      case 'dfd_deleted':
        return 'DFD apagado';

      case 'measurement_created':
        return 'Medição criada';
      case 'measurement_updated':
        return 'Medição atualizada';
      case 'measurement_deleted':
        return 'Medição apagada';
      case 'measurement_attachment_created':
        return 'Arquivo anexado à medição';
      case 'measurement_attachment_deleted':
        return 'Arquivo removido da medição';
      case 'measurement_attachment_renamed':
        return 'Anexo de medição renomeado';

      case 'additive_created':
        return 'Aditivo criado';
      case 'additive_updated':
        return 'Aditivo atualizado';
      case 'additive_deleted':
        return 'Aditivo apagado';
      case 'additive_attachment_added':
      case 'additive_attachment_created':
        return 'Arquivo anexado ao aditivo';
      case 'additive_attachment_deleted':
        return 'Arquivo removido do aditivo';
      case 'additive_attachment_renamed':
        return 'Anexo de aditivo renomeado';

      case 'apostille_created':
        return 'Apostilamento criado';
      case 'apostille_updated':
        return 'Apostilamento atualizado';
      case 'apostille_deleted':
        return 'Apostilamento apagado';
      case 'apostille_attachment_added':
      case 'apostille_attachment_created':
        return 'Arquivo anexado ao apostilamento';
      case 'apostille_attachment_deleted':
        return 'Arquivo removido do apostilamento';
      case 'apostille_attachment_renamed':
        return 'Anexo de apostilamento renomeado';

      case 'validity_created':
        return 'Validade criada';
      case 'validity_updated':
        return 'Validade atualizada';
      case 'validity_deleted':
        return 'Validade apagada';
      case 'validity_attachment_created':
        return 'Arquivo anexado à validade';
      case 'validity_attachment_deleted':
        return 'Arquivo removido da validade';
      case 'validity_attachment_renamed':
        return 'Anexo de validade renomeado';

      case 'revision_created':
        return 'Revisão criada';
      case 'revision_updated':
        return 'Revisão atualizada';
      case 'revision_deleted':
        return 'Revisão apagada';
      case 'revision_attachment_created':
        return 'Arquivo anexado à revisão';
      case 'revision_attachment_deleted':
        return 'Arquivo removido da revisão';
      case 'revision_attachment_renamed':
        return 'Anexo de revisão renomeado';

      case 'adjustment_created':
        return 'Reajuste criado';
      case 'adjustment_updated':
        return 'Reajuste atualizado';
      case 'adjustment_deleted':
        return 'Reajuste apagado';
      case 'adjustment_attachment_added':
      case 'adjustment_attachment_created':
        return 'Arquivo anexado ao reajuste';
      case 'adjustment_attachment_deleted':
        return 'Arquivo removido do reajuste';
      case 'adjustment_attachment_renamed':
        return 'Anexo de reajuste renomeado';

      default:
        return _humanizeAction(action);
    }
  }

  String _actionToFriendlyVerb(String action) {
    final clean = action.trim().toLowerCase();

    switch (clean) {
      case 'dfd_created':
        return 'Criado';
      case 'dfd_updated':
        return 'Atualizado';
      case 'dfd_deleted':
        return 'Apagado';

      case 'measurement_created':
      case 'additive_created':
      case 'apostille_created':
      case 'validity_created':
      case 'revision_created':
      case 'adjustment_created':
        return 'Criado';

      case 'measurement_updated':
      case 'additive_updated':
      case 'apostille_updated':
      case 'validity_updated':
      case 'revision_updated':
      case 'adjustment_updated':
        return 'Atualizado';

      case 'measurement_deleted':
      case 'additive_deleted':
      case 'apostille_deleted':
      case 'validity_deleted':
      case 'revision_deleted':
      case 'adjustment_deleted':
        return 'Removido';

      case 'measurement_attachment_created':
      case 'additive_attachment_added':
      case 'additive_attachment_created':
      case 'apostille_attachment_added':
      case 'apostille_attachment_created':
      case 'validity_attachment_created':
      case 'revision_attachment_created':
      case 'adjustment_attachment_added':
      case 'adjustment_attachment_created':
        return 'Anexado';

      case 'measurement_attachment_deleted':
      case 'additive_attachment_deleted':
      case 'apostille_attachment_deleted':
      case 'validity_attachment_deleted':
      case 'revision_attachment_deleted':
      case 'adjustment_attachment_deleted':
        return 'Removido';

      case 'measurement_attachment_renamed':
      case 'additive_attachment_renamed':
      case 'apostille_attachment_renamed':
      case 'validity_attachment_renamed':
      case 'revision_attachment_renamed':
      case 'adjustment_attachment_renamed':
        return 'Renomeado';

      default:
        if (clean.isEmpty) return '';
        return _humanizeAction(action);
    }
  }

  String _humanizeAction(String action) {
    final clean = action
        .trim()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    if (clean.isEmpty) return '';

    return clean[0].toUpperCase() + clean.substring(1);
  }

  bool _sameAsDemand(NotificationData notification, String value) {
    final demand = _friendlyDemandName(notification);

    if (demand == null) return false;

    return _normalizeCompare(demand) == _normalizeCompare(value);
  }

  bool _isUsefulDemandName(String value) {
    final clean = value.trim();

    if (clean.isEmpty) return false;
    if (_looksLikeContractId(clean)) return false;
    if (_looksLikeContratoWithId(clean)) return false;
    if (_looksLikeModule(clean)) return false;

    return true;
  }

  bool _isUsefulDetails(String value) {
    final clean = value.trim();

    if (clean.isEmpty) return false;
    if (_looksLikeContractId(clean)) return false;
    if (_looksLikeContratoWithId(clean)) return false;
    if (_looksLikeModule(clean)) return false;

    return true;
  }

  bool _looksLikeContratoWithId(String value) {
    final clean = value.trim();
    final lower = clean.toLowerCase();

    if (!lower.startsWith('contrato ')) return false;

    final after = clean.substring(9).trim();

    return _looksLikeContractId(after);
  }

  bool _looksLikeContractId(String value) {
    final clean = value.trim();

    if (clean.isEmpty) return false;

    final hasNoSpaces = !clean.contains(RegExp(r'\s'));
    final isLong = clean.length >= 16;
    final isFirebaseLike = RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(clean);

    return hasNoSpaces && isLong && isFirebaseLike;
  }

  bool _looksLikeModule(String value) {
    final clean = value.trim();

    if (clean.isEmpty) return false;

    final lower = clean.toLowerCase();

    final knownPrefixes = <String>[
      'contracts_',
      'operation_',
      'traffic_',
      'planning_',
      'financial_',
      'assets_',
    ];

    return knownPrefixes.any(lower.startsWith);
  }

  String _normalizeCompare(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _initialsFromName(String value) {
    final clean = value.trim();

    if (clean.isEmpty) return '';

    final parts = clean
        .split(RegExp(r'\s+'))
        .where((item) => item.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) return '';

    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }

    final first = parts.first.characters.take(1).toString();
    final last = parts.last.characters.take(1).toString();

    return '$first$last'.toUpperCase();
  }

  String _clean(String? value) {
    return (value ?? '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBellCubit, NotificationBellState>(
      buildWhen: (previous, current) {
        return previous.userBellNotifications != current.userBellNotifications ||
            previous.unreadUserNotifications != current.unreadUserNotifications ||
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

class _NotificationActorProfile {
  const _NotificationActorProfile({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String photoUrl;
}

class _ActorPhotoLeading extends StatelessWidget {
  const _ActorPhotoLeading({
    required this.photoUrl,
    required this.initials,
    required this.fallbackIcon,
    required this.accentColor,
  });

  final String photoUrl;
  final String initials;
  final IconData fallbackIcon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.trim().isNotEmpty;
    final hasInitials = initials.trim().isNotEmpty;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.16),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.network(
        photoUrl.trim(),
        width: 38,
        height: 38,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }

          return _ActorFallbackLeading(
            initials: initials,
            fallbackIcon: fallbackIcon,
            accentColor: accentColor,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          return _ActorFallbackLeading(
            initials: initials,
            fallbackIcon: fallbackIcon,
            accentColor: accentColor,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _ActorFallbackLeading(
            initials: hasInitials ? initials : '',
            fallbackIcon: fallbackIcon,
            accentColor: accentColor,
          );
        },
      )
          : _ActorFallbackLeading(
        initials: hasInitials ? initials : '',
        fallbackIcon: fallbackIcon,
        accentColor: accentColor,
      ),
    );
  }
}

class _ActorFallbackLeading extends StatelessWidget {
  const _ActorFallbackLeading({
    required this.initials,
    required this.fallbackIcon,
    required this.accentColor,
  });

  final String initials;
  final IconData fallbackIcon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final hasInitials = initials.trim().isNotEmpty;

    if (hasInitials) {
      return Center(
        child: Text(
          initials.trim(),
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: TextStyle(
            color: accentColor,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
      );
    }

    return Icon(
      fallbackIcon,
      color: accentColor,
      size: 21,
    );
  }
}