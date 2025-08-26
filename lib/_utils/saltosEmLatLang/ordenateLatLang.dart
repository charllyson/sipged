import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import 'package:sisged/_blocs/actives/roads/active_roads_data.dart';


/*
Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.sort, size: 16, color: Colors.white),
                          label: const Text('Verificar saltos', style: TextStyle(color: Colors.white)),
                          onPressed: () async {
                            if (road.points != null && road.points!.isNotEmpty) {
                              print('🔍 Antes da ordenação:');
                              for (var p in road.points!) {
                                print('${p.latitude}, ${p.longitude}');
                              }

                              await verificarSaltosEmRodovias(
                                collectionPath: 'actives_roads',
                                distanciaMaxEmKm: 2.5, // você pode ajustar esse valor
                              );

                              final updatedDoc = await FirebaseFirestore.instance.collection('actives_roads').doc(road.id).get();
                              final updatedPoints = (updatedDoc.data()?['points'] as List<dynamic>)
                                  .network((p) => GeoPoint(p.latitude, p.longitude))
                                  .toList();

                              print('✅ Depois da ordenação:');
                              for (var p in updatedPoints) {
                                print('${p.latitude}, ${p.longitude}');
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✅ Pontos ordenados e salvos no Firestore')),
                              );
                            }
                          },


                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.sort, size: 16, color: Colors.white),
                          label: const Text('Ordenar pontos', style: TextStyle(color: Colors.white)),
                          onPressed: () async {
                            if (road.points != null && road.points!.isNotEmpty) {
                              print('🔍 Antes da ordenação:');
                              for (var p in road.points!) {
                                print('${p.latitude}, ${p.longitude}');
                              }

                              await reordenarPontosPorProximidadeGeoPoint(documentId: road.id!);

                              final updatedDoc = await FirebaseFirestore.instance.collection('actives_roads').doc(road.id).get();
                              final updatedPoints = (updatedDoc.data()?['points'] as List<dynamic>)
                                  .network((p) => GeoPoint(p.latitude, p.longitude))
                                  .toList();

                              print('✅ Depois da ordenação:');
                              for (var p in updatedPoints) {
                                print('${p.latitude}, ${p.longitude}');
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✅ Pontos ordenados e salvos no Firestore')),
                              );
                            }
                          },


                        ),
                      ),
*/

/// Ordena os pontos pela sequência mais próxima possível (greedy)
List<LatLng> ordenarPontosPorSequenciaMaisProxima(List<LatLng> pontos) {
  if (pontos.isEmpty) return [];

  final distance = const Distance();
  final pontosNaoVisitados = List<LatLng>.from(pontos);
  final List<LatLng> ordenado = [];

  LatLng atual = pontosNaoVisitados.removeAt(0);
  ordenado.add(atual);

  while (pontosNaoVisitados.isNotEmpty) {
    pontosNaoVisitados.sort(
            (a, b) => distance(atual, a).compareTo(distance(atual, b)));
    atual = pontosNaoVisitados.removeAt(0);
    ordenado.add(atual);
  }

  return ordenado;
}

/// Aplica a ordenação por proximidade e salva no Firestore
Future<void> ordenarESalvarPontosDaRodovia(ActiveRoadsData road) async {
  if (road.points == null || road.points!.isEmpty || road.id == null) return;

  final pontosOrdenados = ordenarPontosPorSequenciaMaisProxima(road.points!);
  final firestore = FirebaseFirestore.instance;
  final docRef = firestore.collection('actives_roads').doc(road.id);

  final novaLista =
  pontosOrdenados.map((p) => GeoPoint(p.latitude, p.longitude)).toList();

  await docRef.update({'points': novaLista});
  print('✅ Pontos ordenados e salvos como GeoPoint para rodovia ${road.id}');
}

/// Reordena pontos de um documento no Firestore utilizando ordenação reversa
Future<void> reordenarPontosPorProximidadeGeoPoint({
  required String documentId,
  String collectionPath = 'actives_roads',
}) async {
  final firestore = FirebaseFirestore.instance;
  final docRef = firestore.collection(collectionPath).doc(documentId);
  final docSnapshot = await docRef.get();

  if (!docSnapshot.exists) {
    print('❌ Documento não encontrado: $documentId');
    return;
  }

  final data = docSnapshot.data();
  if (data == null || !data.containsKey('points')) {
    print('⚠️ Documento sem campo "points".');
    return;
  }

  final List<dynamic> rawPoints = data['points'];
  final List<LatLng> original = rawPoints.map<LatLng>((p) {
    if (p is GeoPoint) {
      return LatLng(p.latitude, p.longitude);
    } else if (p is Map && p.containsKey('latitude')) {
      return LatLng(p['latitude'], p['longitude']);
    } else {
      throw Exception('Formato de ponto não reconhecido: $p');
    }
  }).toList();

  final ordenado = ordenarPontosPorSequenciaLinearDecrescente(original);

  final List<GeoPoint> geoPointsOrdenados =
  ordenado.map((p) => GeoPoint(p.latitude, p.longitude)).toList();

  await docRef.update({'points': geoPointsOrdenados});
  print('✅ Documento $documentId atualizado com ${geoPointsOrdenados.length} pontos reordenados.');
}

