import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:sipged/_widgets/buttons/slider_button.dart';
import 'package:sipged/_widgets/images/gallery/photo_gallery_data.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';

class PhotoGallery extends StatelessWidget {
  const PhotoGallery({
    super.key,
    required this.groups,
    required this.tileKeys,
    required this.thumbnailSize,
    required this.selectionMode,
    required this.selectedPhotoIds,
    required this.classificationDraft,
    required this.canApplyClassification,
    required this.onClassificationChanged,
    required this.onApplyClassification,
    required this.onClearClassification,
    required this.onReorderGroupToIndex,
    required this.onMoveGroupToEnd,
    required this.onSelectionModeTap,
    required this.onThumbnailSizeChanged,
    required this.onPhotoTap,
    required this.onPhotoSelectionTap,
    required this.onPhotoLongPress,
    this.padding = const EdgeInsets.all(2),
    this.spacing = 2,
    this.minThumbnailSize = 72,
    this.maxThumbnailSize = 230,
  });

  final List<SipGedGalleryPhotoGroup> groups;
  final Map<String, GlobalKey> tileKeys;

  final double thumbnailSize;
  final bool selectionMode;
  final List<String> selectedPhotoIds;

  final String classificationDraft;
  final bool canApplyClassification;

  final ValueChanged<String> onClassificationChanged;
  final VoidCallback onApplyClassification;
  final VoidCallback onClearClassification;

  final void Function({
  required String draggedGroupId,
  required int targetIndex,
  }) onReorderGroupToIndex;

  final ValueChanged<String> onMoveGroupToEnd;

  final VoidCallback onSelectionModeTap;
  final ValueChanged<double> onThumbnailSizeChanged;
  final void Function(PhotoGalleryData photo) onPhotoTap;
  final void Function(PhotoGalleryData photo) onPhotoSelectionTap;
  final void Function(PhotoGalleryData photo) onPhotoLongPress;

  final EdgeInsetsGeometry padding;
  final double spacing;

  final double minThumbnailSize;
  final double maxThumbnailSize;

  Set<String> get _selectedPhotoIdsSet => selectedPhotoIds.toSet();

  List<PhotoGalleryData> get _allPhotos {
    return groups.expand((group) => group.photos).toList();
  }

  int _classifiedGroupIndex({
    required List<SipGedGalleryPhotoGroup> classifiedGroups,
    required String groupId,
  }) {
    return classifiedGroups.indexWhere((group) {
      return group.id == groupId;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_allPhotos.isEmpty) {
      return const _EmptyGalleryState();
    }

    final classifiedGroups = groups.where((group) {
      return group.classified;
    }).toList();

    return Stack(
      children: [
        CustomScrollView(
          physics: selectionMode
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            for (final group in groups) ...[
              if (group.classified)
                SliverToBoxAdapter(
                  child: Builder(
                    builder: (context) {
                      final groupIndex = _classifiedGroupIndex(
                        classifiedGroups: classifiedGroups,
                        groupId: group.id,
                      );

                      return _GroupReorderHeader(
                        groupId: group.id,
                        title: group.title,
                        count: group.count,
                        targetIndexBefore: groupIndex,
                        targetIndexAfter: groupIndex + 1,
                        onDropAtIndex: ({
                          required String draggedGroupId,
                          required int targetIndex,
                        }) {
                          onReorderGroupToIndex(
                            draggedGroupId: draggedGroupId,
                            targetIndex: targetIndex,
                          );
                        },
                      );
                    },
                  ),
                ),
              SliverPadding(
                padding: padding,
                sliver: SliverGrid.builder(
                  itemCount: group.photos.length,
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: thumbnailSize,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final photo = group.photos[index];
                    final selected = _selectedPhotoIdsSet.contains(photo.id);

                    return _PhotoTile(
                      key: tileKeys[photo.id],
                      photo: photo,
                      selected: selected,
                      selectionMode: selectionMode,
                      onTap: () {
                        if (selectionMode) {
                          onPhotoSelectionTap(photo);
                          return;
                        }

                        onPhotoTap(photo);
                      },
                      onLongPress: () {
                        onPhotoLongPress(photo);
                      },
                    );
                  },
                ),
              ),
              if (group.classified)
                const SliverToBoxAdapter(
                  child: SizedBox(height: 10),
                ),
            ],
            SliverToBoxAdapter(
              child: _EndGroupDropZone(
                onAccept: onMoveGroupToEnd,
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 130),
            ),
          ],
        ),
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: _TopGradientOverlay(),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BottomGradientOverlay(),
        ),
        Positioned(
          right: 14,
          top: 14,
          child: _GlassSelectionButton(
            selectionMode: selectionMode,
            selectedCount: selectedPhotoIds.length,
            onTap: onSelectionModeTap,
          ),
        ),
        if (selectionMode)
          Positioned(
            left: 14,
            right: 14,
            bottom: 22,
            child: _ClassificationGlassPanel(
              selectedCount: selectedPhotoIds.length,
              initialValue: classificationDraft,
              canApply: canApplyClassification,
              onChanged: onClassificationChanged,
              onApply: onApplyClassification,
              onClear: onClearClassification,
            ),
          )
        else
          Positioned(
            right: 12,
            bottom: 18,
            child: _ZoomGlassSlider(
              thumbnailSize: thumbnailSize,
              minThumbnailSize: minThumbnailSize,
              maxThumbnailSize: maxThumbnailSize,
              onThumbnailSizeChanged: onThumbnailSizeChanged,
            ),
          ),
      ],
    );
  }
}

