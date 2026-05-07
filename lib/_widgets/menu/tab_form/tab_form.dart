// lib/_widgets/menu/tab_form.dart

import 'package:flutter/material.dart';

import 'package:sipged/_utils/theme/sipged_theme.dart';

class TabFormItem {
  const TabFormItem({
    required this.title,
    required this.child,
    this.icon,
    this.enabled = true,
  });

  final String title;
  final IconData? icon;
  final Widget child;
  final bool enabled;
}

class TabForm extends StatefulWidget {
  const TabForm({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.height,
    this.minHeight = 0,
    this.onChanged,
    this.margin = EdgeInsets.zero,
    this.padding = const EdgeInsets.all(12),
    this.backgroundColor = SipGedTheme.tabFormBackground,
    this.borderColor = SipGedTheme.tabFormBorder,
    this.selectedColor = SipGedTheme.tabFormSelectedForeground,
    this.unselectedColor = SipGedTheme.tabFormUnselectedForeground,
    this.selectedBackgroundColor = SipGedTheme.tabFormSelectedBackground,
    this.unselectedBackgroundColor = SipGedTheme.tabFormUnselectedBackground,
    this.tabBarBackgroundColor = SipGedTheme.tabFormHeaderBackground,
    this.borderRadius = 8,
    this.tabRadius = 8,
    this.animationDuration = const Duration(milliseconds: 280),
    this.enableSwipe = true,
    this.swipeThreshold = 48,
    this.borderWidth = 1,
  });

  final List<TabFormItem> items;
  final int initialIndex;

  /// Se informado, a área do conteúdo fica com altura fixa e rolagem interna.
  /// Se null, o container ajusta a altura automaticamente conforme o conteúdo.
  final double? height;

  /// Altura mínima quando [height] for null.
  final double minHeight;

  final ValueChanged<int>? onChanged;

  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  final Color backgroundColor;
  final Color borderColor;

  final Color selectedColor;
  final Color unselectedColor;

  final Color selectedBackgroundColor;
  final Color unselectedBackgroundColor;
  final Color tabBarBackgroundColor;

  final double borderRadius;
  final double tabRadius;
  final double borderWidth;

  final Duration animationDuration;

  final bool enableSwipe;
  final double swipeThreshold;

  @override
  State<TabForm> createState() => _TabFormState();
}

class _TabFormState extends State<TabForm> with TickerProviderStateMixin {
  late int _selectedIndex;
  int _previousIndex = 0;

  double _dragDx = 0;

  int get _safeInitialIndex {
    if (widget.items.isEmpty) return 0;

    if (widget.initialIndex < 0) return 0;

    if (widget.initialIndex >= widget.items.length) {
      return widget.items.length - 1;
    }

    return widget.initialIndex;
  }

  bool get _hasFixedHeight => widget.height != null;

  @override
  void initState() {
    super.initState();

    _selectedIndex = _safeInitialIndex;
    _previousIndex = _selectedIndex;
  }

  @override
  void didUpdateWidget(covariant TabForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.items.isEmpty) {
      if (_selectedIndex != 0) {
        setState(() {
          _previousIndex = _selectedIndex;
          _selectedIndex = 0;
        });
      }

      return;
    }