/// Ordena os pontos começando pelo mais à esquerda e inferior
List<LatLng> ordenarPontosPorSequenciaLinearCrescente(List<LatLng> pontos) {
  if (pontos.isEmpty) return [];

  final distance = const Distance();
  final naoVisitados = List<LatLng>.from(pontos);
  final List<LatLng> ordenado = [];

  naoVisitados.sort((a, b) {
    final c = a.longitude.compareTo(b.longitude);
    return c != 0 ? c : a.latitude.compareTo(b.latitude);
  });

  LatLng atual = naoVisitados.removeAt(0);
  ordenado.add(atual);

  while (naoVisitados.isNotEmpty) {
    naoVisitados.sort((a, b) => distance(atual, a).compareTo(distance(atual, b)));
    atual = naoVisitados.removeAt(0);
    ordenado.add(atual);
  }

  return ordenado;
}

/// Ordena os pontos começando pelo mais à direita e inferior (ordem reversa)
List<LatLng> ordenarPontosPorSequenciaLinearDecrescente(List<LatLng> pontos) {
  if (pontos.isEmpty) return [];

  final distance = const Distance();
  final naoVisitados = List<LatLng>.from(pontos);
  final List<LatLng> ordenado = [];

  naoVisitados.sort((a, b) {
    final c = b.longitude.compareTo(a.longitude);
    return c != 0 ? c : b.latitude.compareTo(a.latitude);
  });

  LatLng atual = naoVisitados.removeAt(0);
  ordenado.add(atual);

  while (naoVisitados.isNotEmpty) {
    naoVisitados.sort((a, b) => distance(atual, a).compareTo(distance(atual, b)));
    atual = naoVisitados.removeAt(0);
    ordenado.add(atual);
  }

  return ordenado;
}

/// Segmenta os pontos por distância máxima entre trechos (ordem normal)
List<List<LatLng>> ordenarPontosComLimiteDeDistanciaCrescente({
  required List<LatLng> pontos,
  double maxDistanciaEmMetros = 12000,
}) {
  if (pontos.isEmpty) return [];

  final distance = const Distance();
  final naoVisitados = List<LatLng>.from(pontos);
  final List<List<LatLng>> segmentos = [];

  LatLng atual = naoVisitados.removeAt(0);
  List<LatLng> segmentoAtual = [atual];

  while (naoVisitados.isNotEmpty) {
    naoVisitados.sort((a, b) => distance(atual, a).compareTo(distance(atual, b)));
    final proximo = naoVisitados.first;
    final distancia = distance(atual, proximo);

    if (distancia <= maxDistanciaEmMetros) {
      atual = naoVisitados.removeAt(0);
      segmentoAtual.add(atual);
    } else {
      segmentos.add(segmentoAtual);
      atual = naoVisitados.removeAt(0);
      segmentoAtual = [atual];
    }
  }

  if (segmentoAtual.isNotEmpty) {
    segmentos.add(segmentoAtual);
  }

  return segmentos;
}


/// Verifica saltos de distância entre pontos de cada rodovia e retorna os IDs
/// dos documentos que apresentam algum salto maior que [distanciaMaxEmKm].
Future<void> verificarSaltosEmRodovias({
  String collectionPath = 'actives_roads',
  double distanciaMaxEmKm = 2.0,
}) async {
  final firestore = FirebaseFirestore.instance;
  final collection = firestore.collection(collectionPath);
  final snapshot = await collection.get();

  final distance = const Distance();
  final List<String> documentosComSaltos = [];

  for (final doc in snapshot.docs) {
    final data = doc.data();
    final rawPoints = data['points'];

    if (rawPoints == null || rawPoints.length < 2) continue;

    final List<LatLng> pontos = rawPoints.map<LatLng>((p) {
      if (p is GeoPoint) {
        return LatLng(p.latitude, p.longitude);
      } else if (p is Map && p.containsKey('latitude')) {
        return LatLng(p['latitude'], p['longitude']);
      } else {
        throw Exception('Formato de ponto não reconhecido: $p');
      }
    }).toList();

    for (int i = 0; i < pontos.length - 1; i++) {
      final d = distance.as(LengthUnit.Kilometer, pontos[i], pontos[i + 1]);
      if (d > distanciaMaxEmKm) {
        documentosComSaltos.add(doc.id);
        print('🚨 Rodovia ${doc.id} (Código do trecho ${data['roadCode']}) tem salto de ${d.toStringAsFixed(2)} km entre os pontos $i e ${i + 1}');
        break; // Não precisa checar os outros pontos dessa rodovia
      }
    }
  }

  print('🔍 Total de rodovias com saltos maiores que $distanciaMaxEmKm km: ${documentosComSaltos.length}');
  print('🆔 IDs: $documentosComSaltos');
}
