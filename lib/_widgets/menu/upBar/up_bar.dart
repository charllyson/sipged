import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/menu/pop_up/pup_up_photo_menu.dart';
import 'package:sipged/_widgets/menu/upBar/tight.dart';
import 'package:sipged/screens/common/notification/notification_bell.dart';

class UpBar extends StatelessWidget implements PreferredSizeWidget {
  final double titleHeight;
  final double subtitleHeight;

  final List<Widget>? titleWidgets;
  final List<Widget>? subtitleWidgets;

  final Widget? leading;
  final List<Widget> leadingActions;
  final List<Widget> actions;

  final bool showNotificationBell;
  final Widget? notificationBell;
  final String? notificationUserId;

  final bool showPhotoMenu;
  final Widget? photoMenu;

  final double itemsSpacing;
  final double sideGap;

  final BoxDecoration? decoration;
  final List<Color> backgroundBar;

  final bool showBottomBorder;
  final Color bottomBorderColor;
  final double bottomBorderWidth;

  final bool includeSafeTop;
  final double safeTopFallback;

  final double leadingSlotWidth;
  final double gapAfterLeading;
  final double actionSlotWidth;
  final double actionSpacing;

  /// Quando true, o título central respeita o espaço ocupado pelas ações.
  /// Em telas pequenas, isso pode apertar o texto.
  final bool reserveActionSpaceForTitle;

  const UpBar({
    super.key,
    this.titleHeight = 56,
    this.subtitleHeight = 30,
    this.titleWidgets,
    this.subtitleWidgets = const [],
    this.leading,
    this.leadingActions = const [],
    this.actions = const [],
    this.showNotificationBell = true,
    this.notificationBell,
    this.notificationUserId,
    this.showPhotoMenu = true,
    this.photoMenu,
    this.itemsSpacing = 12,
    this.sideGap = 8,
    this.decoration,
    this.backgroundBar = const [Color(0xFF1B2031), Color(0xFF1B2039)],
    this.showBottomBorder = true,
    this.bottomBorderColor = Colors.white,
    this.bottomBorderWidth = 1.0,
    this.includeSafeTop = true,
    this.safeTopFallback = 0,
    this.leadingSlotWidth = 60.0,
    this.gapAfterLeading = 8.0,
    this.actionSlotWidth = 40.0,
    this.actionSpacing = 12.0,
    this.reserveActionSpaceForTitle = true,
  });

  bool get _hasSubtitle => (subtitleWidgets?.isNotEmpty ?? false);

  bool get _shouldReserveLeadingSlot =>
      leading != null || leadingActions.isNotEmpty;

  bool get _hasRightFixedItems => showNotificationBell || showPhotoMenu;

  double _safeTop(BuildContext context) {
    if (!includeSafeTop) return 0.0;

    final mediaTop = MediaQuery.maybeOf(context)?.padding.top;
    if (mediaTop != null && mediaTop >= 0) {
      return mediaTop;
    }

    return safeTopFallback;
  }

  double _contentHeight() {
    return titleHeight + (_hasSubtitle ? subtitleHeight : 0.0);
  }

  double _totalHeight(BuildContext context) {
    return _safeTop(context) + _contentHeight();
  }

  double totalHeight(BuildContext context) {
    return _totalHeight(context);
  }

  @override
  Size get preferredSize {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    double safeTop = safeTopFallback;

    if (includeSafeTop && dispatcher.views.isNotEmpty) {
      final view = dispatcher.views.first;
      safeTop = view.padding.top / view.devicePixelRatio;
    }

    return Size.fromHeight(
      safeTop + titleHeight + (_hasSubtitle ? subtitleHeight : 0.0),
    );
  }

  double _reservedLeftWidth() {
    double width = sideGap;

    if (_shouldReserveLeadingSlot) {
      width += leadingSlotWidth;
    }

    if (_shouldReserveLeadingSlot && leadingActions.isNotEmpty) {
      width += gapAfterLeading;
    }

    if (leadingActions.isNotEmpty) {
      width += leadingActions.length * actionSlotWidth;

      if (leadingActions.length > 1) {
        width += (leadingActions.length - 1) * actionSpacing;
      }
    }

    return width;
  }

  double _reservedRightWidth() {
    double width = sideGap;

    if (actions.isNotEmpty) {
      width += actions.length * actionSlotWidth;

      if (actions.length > 1) {
        width += (actions.length - 1) * actionSpacing;
      }
    }

    if (actions.isNotEmpty && _hasRightFixedItems) {
      width += 8.0;
    }

    final fixedCount = [
      if (showNotificationBell) 1,
      if (showPhotoMenu) 1,
    ].length;

    if (fixedCount > 0) {
      width += fixedCount * actionSlotWidth;

      if (fixedCount > 1) {
        width += 8.0;
      }
    }

    return width;
  }

