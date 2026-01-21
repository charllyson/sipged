import 'package:flutter/material.dart';
import 'package:siged/_blocs/modules/planning/geo/sig_miner/sigmine_data.dart';

class OresDetails extends StatelessWidget {
  final SigMineData feature;
  final VoidCallback onClose;

  const OresDetails({
    super.key,
    required this.feature,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final attrs = <String, String>{
      'Processo': feature.processo,
      'Fase': feature.fase ?? '—',
      'Substância': feature.substancia ?? '—',
      'Titular': feature.titular ?? '—',
      'Uso': feature.uso ?? '—',
      'Área (ha)': feature.areaHa == null
          ? '—'
          : feature.areaHa!.toStringAsFixed(2),
      'UF': feature.uf ?? '—',
      'Último evento': feature.ultimoEvento ?? '—',
      'Data do último evento': feature.dataUltEvento ?? '—',
      'Situação': feature.situacao ?? '—',
    };

    return Material(
      color: Colors.white,
      elevation: 0, // dentro do slot, sem sombra extra
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A), // azul bem escuro
            ),
            child: Row(
              children: [
                const Icon(Icons.layers,
                    color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Detalhes da Jazida — ${feature.processo}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: onClose,
                  icon: const Icon(Icons.close,
                      color: Colors.white70),
                ),
              ],
            ),
          ),

          // Conteúdo
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: attrs.length,
              separatorBuilder: (_, __) =>
              const Divider(height: 8),
              itemBuilder: (_, i) {
                final k = attrs.keys.elementAt(i);
                final v = attrs[k]!;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 180,
                      child: Text(
                        k,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        v,
                        style: const TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
