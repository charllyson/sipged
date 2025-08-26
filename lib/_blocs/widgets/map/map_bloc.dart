import 'dart:ui';

import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:latlong2/latlong.dart';

import 'package:sisged/_blocs/documents/contracts/contracts/contract_rules.dart';

class MapBloc extends BlocBase {
  String? _selectedRegionName;
  List<String> _regionSelectedNames = [];
  int? _selectedIndexGraficRegion;

  String? get selectedRegionName => _selectedRegionName;
  List<String> get regionSelectedNames => _regionSelectedNames;
  int? get selectedIndexGraficRegion => _selectedIndexGraficRegion;

  final Function? onRegionChanged;

  MapBloc({this.onRegionChanged});

  void handleRegionSelection(String? regiao) {
    final tocouMesma = regiao != null &&
        _regionSelectedNames.contains(regiao.toUpperCase());

    if (regiao == null || tocouMesma) {
      _selectedRegionName = null;
      _regionSelectedNames = [];
      _selectedIndexGraficRegion = null;
    } else {
      _regionSelectedNames = [regiao.toUpperCase()];
      _selectedRegionName = regiao;
      _selectedIndexGraficRegion = ContractRules.regions.indexWhere(
            (r) => r.toUpperCase() == regiao.toUpperCase(),
      );
    }

    if (onRegionChanged != null) {
      onRegionChanged!();
    }
  }

  void clearSelection() {
    handleRegionSelection(null);
  }

  LatLng getMidPoint(List<LatLng> points) {
    if (points.isEmpty) return LatLng(0, 0);
    final midIndex = (points.length / 2).floor();
    return points[midIndex];
  }

  bool pointInPolygon(LatLng point, List<LatLng> polygon) {
    int j = polygon.length - 1;
    bool oddNodes = false;

    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].latitude < point.latitude && polygon[j].latitude >= point.latitude) ||
          (polygon[j].latitude < point.latitude && polygon[i].latitude >= point.latitude)) {
        if (polygon[i].longitude +
            (point.latitude - polygon[i].latitude) /
                (polygon[j].latitude - polygon[i].latitude) *
                (polygon[j].longitude - polygon[i].longitude) <
            point.longitude) {
          oddNodes = !oddNodes;
        }
      }
      j = i;
    }

    return oddNodes;
  }

  List<String> toggleRegionSelection({
    required List<String> currentSelection,
    required String region,
    required bool allowMultiSelect,
  }) {
    final newSelection = List<String>.from(currentSelection);

    if (allowMultiSelect) {
      newSelection.contains(region)
          ? newSelection.remove(region)
          : newSelection.add(region);
    } else {
      newSelection.clear();
      newSelection.add(region);
    }

    return newSelection;
  }

  double distanceToSegment(LatLng p, LatLng a, LatLng b) {
    final ap = Offset(p.longitude - a.longitude, p.latitude - a.latitude);
    final ab = Offset(b.longitude - a.longitude, b.latitude - a.latitude);
    final ab2 = ab.dx * ab.dx + ab.dy * ab.dy;
    final ap_ab = ap.dx * ab.dx + ap.dy * ab.dy;
    final t = (ab2 == 0) ? 0 : ap_ab / ab2;

    final closest = Offset(
      a.longitude + ab.dx * t.clamp(0, 1),
      a.latitude + ab.dy * t.clamp(0, 1),
    );

    final distance = const Distance();
    return distance(LatLng(p.latitude, p.longitude), LatLng(closest.dy, closest.dx));
  }

}
