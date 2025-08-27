
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sisged/_blocs/actives/roads/active_roads_data.dart';
import 'package:sisged/_blocs/actives/roads/active_roads_event.dart';
import 'package:sisged/_blocs/actives/roads/active_roads_state.dart';

/// =========================
/// BLOC
/// =========================
class ActiveRoadsBloc extends Bloc<ActiveRoadsEvent, ActiveRoadsState> {
  ActiveRoadsBloc() : super(const ActiveRoadsState()) {
    // Loaders
    on<ActiveRoadsWarmupRequested>(_onWarmup);
    on<ActiveRoadsRefreshRequested>(_onRefresh);

    // Seleção/Filtros
    on<ActiveRoadsSelectPolyline>(_onSelectPolyline);
    on<ActiveRoadsRegionFilterChanged>(_onRegionFilterChanged);
    on<ActiveRoadsSurfaceFilterChanged>(_onSurfaceFilterChanged);
    on<ActiveRoadsPieFilterChanged>(_onPieFilterChanged);

    // CRUD/Import
    on<ActiveRoadsUpsertRequested>(_onUpsert);
    on<ActiveRoadsDeleteRequested>(_onDelete);
    on<ActiveRoadsImportBatchRequested>(_onImportBatch);
  }

  final _roadsRef = FirebaseFirestore.instance.collection('actives_roads');

  // ===========================================================================
  // Loaders
  // ===========================================================================
  Future<void> _onWarmup(
      ActiveRoadsWarmupRequested e,
      Emitter<ActiveRoadsState> emit,
      ) async {
    emit(state.copyWith(loadStatus: ActiveRoadsLoadStatus.loading, error: null));
    try {
      final list = await _fetchAllNormalized();
      emit(state.copyWith(
        initialized: true,
        all: list,
        loadStatus: ActiveRoadsLoadStatus.success,
        error: null,
      ));
    } catch (err) {
      emit(state.copyWith(
        loadStatus: ActiveRoadsLoadStatus.failure,
        error: err.toString(),
      ));
    }
  }

  Future<void> _onRefresh(
      ActiveRoadsRefreshRequested e,
      Emitter<ActiveRoadsState> emit,
      ) async {
    emit(state.copyWith(loadStatus: ActiveRoadsLoadStatus.loading, error: null));
    try {
      final list = await _fetchAllNormalized();
      emit(state.copyWith(
        all: list,
        loadStatus: ActiveRoadsLoadStatus.success,
        error: null,
      ));
    } catch (err) {
      emit(state.copyWith(
        loadStatus: ActiveRoadsLoadStatus.failure,
        error: err.toString(),
      ));
    }
  }

  // ===========================================================================
  // Seleção / Filtros
  // ===========================================================================
  void _onSelectPolyline(
      ActiveRoadsSelectPolyline e,
      Emitter<ActiveRoadsState> emit,
      ) {
    emit(state.copyWith(selectedPolylineId: e.polylineId));
  }

  void _onRegionFilterChanged(
      ActiveRoadsRegionFilterChanged e,
      Emitter<ActiveRoadsState> emit,
      ) {
    emit(state.copyWith(selectedRegionFilter: e.region));
  }

  void _onSurfaceFilterChanged(
      ActiveRoadsSurfaceFilterChanged e,
      Emitter<ActiveRoadsState> emit,
      ) {
    emit(state.copyWith(selectedSurfaceFilter: e.code));
  }

  void _onPieFilterChanged(
      ActiveRoadsPieFilterChanged e,
      Emitter<ActiveRoadsState> emit,
      ) {
    emit(state.copyWith(selectedPieIndexFilter: e.pieIndex));
  }

  // ===========================================================================
  // CRUD / Import
  // ===========================================================================
  Future<void> _onUpsert(
      ActiveRoadsUpsertRequested e,
      Emitter<ActiveRoadsState> emit,
      ) async {
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final data = e.data;
      final ref = _roadsRef.doc(data.id ?? _roadsRef.doc().id);
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
      ActiveRoadsDeleteRequested e,
      Emitter<ActiveRoadsState> emit,
      ) async {
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      await _roadsRef.doc(e.id).delete();
      final filtered = [...state.all]..removeWhere((r) => r.id == e.id);
      emit(state.copyWith(all: filtered, savingOrImporting: false));
    } catch (err) {
      emit(state.copyWith(savingOrImporting: false, error: err.toString()));
    }
  }

  Future<void> _onImportBatch(
      ActiveRoadsImportBatchRequested e,
      Emitter<ActiveRoadsState> emit,
      ) async {
    emit(state.copyWith(savingOrImporting: true, error: null));
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      for (int i = 0; i < e.linhasPrincipais.length; i++) {
        final linha = Map<String, dynamic>.from(e.linhasPrincipais[i]);
        final docRef = _roadsRef.doc();
        linha['id'] = docRef.id;
        linha['createdAt'] = FieldValue.serverTimestamp();
        linha['createdBy'] = uid;
        linha['updatedAt'] = FieldValue.serverTimestamp();
        linha['updatedBy'] = uid;

        if (i < e.subcolecoes.length) {
          final sub = Map<String, dynamic>.from(e.subcolecoes[i]);

          // Se for MultiLineString, normaliza para LineString
          if (sub['geometryType'] == 'MultiLineString' && sub['points'] is List) {
            final multiLine = List<List<dynamic>>.from(sub['points']);
            final flattened = _normalizeMultiLineToGeoPoints(multiLine);
            sub['points'] = flattened;
            sub['geometryType'] = 'LineString';
          }

          final pontos = sub['points'] as List<dynamic>?;
          final tipo = sub['geometryType'] ?? 'LineString';
          linha['geometryType'] = tipo;

          if (pontos != null) {
            linha['points'] = pontos.map((p) {
              if (p is GeoPoint) {
                return p;
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
  Future<List<ActiveRoadsData>> _fetchAllNormalized() async {
    final snap = await _roadsRef.get();
    final result = <ActiveRoadsData>[];

    for (final doc in snap.docs) {
      final data = Map<String, dynamic>.from(doc.data());

      // Corrige possíveis MultiLineString salvos como lista de listas
      final needsFix = data['geometryType'] == 'MultiLineString' ||
          (data['points'] is List &&
              (data['points'].isNotEmpty && data['points'][0] is List));

      if (needsFix) {
        final multiPoints = List<List<dynamic>>.from(data['points']);
        final flattened = _normalizeMultiLineToGeoPoints(multiPoints);

        data['points'] = flattened;
        data['geometryType'] = 'LineString';

        // opcional: persiste correção no banco
        await doc.reference.update({
          'points': flattened,
          'geometryType': 'LineString',
        });
      }

      final rd = ActiveRoadsData.fromMap(data, id: doc.id);
      if (rd.id != null && rd.points != null && rd.points!.isNotEmpty) {
        result.add(rd);
      }
    }

    // ordena por acrônimo + km inicial (coerente com Store)
    result.sort((a, b) {
      final aKey = '${a.acronym ?? ''}_${a.initialKm ?? 0}';
      final bKey = '${b.acronym ?? ''}_${b.initialKm ?? 0}';
      return aKey.compareTo(bKey);
    });

    return List.unmodifiable(result);
  }

  List<GeoPoint> _normalizeMultiLineToGeoPoints(List<List<dynamic>> segmentos) {
    List<Map<String, double>> caminhoFinal = [];

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
}
