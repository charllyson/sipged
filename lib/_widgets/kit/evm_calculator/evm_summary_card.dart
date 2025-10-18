import 'package:flutter/material.dart';
import 'evm_calculator.dart';

class EvmSummaryCard extends StatelessWidget {
  final EvmSnapshot evm;

  const EvmSummaryCard({super.key, required this.evm});

  Color _badge(double x) {
    if (x >= 0.98) return Colors.green;
    if (x >= 0.92) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 165,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tile(
                title: 'CPI',
                value: evm.cpi.toStringAsFixed(2),
                color: _badge(evm.cpi),
                tooltip: 'CPI = EV / AC\n>1 bom, <1 estouro de custo',
                t: t,
              ),
              const SizedBox(width: 12),
              _tile(
                title: 'SPI',
                value: evm.spi.toStringAsFixed(2),
                color: _badge(evm.spi),
                tooltip: 'SPI = EV / PV\n>1 adiantado, <1 atrasado',
                t: t,
              ),
              const SizedBox(width: 12),
              _tile(
                title: 'EAC',
                value: _money(evm.eac),
                color: Colors.blueGrey,
                tooltip: 'Estimate at Completion (projeção de custo ao término)',
                t: t,
              ),
              const SizedBox(width: 12),
              _tile(
                title: 'ETC',
                value: _money(evm.etc),
                color: Colors.blueGrey,
                tooltip: 'Estimate to Complete (falta gastar)',
                t: t,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile({
    required String title,
    required String value,
    required Color color,
    required TextTheme t,
    String? tooltip,
  }) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: t.labelMedium),
        const SizedBox(height: 2),
        Text(value, style: t.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
    return tooltip == null ? body : Tooltip(message: tooltip, child: body);
  }

  static String _money(num v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      buf.write(s[i]);
      final rem = s.length - i - 1;
      if (rem > 0 && rem % 3 == 0) buf.write('.');
    }
    return 'R\$ $buf';
  }
}
