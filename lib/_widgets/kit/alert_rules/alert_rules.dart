class AlertItem {
  final String id;
  final String title;
  final String description;
  final String severity; // info|warn|crit
  AlertItem({required this.id, required this.title, required this.description, this.severity='warn'});
}

class AlertRules {
  static List<AlertItem> evaluate({
    required double cpi,
    required double spi,
    required double costPerKm,
    double? mediaServico,
    double? tetoServico,
    Duration? toContractEnd,
    Duration? toGuaranteeEnd,
  }) {
    final out = <AlertItem>[];

    if (tetoServico != null && costPerKm > tetoServico) {
      out.add(AlertItem(
        id: 'custo-km-teto',
        title: 'Custo por km acima do teto',
        description: 'R\$/km do contrato está acima do teto histórico do serviço.',
        severity: 'crit',
      ));
    }

    if (cpi < 0.95) {
      out.add(AlertItem(
        id: 'cpi-baixo',
        title: 'CPI < 0.95',
        description: 'Indicativo de estouro de custo.',
        severity: cpi < 0.90 ? 'crit' : 'warn',
      ));
    }
    if (spi < 0.95) {
      out.add(AlertItem(
        id: 'spi-baixo',
        title: 'SPI < 0.95',
        description: 'Indicativo de atraso de prazo.',
        severity: spi < 0.90 ? 'crit' : 'warn',
      ));
    }

    if (toContractEnd != null && toContractEnd.inDays <= 60) {
      out.add(AlertItem(
        id: 'validade-contrato',
        title: 'Validade contratual próxima',
        description: 'Menos de 60 dias para o término.',
        severity: 'warn',
      ));
    }

    if (toGuaranteeEnd != null && toGuaranteeEnd.inDays <= 30) {
      out.add(AlertItem(
        id: 'garantia-vencendo',
        title: 'Garantia vencendo',
        description: 'Menos de 30 dias para o vencimento das garantias.',
        severity: 'warn',
      ));
    }

    return out;
  }
}
