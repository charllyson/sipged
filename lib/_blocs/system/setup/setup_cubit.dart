import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'setup_data.dart';
import 'setup_repository.dart';
import 'setup_state.dart';

class SetupCubit extends Cubit<SetupState> {
  final SetupRepository _repo;

  SetupCubit({SetupRepository? repository})
      : _repo = repository ?? SetupRepository(),
        super(SetupState.initial());

  String get companyDocId => SetupRepository.companyDocId;

  Future<void> loadSystemSetup() async {
    try {
      emit(state.copyWith(
        isLoading: true,
        clearError: true,
      ));

      final results = await Future.wait<dynamic>([
        _repo.loadCompanyProfile(),
        _repo.loadCompanyBodies(),
        _repo.loadUnits(),
        _repo.loadRoads(),
        _repo.loadRegions(),
        _repo.loadFundingSources(),
        _repo.loadPrograms(),
        _repo.loadExpenseNatures(),
      ]);

      emit(state.copyWith(
        isLoading: false,
        hasLoadedSystem: true,
        companyProfile: results[0] as SetupData?,
        companyBodies: results[1] as List<SetupData>,
        units: results[2] as List<SetupData>,
        roads: results[3] as List<SetupData>,
        regions: results[4] as List<SetupData>,
        fundingSources: results[5] as List<SetupData>,
        programs: results[6] as List<SetupData>,
        expenseNatures: results[7] as List<SetupData>,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        hasLoadedSystem: true,
        error: e.toString(),
      ));
    }
  }

  Future<void> ensureSystemSetupLoaded() async {
    if (state.hasLoadedSystem) return;
    await loadSystemSetup();
  }

  Future<void> reloadChildren() async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final results = await Future.wait<dynamic>([
        _repo.loadCompanyBodies(),
        _repo.loadUnits(),
        _repo.loadRoads(),
        _repo.loadRegions(),
        _repo.loadFundingSources(),
        _repo.loadPrograms(),
        _repo.loadExpenseNatures(),
      ]);

      emit(state.copyWith(
        isLoading: false,
        companyBodies: results[0] as List<SetupData>,
        units: results[1] as List<SetupData>,
        roads: results[2] as List<SetupData>,
        regions: results[3] as List<SetupData>,
        fundingSources: results[4] as List<SetupData>,
        programs: results[5] as List<SetupData>,
        expenseNatures: results[6] as List<SetupData>,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<SetupData?> saveCompanyProfile({
    required String label,
    required String fantasyName,
    String? cnpj,
    Uint8List? logoBytes,
    String? logoFileName,
    String? logoContentType,
    bool removeLogo = false,
    String? oldLogoPath,
  }) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final saved = await _repo.saveCompanyProfile(
        label: label,
        fantasyName: fantasyName,
        cnpj: cnpj,
        logoBytes: logoBytes,
        logoFileName: logoFileName,
        logoContentType: logoContentType,
        removeLogo: removeLogo,
        oldLogoPath: oldLogoPath,
      );

      emit(state.copyWith(
        isLoading: false,
        companyProfile: saved,
        hasLoadedSystem: true,
      ));

      return saved;
    } on FirebaseException catch (e, s) {
      debugPrint(
          'saveCompanyProfile FirebaseException: ${e.code} - ${e.message}');
      debugPrintStack(stackTrace: s);

      emit(state.copyWith(
        isLoading: false,
        error: 'Firebase (${e.code}): ${e.message}',
      ));
      return null;
    } catch (e, s) {
      debugPrint('saveCompanyProfile error: $e');
      debugPrintStack(stackTrace: s);

      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      return null;
    }
  }

  Future<SetupData?> updateCompanyName(
      String newLabel, {
        String? fantasyName,
      }) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final updatedCompany = await _repo.updateCompanyName(
        newLabel,
        fantasyName: fantasyName,
      );

      emit(state.copyWith(
        isLoading: false,
        companyProfile: updatedCompany,
      ));

