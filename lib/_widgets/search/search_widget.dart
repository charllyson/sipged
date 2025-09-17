import 'package:flutter/material.dart';
import '../suggestions/suggestion_models.dart';
import 'search_overlay.dart';

class SearchAction extends StatefulWidget {
  // Callbacks
  final void Function(String)? onSearch;
  final Future<List<SearchSuggestion>> Function(String)? fetchSuggestions;
  final void Function(SearchSuggestion)? onSuggestionTap;

  // Aparência do botão circular (igual aos seus 48x48 pretinho translúcido)
  final String tooltip;
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;

  // Aparência do campo
  final double maxWidth;
  final double height;
  final String hintText;
  final Color? hintColor;

  // Para onde o campo expande (se o botão está no topo direito, use left)
  final SearchExpandSide expandSide;

  const SearchAction({
    super.key,
    this.onSearch,
    this.fetchSuggestions,
    this.onSuggestionTap,
    this.tooltip = 'Buscar',
    this.backgroundColor = Colors.transparent,
    this.iconColor = Colors.white,
    this.icon = Icons.search,
    this.maxWidth = 340,
    this.height = 42,
    this.hintText = 'Buscar...',
    this.hintColor,
    this.expandSide = SearchExpandSide.left,
  });

  @override
  State<SearchAction> createState() => _SearchActionState();
}

class _SearchActionState extends State<SearchAction> {
  final GlobalKey _btnKey = GlobalKey();
  late final TextEditingController _controller;
  late SearchOverlay _overlay;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _overlay = SearchOverlay(
      context,
      _controller,
      widget.onSearch,
      buttonKey: _btnKey,
      maxWidth: widget.maxWidth,
      height: widget.height,
      hintText: widget.hintText,
      hintColor: widget.hintColor,
      expandSide: widget.expandSide,
      fetchSuggestions: widget.fetchSuggestions,
      onSuggestionTap: widget.onSuggestionTap,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(90);

    return Tooltip(
      message: widget.tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: _btnKey,
          onTap: _overlay.toggleOverlay,
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: radius,
            ),
            child: Icon(widget.icon, color: widget.iconColor),
          ),
        ),
      ),
    );
  }
}
