import 'package:flutter_bloc/flutter_bloc.dart';

import 'setup_data.dart';
import 'setup_state.dart';
import 'setup_repository.dart';

class SetupCubit extends Cubit<SetupState> {
  final SetupRepository _repo;

  SetupCubit({SetupRepository? repository})
      : _repo = repository ?? SetupRepository(),
        super(SetupState.initial());

  // =========================
  // COMPANIES
  // =========================

  Future<void> loadCompanies() async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final companies = await _repo.loadCompanies();

      emit(state.copyWith(isLoading: false, companies: companies));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<SetupData?> createCompany(String label, {String? cnpj}) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final created = await _repo.createCompany(label, cnpj: cnpj);
      final updated = List<SetupData>.from(state.companies)..add(created);

      emit(state.copyWith(isLoading: false, companies: updated));

      return created;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  /// 🔥 EDITAR nome de company
  Future<SetupData?> updateCompanyName(
      String companyId,
      String newLabel,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final updatedCompany =
      await _repo.updateCompanyName(companyId, newLabel);

      final updatedList = state.companies.map((c) {
        final same =
            (c.companyId != null && c.companyId == companyId) ||
                c.id == companyId;
        return same ? updatedCompany : c;
      }).toList();

      // Se a company editada é a selecionada, mantemos o selectedCompanyId.
      emit(
        state.copyWith(
          isLoading: false,
          companies: updatedList,
        ),
      );

      return updatedCompany;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  /// 🔥 DELETAR company
  Future<void> deleteCompany(String companyId) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      await _repo.deleteCompany(companyId);

      final updatedCompanies = state.companies.where((c) {
        final same =
            (c.companyId != null && c.companyId == companyId) ||
                c.id == companyId;
        return !same;
      }).toList();

      final isSelected = state.selectedCompanyId == companyId;

      emit(
        state.copyWith(
          isLoading: false,
          companies: updatedCompanies,
          selectedCompanyId: isSelected ? null : state.selectedCompanyId,
          // se apagou a empresa selecionada, limpa filhos também
          units: isSelected ? const [] : state.units,
          roads: isSelected ? const [] : state.roads,
          regions: isSelected ? const [] : state.regions,
          fundingSources: isSelected ? const [] : state.fundingSources,
          programs: isSelected ? const [] : state.programs,
          expenseNatures: isSelected ? const [] : state.expenseNatures,
          companyBodies: isSelected ? const [] : state.companyBodies,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  /// Helper: encontra o companyId pelo label (companyName/label).
  String? findCompanyIdByLabel(String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    for (final c in state.companies) {
      final name = (c.companyName ?? c.label).trim().toLowerCase();
      if (name == normalized) {
        // companies têm tanto id quanto companyId preenchidos
        return c.companyId ?? c.id;
      }
    }
    return null;
  }

  // =========================
  // SELECT COMPANY AND LOAD CHILDREN (pacotão)
  // =========================

  Future<void> selectCompany(String companyId) async {
    try {
      emit(
        state.copyWith(
          isLoading: true,
          clearError: true,
          selectedCompanyId: companyId,
        ),
      );

      final results = await Future.wait([
        _repo.loadCompanyBodies(companyId),
        _repo.loadUnits(companyId),
        _repo.loadRoads(companyId),
        _repo.loadRegions(companyId),
        _repo.loadFundingSources(companyId),
        _repo.loadPrograms(companyId),
        _repo.loadExpenseNatures(companyId),
      ]);

      emit(
        state.copyWith(
          isLoading: false,
          companyBodies: results[0],
          units: results[1],
          roads: results[2],
          regions: results[3],
          fundingSources: results[4],
          programs: results[5],
          expenseNatures: results[6],
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> reloadChildrenForSelectedCompany() async {
    final companyId = state.selectedCompanyId;
    if (companyId == null) return;
    await selectCompany(companyId);
  }

  // =========================
  // UNITS
  // =========================

  Future<SetupData?> createUnit(String companyId, String label) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final created = await _repo.createUnit(companyId, label);
      final updated = List<SetupData>.from(state.units)..add(created);

      emit(
        state.copyWith(
          isLoading: false,
          units: updated,
          selectedCompanyId: companyId,
        ),
      );

      return created;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  /// 🔥 EDITAR unidade
  Future<SetupData?> updateUnitName(
      String companyId,
      String unitId,
      String newLabel,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final updatedUnit =
      await _repo.updateUnitName(companyId, unitId, newLabel);

      final updatedList = state.units.map((u) {
        final same = (u.unitId != null && u.unitId == unitId) ||
            u.id == unitId;
        return same ? updatedUnit : u;
      }).toList();

      emit(
        state.copyWith(
          isLoading: false,
          units: updatedList,
          selectedCompanyId: companyId,
        ),
      );

      return updatedUnit;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  /// 🔥 DELETAR unidade
  Future<void> deleteUnit(
      String companyId,
      String unitId,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      await _repo.deleteUnit(companyId, unitId);

      final updatedList = state.units.where((u) {
        final same = (u.unitId != null && u.unitId == unitId) ||
            u.id == unitId;
        return !same;
      }).toList();

      emit(
        state.copyWith(
          isLoading: false,
          units: updatedList,
          selectedCompanyId: companyId,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  /// Carrega UNIDADES de uma empresa específica
  Future<void> loadUnitsForCompany(String companyId,
      {bool forceReload = false}) async {
    if (!forceReload &&
        state.selectedCompanyId == companyId &&
        state.units.isNotEmpty) {
      return;
    }

    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final units = await _repo.loadUnits(companyId);

      emit(
        state.copyWith(
          isLoading: false,
          units: units,
          selectedCompanyId: companyId,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  /// Getter usado nas telas: retorna units se forem da empresa atual
  List<SetupData> getUnitsForCompany(String? companyId) {
    if (companyId == null) return const [];
    if (companyId != state.selectedCompanyId) return const [];
    return state.units;
  }

  // =========================
  // ROADS
  // =========================

  Future<SetupData?> createRoad(String companyId, String label) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final created = await _repo.createRoad(companyId, label);
      final updated = List<SetupData>.from(state.roads)..add(created);

      emit(
        state.copyWith(
          isLoading: false,
          roads: updated,
          selectedCompanyId: companyId,
        ),
      );

      return created;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  /// 🔥 EDITAR rodovia
  Future<SetupData?> updateRoadName(
      String companyId,
      String roadId,
      String newLabel,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final updatedRoad =
      await _repo.updateRoadName(companyId, roadId, newLabel);

      final updatedList = state.roads.map((r) {
        final same = (r.roadId != null && r.roadId == roadId) ||
            r.id == roadId;
        return same ? updatedRoad : r;
      }).toList();

      emit(
        state.copyWith(
          isLoading: false,
          roads: updatedList,
          selectedCompanyId: companyId,
        ),
      );

      return updatedRoad;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  /// 🔥 DELETAR rodovia
  Future<void> deleteRoad(
      String companyId,
      String roadId,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      await _repo.deleteRoad(companyId, roadId);

      final updatedList = state.roads.where((r) {
        final same = (r.roadId != null && r.roadId == roadId) ||
            r.id == roadId;
        return !same;
      }).toList();

      emit(
        state.copyWith(
          isLoading: false,
          roads: updatedList,
          selectedCompanyId: companyId,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> loadRoadsForCompany(String companyId,
      {bool forceReload = false}) async {
    if (!forceReload &&
        state.selectedCompanyId == companyId &&
        state.roads.isNotEmpty) {
      return;
    }

    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final roads = await _repo.loadRoads(companyId);

      emit(
        state.copyWith(
          isLoading: false,
          roads: roads,
          selectedCompanyId: companyId,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  List<SetupData> getRoadsForCompany(String? companyId) {
    if (companyId == null) return const [];
    if (companyId != state.selectedCompanyId) return const [];
    return state.roads;
  }

  // =========================
  // REGIONS
  // =========================

  Future<SetupData?> createRegion(
      String companyId,
      String label, {
        List<String>? municipios,
      }) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final created =
      await _repo.createRegion(companyId, label, municipios: municipios);
      final updated = List<SetupData>.from(state.regions)..add(created);

      emit(
        state.copyWith(
          isLoading: false,
          regions: updated,
          selectedCompanyId: companyId,
        ),
      );

      return created;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  Future<SetupData?> updateRegionMunicipios(
      String companyId,
      String regionId,
      List<String> municipios,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final updatedRegion =
      await _repo.updateRegionMunicipios(companyId, regionId, municipios);

      final updatedList = state.regions
          .map((r) => r.regionId == regionId ? updatedRegion : r)
          .toList();

      emit(
        state.copyWith(
          isLoading: false,
          regions: updatedList,
          selectedCompanyId: companyId,
        ),
      );

      return updatedRegion;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  /// 🔥 EDITAR região (nome)
  Future<SetupData?> updateRegionName(
      String companyId,
      String regionId,
      String newLabel,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final updatedRegion =
      await _repo.updateRegionName(companyId, regionId, newLabel);

      final updatedList = state.regions
          .map((r) => r.regionId == regionId ? updatedRegion : r)
          .toList();

      emit(
        state.copyWith(
          isLoading: false,
          regions: updatedList,
          selectedCompanyId: companyId,
        ),
      );

      return updatedRegion;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  /// 🔥 DELETAR região
  Future<void> deleteRegion(
      String companyId,
      String regionId,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      await _repo.deleteRegion(companyId, regionId);

      final updatedList =
      state.regions.where((r) => r.regionId != regionId).toList();

      emit(
        state.copyWith(
          isLoading: false,
          regions: updatedList,
          selectedCompanyId: companyId,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> loadRegionsForCompany(String companyId,
      {bool forceReload = false}) async {
    if (!forceReload &&
        state.selectedCompanyId == companyId &&
        state.regions.isNotEmpty) {
      return;
    }

    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final regions = await _repo.loadRegions(companyId);

      emit(
        state.copyWith(
          isLoading: false,
          regions: regions,
          selectedCompanyId: companyId,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  List<SetupData> getRegionsForCompany(String? companyId) {
    if (companyId == null) return const [];
    if (companyId != state.selectedCompanyId) return const [];
    return state.regions;
  }

  // =========================
  // FUNDING SOURCES
  // =========================

  Future<SetupData?> createFundingSource(
      String companyId,
      String label,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final created = await _repo.createFundingSource(companyId, label);
      final updated = List<SetupData>.from(state.fundingSources)..add(created);

      emit(
        state.copyWith(
          isLoading: false,
          fundingSources: updated,
          selectedCompanyId: companyId,
        ),
      );

      return created;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  /// 🔥 EDITAR fonte de recurso
  Future<SetupData?> updateFundingSourceName(
      String companyId,
      String sourceId,
      String newLabel,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final updated =
      await _repo.updateFundingSourceName(companyId, sourceId, newLabel);

      final updatedList = state.fundingSources.map((f) {
        final same = (f.genericId != null && f.genericId == sourceId) ||
            f.id == sourceId;
        return same ? updated : f;
      }).toList();

      emit(
        state.copyWith(
          isLoading: false,
          fundingSources: updatedList,
          selectedCompanyId: companyId,
        ),
      );

      return updated;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  /// 🔥 DELETAR fonte de recurso
  Future<void> deleteFundingSource(
      String companyId,
      String sourceId,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      await _repo.deleteFundingSource(companyId, sourceId);

      final updatedList = state.fundingSources.where((f) {
        final same = (f.genericId != null && f.genericId == sourceId) ||
            f.id == sourceId;
        return !same;
      }).toList();

      emit(
        state.copyWith(
          isLoading: false,
          fundingSources: updatedList,
          selectedCompanyId: companyId,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> loadFundingSourcesForCompany(String companyId,
      {bool forceReload = false}) async {
    if (!forceReload &&
        state.selectedCompanyId == companyId &&
        state.fundingSources.isNotEmpty) {
      return;
    }

    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final list = await _repo.loadFundingSources(companyId);

      emit(
        state.copyWith(
          isLoading: false,
          fundingSources: list,
          selectedCompanyId: companyId,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  List<SetupData> getFundingSourcesForCompany(String? companyId) {
    if (companyId == null) return const [];
    if (companyId != state.selectedCompanyId) return const [];
    return state.fundingSources;
  }

  // =========================
  // PROGRAMS
  // =========================

  Future<SetupData?> createProgram(String companyId, String label) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final created = await _repo.createProgram(companyId, label);
      final updated = List<SetupData>.from(state.programs)..add(created);

      emit(
        state.copyWith(
          isLoading: false,
          programs: updated,
          selectedCompanyId: companyId,
        ),
      );

      return created;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  /// 🔥 EDITAR programa
  Future<SetupData?> updateProgramName(
      String companyId,
      String programId,
      String newLabel,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final updated =
      await _repo.updateProgramName(companyId, programId, newLabel);

      final updatedList = state.programs.map((p) {
        final same = (p.genericId != null && p.genericId == programId) ||
            p.id == programId;
        return same ? updated : p;
      }).toList();

      emit(
        state.copyWith(
          isLoading: false,
          programs: updatedList,
          selectedCompanyId: companyId,
        ),
      );

      return updated;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  /// 🔥 DELETAR programa
  Future<void> deleteProgram(
      String companyId,
      String programId,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      await _repo.deleteProgram(companyId, programId);

      final updatedList = state.programs.where((p) {
        final same = (p.genericId != null && p.genericId == programId) ||
            p.id == programId;
        return !same;
      }).toList();

      emit(
        state.copyWith(
          isLoading: false,
          programs: updatedList,
          selectedCompanyId: companyId,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> loadProgramsForCompany(String companyId,
      {bool forceReload = false}) async {
    if (!forceReload &&
        state.selectedCompanyId == companyId &&
        state.programs.isNotEmpty) {
      return;
    }

    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final list = await _repo.loadPrograms(companyId);

      emit(
        state.copyWith(
          isLoading: false,
          programs: list,
          selectedCompanyId: companyId,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  List<SetupData> getProgramsForCompany(String? companyId) {
    if (companyId == null) return const [];
    if (companyId != state.selectedCompanyId) return const [];
    return state.programs;
  }

  // =========================
  // EXPENSE NATURES
  // =========================

  Future<SetupData?> createExpenseNature(
      String companyId, String label) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final created = await _repo.createExpenseNature(companyId, label);
      final updated =
      List<SetupData>.from(state.expenseNatures)..add(created);

      emit(
        state.copyWith(
          isLoading: false,
          expenseNatures: updated,
          selectedCompanyId: companyId,
        ),
      );

      return created;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  /// 🔥 EDITAR natureza de despesa
  Future<SetupData?> updateExpenseNatureName(
      String companyId,
      String natureId,
      String newLabel,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final updated = await _repo.updateExpenseNatureName(
          companyId, natureId, newLabel);

      final updatedList = state.expenseNatures.map((n) {
        final same = (n.genericId != null && n.genericId == natureId) ||
            n.id == natureId;
        return same ? updated : n;
      }).toList();

      emit(
        state.copyWith(
          isLoading: false,
          expenseNatures: updatedList,
          selectedCompanyId: companyId,
        ),
      );

      return updated;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  /// 🔥 DELETAR natureza de despesa
  Future<void> deleteExpenseNature(
      String companyId,
      String natureId,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      await _repo.deleteExpenseNature(companyId, natureId);

      final updatedList = state.expenseNatures.where((n) {
        final same = (n.genericId != null && n.genericId == natureId) ||
            n.id == natureId;
        return !same;
      }).toList();

      emit(
        state.copyWith(
          isLoading: false,
          expenseNatures: updatedList,
          selectedCompanyId: companyId,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  /// Helper de compatibilidade:
  /// garante que TUDO da empresa esteja carregado (unidades, regiões, etc.)
  /// sem recarregar à toa se já estiver em memória.
  Future<void> ensureCompanySetupLoaded(String? companyId) async {
    final id = companyId?.trim();
    if (id == null || id.isEmpty) return;

    final alreadySelected = state.selectedCompanyId == id;

    final hasAllChildren = state.units.isNotEmpty &&
        state.roads.isNotEmpty &&
        state.regions.isNotEmpty &&
        state.fundingSources.isNotEmpty &&
        state.programs.isNotEmpty &&
        state.expenseNatures.isNotEmpty;

    if (alreadySelected && hasAllChildren) {
      // Já está tudo carregado para essa empresa
      return;
    }

    // Usa o "pacotão" que já criamos
    await selectCompany(id);
  }

  // =========================
  // COMPANY BODIES (empresas contratadas / licitantes)
  // =========================

  Future<SetupData?> createCompanyBody(
      String companyId,
      String label, {
        String? cnpj,
      }) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final created = await _repo.createCompanyBody(
        companyId,
        label,
        cnpj: cnpj,
      );
      final updated = List<SetupData>.from(state.companyBodies)..add(created);

      emit(
        state.copyWith(
          isLoading: false,
          companyBodies: updated,
          selectedCompanyId: companyId,
        ),
      );

      return created;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  /// 🔥 EDITAR empresa contratada / licitante
  Future<SetupData?> updateCompanyBodyName(
      String companyId,
      String bodyId,
      String newLabel,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final updated = await _repo.updateCompanyBodyName(
          companyId, bodyId, newLabel);

      final updatedList = state.companyBodies.map((b) {
        final same = (b.genericId != null && b.genericId == bodyId) ||
            b.id == bodyId;
        return same ? updated : b;
      }).toList();

      emit(
        state.copyWith(
          isLoading: false,
          companyBodies: updatedList,
          selectedCompanyId: companyId,
        ),
      );

      return updated;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  /// 🔥 DELETAR empresa contratada / licitante
  Future<void> deleteCompanyBody(
      String companyId,
      String bodyId,
      ) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      await _repo.deleteCompanyBody(companyId, bodyId);

      final updatedList = state.companyBodies.where((b) {
        final same = (b.genericId != null && b.genericId == bodyId) ||
            b.id == bodyId;
        return !same;
      }).toList();

      emit(
        state.copyWith(
          isLoading: false,
          companyBodies: updatedList,
          selectedCompanyId: companyId,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> loadCompanyBodiesForCompany(
      String companyId, {
        bool forceReload = false,
      }) async {
    if (!forceReload &&
        state.selectedCompanyId == companyId &&
        state.companyBodies.isNotEmpty) {
      return;
    }

    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final list = await _repo.loadCompanyBodies(companyId);

      emit(
        state.copyWith(
          isLoading: false,
          companyBodies: list,
          selectedCompanyId: companyId,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  List<SetupData> getCompanyBodiesForCompany(String? companyId) {
    if (companyId == null) return const [];
    if (companyId != state.selectedCompanyId) return const [];
    return state.companyBodies;
  }

  Future<void> loadExpenseNaturesForCompany(String companyId,
      {bool forceReload = false}) async {
    if (!forceReload &&
        state.selectedCompanyId == companyId &&
        state.expenseNatures.isNotEmpty) {
      return;
    }

    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final list = await _repo.loadExpenseNatures(companyId);

      emit(
        state.copyWith(
          isLoading: false,
          expenseNatures: list,//
          selectedCompanyId: companyId,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  List<SetupData> getExpenseNaturesForCompany(String? companyId) {
    if (companyId == null) return const [];
    if (companyId != state.selectedCompanyId) return const [];
    return state.expenseNatures;
  }
}
