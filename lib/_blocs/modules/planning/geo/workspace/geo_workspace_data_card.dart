
class GeoWorkspaceDataCard {
  final String? title;
  final String? subtitle;
  final String? label;
  final String? value;

  const GeoWorkspaceDataCard({
    this.title,
    this.subtitle,
    this.label,
    this.value,
  });

  bool get hasData =>
      (value?.trim().isNotEmpty ?? false) ||
          (label?.trim().isNotEmpty ?? false);
}