import 'package:flutter/material.dart';
import '../../../../_blocs/actives/active_road_bloc.dart';
import '../../../../_datas/actives/roads/active_roads_data.dart';
import '../../../../_widgets/map/polylines/tappable_changed_polyline.dart';
import 'active_roads_details.dart';
import 'active_roads_tooltip_widget.dart';

/// Controller responsável por orquestrar o fluxo de dados e interações
/// da tela de rede de rodovias ativas.
/// - Mantém estado de loading e seleção de polyline
/// - Carrega dados do Firestore via ActiveRoadsBloc
/// - Gera polylines estilizadas para o mapa
/// - Exibe tooltip e dialog de detalhes
class ActiveRoadsController extends ChangeNotifier {
  final ActiveRoadsBloc _bloc;

  ActiveRoadsController({ActiveRoadsBloc? bloc}) : _bloc = (bloc ?? ActiveRoadsBloc());

  bool _loading = false;
  bool get loading => _loading;

  /// Id (tag) da polyline selecionada no mapa
  final ValueNotifier<String?> selectedPolylineId = ValueNotifier<String?>(null);

  OverlayState? _overlayState;

  Map<String, ActiveRoadsData> get roadDataMap => _bloc.roadDataMap;

  /// Deve ser chamado no initState (via addPostFrameCallback) para
  /// habilitar tooltips em overlay.
  void attachOverlay(OverlayState overlayState) {
    _overlayState = overlayState;
  }

  /// Carga inicial dos dados do Firestore
  Future<void> load() async {
    _setLoading(true);
    try {
      await _bloc.carregarRodoviasDoFirebase();
      clearSelection();
    } finally {
      _setLoading(false);
    }
  }

  /// Limpa seleção da polyline
  void clearSelection() {
    selectedPolylineId.value = null;
  }

  /// Seleciona uma polyline pelo tag
  void selectPolylineByTag(String? tag) {
    selectedPolylineId.value = tag;
  }

  /// Gera as polylines estilizadas a partir do bloc
  List<TappableChangedPolyline> buildStyledPolylines() {
    return _bloc.gerarPolylinesEstilizadas(
      selectedId: selectedPolylineId.value,
    );
  }

  /// Exibe tooltip acima da posição clicada
  void showPolylineTooltip({
    required BuildContext context,
    required Offset position,
    required String tag,
  }) {
    if (_overlayState == null) return;
    final road = roadDataMap[tag];
    if (road == null) return;

    ActiveRoadsTooltipWidget.show(
      overlayState: _overlayState!,
      position: position,
      road: road,
      onVerMais: () {
        // Fecha tooltip e abre os detalhes
        ActiveRoadsTooltipWidget.hide();
        _openDetailsDialog(context, road);
      },
    );
  }

  /// Abre o diálogo com os detalhes da rodovia
  Future<void> _openDetailsDialog(BuildContext context, ActiveRoadsData road) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          height: MediaQuery.of(context).size.height * 0.7,
          width: MediaQuery.of(context).size.width * 0.8,
          child: ActiveRoadsDetails(road: road),
        ),
      ),
    );
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  @override
  void dispose() {
    selectedPolylineId.dispose();
    super.dispose();
  }
}
