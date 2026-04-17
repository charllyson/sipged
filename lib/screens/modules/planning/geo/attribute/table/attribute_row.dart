import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';

class AttributeRow {
  final int featureIndex;
  final FeatureData feature;

  const AttributeRow({
    required this.featureIndex,
    required this.feature,
  });
}