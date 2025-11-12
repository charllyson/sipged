import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Carrega UF -> Municípios a partir de um GeoJSON.
/// Robusto a variações de chaves e com fallback por CD_UF.
class GeoJsonLocationsService {
  GeoJsonLocationsService._();
  static final GeoJsonLocationsService I = GeoJsonLocationsService._();

  bool _loaded = false;
  bool debug = true;

  List<String> ufs = const [];
  Map<String, List<String>> municipiosByUf = const {};

  void reset() {
    _loaded = false;
    ufs = const [];
    municipiosByUf = const {};
  }

  Future<void> loadFromAsset({
    String path = 'assets/geojson/limits/limites_territoriais.geojson',

    // Aliases de UF (case-insensitive).
    List<String> ufKeys = const [
      'SIGLA_UF','SG_UF','UF','uf',
      'NM_UF','nm_uf','NOME_UF','nome_uf','estado','STATE','state',
      'UF_SIGLA','UF_SIG','sg_uf','sigla_uf',
    ],

    // Aliases explícitos de CD_UF (numérico) para fallback.
    List<String> ufCodeKeys = const [
      'CD_UF','cd_uf','COD_UF','codigo_uf','codigoUF','CODUF',
    ],

    // Aliases de Município (case-insensitive).
    List<String> munKeys = const [
      'NM_MUN','nm_mun',
      'NM_MUNICIPIO','nm_municipio',
      'NOME_MUNICIPIO','nome_municipio',
      'MUNICIPIO','municipio',
      'NM_MUNIC','nm_munic',
      'NM_MUNICIP','nm_municip',
      'NM','nm','NOME','nome',
      'NAME','name','NAME_1','name_1','CITY','city','CITY_NAME','city_name',
      'MUN','mun',
    ],

    bool upperMun = false,
    bool stripDiacriticsMun = false,
    bool force = false,
  }) async {
    if (_loaded && !force) return;

    final raw = await rootBundle.loadString(path);
    final json = jsonDecode(raw);

    final feats = _extractFeatures(json);
    if (feats == null) {
      throw Exception('GeoJSON inválido ou sem "features".');
    }

    // Coleta temporária por UF (sigla) -> set de municípios
    final tmp = <String, Set<String>>{};
    // Diagnóstico
    int total = 0, noProps = 0, noUf = 0, noMun = 0;

    for (final f in feats) {
      total++;
      if (f is! Map) { noProps++; continue; }
      final props = f['properties'];
      if (props is! Map) { noProps++; continue; }

      // 1) UF por aliases textuais
      String? ufSigla = _canonUfFromAliases(props, ufKeys);

      // 2) Fallback por CD_UF (numérico) se não encontrou
      if (ufSigla == null) {
        final codeRaw = _firstNonEmpty(props, ufCodeKeys);
        if (codeRaw != null) {
          final digits = codeRaw.replaceAll(RegExp(r'\D'), '');
          if (digits.isNotEmpty) {
            ufSigla = _ufByCode[digits];
          }
        }
      }

      if (ufSigla == null) { noUf++; continue; }

      // Município
      final munRaw = _firstNonEmpty(props, munKeys);
      if (munRaw == null) { noMun++; continue; }

      final mun = _normMunicipio(munRaw,
        upper: upperMun,
        strip: stripDiacriticsMun,
      );

      final set = tmp.putIfAbsent(ufSigla, () => <String>{});
      set.add(mun);
    }

    // Ordenar e fixar estrutura final
    final orderedUfs = tmp.keys.toList()..sort();
    final byUf = <String, List<String>>{};
    for (final uf in orderedUfs) {
      final list = tmp[uf]!.toList()..sort(_comparePtBr);
      byUf[uf] = list;
    }

    ufs = orderedUfs;
    municipiosByUf = byUf;
    _loaded = true;
  }

  /// Dump de depuração para uma UF (ex.: 'AL').
  /// Exibe as primeiras cidades e verifica amostras específicas.
  void debugDumpUf(String uf, {List<String> samples = const []}) {
    final list = municipiosByUf[uf] ?? const [];
    for (final s in samples) {
      final has = list.contains(s);
      // Também checa variações sem acento/caixa (tolerante)
      final hasLoose = list.any((e) =>
      _removeDiacritics(e).toLowerCase() ==
          _removeDiacritics(s).toLowerCase()
      );
    }
  }

