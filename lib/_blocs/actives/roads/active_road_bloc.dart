import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sisged/_widgets/map/polylines/tappable_changed_polyline.dart';
import 'package:sisged/_blocs/actives/roads/active_road_rules.dart';
import 'package:sisged/_blocs/actives/roads/active_road_style.dart';
import 'package:sisged/_blocs/actives/roads/active_roads_data.dart';

class ActiveRoadsBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Map<String, ActiveRoadsData> roadDataMap = {};
  String? selectedPolylineId;

  ActiveRoadsBloc();

  Future<List<ActiveRoadsData>> getAllRoads() async {
    final snapshot = await _db.collection('actives_roads').get();
    return snapshot.docs.map((doc) => ActiveRoadsData.fromDocument(doc)).toList();
  }

  Future<void> saveOrUpdateRoad(ActiveRoadsData data) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final ref = _db.collection('actives_roads').doc(data.id ?? _db.collection('actives_roads').doc().id);
    data.id = ref.id;

    final json = data.toMap()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
      });

    final doc = await ref.get();
    if (!doc.exists) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = uid;
    }

    await ref.set(json, SetOptions(merge: true));
  }

  Future<void> deleteRoad(String roadId) async {
    await _db.collection('actives_roads').doc(roadId).delete();
  }

  /// 🆕 Importa várias rodovias com pontos diretamente em 'points'
  Future<void> importarRodoviasComCoordenadas({
    required List<Map<String, dynamic>> linhasPrincipais,
    required List<Map<String, dynamic>> subcolecoes,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    for (int i = 0; i < linhasPrincipais.length; i++) {
      final linha = linhasPrincipais[i];
      final docRef = _db.collection('actives_roads').doc();
      linha['id'] = docRef.id;
      linha['createdAt'] = FieldValue.serverTimestamp();
      linha['createdBy'] = uid;
      linha['updatedAt'] = FieldValue.serverTimestamp();
      linha['updatedBy'] = uid;

      // 👉 Verifica e salva tipo de geometria (LineString ou MultiLineString)
      if (i < subcolecoes.length) {
        final sub = subcolecoes[i];

        // 🟡 Se for MultiLineString, converte para LineString (lista única de pontos)
        if (sub['geometryType'] == 'MultiLineString' && sub['points'] is List) {
          final multiLinePoints = sub['points'] as List;
          final flattenedPoints = multiLinePoints.expand((linha) => linha).toList();
          sub['points'] = flattenedPoints;
          sub['geometryType'] = 'LineString'; // força o tipo
        }

        final pontos = sub['points'] as List<dynamic>?;
        final tipo = sub['geometryType'] ?? 'LineString'; // já vai pegar como 'LineString' após força

        linha['geometryType'] = tipo;

        if (pontos != null) {
          linha['points'] = pontos.map((ponto) {
            return GeoPoint(
              (ponto['latitude'] as num).toDouble(),
              (ponto['longitude'] as num).toDouble(),
            );
          }).toList();
        }
      }


      await docRef.set(linha, SetOptions(merge: true));
      print('✅ Rodovia salva com tipo $linha["geometryType"]: ${linha['id']}');
    }
  }

  Map<String, dynamic> normalizeMultiLineToLineString(Map<String, dynamic> sub) {
    final pontos = sub['points'];

    if (sub['geometryType'] == 'MultiLineString' && pontos is List) {
      List<List<Map<String, double>>> trechos = pontos
          .map<List<Map<String, double>>>((linha) =>
          linha.map<Map<String, double>>((p) => {
            'latitude': (p['latitude'] as num).toDouble(),
            'longitude': (p['longitude'] as num).toDouble(),
          }).toList())
          .toList();

      List<Map<String, double>> caminhoFinal = [];

      for (var trecho in trechos) {
        if (caminhoFinal.isEmpty) {
          caminhoFinal.addAll(trecho);
        } else {
          final ultimoPonto = caminhoFinal.last;
          final primeiro = trecho.first;
          final ultimo = trecho.last;

          final distFirst = _dist(ultimoPonto, primeiro);
          final distLast = _dist(ultimoPonto, ultimo);

          final trechoOrdenado = distLast < distFirst ? trecho.reversed.toList() : trecho;
          caminhoFinal.addAll(trechoOrdenado);
        }
      }

      sub['points'] = caminhoFinal;
      sub['geometryType'] = 'LineString';
    }

    return sub;
  }

  double _dist(Map<String, double> p1, Map<String, double> p2) {
    final dx = p1['longitude']! - p2['longitude']!;
    final dy = p1['latitude']! - p2['latitude']!;
    return dx * dx + dy * dy;
  }



  Future<void> carregarRodoviasDoFirebase() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('actives_roads').get();
    roadDataMap.clear();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      // 🟡 Verifica se os pontos ainda são uma lista de listas (MultiLine não normalizado)
      if (data['geometryType'] == 'MultiLineString' ||
          (data['points'] is List && (data['points'].isNotEmpty && data['points'][0] is List))) {

        final List<List<dynamic>> multiPoints = List<List<dynamic>>.from(data['points']);
        final flattened = _normalizeMultiLineFirestorePoints(multiPoints);

        data['points'] = flattened;
        data['geometryType'] = 'LineString'; // força correção

        // ⚠️ Opcional: atualiza no banco com dados corrigidos
        await doc.reference.update({
          'points': flattened,
          'geometryType': 'LineString',
        });
      }

      final normalizedRoad = ActiveRoadsData.fromMap(data);
      if (normalizedRoad.id != null && normalizedRoad.points != null && normalizedRoad.points!.isNotEmpty) {
        roadDataMap[normalizedRoad.id!] = normalizedRoad;
      }
    }
  }

  List<GeoPoint> _normalizeMultiLineFirestorePoints(List<List<dynamic>> segmentos) {
    List<Map<String, double>> caminhoFinal = [];

    for (var trecho in segmentos) {
      final pontos = trecho.map<Map<String, double>>((p) {
        return {
          'latitude': (p['latitude'] as num).toDouble(),
          'longitude': (p['longitude'] as num).toDouble(),
        };
      }).toList();

      if (caminhoFinal.isEmpty) {
        caminhoFinal.addAll(pontos);
      } else {
        final ultimo = caminhoFinal.last;
        final primeiro = pontos.first;
        final fim = pontos.last;

        final distFirst = _dist(ultimo, primeiro);
        final distLast = _dist(ultimo, fim);

        final pontosOrdenados = distLast < distFirst ? pontos.reversed.toList() : pontos;
        caminhoFinal.addAll(pontosOrdenados);
      }
    }

    return caminhoFinal
        .map((p) => GeoPoint(p['latitude']!, p['longitude']!))
        .toList();
  }


  List<TappableChangedPolyline> gerarPolylinesEstilizadas({String? selectedId}) {
    final List<TappableChangedPolyline> polylines = [];

    for (final entry in roadDataMap.entries) {
      final road = entry.value;
      final tagId = road.id!;
      final estilo = ActiveRoadsStyle.styleQGISParaStatus(road.stateSurface, 12);
      final isSelected = tagId == selectedId;

      final multilinha = estilo.asMap().entries.map((entry) {
        final index = entry.key;
        final camada = entry.value;

        return TappableChangedPolyline(
          isDotted: false,
          points: ActiveRoadsRules.deslocarPontos(
            road.points!,
            deslocamentoOrtogonal: index * 0.00003,
          ),
          color: isSelected ? Colors.redAccent : camada.cor,
          defaultColor: camada.cor,
          strokeWidth: isSelected ? camada.width + 2 : camada.width,
          tag: tagId,
        );
      });

      polylines.addAll(multilinha);
    }

    return polylines;
  }



  void setSelectedPolyline(String? polylineId) {
    selectedPolylineId = polylineId;
  }

}
