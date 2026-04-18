enum FeatureGeometryType {
  point,
  multiPoint,
  lineString,
  multiLineString,
  polygon,
  multiPolygon,
  unknown,
}

enum FeatureGeometryFamily {
  point,
  line,
  polygon,
  unknown,
}

enum TypeFieldGeoJson {
  string,
  integer,
  double_,
  boolean,
  datetime,
}