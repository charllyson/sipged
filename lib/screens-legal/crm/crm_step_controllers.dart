// lib/screens/crm/precatorios/controllers/crm_step_controllers.dart
import 'package:flutter/material.dart';
import 'package:siged/screens-legal/crm/crm_step_page.dart';

/// ===== Helpers base =====
abstract class _BaseCrmController extends CrmStepController {
  final Map<String, TextEditingController> _map = {};
  DateTime? _next;
  String _status = 'NOVO';

  @override
  Map<String, TextEditingController> get fields => _map;

  @override
  DateTime? get nextActionDate => _next;
  @override
  set nextActionDate(DateTime? v) => _next = v;

  @override
  String get status => _status;
  @override
  set status(String v) => _status = v;

  TextEditingController _t([String key = '']) =>
      _map.putIfAbsent(key, () => TextEditingController());

  @override
  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'nextActionDate': nextActionDate?.toIso8601String(),
      'fields': { for (final e in fields.entries) e.key : e.value.text },
    };
  }
}

/// 0. Resumo (visão geral do lead)
class CrmResumoController extends _BaseCrmController {
  @override
  void initWithMock() {
    fields.clear();
    fields['cliente_nome'] = TextEditingController(text: 'Maria da Silva');
    fields['tipo_cliente'] = TextEditingController(text: 'Pessoa Física');
    fields['origem_lead'] = TextEditingController(text: 'Indicação');
    fields['telefone'] = TextEditingController(text: '(11) 99999-0000');
    fields['email'] = TextEditingController(text: 'maria@example.com');
    fields['valor_estimado_precatorio'] = TextEditingController(text: 'R\$ 450.000,00');
    fields['etapa_atual'] = TextEditingController(text: 'Qualificação');
    fields['responsavel'] = TextEditingController(text: 'Charllyson');
    fields['obs_geral'] = TextEditingController(text: 'Lead quente, pediu retorno 14h.');
    nextActionDate = DateTime.now().add(const Duration(days: 1));
    status = 'EM ANDAMENTO';
  }
}

/// 1. Captação
class CrmCaptacaoController extends _BaseCrmController {
  @override
  void initWithMock() {
    fields.clear();
    fields['origem'] = TextEditingController(text: 'Portal Transparência');
    fields['canal'] = TextEditingController(text: 'Telefone');
    fields['campanha'] = TextEditingController(text: 'Campanha Novembro');
    fields['owner'] = TextEditingController(text: 'Charllyson');
    fields['obs'] = TextEditingController(text: 'Chegou via lista de precatórios federais.');
    nextActionDate = DateTime.now().add(const Duration(days: 2));
    status = 'EM ANDAMENTO';
  }
}

/// 2. Qualificação
class CrmQualificacaoController extends _BaseCrmController {
  @override
  void initWithMock() {
    fields.clear();
    fields['titular_nome'] = TextEditingController(text: 'Maria da Silva');
    fields['cpf_cnpj'] = TextEditingController(text: '123.456.789-00');
    fields['ente_devedor'] = TextEditingController(text: 'União / TRF5');
    fields['tipo_precatorio'] = TextEditingController(text: 'Alimentar');
    fields['numero_precatorio'] = TextEditingController(text: '2021.0001234-5');
    fields['situacao'] = TextEditingController(text: 'Pago Parcial / Fila');
    fields['interesse_venda'] = TextEditingController(text: 'Alto');
    fields['obs'] = TextEditingController(text: 'Cliente demonstra urgência.');
    nextActionDate = DateTime.now().add(const Duration(days: 1));
    status = 'EM ANDAMENTO';
  }
}

/// 3. Contato inicial
class CrmContatoInicialController extends _BaseCrmController {
  @override
  void initWithMock() {
    fields.clear();
    fields['data_contato'] = TextEditingController(text: '02/11/2025');
    fields['meio'] = TextEditingController(text: 'Ligação');
    fields['phone_whatsapp'] = TextEditingController(text: '(11) 99999-0000');
    fields['resumo_conversa'] = TextEditingController(text: 'Explicada proposta, pediu avaliação.');
    fields['resultado'] = TextEditingController(text: 'Agendado retorno');
    nextActionDate = DateTime.now().add(const Duration(days: 1));
    status = 'EM ANDAMENTO';
  }
}

/// 4. Documentos
class CrmDocumentosController extends _BaseCrmController {
  @override
  void initWithMock() {
    fields.clear();
    fields['docs_recebidos'] = TextEditingController(text: 'RG, CPF, Procuração, Extrato TRF');
    fields['pendencias'] = TextEditingController(text: 'Comprovante de endereço');
    fields['link_pasta'] = TextEditingController(text: 'https://drive.google.com/...pasta');
    fields['observacoes'] = TextEditingController(text: 'Organizar por subpastas.');
    nextActionDate = DateTime.now().add(const Duration(days: 3));
    status = 'AGUARDANDO CLIENTE';
  }
}

