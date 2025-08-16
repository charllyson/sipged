/// handle_selection_utils.dart
library;

/// Função utilitária genérica para lidar com seleção de elementos em tabelas, gráficos ou listas.
/// Permite selecionar um item com base em sua ordem e sincronizar a seleção visual (índice).
///
/// Pode ser usada em qualquer tela com:
/// - lista de dados (como aditivos, apostilas, medições...)
/// - controle de índice de linha selecionada (ex: gráfico, tabela)
///
/// Exemplo de uso:
/// ```dart
/// void handleApostilaSelection(ApostilleData data) {
///   handleGenericSelection<ApostilleData>(
///     data: data,
///     list: _listaDeApostilas,
///     getOrder: (e) => e.apostilleOrder,
///     onSetState: (index) {
///       setState(() {
///         _selected = data;
///         _selectedIndex = index;
///       });
///       _fillFields(data);
///     },
///   );
/// }
/// ```

T handleGenericSelection<T>({
  required T data,
  required List<T> list,
  required int? Function(T element) getOrder,
  required void Function(int index) onSetState,
}) {
  final currentOrder = getOrder(data);
  final index = list.indexWhere((element) => getOrder(element) == currentOrder);
  onSetState(index);
  return data;
}
