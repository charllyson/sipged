import 'package:flutter/material.dart';
import 'package:sipged/_widgets/toolBox/flyout_list.dart';
import 'package:sipged/_widgets/toolBox/panel_shell.dart';
import 'package:sipged/_widgets/toolBox/tool_button.dart';
import 'package:sipged/_widgets/toolBox/tool_box_controller.dart';
import 'package:sipged/_widgets/toolBox/tool_slot.dart';

enum AIDockSide { left, right }

class ToolDock extends StatefulWidget {
  const ToolDock({
    super.key,
    required this.slots,
    this.controller,
    this.side = AIDockSide.left,
    this.radius = 8,
    this.iconSize = 18,
    this.buttonSize = 34,
    this.spacing = 6,
    this.background = const Color(0xFF3C3C3C),
    this.border = const Color(0xFF6E6E6E),
    this.iconColor = Colors.white,
    this.activeBorder = const Color(0xFF8CC8FF),
    this.flyoutBg = const Color(0xFF3C3C3C),
    this.flyoutMaxHeight = 280,
    this.gapDockFlyout = 4,
    this.gapFlyoutSide = 4,
    this.onSelectionChanged,
    this.initialSelectedId,
    this.onBeforeOpenMenu,
  });

  final List<ToolSlot> slots;
  final ToolBoxController? controller;
  final AIDockSide side;
  final double radius;
  final double iconSize;
  final double buttonSize;
  final double spacing;

  final Color background;
  final Color border;
  final Color iconColor;
  final Color activeBorder;

  final Color flyoutBg;
  final double flyoutMaxHeight;

  final double gapDockFlyout;
  final double gapFlyoutSide;

  final void Function(String selectedId)? onSelectionChanged;
  final String? initialSelectedId;
  final VoidCallback? onBeforeOpenMenu;

  @override
  State<ToolDock> createState() => ToolDockState();
}

class ToolDockState extends State<ToolDock> {
  OverlayEntry? _overlayEntry;
  String? _openSlotId;
  String? _selectedId;
  late final Map<String, ToolSlot> _byId;

  final Map<String, LayerLink> _links = {};
  LayerLink linkFor(String id) => _links.putIfAbsent(id, () => LayerLink());
  final LayerLink _flyoutLink = LayerLink();

  // ícone dinâmico por slot (última ação escolhida)
  final Map<String, IconData> _iconOverrides = {};

  // terceiro menu (side)
  Widget Function(VoidCallback close)? _sideBuilder;
  bool _sideOpenToLeft = true;
  double _sideDy = 0;
  double _sideGap = 4;
  double _sideMaxHeight = 320;

  static const double kItemExtent = 36;
  static const double kFlyoutInnerPadV = 4;

  @override
  void initState() {
    super.initState();
    _byId = {for (final s in widget.slots) s.id: s};
    for (final id in _byId.keys) linkFor(id);
    _selectedId = widget.initialSelectedId;
    widget.controller?.attach(this);
  }

