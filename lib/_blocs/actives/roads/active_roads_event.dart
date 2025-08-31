// lib/_blocs/actives/roads/active_roads_bloc.dart
import 'dart:math' as math;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';

import 'package:siged/_widgets/map/polylines/tappable_changed_polyline.dart';
import 'package:siged/_blocs/actives/roads/active_roads_data.dart';
import 'package:siged/_blocs/actives/roads/active_roads_state.dart';
import 'package:siged/_blocs/actives/roads/active_road_style.dart';
import 'package:siged/_blocs/actives/roads/active_road_rules.dart';

/// =========================
/// EVENTS (sem part/part of)
/// =========================
abstract class ActiveRoadsEvent extends Equatable {
  const ActiveRoadsEvent();
  @override
  List<Object?> get props => [];
}

// ---------- Loaders ----------
class ActiveRoadsWarmupRequested extends ActiveRoadsEvent {
  const ActiveRoadsWarmupRequested();
}

class ActiveRoadsRefreshRequested extends ActiveRoadsEvent {
  const ActiveRoadsRefreshRequested();
}

// ---------- Seleção / Filtros ----------
class ActiveRoadsSelectPolyline extends ActiveRoadsEvent {
  final String? polylineId;
  const ActiveRoadsSelectPolyline(this.polylineId);
  @override
  List<Object?> get props => [polylineId];
}

class ActiveRoadsRegionFilterChanged extends ActiveRoadsEvent {
  final String? region; // ex.: "SERTÃO"
  const ActiveRoadsRegionFilterChanged(this.region);
  @override
  List<Object?> get props => [region];
}

class ActiveRoadsSurfaceFilterChanged extends ActiveRoadsEvent {
  final String? code; // ex.: "PAV", "EOP", null para limpar
  const ActiveRoadsSurfaceFilterChanged(this.code);
  @override
  List<Object?> get props => [code];
}

class ActiveRoadsPieFilterChanged extends ActiveRoadsEvent {
  final int? pieIndex; // índice da fatia selecionada no Pie
  const ActiveRoadsPieFilterChanged(this.pieIndex);
  @override
  List<Object?> get props => [pieIndex];
}

// ---------- CRUD / Import ----------
class ActiveRoadsUpsertRequested extends ActiveRoadsEvent {
  final ActiveRoadsData data;
  const ActiveRoadsUpsertRequested(this.data);
  @override
  List<Object?> get props => [data];
}

class ActiveRoadsDeleteRequested extends ActiveRoadsEvent {
  final String id;
  const ActiveRoadsDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class ActiveRoadsImportBatchRequested extends ActiveRoadsEvent {
  final List<Map<String, dynamic>> linhasPrincipais;
  final List<Map<String, dynamic>> subcolecoes;
  const ActiveRoadsImportBatchRequested({
    required this.linhasPrincipais,
    required this.subcolecoes,
  });

  @override
  List<Object?> get props => [linhasPrincipais, subcolecoes];
}