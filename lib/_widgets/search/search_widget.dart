import 'package:flutter/material.dart';

import 'package:sisged/screens/commons/search/search_overlay_manager.dart';
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
  late final SearchOverlayManager _overlayManager;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _overlayManager = SearchOverlayManager(context, _controller, widget.onSearch);
  }

  @override
  void dispose() {
    _controller.dispose();
    // se seu SearchOverlayManager tiver método de dispose/fechar, chame aqui:
    // _overlayManager.dispose();  // (caso exista)
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