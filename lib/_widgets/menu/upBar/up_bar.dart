import 'package:flutter/material.dart';
import 'package:sipged/_widgets/menu/pop_up/pup_up_photo_menu.dart';
import 'package:sipged/_widgets/menu/upBar/tight.dart';

class UpBar extends StatelessWidget implements PreferredSizeWidget {
  final double titleHeight;
  final double subtitleHeight;

  final List<Widget>? titleWidgets;
  final List<Widget>? subtitleWidgets;

  final Widget? leading;
  final List<Widget> leadingActions;
  final List<Widget> actions;

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

  const UpBar({
    super.key,
    this.titleHeight = 56,
    this.subtitleHeight = 30,
    this.titleWidgets,
    this.subtitleWidgets = const [],
    this.leading,
    this.leadingActions = const [],
    this.actions = const [],
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
  });

  bool get _hasSubtitle => (subtitleWidgets?.isNotEmpty ?? false);

  bool get _shouldReserveLeadingSlot =>
      leading != null || leadingActions.isNotEmpty;

  double _safeTop(BuildContext context) {
    if (!includeSafeTop) return 0.0;

    final mediaTop = MediaQuery.maybeOf(context)?.padding.top;
    if (mediaTop != null && mediaTop >= 0) {
      return mediaTop;
    }

    return safeTopFallback;
  }

  double _contentHeight() =>
      titleHeight + (_hasSubtitle ? subtitleHeight : 0.0);

  double _totalHeight(BuildContext context) =>
      _safeTop(context) + _contentHeight();

  double totalHeight(BuildContext context) => _totalHeight(context);

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

    if (actions.isNotEmpty && showPhotoMenu) {
      width += 8.0;
    }

    if (showPhotoMenu) {
      width += actionSlotWidth;
    }

    return width;
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = _safeTop(context);
    final leftPad = _reservedLeftWidth();
    final rightPad = _reservedRightWidth();
    final photoSlotSize = actionSlotWidth;

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
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: leftPad,
                          right: rightPad,
                        ),
                        child: ClipRect(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    children: _withSpacing(
                                      titleWidgets ?? const [],
                                      itemsSpacing,
                                    ),
                                  ),
                                ),
                              );
                            },
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
                                    leadingActions,
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
                                  children: _withSpacing(actions, actionSpacing),
                                ),
                              if (actions.isNotEmpty && showPhotoMenu)
                                const SizedBox(width: 8),
                              if (showPhotoMenu)
                                SizedBox.square(
                                  dimension: photoSlotSize,
                                  child: Center(
                                    child: photoMenu ??
                                        const PopUpPhotoMenu(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                              subtitleWidgets ?? const [],
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