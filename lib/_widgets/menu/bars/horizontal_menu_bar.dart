import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:siged/_widgets/menu/bars/top_menu_button.dart';
import 'menu_bar_item.dart';

class HorizontalMenuBar extends StatefulWidget {
  final List<MenuBarItem> menus;

  /// Altura da barra de menus (linha horizontal)
  final double height;

  /// Cores/estilo (a cor aqui é usada só como base; o visual final é "glass")
  final Color backgroundColor;
  final Color panelColor;
  final TextStyle? menuTextStyle;
  final TextStyle? itemTextStyle;

  const HorizontalMenuBar({
    super.key,
    required this.menus,
    this.height = 30,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.panelColor = Colors.white,
    this.menuTextStyle,
    this.itemTextStyle,
  });

  @override
  State<HorizontalMenuBar> createState() => _HorizontalMenuBarState();
}

class _HorizontalMenuBarState extends State<HorizontalMenuBar> {
  int? _openMenuIndex;

  /// Caminho de submenus (índice em cada nível)
  final List<int> _submenuPath = [];

  /// Hover do item dentro do painel
  int? _hoveredItemIndex;

  /// Nível do painel onde o mouse está
  int? _hoveredDepth;

  /// Hover do menu principal (Arquivo, Editar...)
  int? _hoveredMenuIndex;

  OverlayEntry? _overlayEntry;

  /// Link usado pelo menu atualmente aberto
  final LayerLink _layerLink = LayerLink();

  /// Azul do submenu (mantido)
  static const macBlue = Color(0xFF0A84FF);

  /// Cinza de hover/selecionado no menu principal / pai de submenu
  static const menuHoverGrey = Color(0xFFD0D0D0);

  /// Altura aproximada de cada item (para alinhar submenu com o pai)
  static const double _menuItemHeight = 28.0;

  /// Cor base da barra (harmonizada com a UpBar)
  static const Color _barBase = Color(0xFF1B2035);

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _rebuildOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  void _closeMenus() {
    setState(() {
      _openMenuIndex = null;
      _submenuPath.clear();
      _hoveredItemIndex = null;
      _hoveredDepth = null;
      _hoveredMenuIndex = null;
    });
    _removeOverlay();
  }

  void _toggleMenu(int index) {
    // Clicou de novo no mesmo menu → fecha
    if (_openMenuIndex == index) {
      _closeMenus();
      return;
    }

    setState(() {
      _openMenuIndex = index;
      _submenuPath.clear();
      _hoveredItemIndex = null;
      _hoveredDepth = null;
    });

    _showOverlay();
  }

