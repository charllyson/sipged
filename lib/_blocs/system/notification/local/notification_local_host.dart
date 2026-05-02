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
                                  leadingLabel: notification.leadingLabel,
                                  icon: notification.resolvedIcon,
                                  accentColor:
                                  notification.resolvedAccentColor,
                                  backgroundColor:
                                  notification.backgroundColor,
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