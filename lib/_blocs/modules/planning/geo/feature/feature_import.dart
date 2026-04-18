import 'package:sipged/_blocs/modules/planning/geo/feature/feature_enums.dart';

class FeatureImport {
  final String name;
  final bool selected;
  final TypeFieldGeoJson type;

  const FeatureImport({
    required this.name,
    required this.selected,
    required this.type,
  });

  FeatureImport copyWith({
    String? name,
    bool? selected,
    TypeFieldGeoJson? type,
  }) {
    return FeatureImport(
      name: name ?? this.name,
      selected: selected ?? this.selected,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FeatureImport &&
        other.name == name &&
        other.selected == selected &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(name, selected, type);
}
