import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Controller de TESTE para Termo de Arquivamento.
/// Dropdowns também usam TextEditingController (compatível com DropDownButtonChange).
class TermoArquivamentoController extends ChangeNotifier {
  bool isEditable = true;

  // 1) Metadados
  final taNumeroCtrl = TextEditingController();
  final taDataCtrl = TextEditingController();
  final taProcessoCtrl = TextEditingController();
  final taResponsavelCtrl = TextEditingController(); // Autocomplete fake
  String? taResponsavelUserId;

  // 2) Motivo / Abrangência
  final taMotivoCtrl = TextEditingController(); // DropDown
  final taAbrangenciaCtrl = TextEditingController(); // DropDown
  final taDescricaoAbrangenciaCtrl = TextEditingController();

  // 3) Fundamentação
  final taFundamentosLegaisCtrl = TextEditingController();
  final taJustificativaCtrl = TextEditingController();

  // 4) Peças / Links
  final taPecasAnexasCtrl = TextEditingController();
  final taLinksCtrl = TextEditingController();

  // 5) Decisão
  final taAutoridadeCtrl = TextEditingController(); // Autocomplete fake
  String? taAutoridadeUserId;
  final taDecisaoCtrl = TextEditingController(); // DropDown
  final taDataDecisaoCtrl = TextEditingController();
  final taObservacoesDecisaoCtrl = TextEditingController();

  // 6) Reabertura
  final taReaberturaCondicaoCtrl = TextEditingController(); // DropDown
  final taPrazoReaberturaCtrl = TextEditingController();

  void initWithMock() {
    taNumeroCtrl.text = 'TA-2025-007';
    taDataCtrl.text = '27/09/2025';
    taProcessoCtrl.text = 'SEI 64000.000000/2025-11';
    taResponsavelCtrl.text = 'Setor de Compras (uid:resp1)';
    taResponsavelUserId = 'resp1';

    taMotivoCtrl.text = 'Inviabilidade técnica/econômica';
    taAbrangenciaCtrl.text = 'Parcial (lotes/itens)';
    taDescricaoAbrangenciaCtrl.text = 'Arquiva-se o Lote 2 (sinalização), mantém-se Lote 1.';

    taFundamentosLegaisCtrl.text = 'Lei 14.133/2021, art. 71, §…; parecer jurídico PJ-2025-042.';
    taJustificativaCtrl.text = 'Preço acima da mediana; pesquisa de mercado insuficiente para o Lote 2.';

    taPecasAnexasCtrl.text = 'ETP, TR, parecer jurídico, cotações, atas.';
    taLinksCtrl.text = 'SEI://termo-arquivamento; Drive://pasta-arquivamento';

    taAutoridadeCtrl.text = 'Diretor-Geral (uid:dir1)'; taAutoridadeUserId = 'dir1';
    taDecisaoCtrl.text = 'Arquivar após saneamento';
    taDataDecisaoCtrl.text = '30/09/2025';
    taObservacoesDecisaoCtrl.text = 'Reabrir após nova pesquisa de preços.';

    taReaberturaCondicaoCtrl.text = 'Após saneamento';
    taPrazoReaberturaCtrl.text = 'Em até 60 dias';
    notifyListeners();
  }

  String? quickValidate() {
    if (taNumeroCtrl.text.trim().isEmpty) return 'Informe o nº do termo.';
    if (taDataCtrl.text.trim().isEmpty) return 'Informe a data.';
    if (taProcessoCtrl.text.trim().isEmpty) return 'Informe o nº do processo.';
    if (taMotivoCtrl.text.trim().isEmpty) return 'Selecione o motivo do arquivamento.';
    if (taDecisaoCtrl.text.trim().isEmpty) return 'Informe a decisão da autoridade.';
    return null;
  }

  Map<String, dynamic> save() {
    final e = quickValidate();
    if (e != null) throw StateError(e);
    return toMap();
  }

