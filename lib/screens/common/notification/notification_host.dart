import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/notification/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_state.dart';
import 'package:sipged/_widgets/cards/toast/toast_card.dart';

class NotificationHost extends StatelessWidget {
  const NotificationHost({
    super.key,
    required this.child,
    this.cardWidth = 310,
    this.gapRight = 20,
    this.gapTop = 70,
    this.verticalSpacing = 5,
  });

  final Widget child;

  final double cardWidth;
  final double gapRight;
  final double gapTop;
  final double verticalSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        BlocBuilder<NotificationCubit, NotificationState>(
          buildWhen: (previous, current) {
            return previous.visible != current.visible;
          },
          builder: (context, state) {
            if (state.visible.isEmpty) {
              return const SizedBox.shrink();
            }

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
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: cardWidth,
                          maxWidth: cardWidth,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            state.visible.length,
                                (index) {
                              final notification = state.visible[index];

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == state.visible.length - 1
                                      ? 0
                                      : verticalSpacing,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  child: ToastCard(
                                    key: ValueKey(notification.id),
                                    id: notification.id ??
                                        '${notification.title}_${notification.createdAt?.millisecondsSinceEpoch ?? index}',
                                    title: notification.title,
                                    subtitle: notification.subtitle,
                                    details: notification.details,
                                    leadingLabel: notification.leadingLabel,
                                    icon: notification.resolvedIcon,
                                    accentColor:
                                    notification.resolvedAccentColor,
                                    backgroundColor:
                                    notification.backgroundColor,
                                    width: cardWidth,
                                    onClose: () {
                                      context
                                          .read<NotificationCubit>()
                                          .dismiss(notification);
                                    },
                                  ),
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