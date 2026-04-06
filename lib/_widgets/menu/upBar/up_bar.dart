import 'package:flutter/material.dart';
import 'package:sipged/_widgets/menu/pop_up/pup_up_photo_menu.dart';
import 'package:sipged/_widgets/menu/upBar/tight.dart';

class UpBar extends StatelessWidget implements PreferredSizeWidget {
  final double titleHeight;
  final double subtitleHeight;

  final List<Widget>? titleWidgets;
  final List<Widget>? subtitleWidgets;

  /// Botão principal da esquerda (menu principal, voltar, etc.)
  final Widget? leading;

  /// Botões adicionais à esquerda, exibidos logo após o slot do leading.
  final List<Widget> leadingActions;

  /// Ações da direita.
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

  /// Largura do slot reservado ao leading.
  final double leadingSlotWidth;

  /// Espaço entre o leading e os botões adicionais à esquerda.
  final double gapAfterLeading;

  /// Largura reservada para cada ação lateral.
  final double actionSlotWidth;

  /// Espaçamento entre ações laterais.
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

  /// Regra inteligente:
  /// - se existe leading, reserva o slot;
  /// - se não existe leading, mas existem leadingActions, também reserva;
  /// - caso contrário, não reserva.
  bool get _shouldReserveLeadingSlot =>
      leading != null || leadingActions.isNotEmpty;

  double _windowTopPaddingRaw() {
    if (!includeSafeTop) return 0.0;

    try {
      final dispatcher = WidgetsBinding.instance.platformDispatcher;
      if (dispatcher.views.isEmpty) return safeTopFallback;

      final view = dispatcher.views.first;
      final paddingTop = view.padding.top / view.devicePixelRatio;

      if (paddingTop.isFinite && paddingTop >= 0) {
        return paddingTop;
      }
    } catch (_) {}

    return safeTopFallback;
  }

  double _devicePixelRatio() {
    try {
      final dispatcher = WidgetsBinding.instance.platformDispatcher;
      if (dispatcher.views.isEmpty) return 1.0;
      return dispatcher.views.first.devicePixelRatio;
    } catch (_) {
      return 1.0;
    }
  }

  double _snapToPhysicalPixel(double value) {
    final dpr = _devicePixelRatio();
    if (dpr <= 0) return value;
    return (value * dpr).roundToDouble() / dpr;
  }

  double _safeTop() => _snapToPhysicalPixel(_windowTopPaddingRaw());

  double _contentHeight() =>
      titleHeight + (_hasSubtitle ? subtitleHeight : 0.0);

  double _totalHeight() => _safeTop() + _contentHeight();

  double totalHeight(BuildContext context) => _totalHeight();

  @override
  Size get preferredSize => Size.fromHeight(_totalHeight());

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
    final double safeTop = _safeTop();
    final double leftPad = _reservedLeftWidth();
    final double rightPad = _reservedRightWidth();

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
        height: _totalHeight(),
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
                            children: [
                              if (_shouldReserveLeadingSlot)
                                SizedBox(
                                  width: leadingSlotWidth,
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
                            children: [
                              if (actions.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children:
                                  _withSpacing(actions, actionSpacing),
                                ),
                              if (actions.isNotEmpty && showPhotoMenu)
                                const SizedBox(width: 8),
                              if (showPhotoMenu)
                                Tight(
                                  child: photoMenu ?? const PopUpPhotoMenu(),
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