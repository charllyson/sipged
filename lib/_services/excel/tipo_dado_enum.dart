enum TipoDado {
  string,
  int_,
  double_,
  bool_,
  dateTime,
}

extension TipoDadoExtension on TipoDado {
  String get name {
    switch (this) {
      case TipoDado.string:
        return 'String';
      case TipoDado.int_:
        return 'int';
      case TipoDado.double_:
        return 'double';
      case TipoDado.bool_:
        return 'bool';
      case TipoDado.dateTime:
        return 'DateTime';
    }
  }

  static TipoDado fromString(String value) {
    switch (value.toLowerCase()) {
      case 'int':
        return TipoDado.int_;
      case 'double':
        return TipoDado.double_;
      case 'bool':
        return TipoDado.bool_;
      case 'datetime':
        return TipoDado.dateTime;
      default:
        return TipoDado.string;
    }
  }
}
