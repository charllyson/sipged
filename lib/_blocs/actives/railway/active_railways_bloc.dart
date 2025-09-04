import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/actives/railway/active_railway_data.dart';
import 'package:siged/_blocs/actives/railway/active_railways_event.dart';
import 'package:siged/_blocs/actives/railway/active_railways_state.dart';


/// =========================
/// BLOC — Ferrovias
/// =========================
class ActiveRailwaysBloc extends Bloc<ActiveRailwaysEvent, ActiveRailwaysState> {
  ActiveRailwaysBloc() : super(const ActiveRailwaysState()) {
    // Loaders
    on<ActiveRailwaysWarmupRequested>(_onWarmup);
    on<ActiveRailwaysRefreshRequested>(_onRefresh);

    // Seleção/Filtros
    on<ActiveRailwaysSelectPolyline>(_onSelectPolyline);
    on<ActiveRailwaysRegionFilterChanged>(_onRegionFilterChanged);
    on<ActiveRailwaysStatusFilterChanged>(_onStatusFilterChanged);
    on<ActiveRailwaysPieFilterChanged>(_onPieFilterChanged);

    // CRUD/Import
    on<ActiveRailwaysUpsertRequested>(_onUpsert);
    on<ActiveRailwaysDeleteRequested>(_onDelete);
    on<ActiveRailwaysImportBatchRequested>(_onImportBatch);

    // 🔹 Zoom do mapa
    // lib/_blocs/actives/railway/active_railways_bloc.dart
    on<ActiveRailwaysMapZoomChanged>((event, emit) {
      final z = double.parse(event.zoom.toStringAsFixed(2));
      if ((state.mapZoom - z).abs() >= 0.05) {
        emit(state.copyWith(mapZoom: z));
      }
    });

  }

  /// Coleção específica de FERROVIAS
  final _railRef = FirebaseFirestore.instance.collection('actives_railways');

  // ===========================================================================
  // Loaders
  // ===========================================================================
  Future<void> _onWarmup(
      ActiveRailwaysWarmupRequested e,
      Emitter<ActiveRailwaysState> emit,
      ) async {
    emit(state.copyWith(loadStatus: ActiveRailwaysLoadStatus.loading, error: null));
    try {
      final list = await _fetchAllNormalized();
      emit(state.copyWith(
        initialized: true,
        all: list,
        loadStatus: ActiveRailwaysLoadStatus.success,
        error: null,
      ));
    } catch (err) {
      emit(state.copyWith(
        loadStatus: ActiveRailwaysLoadStatus.failure,
        error: err.toString(),
      ));
    }
  }

  Future<void> _onRefresh(
      ActiveRailwaysRefreshRequested e,
      Emitter<ActiveRailwaysState> emit,
      ) async {
    emit(state.copyWith(loadStatus: ActiveRailwaysLoadStatus.loading, error: null));
    try {
      final list = await _fetchAllNormalized();
      emit(state.copyWith(
        all: list,
        loadStatus: ActiveRailwaysLoadStatus.success,
        error: null,
      ));
    } catch (err) {
      emit(state.copyWith(
        loadStatus: ActiveRailwaysLoadStatus.failure,
        error: err.toString(),
      ));
    }
  }

  // ===========================================================================
  // Seleção / Filtros
  // ===========================================================================
  void _onSelectPolyline(
      ActiveRailwaysSelectPolyline e,
      Emitter<ActiveRailwaysState> emit,
      ) {
    emit(state.copyWith(selectedPolylineId: e.polylineId));
  }

  void _onRegionFilterChanged(
      ActiveRailwaysRegionFilterChanged e,
      Emitter<ActiveRailwaysState> emit,
      ) {
    emit(state.copyWith(selectedRegionFilter: e.region));
  }

  void _onStatusFilterChanged(
      ActiveRailwaysStatusFilterChanged e,
      Emitter<ActiveRailwaysState> emit,
      ) {
    emit(state.copyWith(selectedStatusFilter: e.statusCode));
  }

  void _onPieFilterChanged(
      ActiveRailwaysPieFilterChanged e,
      Emitter<ActiveRailwaysState> emit,
      ) {
    emit(state.copyWith(selectedPieIndexFilter: e.pieIndex));
  }

