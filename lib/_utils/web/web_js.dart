import 'dart:js_interop';

JSAny? jsifyObject(Object? value) => value.jsify();

T? dartifyObject<T>(JSAny? value) {
  final dartValue = value.dartify();
  if (dartValue is T) return dartValue;
  return null;
}