  void _showOverlay() {
    _removeOverlay();

    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          // 🔹 Camada "clicável" transparente para capturar cliques fora
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (_) {
                // Clique em qualquer lugar fora do menu fecha tudo
                _closeMenus();
              },
            ),
          ),

          // 🔹 Seguidor que posiciona o painel do menu abaixo do item clicado
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, widget.height),
            child: _buildDropdownCascade(ctx),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  /// Retorna os itens do nível [depth]
  /// depth = 0 → filhos do menu principal aberto
  /// depth = 1 → filhos do item selecionado no nível 0, e assim por diante
  List<MenuBarItem> _itemsAtDepth(int depth) {
    if (_openMenuIndex == null) return const [];

    MenuBarItem current = widget.menus[_openMenuIndex!];

    if (depth == 0) return current.children;

    for (int d = 0; d < depth; d++) {
      if (d >= _submenuPath.length) return const [];
      final idx = _submenuPath[d];
      if (idx < 0 || idx >= current.children.length) return const [];
      current = current.children[idx];
    }

    return current.children;
  }

  /// ---------- Painéis em cascata / compactos ----------
  Widget _buildDropdownCascade(BuildContext context) {
    if (_openMenuIndex == null) {
      return const SizedBox.shrink();
    }

    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 600; // 👈 mobile / telas estreitas

    if (isCompact) {
      // ----- MODO COMPACTO (MOBILE): um painel por vez, estilo "drill-down" -----
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      final itemStyle = widget.itemTextStyle ??
          TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
          );

      // Profundidade a exibir: se já entrou em algum submenu,
      // mostra sempre o nível "mais fundo".
      final depthToShow = _submenuPath.isEmpty ? 0 : _submenuPath.length;
      final items = _itemsAtDepth(depthToShow);

      return Align(
        alignment: Alignment.topLeft,
        child: _buildCompactPanel(
          context: context,
          depth: depthToShow,
          items: items,
          itemStyle: itemStyle,
        ),
      );
    }

    // ----- MODO DESKTOP (LARGO): cascata horizontal, como estava antes -----
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final itemStyle = widget.itemTextStyle ??
        TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
        );

    final List<Widget> panels = [];
    int depth = 0;

    while (true) {
      final items = _itemsAtDepth(depth);
      if (items.isEmpty) break;

      // Calcula o offset vertical para alinhar com o pai
      double topOffset = 0;
      if (depth > 0) {
        final parentDepth = depth - 1;
        int parentIndex = 0;
        if (_submenuPath.length > parentDepth) {
          parentIndex = _submenuPath[parentDepth];
        }
        if (parentIndex < 0) parentIndex = 0;
        topOffset = parentIndex * _menuItemHeight;
      }

      panels.add(
        Padding(
          padding: EdgeInsets.only(right: depth == 0 ? 0 : 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (topOffset > 0) SizedBox(height: topOffset),
              _buildPanelForDepth(
                context: context,
                depth: depth,
                items: items,
                itemStyle: itemStyle,
              ),
            ],
          ),
        ),
      );

      if (depth >= _submenuPath.length) break;
      depth++;
    }

    if (panels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.topLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: panels,
      ),
    );
  }

  /// ---------- Painel compacto (mobile): um nível por vez + "Voltar" ----------
  Widget _buildCompactPanel({
    required BuildContext context,
    required int depth,
    required List<MenuBarItem> items,
    required TextStyle itemStyle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final base = isDark ? Colors.white : Colors.black;
    final glassFill = Colors.white.withOpacity(0.25);
    final glassBorder = base.withOpacity(0.18);
    final shadows = [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.35 : 0.18),
        blurRadius: 20,
        offset: const Offset(0, 12),
      ),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 200,
        maxWidth: 260,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: glassFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: glassBorder),
              boxShadow: shadows,
            ),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botão "Voltar" quando estiver em um submenu
                if (depth > 0)
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (_submenuPath.isNotEmpty) {
                          _submenuPath.removeLast();
                          _hoveredDepth = null;
                          _hoveredItemIndex = null;
                        }
                      });
                      _rebuildOverlay();
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_back, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Voltar',
                            style: itemStyle,
                          ),
                        ],
                      ),
                    ),
                  ),

                if (depth > 0)
                  const Divider(height: 4),

                ...List.generate(items.length, (index) {
                  final item = items[index];
                  final hasChildren = item.children.isNotEmpty;

                  // No modo compacto, hover praticamente não importa (mobile),
                  // mas mantemos para desktop se ele ficar estreito.
                  final isHovered =
                  (_hoveredDepth == depth && _hoveredItemIndex == index);

                  final isPathParent = depth < _submenuPath.length &&
                      _submenuPath[depth] == index;

                  Color bgColor;
                  Color textColor;
                  Color iconColor;

                  if (isHovered) {
                    bgColor = macBlue;
                    textColor = Colors.white;
                    iconColor = Colors.white;
                  } else if (isPathParent) {
                    bgColor = Colors.white.withOpacity(isDark ? 0.20 : 0.45);
                    textColor = isDark ? Colors.white : Colors.black87;
                    iconColor = isDark ? Colors.white70 : Colors.black54;
                  } else {
                    bgColor = Colors.transparent;
                    textColor = itemStyle.color ?? Colors.black87;
                    iconColor = isDark ? Colors.white70 : Colors.black54;
                  }

                  return MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        _hoveredDepth = depth;
                        _hoveredItemIndex = index;
                      });
                      _rebuildOverlay();
                    },
                    onExit: (_) {
                      setState(() {
                        _hoveredDepth = null;
                        _hoveredItemIndex = null;
                      });
                      _rebuildOverlay();
                    },
                    child: InkWell(
                      onTap: () {
                        if (hasChildren) {
                          // No compacto: toque navega para o próximo nível
                          setState(() {
                            if (_submenuPath.length > depth) {
                              _submenuPath[depth] = index;
                              _submenuPath.removeRange(
                                  depth + 1, _submenuPath.length);
                            } else if (_submenuPath.length == depth) {
                              _submenuPath.add(index);
                            }
                            _hoveredDepth = depth;
                            _hoveredItemIndex = index;
                          });
                          _rebuildOverlay();
                          return;
                        }

                        // Folha: executa ação e fecha
                        item.onTap?.call();
                        _closeMenus();
                      },
                      borderRadius: BorderRadius.circular(6),
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.label,
                                style: itemStyle.copyWith(color: textColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasChildren)
                              Icon(
                                Icons.chevron_right,
                                size: 14,
                                color: iconColor,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ---------- Painel "normal" (desktop): usado na cascata horizontal ----------
  Widget _buildPanelForDepth({
    required BuildContext context,
    required int depth,
    required List<MenuBarItem> items,
    required TextStyle itemStyle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Glass dos PAINÉIS (submenu) – ORIGINAL
    final base = isDark ? Colors.white : Colors.black;
    final glassFill = Colors.white.withOpacity(0.25);
    final glassBorder = base.withOpacity(0.18);
    final shadows = [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.35 : 0.18),
        blurRadius: 20,
        offset: const Offset(0, 12),
      ),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 180,
        maxWidth: 260, // largura estilo macOS
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: glassFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: glassBorder),
              boxShadow: shadows,
            ),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(items.length, (index) {
                  final item = items[index];
                  final hasChildren = item.children.isNotEmpty;

                  // Hover atual (azul)
                  final isHovered =
                  (_hoveredDepth == depth && _hoveredItemIndex == index);

                  // Item faz parte do caminho de submenu (pai ativo)
                  final isPathParent = depth < _submenuPath.length &&
                      _submenuPath[depth] == index;

                  Color bgColor;
                  Color textColor;
                  Color iconColor;

                  if (isHovered) {
                    // 1ª prioridade: hover
                    bgColor = macBlue;
                    textColor = Colors.white;
                    iconColor = Colors.white;
                  } else if (isPathParent) {
                    // 2ª prioridade: pai de submenu aberto
                    bgColor = Colors.white.withOpacity(isDark ? 0.20 : 0.45);
                    textColor = isDark ? Colors.white : Colors.black87;
                    iconColor = isDark ? Colors.white70 : Colors.black54;
                  } else {
                    // Normal
                    bgColor = Colors.transparent;
                    textColor = itemStyle.color ?? Colors.black87;
                    iconColor = isDark ? Colors.white70 : Colors.black54;
                  }

                  return MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        _hoveredDepth = depth;
                        _hoveredItemIndex = index;

                        if (hasChildren) {
                          // Atualiza o caminho de submenu neste nível
                          if (_submenuPath.length > depth) {
                            _submenuPath[depth] = index;
                            _submenuPath.removeRange(
                                depth + 1, _submenuPath.length);
                          } else if (_submenuPath.length == depth) {
                            _submenuPath.add(index);
                          }
                        } else {
                          // Item sem filhos → corta níveis abaixo
                          if (_submenuPath.length > depth) {
                            _submenuPath.removeRange(
                                depth, _submenuPath.length);
                          }
                        }
                      });
                      _rebuildOverlay();
                    },
                    onExit: (_) {
                      setState(() {
                        _hoveredDepth = null;
                        _hoveredItemIndex = null;
                      });
                      _rebuildOverlay();
                    },
                    child: InkWell(
                      onTap: () {
                        if (hasChildren) {
                          // Desktop: clique "fixa" o submenu (além do hover)
                          setState(() {
                            if (_submenuPath.length > depth) {
                              _submenuPath[depth] = index;
                              _submenuPath.removeRange(
                                  depth + 1, _submenuPath.length);
                            } else if (_submenuPath.length == depth) {
                              _submenuPath.add(index);
                            }
                            _hoveredDepth = depth;
                            _hoveredItemIndex = index;
                          });
                          _rebuildOverlay();
                          return;
                        }

                        // Folha: executa ação e fecha tudo
                        item.onTap?.call();
                        _closeMenus();
                      },
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.label,
                                style: itemStyle.copyWith(color: textColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasChildren)
                              Icon(
                                Icons.chevron_right,
                                size: 14,
                                color: iconColor,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ---------- Barra (barGlass) harmonizada com a UpBar ----------
    final barTopFill =
    _barBase.withOpacity(isDark ? 0.82 : 0.90); // parte de cima da barra
    final barBottomFill =
    _barBase.withOpacity(isDark ? 0.96 : 0.98); // parte de baixo
    final barBorder =
    Colors.white.withOpacity(isDark ? 0.12 : 0.10); // linha de separação

    final baseMenuTextStyle = widget.menuTextStyle ??
        TextStyle(
          fontSize: 12,
          color: Colors.white.withOpacity(0.90),
          fontWeight: FontWeight.w500,
        );

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [barTopFill, barBottomFill],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border(
              bottom: BorderSide(color: barBorder),
            ),
          ),

          // ⭐ Scroll horizontal do menu principal (quando muitos itens)
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  for (var i = 0; i < widget.menus.length; i++)
                    MouseRegion(
                      onEnter: (_) {
                        setState(() => _hoveredMenuIndex = i);
                      },
                      onExit: (_) {
                        setState(() => _hoveredMenuIndex = null);
                      },
                      child: CompositedTransformTarget(
                        link: _openMenuIndex == i ? _layerLink : LayerLink(),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color:
                            (_hoveredMenuIndex == i || _openMenuIndex == i)
                                ? Colors.white.withOpacity(
                              isDark ? 0.18 : 0.35,
                            )
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: TopMenuButton(
                            label: widget.menus[i].label,
                            isOpen: false,
                            textStyle: baseMenuTextStyle,
                            onTap: () => _toggleMenu(i),
                          ),
                        ),
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
