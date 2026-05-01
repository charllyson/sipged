import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/map/search/search_box.dart';

import 'search_suggestion.dart';

enum SearchExpandSide { left, right }

class SearchOverlay {
  SearchOverlay(
      this.context,
      this.controller,
      this.onSearch, {
        required this.buttonKey,
        this.maxWidth = 340,
        this.height = 42,
        this.hintText = 'Buscar...',
        this.hintColor,
        this.expandSide = SearchExpandSide.left,
        this.fetchSuggestions,
        this.onSuggestionTap,
      });

  final BuildContext context;
  final TextEditingController controller;
  final void Function(String)? onSearch;

  final GlobalKey buttonKey;
  final double maxWidth;
  final double height;
  final String hintText;
  final Color? hintColor;
  final SearchExpandSide expandSide;

  final Future<List<SearchSuggestion<dynamic>>> Function(String)?
  fetchSuggestions;
  final void Function(SearchSuggestion<dynamic>)? onSuggestionTap;

  OverlayEntry? _entry;

  bool _visible = false;
  bool _expanded = false;
  bool _loading = false;
  bool _listeningController = false;
  bool _disposed = false;

  final List<SearchSuggestion<dynamic>> _suggestions =
  <SearchSuggestion<dynamic>>[];

  Timer? _debounce;
  int _reqSeq = 0;

  void toggleOverlay() {
    if (_disposed) return;
    _visible ? _close() : _open();
  }

  void dispose() {
    _disposed = true;

    _debounce?.cancel();
    _debounce = null;

    _removeControllerListening();

    try {
      _entry?.remove();
    } catch (_) {}

    _entry = null;
    _visible = false;
    _suggestions.clear();
    _loading = false;
    _reqSeq++;
  }

  Rect _anchorRect() {
    final box = buttonKey.currentContext?.findRenderObject() as RenderBox?;

    if (box == null || !box.hasSize) return Rect.zero;

    final topLeft = box.localToGlobal(Offset.zero);
    final size = box.size;

    return Rect.fromLTWH(
      topLeft.dx,
      topLeft.dy,
      size.width,
      size.height,
    );
  }

  void _ensureControllerListening() {
    if (_listeningController) return;

    controller.addListener(_onQueryChanged);
    _listeningController = true;
  }

  void _removeControllerListening() {
    if (!_listeningController) return;

    controller.removeListener(_onQueryChanged);
    _listeningController = false;
  }

