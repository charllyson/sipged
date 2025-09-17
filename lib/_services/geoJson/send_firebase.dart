// lib/_services/geoJson/send_firebase.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ BLoCs usados
import 'package:siged/_blocs/sectors/operation/road/schedule_road_bloc.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_event.dart';
import 'package:siged/_blocs/actives/railway/active_railways_bloc.dart';
import 'package:siged/_blocs/actives/railway/active_railways_event.dart';

// ✅ Stub unificado (aceita .geojson/.json/.kml/.kmz)
import 'import_any_vector.dart';

Future<void> GeoJsonSendFirebase(BuildContext context, {String? fixedPath}) async {
  final TextEditingController pathController = TextEditingController();

  // Se veio "fixedPath", usa sem perguntar; senão abre diálogo
  final path = fixedPath ??
      await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Informe o caminho da coleção'),
          content: TextField(
            controller: pathController,
            decoration: const InputDecoration(
              labelText: 'Ex: planning_highway_domain, actives_railways…',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final p = pathController.text.trim();
                if (p.isNotEmpty) Navigator.pop(context, p);
              },
              child: const Text('Importar'),
            ),
          ],
        ),
      );

  if (!context.mounted || path == null || path.isEmpty) return;

  // Abre o file picker + preview + saneamento e devolve (linhas, geometrias-20m)
  await ImportVector.importAny(
    context: context,
    path: path,
    onSalvar: (linhasPrincipais, geometrias) async {
      // Mantém caso especial
      if (path == 'actives_railways') {
        context.read<ActiveRailwaysBloc>().add(
          ActiveRailwaysImportBatchRequested(
            linhasPrincipais: linhasPrincipais,
            geometrias: geometrias,
          ),
        );
        return;
      }

      // ✅ Se for domínio de faixa de domínio (KML/KMZ ou mesmo GeoJSON), salva direto na coleção
      if (path == 'planning_highway_domain') {
        await _saveBatchToPath(path, linhasPrincipais, geometrias);
        return;
      }

      // 🟦 UNIFICADO NO BOARD (quando importar GeoJSON de projeto)
      String? contractId;
      String? summary;
      try {
        final st = context.read<ScheduleRoadBloc>().state;
        contractId = st.contractId;
        summary = st.summarySubjectContract;
      } catch (_) {
        // sem board bloc no contexto → fallback multi-doc abaixo
      }

      if (contractId != null && contractId!.isNotEmpty) {
        // Constrói uma Geometry a partir das "geometrias" recebidas
        final geometry = _geometryFromGeometrias(geometrias);

        // Dispara o evento unificado para o BoardBloc (repo do Board trata o upsert)
        context.read<ScheduleRoadBloc>().add(
          ScheduleProjectImportGeoJsonRequested(
            geometry, // aceita Geometry/Feature/FeatureCollection
            summarySubjectContract: summary,
          ),
        );
      } else {
        // fallback: grava em lote na coleção informada (compat)
        await _saveBatchToPath(path, linhasPrincipais, geometrias);
      }
    },
    onFinished: () {
      if (!context.mounted) return;

      bool refreshed = false;
      try {
        context.read<ScheduleRoadBloc>().add(const ScheduleRefreshRequested());
        refreshed = true;
      } catch (_) {}

      try {
        context.read<ActiveRailwaysBloc>().add(const ActiveRailwaysRefreshRequested());
        refreshed = true;
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Importação concluída.${refreshed ? '' : ' (dados salvos)'}')),
      );
    },
    maxJumpKm: 2.0,
  );
}

// ================= helpers =================