  double _adaptiveLeftPad({
    required double availableWidth,
    required double leftPad,
    required double rightPad,
  }) {
    if (!reserveActionSpaceForTitle) return sideGap;

    final remaining = availableWidth - leftPad - rightPad;

    if (remaining < 160) {
      return sideGap;
    }

    return leftPad;
  }

  double _adaptiveRightPad({
    required double availableWidth,
    required double leftPad,
    required double rightPad,
  }) {
    if (!reserveActionSpaceForTitle) return sideGap;

    final remaining = availableWidth - leftPad - rightPad;

    if (remaining < 160) {
      return sideGap;
    }

    return rightPad;
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = _safeTop(context);

    final rawLeftPad = _reservedLeftWidth();
    final rawRightPad = _reservedRightWidth();

    final bg = decoration ??
        BoxDecoration(
          border: showBottomBorder
              ? Border(
            bottom: BorderSide(
              color: bottomBorderColor,
              width: bottomBorderWidth,
            ),
          )
              : null,
          gradient: LinearGradient(
            colors: backgroundBar,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: _totalHeight(context),
        child: DecoratedBox(
          decoration: bg,
          child: Padding(
            padding: EdgeInsets.only(top: safeTop),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: titleHeight,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;

                      final leftPad = _adaptiveLeftPad(
                        availableWidth: availableWidth,
                        leftPad: rawLeftPad,
                        rightPad: rawRightPad,
                      );

                      final rightPad = _adaptiveRightPad(
                        availableWidth: availableWidth,
                        leftPad: rawLeftPad,
                        rightPad: rawRightPad,
                      );

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: leftPad,
                                right: rightPad,
                              ),
                              child: ClipRect(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      children: _withSpacing(
                                        _normalizeCenterWidgets(
                                          titleWidgets ?? const [],
                                        ),
                                        itemsSpacing,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: sideGap),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (_shouldReserveLeadingSlot)
                                    SizedBox(
                                      width: leadingSlotWidth,
                                      height: titleHeight,
                                      child: leading != null
                                          ? Align(
                                        alignment: Alignment.centerLeft,
                                        child: Tight(child: leading!),
                                      )
                                          : const SizedBox.shrink(),
                                    ),
                                  if (_shouldReserveLeadingSlot &&
                                      leadingActions.isNotEmpty)
                                    SizedBox(width: gapAfterLeading),
                                  if (leadingActions.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      children: _withSpacing(
                                        leadingActions.map((e) {
                                          return SizedBox.square(
                                            dimension: actionSlotWidth,
                                            child: Center(
                                              child: Tight(child: e),
                                            ),
                                          );
                                        }).toList(),
                                        actionSpacing,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.only(right: sideGap),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (actions.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      children: _withSpacing(
                                        actions.map((e) {
                                          return SizedBox.square(
                                            dimension: actionSlotWidth,
                                            child: Center(
                                              child: Tight(child: e),
                                            ),
                                          );
                                        }).toList(),
                                        actionSpacing,
                                      ),
                                    ),
                                  if (actions.isNotEmpty && _hasRightFixedItems)
                                    const SizedBox(width: 8),
                                  if (showNotificationBell)
                                    SizedBox.square(
                                      dimension: actionSlotWidth,
                                      child: Center(
                                        child: notificationBell ??
                                            NotificationBell(
                                              userId: notificationUserId ??
                                                  FirebaseAuth.instance
                                                      .currentUser?.uid,
                                            ),
                                      ),
                                    ),
                                  if (showNotificationBell && showPhotoMenu)
                                    const SizedBox(width: 8),
                                  if (showPhotoMenu)
                                    SizedBox.square(
                                      dimension: actionSlotWidth,
                                      child: Center(
                                        child:
                                        photoMenu ?? const PopUpPhotoMenu(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (_hasSubtitle)
                  SizedBox(
                    height: subtitleHeight,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 12),
                      child: Align(
                        alignment: Alignment.center,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: _withSpacing(
                              _normalizeCenterWidgets(
                                subtitleWidgets ?? const [],
                              ),
                              itemsSpacing,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _normalizeCenterWidgets(List<Widget> items) {
    if (items.isEmpty) return const [];

    return items.map((item) {
      if (item is Text) {
        return Text(
          item.data ?? '',
          key: item.key,
          style: item.style,
          strutStyle: item.strutStyle,
          textAlign: item.textAlign,
          textDirection: item.textDirection,
          locale: item.locale,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          textScaler: item.textScaler,
          maxLines: 1,
          semanticsLabel: item.semanticsLabel,
          textWidthBasis: item.textWidthBasis,
          textHeightBehavior: item.textHeightBehavior,
          selectionColor: item.selectionColor,
        );
      }

      return item;
    }).toList();
  }

  List<Widget> _withSpacing(List<Widget> items, double spacing) {
    if (items.isEmpty) return const [];

    final out = <Widget>[];

    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);

      if (i < items.length - 1) {
        out.add(SizedBox(width: spacing));
      }
    }

    return out;
  }
}