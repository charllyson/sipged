// lib/screens/sectors/planning/sigmine/sigmine_network_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:siged/_services/sigmine/sigmine_service.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';

// ✅ Split responsivo
import 'package:siged/_widgets/layout/responsive_split_view.dart';

import 'package:siged/screens/sectors/planning/sigmine/sigmine_map.dart';
import 'package:siged/screens/sectors/planning/sigmine/sigmine_panel.dart';
import 'package:siged/screens/sectors/planning/sigmine/sigmine_details.dart';

class SigmineNetworkPage extends StatefulWidget {
  const SigmineNetworkPage({super.key});

  @override
  State<SigmineNetworkPage> createState() => _SigmineNetworkPageState();
}

class _SigmineNetworkPageState extends State<SigmineNetworkPage> {
  final _ufs = const [
    'AC','AL','AM','AP','BA','CE','DF','ES','GO','MA','MG','MS','MT',
    'PA','PB','PE','PI','PR','RJ','RN','RO','RR','RS','SC','SE','SP','TO'
  ];

  String? _selectedUF = 'AL';
  bool _loading = false;
  bool _showPanel = true;

  // (valores só para referência do comportamento antigo; o ResponsiveSplitView calibra automaticamente)
  double _splitVSmall = 0.58; // altura do MAPA no stacked
  double _splitH = 0.44;      // largura do PAINEL no wide

  List<SigmineFeature> _features = [];

  /// Mantemos **normalizado** (UPPER/TRIM)
  Set<String> _mineriosAtivos = {};

  /// Paleta por **chave normalizada** (compartilhada entre mapa e gráfico)
  final Map<String, Color> _colorMap = {};

  MapController? _controller;

  // Detalhes
  SigmineFeature? _selectedFeature; // quando != null, mostra painel de detalhes

  // ---------- Helpers ----------
  String _normalizeMinerio(String? s) =>
      (s ?? 'INDEFINIDO').trim().toUpperCase();