class _GroupReorderHeader extends StatelessWidget {
  const _GroupReorderHeader({
    required this.groupId,
    required this.title,
    required this.count,
    required this.targetIndexBefore,
    required this.targetIndexAfter,
    required this.onDropAtIndex,
  });

  final String groupId;
  final String title;
  final int count;

  final int targetIndexBefore;
  final int targetIndexAfter;

  final void Function({
  required String draggedGroupId,
  required int targetIndex,
  }) onDropAtIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GroupInsertionDropZone(
          targetIndex: targetIndexBefore,
          height: 24,
          label: 'Soltar acima',
          onAccept: (draggedGroupId) {
            if (draggedGroupId.trim() == groupId.trim()) {
              return;
            }

            onDropAtIndex(
              draggedGroupId: draggedGroupId,
              targetIndex: targetIndexBefore,
            );
          },
        ),
        _DraggableGroupLabel(
          groupId: groupId,
          title: title,
          count: count,
        ),
        _GroupInsertionDropZone(
          targetIndex: targetIndexAfter,
          height: 24,
          label: 'Soltar abaixo',
          onAccept: (draggedGroupId) {
            if (draggedGroupId.trim() == groupId.trim()) {
              return;
            }

            onDropAtIndex(
              draggedGroupId: draggedGroupId,
              targetIndex: targetIndexAfter,
            );
          },
        ),
      ],
    );
  }
}

class _GroupInsertionDropZone extends StatelessWidget {
  const _GroupInsertionDropZone({
    required this.targetIndex,
    required this.onAccept,
    this.height = 24,
    this.label = 'Soltar aqui',
  });

  final int targetIndex;
  final ValueChanged<String> onAccept;
  final double height;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        return details.data.trim().isNotEmpty;
      },
      onAcceptWithDetails: (details) {
        onAccept(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: hovering ? height + 14 : height,
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          decoration: BoxDecoration(
            color: hovering
                ? const Color(0xFF2563EB).withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: hovering
                  ? const Color(0xFF2563EB).withValues(alpha: 0.50)
                  : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: hovering
              ? Center(
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF2563EB).withValues(alpha: 0.95),
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          )
              : const SizedBox.expand(),
        );
      },
    );
  }
}

class _DraggableGroupLabel extends StatelessWidget {
  const _DraggableGroupLabel({
    required this.groupId,
    required this.title,
    required this.count,
  });

  final String groupId;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final feedbackWidth = (screenWidth - 32).clamp(
      240.0,
      560.0,
    );

    return Draggable<String>(
      data: groupId,
      axis: Axis.vertical,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      ignoringFeedbackPointer: true,
      ignoringFeedbackSemantics: true,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: feedbackWidth,
          child: Transform.scale(
            scale: 1.02,
            alignment: Alignment.centerLeft,
            child: _GroupLabelContent(
              title: title,
              count: count,
              dragging: true,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.28,
        child: _GroupLabelContent(
          title: title,
          count: count,
          dragging: false,
        ),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: _GroupLabelContent(
          title: title,
          count: count,
          dragging: false,
        ),
      ),
    );
  }
}

class _GroupLabelContent extends StatelessWidget {
  const _GroupLabelContent({
    required this.title,
    required this.count,
    required this.dragging,
  });