    if (_selectedIndex >= widget.items.length) {
      final nextIndex = widget.items.length - 1;

      setState(() {
        _previousIndex = _selectedIndex;
        _selectedIndex = nextIndex;
      });

      widget.onChanged?.call(nextIndex);
    }
  }

  void _selectTab(int index) {
    if (index < 0 || index >= widget.items.length) return;

    final item = widget.items[index];

    if (!item.enabled) return;

    if (_selectedIndex == index) return;

    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });

    widget.onChanged?.call(index);
  }

  int _findPreviousEnabledIndex() {
    for (int index = _selectedIndex - 1; index >= 0; index--) {
      if (widget.items[index].enabled) return index;
    }

    return _selectedIndex;
  }

  int _findNextEnabledIndex() {
    for (int index = _selectedIndex + 1; index < widget.items.length; index++) {
      if (widget.items[index].enabled) return index;
    }

    return _selectedIndex;
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _dragDx = 0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _dragDx += details.delta.dx;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!widget.enableSwipe) return;

    final velocity = details.primaryVelocity ?? 0;
    final shouldMoveLeft = _dragDx < -widget.swipeThreshold || velocity < -500;
    final shouldMoveRight = _dragDx > widget.swipeThreshold || velocity > 500;

    if (shouldMoveLeft) {
      _selectTab(_findNextEnabledIndex());
      return;
    }

    if (shouldMoveRight) {
      _selectTab(_findPreviousEnabledIndex());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedChild = widget.items[_selectedIndex].child;
    final radius = BorderRadius.circular(widget.borderRadius);

    return Container(
      margin: widget.margin,

      /// Fundo do container.
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: radius,
      ),

      /// Borda desenhada por cima dos filhos.
      /// Isso impede o fundo da aba selecionada de "cortar" a borda.
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: widget.borderColor,
          width: widget.borderWidth,
        ),
      ),

      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TabFormHeader(
            items: widget.items,
            selectedIndex: _selectedIndex,
            onTap: _selectTab,
            selectedColor: widget.selectedColor,
            unselectedColor: widget.unselectedColor,
            selectedBackgroundColor: widget.selectedBackgroundColor,
            unselectedBackgroundColor: widget.unselectedBackgroundColor,
            tabBarBackgroundColor: widget.tabBarBackgroundColor,
            tabRadius: widget.tabRadius,
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart:
            widget.enableSwipe ? _onHorizontalDragStart : null,
            onHorizontalDragUpdate:
            widget.enableSwipe ? _onHorizontalDragUpdate : null,
            onHorizontalDragEnd:
            widget.enableSwipe ? _onHorizontalDragEnd : null,
            child: _hasFixedHeight
                ? SizedBox(
              height: widget.height,
              child: _AnimatedTabBody(
                selectedIndex: _selectedIndex,
                previousIndex: _previousIndex,
                duration: widget.animationDuration,
                padding: widget.padding,
                fixedHeight: true,
                child: selectedChild,
              ),
            )
                : ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: widget.minHeight,
              ),
              child: AnimatedSize(
                duration: widget.animationDuration,
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _AnimatedTabBody(
                  selectedIndex: _selectedIndex,
                  previousIndex: _previousIndex,
                  duration: widget.animationDuration,
                  padding: widget.padding,
                  fixedHeight: false,
                  child: selectedChild,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedTabBody extends StatelessWidget {
  const _AnimatedTabBody({
    required this.selectedIndex,
    required this.previousIndex,
    required this.duration,
    required this.padding,
    required this.fixedHeight,
    required this.child,
  });

  final int selectedIndex;
  final int previousIndex;
  final Duration duration;
  final EdgeInsetsGeometry padding;
  final bool fixedHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final direction = selectedIndex >= previousIndex ? 1.0 : -1.0;

    final content = Padding(
      padding: padding,
      child: child,
    );

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        final isIncoming = child.key == ValueKey<int>(selectedIndex);

        final beginOffset = isIncoming
            ? Offset(direction, 0)
            : Offset(-direction * 0.35, 0);

        final offsetAnimation = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
      child: fixedHeight
          ? SingleChildScrollView(
        key: ValueKey<int>(selectedIndex),
        physics: const BouncingScrollPhysics(),
        child: content,
      )
          : KeyedSubtree(
        key: ValueKey<int>(selectedIndex),
        child: content,
      ),
    );
  }
}

class _TabFormHeader extends StatelessWidget {
  const _TabFormHeader({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
    required this.selectedBackgroundColor,
    required this.unselectedBackgroundColor,
    required this.tabBarBackgroundColor,
    required this.tabRadius,
  });

  final List<TabFormItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedBackgroundColor;
  final Color unselectedBackgroundColor;
  final Color tabBarBackgroundColor;
  final double tabRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: tabBarBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: SipGedTheme.blackAlpha(0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            Expanded(
              child: _TabFormButton(
                item: items[index],
                selected: selectedIndex == index,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                selectedBackgroundColor: selectedBackgroundColor,
                unselectedBackgroundColor: unselectedBackgroundColor,
                radius: tabRadius,
                onTap: () => onTap(index),
              ),
            ),
            if (index < items.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _TabFormButton extends StatelessWidget {
  const _TabFormButton({
    required this.item,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.selectedBackgroundColor,
    required this.unselectedBackgroundColor,
    required this.radius,
    required this.onTap,
  });

  final TabFormItem item;
  final bool selected;

  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedBackgroundColor;
  final Color unselectedBackgroundColor;

  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = item.enabled;

    final foregroundColor = !enabled
        ? SipGedTheme.tabFormDisabledForeground
        : selected
        ? selectedColor
        : unselectedColor;

    final backgroundColor =
    selected ? selectedBackgroundColor : unselectedBackgroundColor;

    final borderColor =
    selected ? selectedBackgroundColor : SipGedTheme.transparent;

    final overlayColor = selected
        ? SipGedTheme.whiteAlpha(0.08)
        : selectedBackgroundColor.withValues(alpha: 0.08);

    return Material(
      color: SipGedTheme.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(radius),
        overlayColor: WidgetStatePropertyAll<Color>(overlayColor),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: selectedBackgroundColor.withValues(alpha: 0.24),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: 18,
                  color: foregroundColor,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight:
                    selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}