  // Paleta base (estável) para alocação incremental
  static const List<Color> _basePalette = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.brown,
  ];

  /// Retorna SEMPRE a mesma cor para a mesma chave normalizada.
  Color _getColorForMinerio(String nomeNormalizado) {
    final key = nomeNormalizado;
    final existing = _colorMap[key];
    if (existing != null) return existing;

    final color = _basePalette[_colorMap.length % _basePalette.length];
    _colorMap[key] = color;
    return color;
  }

  Map<String, int> get _minerioCounts {
    final counts = <String, int>{};
    for (final f in _features) {
      final key = _normalizeMinerio(f.substancia);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  SigmineFeature? _byProcess(String processoRaw) {
    final key = processoRaw.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    for (final f in _features) {
      final p = (f.processo).replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
      if (p == key) return f;
    }
    // fallback startsWith
    for (final f in _features) {
      final p = (f.processo).replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
      if (p.startsWith(key)) return f;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUF('AL'));
  }

  // ---------- Carregar por UF (pré-semeando a paleta) ----------
  Future<void> _loadUF(String uf) async {
    setState(() {
      _loading = true;
      _features = [];
      _mineriosAtivos.clear();
      _colorMap.clear(); // zera paleta ao trocar de UF
      _selectedFeature = null; // fecha detalhes ao trocar de UF
    });

    try {
      final feats = await SigmineService.fetchByUF(uf);

      final ativos = feats.map((f) => _normalizeMinerio(f.substancia)).toSet();

      // ✅ PRÉ-SEMEIA a paleta numa ordem determinística (alfabética)
      final ordered = ativos.toList()..sort();
      for (final key in ordered) {
        _getColorForMinerio(key);
      }

      setState(() {
        _features = feats;
        _mineriosAtivos = ativos;
        _loading = false;
      });

      if (_controller != null && feats.isNotEmpty) {
        final bounds = SigmineService.boundsFromFeatures(feats);
        _controller!.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(24)),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar $uf: $e')),
      );
    }
  }

  // ---------- Interações ----------
  void _selectSingleMinerio(String nomeNormalizado) {
    setState(() {
      _selectedFeature = null; // ao filtrar por minério, fecha detalhes
      if (_mineriosAtivos.length == 1 && _mineriosAtivos.contains(nomeNormalizado)) {
        _mineriosAtivos = _features
            .map((f) => _normalizeMinerio(f.substancia))
            .toSet();
      } else {
        _mineriosAtivos = {nomeNormalizado};
      }
    });
  }

  void _togglePanelVisibility() => setState(() => _showPanel = !_showPanel);

  void _openDetailsByProcess(String processo) {
    final f = _byProcess(processo);
    if (f != null) {
      setState(() => _selectedFeature = f);
    }
  }

  void _openDetails(SigmineFeature f) {
    setState(() => _selectedFeature = f);
  }

  void _closeDetails() {
    setState(() => _selectedFeature = null);
  }

  @override
  Widget build(BuildContext context) {
    final minerioCounts = _minerioCounts;
    final mineriosNorm = minerioCounts.keys.toList()..sort(); // legenda estável
    final contagens = minerioCounts.values.toList();

    final selectedIndex = (_mineriosAtivos.length == 1)
        ? mineriosNorm.indexWhere((m) => _mineriosAtivos.contains(m))
        : -1;

    // Painel da direita: ou lista/indicadores, ou detalhes
    final Widget rightPane = (_selectedFeature == null)
        ? SigminePanel(
      minerios: mineriosNorm,
      contagens: contagens,
      selectedIndex: selectedIndex >= 0 ? selectedIndex : null,
      getColorForMinerio: _getColorForMinerio,
      onSelectMinerio: (m) => _selectSingleMinerio(m),
      hasData: _features.isNotEmpty,
    )
        : SigmineDetails(
      feature: _selectedFeature!,
      onClose: _closeDetails,
    );

    final mapWidget = SigmineMap(
      featuresAtivos: _features,
      mineriosAtivos: _mineriosAtivos,
      getColorForMinerio: _getColorForMinerio, // 📌 mesma paleta do gráfico
      onRegionTap: (processo) {
        // clique em polígono sem apertar "detalhes" — mantém tooltip no map
      },
      onControllerReady: (c) => _controller = c,
      ufs: _ufs,
      selectedUF: _selectedUF,
      loading: _loading,
      onChangeUF: (uf) {
        setState(() => _selectedUF = uf);
        _loadUF(uf);
      },
      // 🆕 Ao tocar em "Detalhes" no tooltip do mapa:
      onRequestDetails: (feature) => _openDetails(feature),
      // 🆕 Alternativa: abrir por processo (se preferir por string)
      onRequestDetailsByProcess: (processo) => _openDetailsByProcess(processo),
    );

    // ====== UI ======
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: UpBar(
          leading: const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: BackCircleButton(),
          ),
          actions: [
            IconButton(
              tooltip: _showPanel ? 'Ocultar painel' : 'Mostrar painel',
              icon: Icon(
                _showPanel ? Icons.view_sidebar : Icons.view_sidebar_outlined,
                color: Colors.white,
              ),
              onPressed: _togglePanelVisibility,
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          const BackgroundClean(),

          // ✅ Split responsivo:
          // - >= 1280px: lado a lado (mapa à esquerda, painel à direita)
          // - < 1280px: empilhado (mapa em cima, painel embaixo)
          // - showRightPanel = false: mapa ocupa 100%
          ResponsiveSplitView(
            left: mapWidget,
            right: rightPane,
            showRightPanel: _showPanel,
            breakpoint: 1280.0,         // seu corte "iPad Pro portrait fica stacked"
            rightPanelWidth: 520.0,     // alvo no wide (~_splitH de antes)
            bottomPanelHeight: 380.0,   // alvo do PAINEL no stacked (mapa fica em cima)
            showDividers: true,
            dividerThickness: 12.0,
            dividerBackgroundColor: Colors.white,
            dividerBorderColor: Colors.black12,
            gripColor: const Color(0xFF9E9E9E),
          ),

          if (_loading) ...[
            Positioned.fill(
              child: ModalBarrier(
                dismissible: false,
                color: Colors.black.withOpacity(0.20),
              ),
            ),
            const Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(strokeWidth: 3),
                      SizedBox(width: 12),
                      Text('Carregando feições...',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
