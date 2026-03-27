
class GeoWorkspaceDataChart {
  final String? title;
  final List<String>? labels;
  final List<double>? values;

  const GeoWorkspaceDataChart({
    this.title,
    this.labels,
    this.values,
  });

  bool get hasData =>
      labels != null &&
          values != null &&
          labels!.isNotEmpty &&
          values!.isNotEmpty &&
          labels!.length == values!.length;
}