/// Converte `geometrias` em uma Geometry GeoJSON.
/// Se houver >1 segmento => MultiLineString; senão LineString.
Map<String, dynamic> _geometryFromGeometrias(List<Map<String, dynamic>> geometrias) {
  final segmentos = <List<List<double>>>[];

  for (final g in geometrias) {
    final geom = Map<String, dynamic>.from(g);
    final type = (geom['geometryType'] ?? 'LineString').toString();
    final pts = (geom['points'] as List?) ?? const [];

    List<List<double>> toLonLat(List<dynamic> raw) {
      return raw.map<List<double>>((p) {
        if (p is GeoPoint) return [p.longitude, p.latitude];
        if (p is List && p.length >= 2) {
          final lon = (p[0] as num).toDouble();
          final lat = (p[1] as num).toDouble();
          return [lon, lat];
        }
        // map {latitude, longitude}
        final lat = (p['latitude'] as num).toDouble();
        final lon = (p['longitude'] as num).toDouble();
        return [lon, lat];
      }).toList();
    }

    if (type == 'MultiLineString') {
      for (final seg in pts) {
        segmentos.add(toLonLat(List<dynamic>.from(seg as List)));
      }
    } else {
      segmentos.add(toLonLat(pts));
    }
  }

  if (segmentos.length == 1) {
    return {'type': 'LineString', 'coordinates': segmentos.first};
  }
  return {'type': 'MultiLineString', 'coordinates': segmentos};
}

Future<void> _saveBatchToPath(
    String path,
    List<Map<String, dynamic>> linhasPrincipais,
    List<Map<String, dynamic>> geometrias,
    ) async {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final col = FirebaseFirestore.instance.collection(path);

  for (int i = 0; i < linhasPrincipais.length; i++) {
    final linha = Map<String, dynamic>.from(linhasPrincipais[i]);
    final docRef = col.doc(); // 1 doc por feature (autoId)
    linha['id'] = docRef.id;
    linha['createdAt'] = FieldValue.serverTimestamp();
    linha['createdBy'] = uid;
    linha['updatedAt'] = FieldValue.serverTimestamp();
    linha['updatedBy'] = uid;

    if (i < geometrias.length) {
      final sub = Map<String, dynamic>.from(geometrias[i]);

      if (sub['geometryType'] == 'MultiLineString' && sub['points'] is List) {
        final flattened = _normalizeMultiLineToGeoPoints(
          List<List<dynamic>>.from(sub['points']),
        );
        sub['points'] = flattened;
        sub['geometryType'] = 'LineString';
      }

      final pontos = sub['points'] as List<dynamic>?;
      linha['geometryType'] = sub['geometryType'] ?? 'LineString';

      if (pontos != null) {
        linha['points'] = pontos.map((p) {
          if (p is GeoPoint) return p;
          if (p is List && p.length >= 2) {
            final lat = (p[1] as num).toDouble(); // [lon, lat]
            final lng = (p[0] as num).toDouble();
            return GeoPoint(lat, lng);
          }
          return GeoPoint(
            (p['latitude'] as num).toDouble(),
            (p['longitude'] as num).toDouble(),
          );
        }).toList();
      }
    }

    await docRef.set(linha, SetOptions(merge: true));
  }
}

List<GeoPoint> _normalizeMultiLineToGeoPoints(List<List<dynamic>> segmentos) {
  final caminhoFinal = <Map<String, double>>[];

  double _dist(Map<String, double> a, Map<String, double> b) {
    final dx = a['longitude']! - b['longitude']!;
    final dy = a['latitude']! - b['latitude']!;
    return dx * dx + dy * dy;
  }

  for (final trecho in segmentos) {
    final pontos = trecho.map<Map<String, double>>((p) {
      if (p is GeoPoint) return {'latitude': p.latitude, 'longitude': p.longitude};
      if (p is List && p.length >= 2) {
        return {'latitude': (p[1] as num).toDouble(), 'longitude': (p[0] as num).toDouble()};
      }
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
      final ord = _dist(ultimo, fim) < _dist(ultimo, primeiro) ? pontos.reversed : pontos;
      caminhoFinal.addAll(ord.toList());
    }
  }

  return caminhoFinal.map((p) => GeoPoint(p['latitude']!, p['longitude']!)).toList();
}
