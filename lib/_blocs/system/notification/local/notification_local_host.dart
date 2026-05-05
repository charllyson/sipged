import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/local/notification_local_state.dart';
import 'package:sipged/_widgets/cards/toast/toast_card.dart';

class NotificationLocalHost extends StatelessWidget {
  const NotificationLocalHost({
    super.key,
    required this.child,
    this.gapRight = 10,
    this.gapTop = 60,
    this.verticalSpacing = 2,
  });

  final Widget child;

  final double gapRight;
  final double gapTop;
  final double verticalSpacing;

  String _clean(dynamic value) {
    return (value ?? '').toString().trim();
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

  Widget _buildToastLeading({
    required IconData icon,
    required Color accentColor,
    required Map<String, dynamic> extra,
  }) {
    final actorName = _clean(extra['actorName']);
    final photoUrl = _clean(
      extra['actorPhotoUrl'] ??
          extra['photoUrl'] ??
          extra['photoURL'] ??
          extra['profilePhotoUrl'] ??
          extra['photo'],
    );

    final initials = _initialsFromName(actorName);

    return _ToastActorLeading(
      photoUrl: photoUrl,
      initials: initials,
      fallbackIcon: icon,
      accentColor: accentColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cardWidth = ToastCard.defaultWidth;
    final cardHeight = ToastCard.defaultHeight;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        BlocBuilder<NotificationLocalCubit, NotificationLocalState>(
          buildWhen: (previous, current) {
            return previous.visible != current.visible;
          },
          builder: (context, state) {
            if (state.visible.isEmpty) {
              return const SizedBox.shrink();
            }

            final visible = state.visible.reversed.toList();

            final totalHeight = visible.length * cardHeight +
                (visible.length - 1) * verticalSpacing;

            return Positioned(
              top: gapTop,
              right: gapRight,
              child: SafeArea(
                top: false,
                left: false,
                right: true,
                bottom: true,
                child: Material(
                  type: MaterialType.transparency,
                  child: DefaultTextStyle(
                    style: (theme.textTheme.bodyMedium ??
                        const TextStyle(fontSize: 14))
                        .copyWith(
                      decoration: TextDecoration.none,
                      color: Colors.black87,
                    ),
                    child: IconTheme(
                      data: const IconThemeData(
                        color: Colors.black54,
                      ),
                      child: SizedBox(
                        width: cardWidth,
                        height: totalHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: List.generate(
                            visible.length,
                                (index) {
                              final notification = visible[index];

                              final notificationKey = notification.id ??
                                  '${notification.title}_${notification.createdAt?.millisecondsSinceEpoch ?? notification.hashCode}';

                              final top =
                                  index * (cardHeight + verticalSpacing);

                              return AnimatedPositioned(
                                key: ValueKey(
                                  'toast_position_$notificationKey',
                                ),
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutCubic,
                                top: top,
                                right: 0,
                                width: cardWidth,
                                height: cardHeight,
                                child: ToastCard(
                                  key: ValueKey(
                                    'toast_card_$notificationKey',
                                  ),
                                  id: notificationKey,
                                  title: notification.title,
                                  subtitle: notification.subtitle,
                                  details: notification.details,
                                  leading: _buildToastLeading(
                                    icon: notification.resolvedIcon,
                                    accentColor:
                                    notification.resolvedAccentColor,
                                    extra: notification.extra,
                                  ),
                                  icon: notification.resolvedIcon,
                                  accentColor:
                                  notification.resolvedAccentColor,
                                  backgroundColor: notification.backgroundColor,
                                  onClose: () {
                                    context
                                        .read<NotificationLocalCubit>()
                                        .dismiss(notification);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ToastActorLeading extends StatelessWidget {
  const _ToastActorLeading({
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
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(
          color: accentColor.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.network(
        photoUrl.trim(),
        width: 34,
        height: 34,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _ToastActorFallback(
            initials: initials,
            fallbackIcon: fallbackIcon,
            accentColor: accentColor,
          );
        },
      )
          : _ToastActorFallback(
        initials: hasInitials ? initials : '',
        fallbackIcon: fallbackIcon,
        accentColor: accentColor,
      ),
    );
  }
}

class _ToastActorFallback extends StatelessWidget {
  const _ToastActorFallback({
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
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
            decoration: TextDecoration.none,
          ),
        ),
      );
    }

    return Icon(
      fallbackIcon,
      color: accentColor,
      size: 20,
    );
  }
}