  List<String> getMunicipios(String? ufSigla) {
    if (ufSigla == null) return const [];
    return municipiosByUf[ufSigla] ?? const [];
  }

  // ----------------- Helpers -----------------

  List? _extractFeatures(dynamic json) {
    if (json is Map) {
      if (json['features'] is List) return json['features'] as List;
      if (json['data'] is Map && json['data']['features'] is List) {
        return json['data']['features'] as List;
      }
    }
    return null;
  }

  Map<String, dynamic> _propsIndex(Map props) {
    return { for (final e in props.entries)
      e.key.toString().toLowerCase(): e.value };
  }

  String? _firstNonEmpty(Map props, List<String> keys) {
    if (props.isEmpty) return null;
    final idx = _propsIndex(props);
    for (final k in keys) {
      final v = idx[k.toLowerCase()];
      if (v == null) continue;
      final s = _toStr(v)?.trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return null;
  }

  String? _toStr(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is num || v is bool) return v.toString();
    if (v is List) return v.where((e) => e != null).map((e) => e.toString()).join(' ');
    if (v is Map)  return v.values.where((e) => e != null).map((e) => e.toString()).join(' ');
    return v.toString();
  }

  String? _canonUfFromAliases(Map props, List<String> ufKeys) {
    final raw = _firstNonEmpty(props, ufKeys);
    if (raw == null) return null;

    final v = raw.trim();
    final up = v.toUpperCase();

    // 1) Já é a sigla?
    if (_ufSiglas.contains(up)) return up;

    // 2) Tenta nome
    final byName = _ufByName[v.toLowerCase()];
    if (byName != null) return byName;

    // 3) Strings compostas: "AL - Alagoas", "AL/Alagoas" etc.
    final comp = v.split(RegExp(r'[\s\-;\/]')).first.toUpperCase();
    if (_ufSiglas.contains(comp)) return comp;

    return null;
  }

  String _normMunicipio(String s, {bool upper = false, bool strip = false}) {
    var t = s.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (strip) t = _removeDiacritics(t);
    return upper ? t.toUpperCase() : t;
  }

  int _comparePtBr(String a, String b) =>
      _removeDiacritics(a).toLowerCase().compareTo(
        _removeDiacritics(b).toLowerCase(),
      );

  // Remoção simples de acentos
  static const _accentSrc = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
  static const _accentDst = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
  String _removeDiacritics(String s) {
    final buf = StringBuffer();
    for (final rune in s.runes) {
      final ch = String.fromCharCode(rune);
      final i = _accentSrc.indexOf(ch);
      buf.write(i >= 0 ? _accentDst[i] : ch);
    }
    return buf.toString();
  }

  // Referências
  static const Set<String> _ufSiglas = {
    'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG',
    'PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'
  };

  static const Map<String, String> _ufByCode = {
    '12':'AC','27':'AL','16':'AP','13':'AM','29':'BA','23':'CE','53':'DF','32':'ES',
    '52':'GO','21':'MA','51':'MT','50':'MS','31':'MG','15':'PA','25':'PB','41':'PR',
    '26':'PE','22':'PI','33':'RJ','24':'RN','43':'RS','11':'RO','14':'RR','42':'SC',
    '35':'SP','28':'SE','17':'TO',
  };

  static const Map<String, String> _ufByName = {
    'acre':'AC','alagoas':'AL','amapá':'AP','amapa':'AP','amazonas':'AM','bahia':'BA',
    'ceará':'CE','ceara':'CE','distrito federal':'DF','espírito santo':'ES','espirito santo':'ES',
    'goiás':'GO','goias':'GO','maranhão':'MA','maranhao':'MA','mato grosso':'MT',
    'mato grosso do sul':'MS','minas gerais':'MG','pará':'PA','para':'PA','paraíba':'PB',
    'paraiba':'PB','paraná':'PR','parana':'PR','pernambuco':'PE','piauí':'PI','piaui':'PI',
    'rio de janeiro':'RJ','rio grande do norte':'RN','rio grande do sul':'RS','rondônia':'RO',
    'rondonia':'RO','roraima':'RR','santa catarina':'SC','são paulo':'SP','sao paulo':'SP',
    'sergipe':'SE','tocantins':'TO',
  };
}
