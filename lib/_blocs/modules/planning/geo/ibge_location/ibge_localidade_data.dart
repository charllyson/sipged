// lib/_services/ibge/ibge_localidade_data.dart

class IBGELocationStateData {
  final int id;      // código IBGE (ex: 27)
  final String sigla; // ex: 'AL'
  final String nome;  // ex: 'Alagoas'

  const IBGELocationStateData({
    required this.id,
    required this.sigla,
    required this.nome,
  });

  factory IBGELocationStateData.fromJson(Map<String, dynamic> json) {
    return IBGELocationStateData(
      id: json['id'] as int,
      sigla: json['sigla'] as String,
      nome: json['nome'] as String,
    );
  }
}

/// Modelo simples para listar municípios de uma UF
class IBGELocationData {
  final String idIbge;
  final String nome;

  const IBGELocationData({
    required this.idIbge,
    required this.nome,
  });
}

/// Modelo de DETALHE de município, usando tudo que o IBGE
/// expõe no endpoint /localidades/municipios/{id}
class IBGELocationDetailData {
  final String idIbge;
  final String nome;

  final String ufSigla;
  final String ufNome;
  final String regiaoNome;

  final String mesorregiaoNome;
  final String microrregiaoNome;

  final String? regiaoImediataNome;
  final String? regiaoIntermediariaNome;

  const IBGELocationDetailData({
    required this.idIbge,
    required this.nome,
    required this.ufSigla,
    required this.ufNome,
    required this.regiaoNome,
    required this.mesorregiaoNome,
    required this.microrregiaoNome,
    this.regiaoImediataNome,
    this.regiaoIntermediariaNome,
  });

  factory IBGELocationDetailData.fromJson(Map<String, dynamic> json) {
    // Estrutura típica do IBGE:
    // {
    //   "id": 2704302,
    //   "nome": "Maceió",
    //   "microrregiao": {
    //     "nome": "...",
    //     "mesorregiao": {
    //       "nome": "...",
    //       "UF": {
    //         "sigla": "AL",
    //         "nome": "Alagoas",
    //         "regiao": { "nome": "Nordeste" }
    //       }
    //     }
    //   },
    //   "regiao-imediata": {"nome": "..."},
    //   "regiao-intermediaria": {"nome": "..."}
    // }

    final microrregiao = (json['microrregiao'] as Map<String, dynamic>?);
    final mesorregiao =
    (microrregiao?['mesorregiao'] as Map<String, dynamic>?);
    final uf = (mesorregiao?['UF'] as Map<String, dynamic>?);
    final regiao = (uf?['regiao'] as Map<String, dynamic>?);

    final regiaoImediata =
    (json['regiao-imediata'] as Map<String, dynamic>?);
    final regiaoIntermediaria =
    (json['regiao-intermediaria'] as Map<String, dynamic>?);

    return IBGELocationDetailData(
      idIbge: json['id'].toString(),
      nome: (json['nome'] ?? '').toString(),

      ufSigla: (uf?['sigla'] ?? '').toString(),
      ufNome: (uf?['nome'] ?? '').toString(),
      regiaoNome: (regiao?['nome'] ?? '').toString(),

      mesorregiaoNome: (mesorregiao?['nome'] ?? '').toString(),
      microrregiaoNome: (microrregiao?['nome'] ?? '').toString(),

      regiaoImediataNome: (regiaoImediata?['nome'])?.toString(),
      regiaoIntermediariaNome:
      (regiaoIntermediaria?['nome'])?.toString(),
    );
  }
}