  void _open() {
    if (_disposed) return;
    if (_visible) return;

    final overlay = Overlay.of(context);

    _expanded = false;
    _ensureControllerListening();

    _entry = OverlayEntry(
      builder: (ctx) {
        final media = MediaQuery.of(ctx);

        final r = _anchorRect();

        if (r == Rect.zero) {
          Future.microtask(_close);
          return const SizedBox.shrink();
        }

        final available = media.size.width - 32.0;
        final targetMax = math.max(
          200.0,
          math.min(maxWidth, available),
        ).toDouble();

        final top = (r.top + (r.height - height) / 2).clamp(
          8.0,
          media.size.height - height - 8.0,
        );

        final originX = expandSide == SearchExpandSide.left ? r.right : r.left;

        const double listTopGap = 6.0;
        const double itemH = 52.0;
        const int maxItems = 6;
        const double listMaxH = itemH * maxItems + 4.0;

        final endWidth = _expanded ? targetMax : 0.0;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _close,
              ),
            ),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              tween: Tween<double>(
                begin: 0.0,
                end: endWidth,
              ),
              builder: (ctx, w, child) {
                final left = expandSide == SearchExpandSide.left
                    ? originX - w
                    : originX;

                final canInteract = w >= 12.0;

                return Stack(
                  children: [
                    Positioned(
                      top: top,
                      left: left,
                      width: w,
                      height: height,
                      child: IgnorePointer(
                        ignoring: !canInteract,
                        child: SearchBox(
                          controller: controller,
                          hintText: hintText,
                          hintColor: hintColor,
                          onSubmit: (text) {
                            _close();
                            onSearch?.call(text);
                          },
                          onClear: () => controller.clear(),
                          onClose: _close,
                        ),
                      ),
                    ),
                    if (canInteract && (_loading || _suggestions.isNotEmpty))
                      Positioned(
                        top: top + height + listTopGap,
                        left: left,
                        width: w,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: listMaxH,
                          ),
                          child: Material(
                            elevation: 14,
                            shadowColor: Colors.black45,
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                            clipBehavior: Clip.antiAlias,
                            child: _loading
                                ? const _OverlayLoading()
                                : _SuggestionsList(
                              suggestions: _suggestions,
                              onSuggestionTap: (s) {
                                onSuggestionTap?.call(s);
                                _close();
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );

    overlay.insert(_entry!);
    _visible = true;

    Future.microtask(() {
      if (_disposed) return;
      if (!_visible) return;

      _expanded = true;
      _entry?.markNeedsBuild();
    });

    if (controller.text.trim().isNotEmpty) {
      _scheduleFetch();
    }
  }

  void _close() async {
    if (_disposed) return;
    if (!_visible) return;

    _expanded = false;
    _entry?.markNeedsBuild();

    _debounce?.cancel();
    _debounce = null;

    _removeControllerListening();

    await Future.delayed(const Duration(milliseconds: 200));

    if (_disposed) return;

    try {
      _entry?.remove();
    } catch (_) {}

    _entry = null;
    _visible = false;
    _suggestions.clear();
    _loading = false;
    _reqSeq++;
  }

  void _onQueryChanged() {
    _scheduleFetch();
  }

  void _scheduleFetch() {
    if (fetchSuggestions == null) return;

    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      _fetchNow,
    );
  }

  Future<void> _fetchNow() async {
    if (_disposed) return;
    if (fetchSuggestions == null) return;
    if (!_visible) return;

    final q = controller.text.trim();

    if (q.isEmpty) {
      _suggestions.clear();
      _loading = false;
      _entry?.markNeedsBuild();
      return;
    }

    final mySeq = ++_reqSeq;

    _loading = true;
    _entry?.markNeedsBuild();

    try {
      final list = await fetchSuggestions!(q);

      if (_disposed) return;
      if (!_visible) return;
      if (mySeq != _reqSeq) return;

      _suggestions
        ..clear()
        ..addAll(list);
    } catch (_) {
      if (_disposed) return;
      if (!_visible) return;
      if (mySeq != _reqSeq) return;

      _suggestions.clear();
    } finally {
      if (!_disposed && _visible && mySeq == _reqSeq) {
        _loading = false;
        _entry?.markNeedsBuild();
      }
    }
  }

  static IconData iconForKind(SuggestionKind kind) {
    switch (kind) {
      case SuggestionKind.address:
      case SuggestionKind.coordinate:
        return Icons.place_outlined;
      case SuggestionKind.contract:
        return Icons.description_outlined;
      case SuggestionKind.user:
        return Icons.person_outline;
      case SuggestionKind.roadSegment:
        return Icons.alt_route_outlined;
      case SuggestionKind.custom:
        return Icons.search;
    }
  }
}

class _SuggestionsList extends StatelessWidget {
  const _SuggestionsList({
    required this.suggestions,
    required this.onSuggestionTap,
  });

  final List<SearchSuggestion<dynamic>> suggestions;
  final ValueChanged<SearchSuggestion<dynamic>> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Scrollbar(
      thumbVisibility: true,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: suggestions.length,
        separatorBuilder: (_, _) {
          return const Divider(
            height: 1,
            thickness: 0.5,
          );
        },
        itemBuilder: (ctx, i) {
          final s = suggestions[i];

          return ListTile(
            dense: true,
            leading: Icon(
              s.icon ?? SearchOverlay.iconForKind(s.kind),
              size: 20,
              color: Colors.black54,
            ),
            title: Text(
              s.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            subtitle: (s.subtitle?.isNotEmpty ?? false)
                ? Text(
              s.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            )
                : null,
            onTap: () => onSuggestionTap(s),
          );
        },
      ),
    );
  }
}

class _OverlayLoading extends StatelessWidget {
  const _OverlayLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingTreeDots(
            size: 28,
            centered: false,
          ),
          SizedBox(width: 10),
          Text(
            'Buscando...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}