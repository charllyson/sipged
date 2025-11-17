import 'package:flutter/material.dart';
import 'package:siged/screens/process/hiring/6Habilitacao/certidao_card.dart';

class HiringData {
  static const List<String> tiposDeContratacao = [
    'Obra de engenharia',
    'Serviço de engenharia',
    'Serviço comum',
    'Aquisição de material/equipamento',
  ];

  static const List<String> modalidadeDeContratacao = [
    'Dispensa',
    'Inexigibilidade',
    'Pregão',
    'Concorrência',
    'RDC',
    'Concurso',
  ];

  static const List<String> regimeDeExecucao = [
    'Preço global',
    'Preço unitário',
    'Técnica e preço',
    'Melhor técnica',
    'Maior desconto',
    'Outro',
  ];

  static const List<String> metodologia = [
    'SINAPI',
    'Painel de Preços',
    'Cotações diretas',
    'Misto',
  ];

  static const List<String> complexibilidade = [
    'Baixo',
    'Moderado',
    'Alto',
    'Crítico',
  ];

  static const List<String> criterioConsolidacao = [
    'Média simples',
    'Mediana',
    'Menor preço válido',
    'Outros',
  ];

  static const List<String> criterioJulgamento = [
    'Menor preço',
    'Técnica e preço',
    'Maior desconto',
    'Maior retorno econômico',
  ];

  static const List<String> statusProposta = [
    'Classificada',
    'Desclassificada',
  ];

  static const List<String> docAtestados = [
    'Apresentados',
    'Parciais',
    'Não apresentados',
    'Dispensados'
  ];

  static const List<String> situacaoHabilitacao = [
      'Habilitada',
      'Habilitada com ressalvas',
      'Não habilitada',
      'Aguardando complementos',
  ];

  static const List<String> tiposCertidoes = [
    'Válida',
    'Vencida',
    'Em atualização',
    'Dispensada',
    'Não se aplica',
  ];

  static const List<String> fontsRecuros = [
    '0100 - Tesouro',
    '0120 - Convênios',
    '0150 - Vinculados',
    'Outros',
  ];

  static const List<String> parecerConclusao = [
    'Favorável',
    'Favorável com recomendações',
    'Favorável condicionado (ajustes obrigatórios)',
    'Desfavorável',
  ];

  /// Define as cores do card conforme o status da certidão
 static CertidaoColors colorsForStatus(String status, ThemeData theme) {
    // fallback neutro
    Color bg = Colors.grey.shade100;
    Color border = Colors.grey.shade300;
    Color title = theme.colorScheme.onSurface;

    switch (status) {
      case 'Válida':
        bg = Colors.green.shade50;
        border = Colors.green.shade400;
        title = Colors.green.shade800;
        break;
      case 'Vencida':
        bg = Colors.red.shade50;
        border = Colors.red.shade400;
        title = Colors.red.shade800;
        break;
      case 'Em atualização':
        bg = Colors.orange.shade50;
        border = Colors.orange.shade400;
        title = Colors.orange.shade800;
        break;
      case 'Dispensada':
        bg = Colors.blueGrey.shade50;
        border = Colors.blueGrey.shade300;
        title = Colors.blueGrey.shade800;
        break;
      case 'Não se aplica':
        bg = Colors.grey.shade100;
        border = Colors.grey.shade400;
        title = Colors.grey.shade800;
        break;
      default:
      // mantém o neutro
        break;
    }

    return CertidaoColors(
      background: bg,
      border: border,
      title: title,
    );
  }
}
