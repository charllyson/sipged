// lib/screens/sectors/planning/projects/planning_right_way_map.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/map/map_interactive.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';

class PlanningRightWayMap extends StatefulWidget {
  final ContractData contractData;
  final ValueNotifier<bool>? externalPanelController;

  const PlanningRightWayMap({
    super.key,
    required this.contractData,
    this.externalPanelController,
  });

  @override
  State<PlanningRightWayMap> createState() => _PlanningRightWayMapState();
}

class _PlanningRightWayMapState extends State<PlanningRightWayMap> {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          MapInteractivePage<Map<String, dynamic>>(
            showSearch: true,
            searchTargetZoom: 16,
            showSearchMarker: true,
          ),
        ],
      ),
    );
  }
}
