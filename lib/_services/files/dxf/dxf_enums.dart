// lib/_widgets/schedule/civil/dxf_enums.dart

/// Origem do conteúdo que está sendo renderizado.
enum SourceKind {
  dxf, // único suporte
}


/// Modo de ferramenta ativo na tela de anotação.
enum ToolMode {
  draw,   // desenhar polígonos
  select, // selecionar polígonos/itens
  text,   // inserir/editar textos
}

/// (Opcional) modo de seleção usado pelo menu de seleção.
enum SelectionMode {
  direct, // selecionar diretamente
  group // selecionar por grupo
}
