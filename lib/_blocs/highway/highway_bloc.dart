import 'dart:convert';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:flutter/services.dart';
import '../../_datas/highway/highway_data.dart';

class HighwayBloc extends BlocBase {

  HighwayBloc();

  Future<List<HighwayStateData>> loadHighwayStateGeoJson() async {
    final data = await rootBundle.loadString('assets/roads/all-roads.geojson');
    final geojson = json.decode(data);
    final List features = geojson['features'];

    return features.map((f) => HighwayStateData.fromFeature(f)).toList();
  }

}