  // ===========================================================================
  // CRUD / Import
  // ===========================================================================
  Future<void> _onUpsert(
      ActiveRailwaysUpsertRequested e,
      Emitter<ActiveRailwaysState> emit,
      ) async {
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final data = e.data;
      final ref = _railRef.doc(data.id ?? _railRef.doc().id);
      data.id ??= ref.id;

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

      final list = await _fetchAllNormalized();
      emit(state.copyWith(
        all: list,
        savingOrImporting: false,
        error: null,
      ));
    } catch (err) {
      emit(state.copyWith(savingOrImporting: false, error: err.toString()));
    }
  }

  Future<void> _onDelete(
      ActiveRailwaysDeleteRequested e,
      Emitter<ActiveRailwaysState> emit,
      ) async {
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      await _railRef.doc(e.id).delete();
      final filtered = [...state.all]..removeWhere((r) => r.id == e.id);
      emit(state.copyWith(all: filtered, savingOrImporting: false));
    } catch (err) {
      emit(state.copyWith(savingOrImporting: false, error: err.toString()));
    }
  }

  /// Importa várias ferrovias (formato compatível com rodovias).
  Future<void> _onImportBatch(
      ActiveRailwaysImportBatchRequested e,
      Emitter<ActiveRailwaysState> emit,
      ) async {
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      for (int i = 0; i < e.linhasPrincipais.length; i++) {
        final linha = Map<String, dynamic>.from(e.linhasPrincipais[i]);
        final docRef = _railRef.doc();
        linha['id'] = docRef.id;
        linha['createdAt'] = FieldValue.serverTimestamp();
        linha['createdBy'] = uid;
        linha['updatedAt'] = FieldValue.serverTimestamp();
        linha['updatedBy'] = uid;

        if (i < e.geometrias.length) {
          final sub = Map<String, dynamic>.from(e.geometrias[i]);

          if (sub['geometryType'] == 'MultiLineString' && sub['points'] is List) {
            final multi = List<List<dynamic>>.from(sub['points']);
            final flattened = _normalizeMultiLineToGeoPoints(multi);
            sub['points'] = flattened;
            sub['geometryType'] = 'LineString';
          }

          final pontos = sub['points'] as List<dynamic>?;
          final tipo = sub['geometryType'] ?? 'LineString';
          linha['geometryType'] = tipo;

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

      final list = await _fetchAllNormalized();
      emit(state.copyWith(all: list, savingOrImporting: false, error: null));
    } catch (err) {
      emit(state.copyWith(savingOrImporting: false, error: err.toString()));
    }
  }

  // ===========================================================================
  // Firestore helpers
  // ===========================================================================
  Future<List<ActiveRailwayData>> _fetchAllNormalized() async {
    final snap = await _railRef.get();
    final result = <ActiveRailwayData>[];

    for (final doc in snap.docs) {
      var data = Map<String, dynamic>.from(doc.data());

      final needsFix = data['geometryType'] == 'MultiLineString' ||
          (data['points'] is List &&
              data['points'].isNotEmpty &&
              data['points'][0] is List);

      if (needsFix) {
        final multiPoints = List<List<dynamic>>.from(data['points']);
        final flattened = _normalizeMultiLineToGeoPoints(multiPoints);

        data['points'] = flattened;
        data['geometryType'] = 'LineString';

        await doc.reference.update({
          'points': flattened,
          'geometryType': 'LineString',
        });
      }

      final rd = ActiveRailwayData.fromMap(data)..id = doc.id;
      if (rd.id != null && rd.points != null && rd.points!.isNotEmpty) {
        result.add(rd);
      }
    }

    result.sort((a, b) {
      final aKey = '${a.codigo ?? ''}_${a.id ?? ''}';
      final bKey = '${b.codigo ?? ''}_${b.id ?? ''}';
      return aKey.compareTo(bKey);
    });

    return List.unmodifiable(result);
  }

  /// Achata uma MultiLineString em uma única `List<GeoPoint>`, ordenando por continuidade.
  List<GeoPoint> _normalizeMultiLineToGeoPoints(List<List<dynamic>> segmentos) {
    final caminhoFinal = <Map<String, double>>[];

    double _dist(Map<String, double> p1, Map<String, double> p2) {
      final dx = p1['longitude']! - p2['longitude']!;
      final dy = p1['latitude']! - p2['latitude']!;
      return dx * dx + dy * dy;
    }

    for (var trecho in segmentos) {
      final pontos = trecho.map<Map<String, double>>((p) {
        if (p is GeoPoint) {
          return {'latitude': p.latitude, 'longitude': p.longitude};
        }
        if (p is List && p.length >= 2) {
          return {
            'latitude': (p[1] as num).toDouble(),
            'longitude': (p[0] as num).toDouble(),
          };
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

        final distFirst = _dist(ultimo, primeiro);
        final distLast = _dist(ultimo, fim);

        final pontosOrdenados =
        distLast < distFirst ? pontos.reversed.toList() : pontos;
        caminhoFinal.addAll(pontosOrdenados);
      }
    }

    return caminhoFinal
        .map((p) => GeoPoint(p['latitude']!, p['longitude']!))
        .toList();
  }
}
