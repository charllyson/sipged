
class AttributeDataDrag {
  final String sourceId;
  final String sourceLabel;
  final String fieldName;
  final String? aggregation;
  final dynamic fieldValue;
  final List<dynamic> fieldValues;

  const AttributeDataDrag({
    required this.sourceId,
    required this.sourceLabel,
    required this.fieldName,
    this.aggregation,
    this.fieldValue,
    this.fieldValues = const [],
  });
}