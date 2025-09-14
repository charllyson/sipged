import 'package:flutter/material.dart';

import 'package:siged/_widgets/search/search_overlay.dart';
/// =============================================================
/// 2) ACTION: Botão de busca com overlay (isolado)
/// =============================================================
class SearchAction extends StatefulWidget {
  final void Function(String)? onSearch;
  final IconData icon;
  final String tooltip;

  const SearchAction({
    super.key,
    this.onSearch,
    this.icon = Icons.search,
    this.tooltip = 'Buscar',
  });

  @override
  State<SearchAction> createState() => _SearchActionState();
}

class _SearchActionState extends State<SearchAction> {
  late final TextEditingController _controller;
  late final SearchOverlay _overlayManager;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _overlayManager = SearchOverlay(context, _controller, widget.onSearch);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: widget.tooltip,
      icon: const Icon(Icons.search, color: Colors.white),
      onPressed: _overlayManager.toggleOverlay,
    );
  }
}