// lib/screens/modules/planning/environment/municipios/municipio_details.dart
import 'package:flutter/material.dart';
import 'package:siged/_blocs/modules/planning/geo/ibge_location/ibge_localidade_data.dart';

class MunicipioDetails extends StatelessWidget {
  final IBGELocationDetailData detail;
  final VoidCallback onClose;

  const MunicipioDetails({
    super.key,
    required this.detail,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final attrs = <String, String>{
      'Município': detail.nome,
      'UF': '${detail.ufSigla} — ${detail.ufNome}',
      'Região': detail.regiaoNome,
      'Mesorregião': detail.mesorregiaoNome,
      'Microrregião': detail.microrregiaoNome,
      'Região imediata': detail.regiaoImediataNome ?? '—',
      'Região intermediária': detail.regiaoIntermediariaNome ?? '—',
      'ID IBGE': detail.idIbge,
    };

    return Material(
      color: Colors.white,
      elevation: 0,
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
                const Icon(
                  Icons.location_city,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Detalhes do Município — ${detail.nome}',
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
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Conteúdo
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: attrs.length,
              separatorBuilder: (_, _) => const Divider(height: 8),
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