/// 5. Valuation / Triagem
class CrmValuationController extends _BaseCrmController {
  @override
  void initWithMock() {
    fields.clear();
    fields['valor_nominal'] = TextEditingController(text: 'R\$ 520.000,00');
    fields['desagio_sugerido_%'] = TextEditingController(text: '18');
    fields['valor_oferta'] = TextEditingController(text: 'R\$ 426.400,00');
    fields['fonte_calculo'] = TextEditingController(text: 'Fila TRF5 + juros/atualização');
    fields['riscos'] = TextEditingController(text: 'Bloqueios/frações pendentes');
    fields['observacoes'] = TextEditingController(text: 'Validar número do precatório no sistema.');
    nextActionDate = DateTime.now().add(const Duration(days: 1));
    status = 'EM ANDAMENTO';
  }
}

/// 6. Proposta
class CrmPropostaController extends _BaseCrmController {
  @override
  void initWithMock() {
    fields.clear();
    fields['valor_proposta'] = TextEditingController(text: 'R\$ 430.000,00');
    fields['data_envio'] = TextEditingController(text: '03/11/2025');
    fields['canal_envio'] = TextEditingController(text: 'WhatsApp + PDF assinado');
    fields['prazo_validade'] = TextEditingController(text: '5 dias');
    fields['observacoes'] = TextEditingController(text: 'Aplicar bônus se fechar até 72h.');
    nextActionDate = DateTime.now().add(const Duration(days: 2));
    status = 'PROPOSTA ENVIADA';
  }
}

/// 7. Due Diligence
class CrmDueDiligenceController extends _BaseCrmController {
  @override
  void initWithMock() {
    fields.clear();
    fields['checagens'] = TextEditingController(text: 'TRF, certidões, pendências fiscais');
    fields['resultado_preliminar'] = TextEditingController(text: 'OK, seguir com aprovação jurídica');
    fields['responsavel'] = TextEditingController(text: 'Time Jurídico');
    fields['observacoes'] = TextEditingController(text: 'Solicitar mais um extrato atualizado.');
    nextActionDate = DateTime.now().add(const Duration(days: 1));
    status = 'EM ANDAMENTO';
  }
}

/// 8. Aprovação Jurídica
class CrmAprovacaoJuridicaController extends _BaseCrmController {
  @override
  void initWithMock() {
    fields.clear();
    fields['parecer'] = TextEditingController(text: 'Aprovado sem ressalvas');
    fields['condicoes'] = TextEditingController(text: 'Manter valor ofertado');
    fields['responsavel'] = TextEditingController(text: 'Dra. Ana');
    fields['observacoes'] = TextEditingController(text: 'Prosseguir para assinatura');
    nextActionDate = DateTime.now().add(const Duration(days: 1));
    status = 'EM ANDAMENTO';
  }
}

/// 9. Assinaturas
class CrmAssinaturasController extends _BaseCrmController {
  @override
  void initWithMock() {
    fields.clear();
    fields['contratos_enviados'] = TextEditingController(text: 'Cessão, Procuração');
    fields['metodo'] = TextEditingController(text: 'Assinatura eletrônica');
    fields['status_assinatura'] = TextEditingController(text: 'Cliente assinou, interno pendente');
    fields['observacoes'] = TextEditingController(text: 'Conferir certificados.');
    nextActionDate = DateTime.now().add(const Duration(days: 1));
    status = 'EM ANDAMENTO';
  }
}

/// 10. Registro / Cessão
class CrmRegistroCessaoController extends _BaseCrmController {
  @override
  void initWithMock() {
    fields.clear();
    fields['cartorio'] = TextEditingController(text: 'Cartório X');
    fields['protocolo'] = TextEditingController(text: '2025-000123');
    fields['data_protocolo'] = TextEditingController(text: '04/11/2025');
    fields['observacoes'] = TextEditingController(text: 'Prever prazo de 3 dias úteis');
    nextActionDate = DateTime.now().add(const Duration(days: 3));
    status = 'EM ANDAMENTO';
  }
}

/// 11. Pagamento / Repasse
class CrmPagamentoController extends _BaseCrmController {
  @override
  void initWithMock() {
    fields.clear();
    fields['banco_cliente'] = TextEditingController(text: 'Banco do Brasil');
    fields['ag_cc'] = TextEditingController(text: '1234-5 / 43210-6');
    fields['valor_liquido'] = TextEditingController(text: 'R\$ 430.000,00');
    fields['data_prevista'] = TextEditingController(text: '08/11/2025');
    fields['observacoes'] = TextEditingController(text: 'Enviar comprovante ao cliente');
    nextActionDate = DateTime.now().add(const Duration(days: 4));
    status = 'EM ANDAMENTO';
  }
}

/// 12. Pós-Venda
class CrmPosVendaController extends _BaseCrmController {
  @override
  void initWithMock() {
    fields.clear();
    fields['satisfacao'] = TextEditingController(text: 'Alta');
    fields['indicacoes'] = TextEditingController(text: '2 potenciais leads');
    fields['followup_30d'] = TextEditingController(text: 'Agendar ligação em 30 dias');
    fields['observacoes'] = TextEditingController(text: 'Cliente aberto a novas operações.');
    nextActionDate = DateTime.now().add(const Duration(days: 30));
    status = 'EM ANDAMENTO';
  }
}
