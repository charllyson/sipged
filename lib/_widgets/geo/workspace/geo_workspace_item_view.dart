import 'package:sipged/_widgets/resize/resize_data.dart';

class GeoWorkspaceItemView {
  final ResizeData item;
  final bool selected;
  final int dataVersion;

  const GeoWorkspaceItemView({
    required this.item,
    required this.selected,
    required this.dataVersion,
  });

  @override
  bool operator ==(Object other) {
    return other is GeoWorkspaceItemView &&
        other.item == item &&
        other.selected == selected &&
        other.dataVersion == dataVersion;
  }

  @override
  int get hashCode => Object.hash(item, selected, dataVersion);
}