  @override
  void didUpdateWidget(covariant ToolDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach();
      widget.controller?.attach(this);
    }
    _byId
      ..clear()
      ..addEntries(widget.slots.map((s) => MapEntry(s.id, s)));
    for (final id in _byId.keys) linkFor(id);
  }

  @override
  void dispose() {
    closeAnyMenu();
    widget.controller?.detach();
    super.dispose();
  }

  void _setSelected(String id) {
    setState(() => _selectedId = id);
    widget.onSelectionChanged?.call(id);
  }

  void closeSideSubmenu() {
    if (_sideBuilder != null) {
      _sideBuilder = null;
      _overlayEntry?.markNeedsBuild();
    }
  }

  void closeAnyMenu() {
    closeSideSubmenu();
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _openSlotId = null);
  }

  void _openFlyout(ToolSlot slot, Size buttonSize, {bool selectOnOpen = true}) {
    widget.onBeforeOpenMenu?.call();
    closeAnyMenu();

    if (selectOnOpen) {
      _setSelected(slot.id); // selecionar só quando veio de clique
    }

    final opensToRight = widget.side == AIDockSide.left;
    final dx = opensToRight ? (buttonSize.width + widget.gapDockFlyout) : -(widget.gapDockFlyout);
    _openSlotId = slot.id;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: closeAnyMenu,
              ),
            ),
            CompositedTransformFollower(
              link: linkFor(slot.id),
              showWhenUnlinked: false,
              targetAnchor: Alignment.topLeft,
              followerAnchor: Alignment.topLeft,
              offset: Offset(dx, 0.0),
              child: CompositedTransformTarget(
                link: _flyoutLink,
                child: PanelShell(
                  bg: widget.flyoutBg,
                  maxHeight: widget.flyoutMaxHeight,
                  child: FlyoutList(
                    maxHeight: widget.flyoutMaxHeight,
                    items: slot.flyout,
                    onItemTap: (index, action) {
                      if (action.sideBuilder != null) {
                        _sideBuilder    = action.sideBuilder;
                        _sideOpenToLeft = action.sideOpenToLeft;
                        _sideDy         = kFlyoutInnerPadV + index * kItemExtent;
                        _sideGap        = widget.gapFlyoutSide;
                        _sideMaxHeight  = action.sideMaxHeight;
                        _overlayEntry?.markNeedsBuild();
                      } else {
                        // ⚠️ Seleciona o slot APENAS ao escolher uma ação (por clique)
                        _setSelected(slot.id);
                        closeAnyMenu();
                        action.onTap?.call();
                        setState(() => _iconOverrides[slot.id] = action.icon);
                      }
                    },
                    onItemHover: (index, action) {
                      if (action.sideBuilder != null) {
                        _sideBuilder    = action.sideBuilder;
                        _sideOpenToLeft = action.sideOpenToLeft;
                        _sideDy         = kFlyoutInnerPadV + index * kItemExtent;
                        _sideGap        = widget.gapFlyoutSide;
                        _sideMaxHeight  = action.sideMaxHeight;
                        _overlayEntry?.markNeedsBuild();
                      } else {
                        closeSideSubmenu();
                      }
                    },
                  ),
                ),
              ),
            ),
            if (_sideBuilder != null)
              CompositedTransformFollower(
                link: _flyoutLink,
                showWhenUnlinked: false,
                targetAnchor: _sideOpenToLeft ? Alignment.topLeft : Alignment.topRight,
                followerAnchor: _sideOpenToLeft ? Alignment.topRight : Alignment.topLeft,
                offset: Offset(_sideOpenToLeft ? -_sideGap : _sideGap, _sideDy),
                child: PanelShell(
                  bg: widget.flyoutBg,
                  maxHeight: _sideMaxHeight,
                  child: _sideBuilder!.call(closeSideSubmenu),
                ),
              ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {});
  }


  // API usada pelos controladores externos
  void openSideSubmenu({
    required String slotId,
    required Widget Function(VoidCallback close) builder,
    required bool openToLeft,
    required double dy,
    required double gap,
    required double maxHeight,
  }) {
    _sideBuilder    = builder;
    _sideOpenToLeft = openToLeft;
    _sideDy         = dy;
    _sideGap        = gap;
    _sideMaxHeight  = maxHeight;
    _overlayEntry?.markNeedsBuild();
  }

  void openCustomPanel({
    required String slotId,
    required Widget Function(VoidCallback close) builder,
    required double minWidth,
    required double maxHeight,
  }) {
    final slot = _byId[slotId];
    if (slot == null) return;

    widget.onBeforeOpenMenu?.call();
    closeAnyMenu();
    _setSelected(slot.id);

    final opensToRight = widget.side == AIDockSide.left;
    final dx = opensToRight
        ? (widget.buttonSize + widget.gapDockFlyout)
        : -(widget.gapDockFlyout);
    _openSlotId = slot.id;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: closeAnyMenu,
              ),
            ),
            CompositedTransformFollower(
              link: linkFor(slot.id),
              showWhenUnlinked: false,
              targetAnchor: Alignment.topLeft,
              followerAnchor: Alignment.topLeft,
              offset: Offset(dx, 0.0),
              child: PanelShell(
                bg: widget.flyoutBg,
                maxHeight: maxHeight,
                child: builder(closeAnyMenu),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.radius),
        side: BorderSide(color: widget.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final slot in widget.slots) ...[
              ToolButton(
                slot: slot,
                displayIcon: _iconOverrides[slot.id] ?? slot.icon,
                isOpen: _openSlotId == slot.id,
                isSelected: _selectedId == slot.id,
                side: widget.side,
                buttonSize: widget.buttonSize,
                iconSize: widget.iconSize,
                iconColor: widget.iconColor,
                activeBorder: widget.activeBorder,
                layerLink: linkFor(slot.id),
                onTap: () {
                  closeAnyMenu();
                  _setSelected(slot.id);     // clique seleciona
                  slot.onTapMain?.call();
                },
                onLongPress: (btnSize) {
                  if (slot.flyout.isNotEmpty) {
                    _openFlyout(slot, btnSize, selectOnOpen: false); // não seleciona
                  } else {
                    closeAnyMenu();
                    _setSelected(slot.id);
                    slot.onTapMain?.call();
                  }
                },
                onHoverOpen: (btnSize) {
                  if (slot.flyout.isEmpty) return;
                  _openFlyout(slot, btnSize, selectOnOpen: false); // não seleciona
                },
              ),
              SizedBox(height: widget.spacing),
            ],
          ],
        ),
      ),
    );
  }
}