  final String title;
  final int count;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 0, 5),
        child: Row(
          children: [
            Icon(
              Icons.drag_indicator_rounded,
              color: const Color(0xFF6B7280).withValues(alpha: 0.78),
              size: 15,
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 260,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: dragging
                      ? const Color(0xFF2563EB).withValues(alpha: 0.14)
                      : Colors.black.withValues(alpha: 0.055),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: dragging
                        ? const Color(0xFF2563EB).withValues(alpha: 0.24)
                        : Colors.black.withValues(alpha: 0.055),
                  ),
                  boxShadow: dragging
                      ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                      : null,
                ),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: dragging
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF111827),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                color: const Color(0xFF6B7280).withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.black.withValues(alpha: 0.075),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndGroupDropZone extends StatelessWidget {
  const _EndGroupDropZone({
    required this.onAccept,
  });

  final ValueChanged<String> onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        return details.data.trim().isNotEmpty;
      },
      onAcceptWithDetails: (details) {
        onAccept(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: hovering ? 42 : 8,
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          decoration: BoxDecoration(
            color: hovering
                ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hovering
                  ? const Color(0xFF2563EB).withValues(alpha: 0.28)
                  : Colors.transparent,
            ),
          ),
          child: hovering
              ? Center(
            child: Text(
              'Soltar no final',
              style: TextStyle(
                color: const Color(0xFF2563EB).withValues(alpha: 0.88),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class _ClassificationGlassPanel extends StatefulWidget {
  const _ClassificationGlassPanel({
    required this.selectedCount,
    required this.initialValue,
    required this.canApply,
    required this.onChanged,
    required this.onApply,
    required this.onClear,
  });

  final int selectedCount;
  final String initialValue;
  final bool canApply;

  final ValueChanged<String> onChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  State<_ClassificationGlassPanel> createState() =>
      _ClassificationGlassPanelState();
}

class _ClassificationGlassPanelState extends State<_ClassificationGlassPanel> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialValue,
    );
  }

  @override
  void didUpdateWidget(covariant _ClassificationGlassPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedText =
        '${widget.selectedCount} selecionada${widget.selectedCount == 1 ? '' : 's'}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 16,
          sigmaY: 16,
        ),
        child: Material(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _GlassCustomTextField(
                    controller: _controller,
                    selectedText: selectedText,
                    canApply: widget.canApply,
                    onChanged: widget.onChanged,
                    onApply: widget.onApply,
                    onClear: widget.onClear,
                  ),
                ),
                const SizedBox(width: 8),
                _GlassApplyButton(
                  enabled: widget.canApply,
                  onTap: widget.onApply,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCustomTextField extends StatelessWidget {
  const _GlassCustomTextField({
    required this.controller,
    required this.selectedText,
    required this.canApply,
    required this.onChanged,
    required this.onApply,
    required this.onClear,
  });

  final TextEditingController controller;
  final String selectedText;
  final bool canApply;
  final ValueChanged<String> onChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 14,
            bottom: 4,
          ),
          child: Text(
            selectedText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 11.5,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 16,
              sigmaY: 16,
            ),
            child: CustomTextField(
              controller: controller,
              height: 44,
              maxLines: 1,
              labelText: null,
              hintText: 'Classificar como...',
              onChanged: onChanged,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (canApply) {
                  onApply();
                }
              },
              valueColor: const Color(0xFF111827),
              textStyle: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
              textFontSize: 13.5,
              fillCollor: Colors.white.withValues(alpha: 0.82),
              outlined: true,
              borderRadius: 999,
              borderColor: Colors.white.withValues(alpha: 0.42),
              focusedBorderColor: Colors.white.withValues(alpha: 0.88),
              borderWidth: 1,
              isDense: true,
              textAlignVertical: TextAlignVertical.center,
              contentPadding: const EdgeInsets.only(
                left: 14,
                right: 8,
                top: 12,
                bottom: 12,
              ),
              hintStyle: TextStyle(
                color: const Color(0xFF6B7280).withValues(alpha: 0.78),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              suffix: _InsideClearButton(
                onTap: onClear,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 38,
                minHeight: 38,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InsideClearButton extends StatelessWidget {
  const _InsideClearButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Cancelar seleção',
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Material(
          color: Colors.black.withValues(alpha: 0.08),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const SizedBox(
              width: 30,
              height: 30,
              child: Icon(
                Icons.close_rounded,
                color: Color(0xFF111827),
                size: 19,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassApplyButton extends StatelessWidget {
  const _GlassApplyButton({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Aplicar grupo',
      child: Material(
        color: enabled
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.07),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              Icons.check_rounded,
              color: enabled
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.36),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomGlassSlider extends StatelessWidget {
  const _ZoomGlassSlider({
    required this.thumbnailSize,
    required this.minThumbnailSize,
    required this.maxThumbnailSize,
    required this.onThumbnailSizeChanged,
  });

  final double thumbnailSize;
  final double minThumbnailSize;
  final double maxThumbnailSize;
  final ValueChanged<double> onThumbnailSizeChanged;

  @override
  Widget build(BuildContext context) {
    final zoomListenable = ValueNotifier<double>(thumbnailSize);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: SliderButton(
          zoomListenable: zoomListenable,
          minZoom: minThumbnailSize,
          maxZoom: maxThumbnailSize,
          step: 12,
          sliderHeight: 150,
          buttonWidth: 34,
          buttonHeight: 34,
          borderRadius: 12,
          backgroundColor: Colors.black.withValues(alpha: 0.28),
          iconColor: Colors.white,
          activeColor: Colors.white,
          inactiveColor: Colors.white.withValues(alpha: 0.32),
          thumbColor: Colors.white,
          onZoomChanged: onThumbnailSizeChanged,
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    super.key,
    required this.photo,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  final PhotoGalleryData photo;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE5E7EB),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'sipged-gallery-photo-${photo.id}',
              child: Image.network(
                photo.url,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    return child;
                  }

                  return const _PhotoLoadingPlaceholder();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return const _PhotoLoadingPlaceholder();
                },
                errorBuilder: (context, error, stackTrace) {
                  return const _PhotoErrorPlaceholder();
                },
              ),
            ),
            if (selectionMode)
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.black.withValues(alpha: 0.30)
                      : Colors.black.withValues(alpha: 0.08),
                  border: Border.all(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.32),
                    width: selected ? 3 : 1,
                  ),
                ),
              ),
            if (selectionMode)
              Positioned(
                right: 7,
                top: 7,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white
                        : Colors.black.withValues(alpha: 0.30),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.4,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF111827),
                    size: 18,
                  )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SipGedPhotoPreviewPage extends StatefulWidget {
  const SipGedPhotoPreviewPage({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  final List<PhotoGalleryData> photos;
  final int initialIndex;

  @override
  State<SipGedPhotoPreviewPage> createState() => _SipGedPhotoPreviewPageState();
}

class _SipGedPhotoPreviewPageState extends State<SipGedPhotoPreviewPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;
    _pageController = PageController(
      initialPage: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _close() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.photos.length,
              onPageChanged: (index) {
                _currentIndex = index;

                if (context.mounted) {
                  setState(() {});
                }
              },
              itemBuilder: (context, index) {
                final photo = widget.photos[index];

                return Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 5,
                    clipBehavior: Clip.none,
                    child: Hero(
                      tag: 'sipged-gallery-photo-${photo.id}',
                      child: Image.network(
                        photo.url,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.broken_image_rounded,
                            color: Colors.white54,
                            size: 56,
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: _TopGradientOverlay(),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomGradientOverlay(),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: _PreviewButton(
                icon: Icons.close_rounded,
                onTap: _close,
              ),
            ),
            Positioned(
              right: 16,
              top: 20,
              child: Text(
                '${_currentIndex + 1}/${widget.photos.length}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassSelectionButton extends StatelessWidget {
  const _GlassSelectionButton({
    required this.selectionMode,
    required this.selectedCount,
    required this.onTap,
  });

  final bool selectionMode;
  final int selectedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = selectionMode
        ? selectedCount > 0
        ? '$selectedCount selecionada${selectedCount == 1 ? '' : 's'}'
        : 'Cancelar'
        : 'Selecionar';

    final icon =
    selectionMode ? Icons.close_rounded : Icons.check_circle_outline_rounded;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 16,
          sigmaY: 16,
        ),
        child: Material(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _TopGradientOverlay extends StatelessWidget {
  const _TopGradientOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.30),
              Colors.black.withValues(alpha: 0.10),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomGradientOverlay extends StatelessWidget {
  const _BottomGradientOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: 142,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.42),
              Colors.black.withValues(alpha: 0.16),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoLoadingPlaceholder extends StatelessWidget {
  const _PhotoLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE5E7EB),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}

class _PhotoErrorPlaceholder extends StatelessWidget {
  const _PhotoErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE5E7EB),
      child: const Icon(
        Icons.broken_image_rounded,
        color: Color(0xFF9CA3AF),
        size: 28,
      ),
    );
  }
}

class _EmptyGalleryState extends StatelessWidget {
  const _EmptyGalleryState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.photo_library_outlined,
        color: Color(0xFF9CA3AF),
        size: 42,
      ),
    );
  }
}