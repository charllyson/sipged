// lib/_blocs/system/tenant/tenant_cubit.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'tenant_data.dart';
import 'tenant_repository.dart';
import 'tenant_state.dart';

class TenantCubit extends Cubit<TenantState> {
  TenantCubit({
    TenantRepository? repository,
  })  : _repo = repository ?? TenantRepository(),
        super(TenantState.initial());

  final TenantRepository _repo;

  String get tenantId => _repo.tenantId;

  String get companyDocId => _repo.companyDocId;

  String? get selectedTenantId => state.selectedTenantId;

  List<TenantData> get availableTenants => state.availableTenants;

  TenantData? get tenantProfile => state.tenantProfile;

  TenantData? get companyProfile => state.tenantProfile;

  List<String> getUnits() => state.units;

  List<String> getRoads() => state.roads;

  List<String> getRegions() => state.regions;

  List<String> getFundingSources() => state.fundingSources;

  List<String> getPrograms() => state.programs;

  List<String> getExpenseNatures() => state.expenseNatures;

  List<String> getCompanyBodies() => state.companyBodies;

  List<String> getPartners() => state.companyBodies;

  Future<void> loadAvailableTenants({
    bool autoSelectWhenSingle = true,
    bool keepCurrentSelection = true,
    bool usePreferredTenant = true,
  }) async {
    try {
      emit(
        state.copyWith(
          isLoading: true,
          clearError: true,
        ),
      );

      final tenants = await _repo.loadAvailableTenants();

      final currentSelectedId = state.selectedTenantId?.trim();

      final preferredTenantId = usePreferredTenant
          ? await _repo.loadPreferredTenantIdForCurrentUser()
          : null;

      String? selectedId;

      if (keepCurrentSelection &&
          currentSelectedId != null &&
          currentSelectedId.isNotEmpty &&
          tenants.any((tenant) => tenant.id == currentSelectedId)) {
        selectedId = currentSelectedId;
      } else if (preferredTenantId != null &&
          preferredTenantId.isNotEmpty &&
          tenants.any((tenant) => tenant.id == preferredTenantId)) {
        selectedId = preferredTenantId;
      } else if (autoSelectWhenSingle && tenants.length == 1) {
        selectedId = tenants.first.id;
      }

      if (selectedId != null && selectedId.isNotEmpty) {
        _repo.setActiveTenantId(selectedId);
      } else {
        _repo.clearActiveTenantId();
      }

      emit(
        state.copyWith(
          isLoading: false,
          hasLoadedAvailableTenants: true,
          selectedTenantId: selectedId,
          availableTenants: tenants,
          clearTenantProfile: selectedId == null,
          hasLoadedTenant: selectedId == null ? false : state.hasLoadedTenant,
          hasLoadedTenantItems:
          selectedId == null ? false : state.hasLoadedTenantItems,
          units: selectedId == null ? const <String>[] : state.units,
          roads: selectedId == null ? const <String>[] : state.roads,
          regions: selectedId == null ? const <String>[] : state.regions,
          fundingSources:
          selectedId == null ? const <String>[] : state.fundingSources,
          programs: selectedId == null ? const <String>[] : state.programs,
          expenseNatures:
          selectedId == null ? const <String>[] : state.expenseNatures,
          companyBodies:
          selectedId == null ? const <String>[] : state.companyBodies,
          clearError: true,
        ),
      );

      if (selectedId != null && selectedId.isNotEmpty) {
        await selectTenant(
          selectedId,
          persistSelection: false,
        );
      }
    } on FirebaseException catch (e, s) {
      debugPrint(
        'TenantCubit.loadAvailableTenants FirebaseException: '
            '${e.code} - ${e.message}',
      );
      debugPrintStack(stackTrace: s);

      emit(
        state.copyWith(
          isLoading: false,
          hasLoadedAvailableTenants: true,
          error: 'Firebase (${e.code}): ${e.message}',
        ),
      );
    } catch (e, s) {
      debugPrint('TenantCubit.loadAvailableTenants error: $e');
      debugPrintStack(stackTrace: s);

      emit(
        state.copyWith(
          isLoading: false,
          hasLoadedAvailableTenants: true,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> ensureAvailableTenantsLoaded({
    bool autoSelectWhenSingle = true,
    bool usePreferredTenant = true,
  }) async {
    if (state.hasLoadedAvailableTenants) return;

    await loadAvailableTenants(
      autoSelectWhenSingle: autoSelectWhenSingle,
      usePreferredTenant: usePreferredTenant,
    );
  }

  Future<void> selectTenant(
      String tenantId, {
        bool persistSelection = true,
      }) async {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) return;

    final isTenantAvailable = state.availableTenants.isEmpty ||
        state.availableTenants.any((tenant) => tenant.id == cleanTenantId);

    if (!isTenantAvailable) {
      emit(
        state.copyWith(
          error: 'Usuário sem permissão para acessar esta empresa.',
        ),
      );

      return;
    }

    try {
      emit(
        state.copyWith(
          isLoading: true,
          clearError: true,
        ),
      );

      _repo.setActiveTenantId(cleanTenantId);

      if (persistSelection) {
        await _repo.persistActiveTenantForCurrentUser(cleanTenantId);
      }

      emit(
        state.copyWith(
          selectedTenantId: cleanTenantId,
          hasLoadedTenant: false,
          hasLoadedTenantItems: false,
          clearTenantProfile: true,
          units: const <String>[],
          roads: const <String>[],
          regions: const <String>[],
          fundingSources: const <String>[],
          programs: const <String>[],
          expenseNatures: const <String>[],
          companyBodies: const <String>[],
          clearError: true,
        ),
      );

      await loadTenantProfile();
      await loadTenantItems();

      emit(
        state.copyWith(
          isLoading: false,
          clearError: true,
        ),
      );
    } on FirebaseException catch (e, s) {
      debugPrint(
        'TenantCubit.selectTenant FirebaseException: ${e.code} - ${e.message}',
      );
      debugPrintStack(stackTrace: s);

      emit(
        state.copyWith(
          isLoading: false,
          error: 'Firebase (${e.code}): ${e.message}',
        ),
      );
    } catch (e, s) {
      debugPrint('TenantCubit.selectTenant error: $e');
      debugPrintStack(stackTrace: s);

      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> selectTenantByLabel(String label) async {
    final cleanLabel = label.trim().toLowerCase();

    if (cleanLabel.isEmpty) return;

    TenantData? selected;

    for (final tenant in state.availableTenants) {
      final tenantLabel = tenant.label.trim().toLowerCase();
      final companyName = (tenant.companyName ?? '').trim().toLowerCase();
      final fantasyName = (tenant.fantasyName ?? '').trim().toLowerCase();

      if (tenantLabel == cleanLabel ||
          companyName == cleanLabel ||
          fantasyName == cleanLabel) {
        selected = tenant;
        break;
      }
    }

    if (selected == null) return;

    await selectTenant(selected.id);
  }

  Future<void> clearSelectedTenant({
    bool clearPersistedSelection = false,
  }) async {
    try {
      emit(
        state.copyWith(
          isLoading: true,
          clearSelectedTenantId: true,
          clearTenantProfile: true,
          hasLoadedTenant: false,
          hasLoadedTenantItems: false,
          units: const <String>[],
          roads: const <String>[],
          regions: const <String>[],
          fundingSources: const <String>[],
          programs: const <String>[],
          expenseNatures: const <String>[],
          companyBodies: const <String>[],
          clearError: true,
        ),
      );

      _repo.clearActiveTenantId();

      emit(
        state.copyWith(
          isLoading: false,
          clearSelectedTenantId: true,
          clearTenantProfile: true,
          hasLoadedTenant: false,
          hasLoadedTenantItems: false,
          units: const <String>[],
          roads: const <String>[],
          regions: const <String>[],
          fundingSources: const <String>[],
          programs: const <String>[],
          expenseNatures: const <String>[],
          companyBodies: const <String>[],
          clearError: true,
        ),
      );
    } on FirebaseException catch (e, s) {
      debugPrint(
        'TenantCubit.clearSelectedTenant FirebaseException: '
            '${e.code} - ${e.message}',
      );
      debugPrintStack(stackTrace: s);

      emit(
        state.copyWith(
          isLoading: false,
          error: 'Firebase (${e.code}): ${e.message}',
        ),
      );
    } catch (e, s) {
      debugPrint('TenantCubit.clearSelectedTenant error: $e');
      debugPrintStack(stackTrace: s);

      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> prepareTenantSwitch({
    bool clearPersistedSelection = true,
    bool reloadAvailableTenants = true,
  }) async {
    await clearSelectedTenant(
      clearPersistedSelection: clearPersistedSelection,
    );

    if (!reloadAvailableTenants) return;

    await loadAvailableTenants(
      autoSelectWhenSingle: false,
      keepCurrentSelection: false,
      usePreferredTenant: false,
    );
  }

  Future<void> loadTenantProfile() async {
    try {
      emit(
        state.copyWith(
          isLoading: true,
          clearError: true,
        ),
      );

      final profile = await _repo.loadTenantProfile();

      emit(
        state.copyWith(
          isLoading: false,
          hasLoadedTenant: true,
          tenantProfile: profile,
        ),
      );
    } on FirebaseException catch (e, s) {
      debugPrint(
        'TenantCubit.loadTenantProfile FirebaseException: '
            '${e.code} - ${e.message}',
      );
      debugPrintStack(stackTrace: s);

      emit(
        state.copyWith(
          isLoading: false,
          hasLoadedTenant: true,
          error: 'Firebase (${e.code}): ${e.message}',
        ),
      );
    } catch (e, s) {
      debugPrint('TenantCubit.loadTenantProfile error: $e');
      debugPrintStack(stackTrace: s);

      emit(
        state.copyWith(
          isLoading: false,
          hasLoadedTenant: true,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> loadCompanyProfile() {
    return loadTenantProfile();
  }

  Future<void> ensureTenantProfileLoaded() async {
    if (state.hasLoadedTenant) return;

    await loadTenantProfile();
  }

  Future<void> ensureCompanyProfileLoaded() {
    return ensureTenantProfileLoaded();
  }

  Future<void> ensureTenantItemsLoaded() async {
    if (state.hasLoadedTenantItems) return;

    await loadTenantItems();
  }

  Future<void> loadTenantItems() async {
    try {
      emit(
        state.copyWith(
          isLoading: true,
          clearError: true,
        ),
      );

      final result = await _repo.loadTenantItems();

      emit(
        state.copyWith(
          isLoading: false,
          hasLoadedTenantItems: true,
          units: result.units,
          roads: result.roads,
          regions: result.regions,
          fundingSources: result.fundingSources,
          programs: result.programs,
          expenseNatures: result.expenseNatures,
          companyBodies: result.companyBodies,
        ),
      );
    } on FirebaseException catch (e, s) {
      debugPrint(
        'TenantCubit.loadTenantItems FirebaseException: '
            '${e.code} - ${e.message}',
      );
      debugPrintStack(stackTrace: s);

      emit(
        state.copyWith(
          isLoading: false,
          hasLoadedTenantItems: true,
          error: 'Firebase (${e.code}): ${e.message}',
        ),
      );
    } catch (e, s) {
      debugPrint('TenantCubit.loadTenantItems error: $e');
      debugPrintStack(stackTrace: s);

      emit(
        state.copyWith(
          isLoading: false,
          hasLoadedTenantItems: true,
          error: e.toString(),
        ),
      );
    }
  }

  Future<TenantData?> saveTenantProfile({
    required String label,
    required String fantasyName,
    String? cnpj,
    Uint8List? logoBytes,
    String? logoFileName,
    String? logoContentType,
    bool removeLogo = false,
    String? oldLogoPath,
    List<String>? units,
    List<String>? roads,
    List<String>? regions,
    List<String>? fundingSources,
    List<String>? programs,
    List<String>? expenseNatures,
    List<String>? companyBodies,
  }) async {
    try {
      emit(
        state.copyWith(
          isLoading: true,
          clearError: true,
        ),
      );

      final saved = await _repo.saveTenantProfile(
        label: label,
        fantasyName: fantasyName,
        cnpj: cnpj,
        logoBytes: logoBytes,
        logoFileName: logoFileName,
        logoContentType: logoContentType,
        removeLogo: removeLogo,
        oldLogoPath: oldLogoPath,
        units: units ?? state.units,
        roads: roads ?? state.roads,
        regions: regions ?? state.regions,
        fundingSources: fundingSources ?? state.fundingSources,
        programs: programs ?? state.programs,
        expenseNatures: expenseNatures ?? state.expenseNatures,
        companyBodies: companyBodies ?? state.companyBodies,
      );

      final availableTenants = _replaceOrAppendTenant(
        state.availableTenants,
        saved,
      );

      _repo.setActiveTenantId(saved.id);

      await _repo.persistActiveTenantForCurrentUser(saved.id);

      emit(
        state.copyWith(
          isLoading: false,
          hasLoadedTenant: true,
          hasLoadedTenantItems: true,
          tenantProfile: saved,
          selectedTenantId: saved.id,
          availableTenants: availableTenants,
          units: saved.units,
          roads: saved.roads,
          regions: saved.regions,
          fundingSources: saved.fundingSources,
          programs: saved.programs,
          expenseNatures: saved.expenseNatures,
          companyBodies: saved.companyBodies,
        ),
      );

      return saved;
    } on FirebaseException catch (e, s) {
      debugPrint(
        'TenantCubit.saveTenantProfile FirebaseException: '
            '${e.code} - ${e.message}',
      );
      debugPrintStack(stackTrace: s);

      emit(
        state.copyWith(
          isLoading: false,
          error: 'Firebase (${e.code}): ${e.message}',
        ),
      );

      return null;
    } catch (e, s) {
      debugPrint('TenantCubit.saveTenantProfile error: $e');
      debugPrintStack(stackTrace: s);

      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );

      return null;
    }
  }

  Future<TenantData?> saveCompanyProfile({
    required String label,
    required String fantasyName,
    String? cnpj,
    Uint8List? logoBytes,
    String? logoFileName,
    String? logoContentType,
    bool removeLogo = false,
    String? oldLogoPath,
    List<String>? units,
    List<String>? roads,
    List<String>? regions,
    List<String>? fundingSources,
    List<String>? programs,
    List<String>? expenseNatures,
    List<String>? companyBodies,
  }) {
    return saveTenantProfile(
      label: label,
      fantasyName: fantasyName,
      cnpj: cnpj,
      logoBytes: logoBytes,
      logoFileName: logoFileName,
      logoContentType: logoContentType,
      removeLogo: removeLogo,
      oldLogoPath: oldLogoPath,
      units: units,
      roads: roads,
      regions: regions,
      fundingSources: fundingSources,
      programs: programs,
      expenseNatures: expenseNatures,
      companyBodies: companyBodies,
    );
  }

  Future<TenantData?> updateTenantName(
      String newLabel, {
        String? fantasyName,
      }) async {
    try {
      emit(
        state.copyWith(
          isLoading: true,
          clearError: true,
        ),
      );

      final updated = await _repo.updateTenantName(
        newLabel,
        fantasyName: fantasyName,
      );

      final availableTenants = _replaceOrAppendTenant(
        state.availableTenants,
        updated,
      );

      emit(
        state.copyWith(
          isLoading: false,
          hasLoadedTenant: true,
          tenantProfile: updated,
          availableTenants: availableTenants,
        ),
      );

      return updated;
    } on FirebaseException catch (e, s) {
      debugPrint(
        'TenantCubit.updateTenantName FirebaseException: '
            '${e.code} - ${e.message}',
      );
      debugPrintStack(stackTrace: s);

      emit(
        state.copyWith(
          isLoading: false,
          error: 'Firebase (${e.code}): ${e.message}',
        ),
      );

      return null;
    } catch (e, s) {
      debugPrint('TenantCubit.updateTenantName error: $e');
      debugPrintStack(stackTrace: s);

      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );

      return null;
    }
  }

  Future<TenantData?> updateCompanyName(
      String newLabel, {
        String? fantasyName,
      }) {
    return updateTenantName(
      newLabel,
      fantasyName: fantasyName,
    );
  }

  Future<TenantData?> updateTenantLogo({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    try {
      emit(
        state.copyWith(
          isLoading: true,
          clearError: true,
        ),
      );

      final updated = await _repo.updateTenantLogo(
        bytes: bytes,
        fileName: fileName,
        contentType: contentType,
        oldLogoPath: state.tenantProfile?.logoPath,
      );

      final availableTenants = _replaceOrAppendTenant(
        state.availableTenants,
        updated,
      );

      emit(
        state.copyWith(
          isLoading: false,
          hasLoadedTenant: true,
          tenantProfile: updated,
          availableTenants: availableTenants,
        ),
      );

      return updated;
    } on FirebaseException catch (e, s) {
      debugPrint(
        'TenantCubit.updateTenantLogo FirebaseException: '
            '${e.code} - ${e.message}',
      );
      debugPrintStack(stackTrace: s);

      emit(
        state.copyWith(
          isLoading: false,
          error: 'Firebase (${e.code}): ${e.message}',
        ),
      );

      return null;
    } catch (e, s) {
      debugPrint('TenantCubit.updateTenantLogo error: $e');
      debugPrintStack(stackTrace: s);

      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );

      return null;
    }
  }

  Future<TenantData?> updateCompanyLogo({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) {
    return updateTenantLogo(
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }

  Future<void> deleteTenantProfile() async {
    try {
      emit(
        state.copyWith(
          isLoading: true,
          clearError: true,
        ),
      );

      await _repo.deleteTenantProfile();

      emit(
        state.copyWith(
          isLoading: false,
          hasLoadedTenant: true,
          clearTenantProfile: true,
        ),
      );
    } on FirebaseException catch (e, s) {
      debugPrint(
        'TenantCubit.deleteTenantProfile FirebaseException: '
            '${e.code} - ${e.message}',
      );
      debugPrintStack(stackTrace: s);

      emit(
        state.copyWith(
          isLoading: false,
          error: 'Firebase (${e.code}): ${e.message}',
        ),
      );
    } catch (e, s) {
      debugPrint('TenantCubit.deleteTenantProfile error: $e');
      debugPrintStack(stackTrace: s);

      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> deleteCompanyProfile() {
    return deleteTenantProfile();
  }

  String? findCompanyIdByLabel(String label) {
    final normalized = label.trim().toLowerCase();

    if (normalized.isEmpty) return null;

    final profile = state.tenantProfile;

    if (profile == null) return null;

    final name = (profile.companyName ?? profile.label).trim().toLowerCase();

    if (name == normalized) {
      return companyDocId;
    }

    return null;
  }

  List<TenantData> _replaceOrAppendTenant(
      List<TenantData> list,
      TenantData item,
      ) {
    final index = list.indexWhere((e) => e.id == item.id);

    if (index < 0) {
      final updated = [...list, item];

      updated.sort(
            (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
      );

      return updated;
    }

    final updated = [...list];
    updated[index] = item;

    updated.sort(
          (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );

    return updated;
  }

  List<String> _replaceOrAppendString(
      List<String> list,
      String value,
      ) {
    final clean = value.trim();

    if (clean.isEmpty) return list;

    final updated = [...list];

    final index = updated.indexWhere(
          (e) => e.trim().toLowerCase() == clean.toLowerCase(),
    );

    if (index < 0) {
      updated.add(clean);
    } else {
      updated[index] = clean;
    }

    updated.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return updated;
  }

  List<String> _replaceStringItem(
      List<String> list, {
        required String oldValue,
        required String newValue,
      }) {
    final oldClean = oldValue.trim();
    final newClean = newValue.trim();

    if (oldClean.isEmpty || newClean.isEmpty) return list;

    final updated = [...list];

    final index = updated.indexWhere(
          (e) => e.trim().toLowerCase() == oldClean.toLowerCase(),
    );

    if (index < 0) {
      updated.add(newClean);
    } else {
      updated[index] = newClean;
    }

    updated.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return updated;
  }

  List<String> _removeStringItem(
      List<String> list,
      String value,
      ) {
    final clean = value.trim().toLowerCase();

    if (clean.isEmpty) return list;

    final updated = list
        .where((e) => e.trim().toLowerCase() != clean)
        .toSet()
        .toList();

    updated.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return updated;
  }

  Future<String?> createUnit(String label) async {
    try {
      final created = await _repo.createUnit(label);

      emit(
        state.copyWith(
          units: _replaceOrAppendString(state.units, created),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );

      return created;
    } catch (e, s) {
      _handleItemError('createUnit', e, s);
      return null;
    }
  }

  Future<String?> updateUnitName(String oldLabel, String newLabel) async {
    try {
      final updated = await _repo.updateUnitName(oldLabel, newLabel);

      emit(
        state.copyWith(
          units: _replaceStringItem(
            state.units,
            oldValue: oldLabel,
            newValue: updated,
          ),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );

      return updated;
    } catch (e, s) {
      _handleItemError('updateUnitName', e, s);
      return null;
    }
  }

  Future<void> deleteUnit(String label) async {
    try {
      await _repo.deleteUnit(label);

      emit(
        state.copyWith(
          units: _removeStringItem(state.units, label),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );
    } catch (e, s) {
      _handleItemError('deleteUnit', e, s);
    }
  }

  Future<String?> createRoad(String label) async {
    try {
      final created = await _repo.createRoad(label);

      emit(
        state.copyWith(
          roads: _replaceOrAppendString(state.roads, created),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );

      return created;
    } catch (e, s) {
      _handleItemError('createRoad', e, s);
      return null;
    }
  }

  Future<String?> updateRoadName(String oldLabel, String newLabel) async {
    try {
      final updated = await _repo.updateRoadName(oldLabel, newLabel);

      emit(
        state.copyWith(
          roads: _replaceStringItem(
            state.roads,
            oldValue: oldLabel,
            newValue: updated,
          ),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );

      return updated;
    } catch (e, s) {
      _handleItemError('updateRoadName', e, s);
      return null;
    }
  }

  Future<void> deleteRoad(String label) async {
    try {
      await _repo.deleteRoad(label);

      emit(
        state.copyWith(
          roads: _removeStringItem(state.roads, label),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );
    } catch (e, s) {
      _handleItemError('deleteRoad', e, s);
    }
  }

  Future<String?> createRegion(
      String label, {
        List<String> municipios = const <String>[],
      }) async {
    try {
      final created = await _repo.createRegion(
        label,
        municipios: municipios,
      );

      emit(
        state.copyWith(
          regions: _replaceOrAppendString(state.regions, created),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );

      return created;
    } catch (e, s) {
      _handleItemError('createRegion', e, s);
      return null;
    }
  }

  Future<String?> updateRegionName(String oldLabel, String newLabel) async {
    try {
      final updated = await _repo.updateRegionName(oldLabel, newLabel);

      emit(
        state.copyWith(
          regions: _replaceStringItem(
            state.regions,
            oldValue: oldLabel,
            newValue: updated,
          ),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );

      return updated;
    } catch (e, s) {
      _handleItemError('updateRegionName', e, s);
      return null;
    }
  }

  Future<String?> updateRegionMunicipios(
      String label,
      List<String> municipios,
      ) async {
    try {
      final updated = await _repo.updateRegionMunicipios(
        label,
        municipios,
      );

      return updated;
    } catch (e, s) {
      _handleItemError('updateRegionMunicipios', e, s);
      return null;
    }
  }

  Future<void> deleteRegion(String label) async {
    try {
      await _repo.deleteRegion(label);

      emit(
        state.copyWith(
          regions: _removeStringItem(state.regions, label),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );
    } catch (e, s) {
      _handleItemError('deleteRegion', e, s);
    }
  }

  Future<String?> createFundingSource(String label) async {
    try {
      final created = await _repo.createFundingSource(label);

      emit(
        state.copyWith(
          fundingSources: _replaceOrAppendString(
            state.fundingSources,
            created,
          ),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );

      return created;
    } catch (e, s) {
      _handleItemError('createFundingSource', e, s);
      return null;
    }
  }

  Future<String?> updateFundingSourceName(
      String oldLabel,
      String newLabel,
      ) async {
    try {
      final updated = await _repo.updateFundingSourceName(
        oldLabel,
        newLabel,
      );

      emit(
        state.copyWith(
          fundingSources: _replaceStringItem(
            state.fundingSources,
            oldValue: oldLabel,
            newValue: updated,
          ),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );

      return updated;
    } catch (e, s) {
      _handleItemError('updateFundingSourceName', e, s);
      return null;
    }
  }

  Future<void> deleteFundingSource(String label) async {
    try {
      await _repo.deleteFundingSource(label);

      emit(
        state.copyWith(
          fundingSources: _removeStringItem(state.fundingSources, label),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );
    } catch (e, s) {
      _handleItemError('deleteFundingSource', e, s);
    }
  }

  Future<String?> createProgram(String label) async {
    try {
      final created = await _repo.createProgram(label);

      emit(
        state.copyWith(
          programs: _replaceOrAppendString(state.programs, created),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );

      return created;
    } catch (e, s) {
      _handleItemError('createProgram', e, s);
      return null;
    }
  }

  Future<String?> updateProgramName(
      String oldLabel,
      String newLabel,
      ) async {
    try {
      final updated = await _repo.updateProgramName(oldLabel, newLabel);

      emit(
        state.copyWith(
          programs: _replaceStringItem(
            state.programs,
            oldValue: oldLabel,
            newValue: updated,
          ),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );

      return updated;
    } catch (e, s) {
      _handleItemError('updateProgramName', e, s);
      return null;
    }
  }

  Future<void> deleteProgram(String label) async {
    try {
      await _repo.deleteProgram(label);

      emit(
        state.copyWith(
          programs: _removeStringItem(state.programs, label),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );
    } catch (e, s) {
      _handleItemError('deleteProgram', e, s);
    }
  }

  Future<String?> createExpenseNature(String label) async {
    try {
      final created = await _repo.createExpenseNature(label);

      emit(
        state.copyWith(
          expenseNatures: _replaceOrAppendString(
            state.expenseNatures,
            created,
          ),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );

      return created;
    } catch (e, s) {
      _handleItemError('createExpenseNature', e, s);
      return null;
    }
  }

  Future<String?> updateExpenseNatureName(
      String oldLabel,
      String newLabel,
      ) async {
    try {
      final updated = await _repo.updateExpenseNatureName(
        oldLabel,
        newLabel,
      );

      emit(
        state.copyWith(
          expenseNatures: _replaceStringItem(
            state.expenseNatures,
            oldValue: oldLabel,
            newValue: updated,
          ),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );

      return updated;
    } catch (e, s) {
      _handleItemError('updateExpenseNatureName', e, s);
      return null;
    }
  }

  Future<void> deleteExpenseNature(String label) async {
    try {
      await _repo.deleteExpenseNature(label);

      emit(
        state.copyWith(
          expenseNatures: _removeStringItem(state.expenseNatures, label),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );
    } catch (e, s) {
      _handleItemError('deleteExpenseNature', e, s);
    }
  }

  Future<String?> createCompanyBody(
      String label, {
        String? cnpj,
      }) async {
    try {
      final created = await _repo.createCompanyBody(
        label,
        cnpj: cnpj,
      );

      emit(
        state.copyWith(
          companyBodies: _replaceOrAppendString(
            state.companyBodies,
            created,
          ),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );

      return created;
    } catch (e, s) {
      _handleItemError('createCompanyBody', e, s);
      return null;
    }
  }

  Future<String?> createPartner(
      String label, {
        String? cnpj,
      }) {
    return createCompanyBody(
      label,
      cnpj: cnpj,
    );
  }

  Future<String?> updateCompanyBodyName(
      String oldLabel,
      String newLabel,
      ) async {
    try {
      final updated = await _repo.updateCompanyBodyName(
        oldLabel,
        newLabel,
      );

      emit(
        state.copyWith(
          companyBodies: _replaceStringItem(
            state.companyBodies,
            oldValue: oldLabel,
            newValue: updated,
          ),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );

      return updated;
    } catch (e, s) {
      _handleItemError('updateCompanyBodyName', e, s);
      return null;
    }
  }

  Future<String?> updatePartnerName(
      String oldLabel,
      String newLabel,
      ) {
    return updateCompanyBodyName(
      oldLabel,
      newLabel,
    );
  }

  Future<String?> updateCompanyBodyData(
      String oldLabel, {
        String? label,
        String? cnpj,
      }) async {
    try {
      final updated = await _repo.updateCompanyBodyData(
        oldLabel,
        label: label,
        cnpj: cnpj,
      );

      final newLabel = label?.trim();

      if (newLabel != null && newLabel.isNotEmpty) {
        emit(
          state.copyWith(
            companyBodies: _replaceStringItem(
              state.companyBodies,
              oldValue: oldLabel,
              newValue: updated,
            ),
            hasLoadedTenantItems: true,
            clearError: true,
          ),
        );
      }

      return updated;
    } catch (e, s) {
      _handleItemError('updateCompanyBodyData', e, s);
      return null;
    }
  }

  Future<String?> updatePartnerData(
      String oldLabel, {
        String? label,
        String? cnpj,
      }) {
    return updateCompanyBodyData(
      oldLabel,
      label: label,
      cnpj: cnpj,
    );
  }

  Future<void> deleteCompanyBody(String label) async {
    try {
      await _repo.deleteCompanyBody(label);

      emit(
        state.copyWith(
          companyBodies: _removeStringItem(state.companyBodies, label),
          hasLoadedTenantItems: true,
          clearError: true,
        ),
      );
    } catch (e, s) {
      _handleItemError('deleteCompanyBody', e, s);
    }
  }

  Future<void> deletePartner(String label) {
    return deleteCompanyBody(label);
  }

  void _handleItemError(
      String method,
      Object e,
      StackTrace s,
      ) {
    debugPrint('TenantCubit.$method error: $e');
    debugPrintStack(stackTrace: s);

    if (e is FirebaseException) {
      emit(
        state.copyWith(
          error: 'Firebase (${e.code}): ${e.message}',
        ),
      );

      return;
    }

    emit(
      state.copyWith(
        error: e.toString(),
      ),
    );
  }

  void clearError() {
    if (state.error == null) return;

    emit(
      state.copyWith(
        clearError: true,
      ),
    );
  }

  void clearTenantProfile() {
    emit(
      state.copyWith(
        clearTenantProfile: true,
      ),
    );
  }
}