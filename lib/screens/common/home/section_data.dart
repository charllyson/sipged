import 'package:sipged/screens/common/home/module_data_item.dart';

class SectionData<T> {
  final String title;
  final List<ModuleDataItem<T>> items;

  const SectionData({
    required this.title,
    required this.items,
  });
}