  Map<String, dynamic> toMap() => {
    // 1) Metadados
    'numero': taNumeroCtrl.text,
    'data': taDataCtrl.text,
    'processo': taProcessoCtrl.text,
    'responsavelNome': taResponsavelCtrl.text,
    'responsavelUserId': taResponsavelUserId,

    // 2) Motivo/Abrangência
    'motivo': taMotivoCtrl.text,
    'abrangencia': taAbrangenciaCtrl.text,
    'descricaoAbrangencia': taDescricaoAbrangenciaCtrl.text,

    // 3) Fundamentação
    'fundamentosLegais': taFundamentosLegaisCtrl.text,
    'justificativa': taJustificativaCtrl.text,

    // 4) Peças/Links
    'pecasAnexas': taPecasAnexasCtrl.text,
    'links': taLinksCtrl.text,

    // 5) Decisão
    'autoridadeNome': taAutoridadeCtrl.text,
    'autoridadeUserId': taAutoridadeUserId,
    'decisao': taDecisaoCtrl.text,
    'dataDecisao': taDataDecisaoCtrl.text,
    'observacoesDecisao': taObservacoesDecisaoCtrl.text,

    // 6) Reabertura
    'reaberturaCondicao': taReaberturaCondicaoCtrl.text,
    'prazoReabertura': taPrazoReaberturaCtrl.text,
  };

  void fromMap(Map<String, dynamic> m) {
    taNumeroCtrl.text = m['numero'] ?? '';
    taDataCtrl.text = m['data'] ?? '';
    taProcessoCtrl.text = m['processo'] ?? '';
    taResponsavelCtrl.text = m['responsavelNome'] ?? '';
    taResponsavelUserId = m['responsavelUserId'];

    taMotivoCtrl.text = m['motivo'] ?? '';
    taAbrangenciaCtrl.text = m['abrangencia'] ?? '';
    taDescricaoAbrangenciaCtrl.text = m['descricaoAbrangencia'] ?? '';

    taFundamentosLegaisCtrl.text = m['fundamentosLegais'] ?? '';
    taJustificativaCtrl.text = m['justificativa'] ?? '';

    taPecasAnexasCtrl.text = m['pecasAnexas'] ?? '';
    taLinksCtrl.text = m['links'] ?? '';

    taAutoridadeCtrl.text = m['autoridadeNome'] ?? '';
    taAutoridadeUserId = m['autoridadeUserId'];
    taDecisaoCtrl.text = m['decisao'] ?? '';
    taDataDecisaoCtrl.text = m['dataDecisao'] ?? '';
    taObservacoesDecisaoCtrl.text = m['observacoesDecisao'] ?? '';

    taReaberturaCondicaoCtrl.text = m['reaberturaCondicao'] ?? '';
    taPrazoReaberturaCtrl.text = m['prazoReabertura'] ?? '';
    notifyListeners();
  }

  void clear() {
    for (final ctrl in [
      taNumeroCtrl, taDataCtrl, taProcessoCtrl, taResponsavelCtrl,
      taMotivoCtrl, taAbrangenciaCtrl, taDescricaoAbrangenciaCtrl,
      taFundamentosLegaisCtrl, taJustificativaCtrl,
      taPecasAnexasCtrl, taLinksCtrl,
      taAutoridadeCtrl, taDecisaoCtrl, taDataDecisaoCtrl, taObservacoesDecisaoCtrl,
      taReaberturaCondicaoCtrl, taPrazoReaberturaCtrl,
    ]) { ctrl.clear(); }
    taResponsavelUserId = null;
    taAutoridadeUserId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final ctrl in [
      taNumeroCtrl, taDataCtrl, taProcessoCtrl, taResponsavelCtrl,
      taMotivoCtrl, taAbrangenciaCtrl, taDescricaoAbrangenciaCtrl,
      taFundamentosLegaisCtrl, taJustificativaCtrl,
      taPecasAnexasCtrl, taLinksCtrl,
      taAutoridadeCtrl, taDecisaoCtrl, taDataDecisaoCtrl, taObservacoesDecisaoCtrl,
      taReaberturaCondicaoCtrl, taPrazoReaberturaCtrl,
    ]) { ctrl.dispose(); }
    super.dispose();
  }
}