      return updatedCompany;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  Future<SetupData?> updateCompanyLogo({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final updatedCompany = await _repo.updateCompanyLogo(
        bytes: bytes,
        fileName: fileName,
        contentType: contentType,
        oldLogoPath: state.companyProfile?.logoPath,
      );

      emit(state.copyWith(
        isLoading: false,
        companyProfile: updatedCompany,
      ));

      return updatedCompany;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  Future<void> deleteCompanyProfile() async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      await _repo.deleteCompanyProfile();

      emit(state.copyWith(
        isLoading: false,
        clearCompanyProfile: true,
        companyBodies: const [],
        units: const [],
        roads: const [],
        regions: const [],
        fundingSources: const [],
        programs: const [],
        expenseNatures: const [],
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  String? findCompanyIdByLabel(String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    final company = state.companyProfile;
    if (company == null) return null;

    final name = (company.companyName ?? company.label).trim().toLowerCase();
    if (name == normalized) return companyDocId;

    return null;
  }

  Future<SetupData?> createUnit(String label) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final created = await _repo.createUnit(label);
      final updated = List<SetupData>.from(state.units)..add(created);

      emit(state.copyWith(
        isLoading: false,
        units: updated,
      ));

      return created;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  Future<SetupData?> updateUnitName(
      String unitId,
      String newLabel,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final updatedUnit = await _repo.updateUnitName(unitId, newLabel);

      final updatedList = state.units.map((u) {
        final same = (u.unitId != null && u.unitId == unitId) || u.id == unitId;
        return same ? updatedUnit : u;
      }).toList();

      emit(state.copyWith(
        isLoading: false,
        units: updatedList,
      ));

      return updatedUnit;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  Future<void> deleteUnit(String unitId) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      await _repo.deleteUnit(unitId);

      final updatedList = state.units.where((u) {
        final same = (u.unitId != null && u.unitId == unitId) || u.id == unitId;
        return !same;
      }).toList();

      emit(state.copyWith(
        isLoading: false,
        units: updatedList,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  List<SetupData> getUnits() => state.units;

  Future<SetupData?> createRoad(String label) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final created = await _repo.createRoad(label);
      final updated = List<SetupData>.from(state.roads)..add(created);

      emit(state.copyWith(
        isLoading: false,
        roads: updated,
      ));

      return created;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  Future<SetupData?> updateRoadName(
      String roadId,
      String newLabel,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final updatedRoad = await _repo.updateRoadName(roadId, newLabel);

      final updatedList = state.roads.map((r) {
        final same = (r.roadId != null && r.roadId == roadId) || r.id == roadId;
        return same ? updatedRoad : r;
      }).toList();

      emit(state.copyWith(
        isLoading: false,
        roads: updatedList,
      ));

      return updatedRoad;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  Future<void> deleteRoad(String roadId) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      await _repo.deleteRoad(roadId);

      final updatedList = state.roads.where((r) {
        final same = (r.roadId != null && r.roadId == roadId) || r.id == roadId;
        return !same;
      }).toList();

      emit(state.copyWith(
        isLoading: false,
        roads: updatedList,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  List<SetupData> getRoads() => state.roads;

  Future<SetupData?> createRegion(
      String label, {
        List<String>? municipios,
      }) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final created = await _repo.createRegion(
        label,
        municipios: municipios,
      );
      final updated = List<SetupData>.from(state.regions)..add(created);

      emit(state.copyWith(
        isLoading: false,
        regions: updated,
      ));

      return created;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  Future<SetupData?> updateRegionMunicipios(
      String regionId,
      List<String> municipios,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final updatedRegion =
      await _repo.updateRegionMunicipios(regionId, municipios);

      final updatedList = state.regions
          .map((r) => r.regionId == regionId ? updatedRegion : r)
          .toList();

      emit(state.copyWith(
        isLoading: false,
        regions: updatedList,
      ));

      return updatedRegion;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  Future<SetupData?> updateRegionName(
      String regionId,
      String newLabel,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final updatedRegion = await _repo.updateRegionName(regionId, newLabel);

      final updatedList = state.regions
          .map((r) => r.regionId == regionId ? updatedRegion : r)
          .toList();

      emit(state.copyWith(
        isLoading: false,
        regions: updatedList,
      ));

      return updatedRegion;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  Future<void> deleteRegion(String regionId) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      await _repo.deleteRegion(regionId);

      final updatedList =
      state.regions.where((r) => r.regionId != regionId).toList();

      emit(state.copyWith(
        isLoading: false,
        regions: updatedList,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  List<SetupData> getRegions() => state.regions;

  Future<SetupData?> createFundingSource(String label) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final created = await _repo.createFundingSource(label);
      final updated = List<SetupData>.from(state.fundingSources)..add(created);

      emit(state.copyWith(
        isLoading: false,
        fundingSources: updated,
      ));

      return created;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  Future<SetupData?> updateFundingSourceName(
      String sourceId,
      String newLabel,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final updated = await _repo.updateFundingSourceName(sourceId, newLabel);

      final updatedList = state.fundingSources.map((f) {
        final same =
            (f.genericId != null && f.genericId == sourceId) || f.id == sourceId;
        return same ? updated : f;
      }).toList();

      emit(state.copyWith(
        isLoading: false,
        fundingSources: updatedList,
      ));

      return updated;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  Future<void> deleteFundingSource(String sourceId) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      await _repo.deleteFundingSource(sourceId);

      final updatedList = state.fundingSources.where((f) {
        final same =
            (f.genericId != null && f.genericId == sourceId) || f.id == sourceId;
        return !same;
      }).toList();

      emit(state.copyWith(
        isLoading: false,
        fundingSources: updatedList,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  List<SetupData> getFundingSources() => state.fundingSources;

  Future<SetupData?> createProgram(String label) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final created = await _repo.createProgram(label);
      final updated = List<SetupData>.from(state.programs)..add(created);

      emit(state.copyWith(
        isLoading: false,
        programs: updated,
      ));

      return created;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  Future<SetupData?> updateProgramName(
      String programId,
      String newLabel,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final updated = await _repo.updateProgramName(programId, newLabel);

      final updatedList = state.programs.map((p) {
        final same =
            (p.genericId != null && p.genericId == programId) || p.id == programId;
        return same ? updated : p;
      }).toList();

      emit(state.copyWith(
        isLoading: false,
        programs: updatedList,
      ));

      return updated;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  Future<void> deleteProgram(String programId) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      await _repo.deleteProgram(programId);

      final updatedList = state.programs.where((p) {
        final same =
            (p.genericId != null && p.genericId == programId) || p.id == programId;
        return !same;
      }).toList();

      emit(state.copyWith(
        isLoading: false,
        programs: updatedList,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  List<SetupData> getPrograms() => state.programs;

  Future<SetupData?> createExpenseNature(String label) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final created = await _repo.createExpenseNature(label);
      final updated = List<SetupData>.from(state.expenseNatures)..add(created);

      emit(state.copyWith(
        isLoading: false,
        expenseNatures: updated,
      ));

      return created;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  Future<SetupData?> updateExpenseNatureName(
      String natureId,
      String newLabel,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final updated = await _repo.updateExpenseNatureName(natureId, newLabel);

      final updatedList = state.expenseNatures.map((n) {
        final same =
            (n.genericId != null && n.genericId == natureId) || n.id == natureId;
        return same ? updated : n;
      }).toList();

      emit(state.copyWith(
        isLoading: false,
        expenseNatures: updatedList,
      ));

      return updated;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  Future<void> deleteExpenseNature(String natureId) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      await _repo.deleteExpenseNature(natureId);

      final updatedList = state.expenseNatures.where((n) {
        final same =
            (n.genericId != null && n.genericId == natureId) || n.id == natureId;
        return !same;
      }).toList();

      emit(state.copyWith(
        isLoading: false,
        expenseNatures: updatedList,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  List<SetupData> getExpenseNatures() => state.expenseNatures;

  Future<SetupData?> createCompanyBody(
      String label, {
        String? cnpj,
      }) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final created = await _repo.createCompanyBody(label, cnpj: cnpj);
      final updated = List<SetupData>.from(state.companyBodies)..add(created);

      emit(state.copyWith(
        isLoading: false,
        companyBodies: updated,
      ));

      return created;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  Future<SetupData?> updateCompanyBodyName(
      String bodyId,
      String newLabel,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final updated = await _repo.updateCompanyBodyName(bodyId, newLabel);

      final updatedList = state.companyBodies.map((b) {
        final same =
            (b.genericId != null && b.genericId == bodyId) || b.id == bodyId;
        return same ? updated : b;
      }).toList();

      emit(state.copyWith(
        isLoading: false,
        companyBodies: updatedList,
      ));

      return updated;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  Future<void> deleteCompanyBody(String bodyId) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      await _repo.deleteCompanyBody(bodyId);

      final updatedList = state.companyBodies.where((b) {
        final same =
            (b.genericId != null && b.genericId == bodyId) || b.id == bodyId;
        return !same;
      }).toList();

      emit(state.copyWith(
        isLoading: false,
        companyBodies: updatedList,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  List<SetupData> getCompanyBodies() => state.companyBodies;
}