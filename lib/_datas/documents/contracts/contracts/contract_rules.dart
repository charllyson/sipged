import 'package:flutter/material.dart';

class ContractRules {

  static const List<String> companies = [
    'L.P',
    'F.P',
    'ENGEMAT',
    'A.B',
    'S.V.C',
    'LED',
    'BRANDÃO',
    'S.A.',
    'JATOBETON',
    'W.M.',
    'STRATA',
    'C.L.C',
    'TOTEM',
    'PIMENTEL',
    'DEZOITODEZOITO',
    'N.M',
    'ENG. ELÉTRICA COMÉRCIO',
    'INTERVIA'
  ];

  static List<String> statusTypes = [
    'EM ANDAMENTO',
    'A INICIAR',
    'CONCLUÍDO',
    'PARALISADO',
    'CANCELADO',
    'EM PROJETO',
  ];
  static Map<String, int> priorityStatus = {
    'EM ANDAMENTO': 0,
    'A INICIAR': 1,
    'EM PROJETO': 2,
    'PARALISADO': 3,
    'CONCLUÍDO': 4,
    'CANCELADO': 5,
  };

  static List<String> typeOfService = [
    'IMPLANTAÇÃO',
    'PAVIMENTAÇÃO',
    'IMPLANTAÇÃO E PAVIMENTAÇÃO',
    'RESTAURAÇÃO',
    'DUPLICAÇÃO',
    'CONSERVAÇÃO',
    'MANUTENÇÃO',
    'VICINAIS',
    'VIAS URBANAS',
    'OAE',
    'SINALIZAÇÃO',
    'CONSTRUÇÃO',
    'REABILITAÇÃO',
    'GERENCIAMENTO',
    'SUPERVISÃO',
    'FISCALIZAÇÃO',
    'ELABORAÇÃO DE PROJETO',
  ];

  static const List<String> regions = [
    'AGRESTE',
    'NORTE',
    'METROPOLITANA',
    'SERTÃO',
    'SUL',
    'VALE DO MUNDAÚ',
    'VALE DO PARAÍBA'
  ];

  static String getTitleByStatus(String status) {
    switch (status) {
      case 'EM ANDAMENTO':
        return 'Demandas em Andamento';
      case 'A INICIAR':
        return 'Demandas a Iniciar';
      case 'CONCLUÍDO':
        return 'Demandas Concluídas';
      case 'EM PROJETO':
        return 'Demandas em Projeto';
      case 'PARALISADO':
        return 'Demandas Paralisadas';
      case 'CANCELADO':
        return 'Demandas Canceladas';
      default:
        return 'Outro';
    }
  }
}