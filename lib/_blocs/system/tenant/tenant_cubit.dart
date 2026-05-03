// lib/_blocs/system/tenant/tenant_cubit.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'tenant_data.dart';
import 'tenant_repository.dart';
import 'tenant_state.dart';

class TenantCubit extends Cubit<TenantState> {
  final TenantRepository _repo;

  TenantCubit({
    TenantRepository? repository,
  })  : _repo = repository ?? TenantRepository(),
        super(TenantState.initial());

  String get tenantId => _repo.tenantId;

  String get companyDocId => _repo.companyDocId;

  TenantData? get tenantProfile => state.tenantProfile;

  TenantData? get companyProfile => state.tenantProfile;

  List<TenantItemData> getUnits() => state.units;

  List<TenantItemData> getRoads() => state.roads;

  List<TenantItemData> getRegions() => state.regions;

  List<TenantItemData> getFundingSources() => state.fundingSources;

  List<TenantItemData> getPrograms() => state.programs;

  List<TenantItemData> getExpenseNatures() => state.expenseNatures;

  List<TenantItemData> getCompanyBodies() => state.companyBodies;

  List<TenantItemData> getPartners() => state.companyBodies;

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
        'loadTenantProfile FirebaseException: ${e.code} - ${e.message}',
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
      debugPrint('loadTenantProfile error: $e');
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
        'loadTenantItems FirebaseException: ${e.code} - ${e.message}',
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
      debugPrint('loadTenantItems error: $e');
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
      );

      emit(
        state.copyWith(
          isLoading: false,
          hasLoadedTenant: true,
          tenantProfile: saved,
        ),
      );

      return saved;
    } on FirebaseException catch (e, s) {
      debugPrint(
        'saveTenantProfile FirebaseException: ${e.code} - ${e.message}',
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
      debugPrint('saveTenantProfile error: $e');
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

      emit(
        state.copyWith(
          isLoading: false,
          hasLoadedTenant: true,
          tenantProfile: updated,
        ),
      );

      return updated;
    } on FirebaseException catch (e, s) {
      debugPrint(
        'updateTenantName FirebaseException: ${e.code} - ${e.message}',
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
      debugPrint('updateTenantName error: $e');
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

      emit(
        state.copyWith(
          isLoading: false,
          hasLoadedTenant: true,
          tenantProfile: updated,
        ),
      );

      return updated;
    } on FirebaseException catch (e, s) {
      debugPrint(
        'updateTenantLogo FirebaseException: ${e.code} - ${e.message}',
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
      debugPrint('updateTenantLogo error: $e');
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
        'deleteTenantProfile FirebaseException: ${e.code} - ${e.message}',
      );
      debugPrintStack(stackTrace: s);

      emit(
        state.copyWith(
          isLoading: false,
          error: 'Firebase (${e.code}): ${e.message}',
        ),
      );
    } catch (e, s) {
      debugPrint('deleteTenantProfile error: $e');
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

  List<TenantItemData> _replaceOrAppend(
      List<TenantItemData> list,
      TenantItemData item,
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

  List<TenantItemData> _removeById(
      List<TenantItemData> list,
      String id,
      ) {
    return list.where((e) => e.id != id).toList();
  }

  Future<TenantItemData?> createUnit(String label) async {
    try {
      final created = await _repo.createUnit(label);

      emit(
        state.copyWith(
          units: _replaceOrAppend(state.units, created),
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

  Future<TenantItemData?> updateUnitName(String id, String label) async {
    try {
      final updated = await _repo.updateUnitName(id, label);

      emit(
        state.copyWith(
          units: _replaceOrAppend(state.units, updated),
          clearError: true,
        ),
      );

      return updated;
    } catch (e, s) {
      _handleItemError('updateUnitName', e, s);
      return null;
    }
  }

  Future<void> deleteUnit(String id) async {
    try {
      await _repo.deleteUnit(id);

      emit(
        state.copyWith(
          units: _removeById(state.units, id),
          clearError: true,
        ),
      );
    } catch (e, s) {
      _handleItemError('deleteUnit', e, s);
    }
  }

  Future<TenantItemData?> createRoad(String label) async {
    try {
      final created = await _repo.createRoad(label);

      emit(
        state.copyWith(
          roads: _replaceOrAppend(state.roads, created),
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

  Future<TenantItemData?> updateRoadName(String id, String label) async {
    try {
      final updated = await _repo.updateRoadName(id, label);

      emit(
        state.copyWith(
          roads: _replaceOrAppend(state.roads, updated),
          clearError: true,
        ),
      );

      return updated;
    } catch (e, s) {
      _handleItemError('updateRoadName', e, s);
      return null;
    }
  }

  Future<void> deleteRoad(String id) async {
    try {
      await _repo.deleteRoad(id);

      emit(
        state.copyWith(
          roads: _removeById(state.roads, id),
          clearError: true,
        ),
      );
    } catch (e, s) {
      _handleItemError('deleteRoad', e, s);
    }
  }

  Future<TenantItemData?> createRegion(
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
          regions: _replaceOrAppend(state.regions, created),
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

  Future<TenantItemData?> updateRegionName(String id, String label) async {
    try {
      final updated = await _repo.updateRegionName(id, label);

      emit(
        state.copyWith(
          regions: _replaceOrAppend(state.regions, updated),
          clearError: true,
        ),
      );

      return updated;
    } catch (e, s) {
      _handleItemError('updateRegionName', e, s);
      return null;
    }
  }

  Future<TenantItemData?> updateRegionMunicipios(
      String id,
      List<String> municipios,
      ) async {
    try {
      final updated = await _repo.updateRegionMunicipios(
        id,
        municipios,
      );

      emit(
        state.copyWith(
          regions: _replaceOrAppend(state.regions, updated),
          clearError: true,
        ),
      );

      return updated;
    } catch (e, s) {
      _handleItemError('updateRegionMunicipios', e, s);
      return null;
    }
  }

  Future<void> deleteRegion(String id) async {
    try {
      await _repo.deleteRegion(id);

      emit(
        state.copyWith(
          regions: _removeById(state.regions, id),
          clearError: true,
        ),
      );
    } catch (e, s) {
      _handleItemError('deleteRegion', e, s);
    }
  }

  Future<TenantItemData?> createFundingSource(String label) async {
    try {
      final created = await _repo.createFundingSource(label);

      emit(
        state.copyWith(
          fundingSources: _replaceOrAppend(state.fundingSources, created),
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

  Future<TenantItemData?> updateFundingSourceName(
      String id,
      String label,
      ) async {
    try {
      final updated = await _repo.updateFundingSourceName(id, label);

      emit(
        state.copyWith(
          fundingSources: _replaceOrAppend(state.fundingSources, updated),
          clearError: true,
        ),
      );

      return updated;
    } catch (e, s) {
      _handleItemError('updateFundingSourceName', e, s);
      return null;
    }
  }

  Future<void> deleteFundingSource(String id) async {
    try {
      await _repo.deleteFundingSource(id);

      emit(
        state.copyWith(
          fundingSources: _removeById(state.fundingSources, id),
          clearError: true,
        ),
      );
    } catch (e, s) {
      _handleItemError('deleteFundingSource', e, s);
    }
  }

  Future<TenantItemData?> createProgram(String label) async {
    try {
      final created = await _repo.createProgram(label);

      emit(
        state.copyWith(
          programs: _replaceOrAppend(state.programs, created),
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

  Future<TenantItemData?> updateProgramName(String id, String label) async {
    try {
      final updated = await _repo.updateProgramName(id, label);

      emit(
        state.copyWith(
          programs: _replaceOrAppend(state.programs, updated),
          clearError: true,
        ),
      );

      return updated;
    } catch (e, s) {
      _handleItemError('updateProgramName', e, s);
      return null;
    }
  }

  Future<void> deleteProgram(String id) async {
    try {
      await _repo.deleteProgram(id);

      emit(
        state.copyWith(
          programs: _removeById(state.programs, id),
          clearError: true,
        ),
      );
    } catch (e, s) {
      _handleItemError('deleteProgram', e, s);
    }
  }

  Future<TenantItemData?> createExpenseNature(String label) async {
    try {
      final created = await _repo.createExpenseNature(label);

      emit(
        state.copyWith(
          expenseNatures: _replaceOrAppend(state.expenseNatures, created),
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

  Future<TenantItemData?> updateExpenseNatureName(
      String id,
      String label,
      ) async {
    try {
      final updated = await _repo.updateExpenseNatureName(id, label);

      emit(
        state.copyWith(
          expenseNatures: _replaceOrAppend(state.expenseNatures, updated),
          clearError: true,
        ),
      );

      return updated;
    } catch (e, s) {
      _handleItemError('updateExpenseNatureName', e, s);
      return null;
    }
  }

  Future<void> deleteExpenseNature(String id) async {
    try {
      await _repo.deleteExpenseNature(id);

      emit(
        state.copyWith(
          expenseNatures: _removeById(state.expenseNatures, id),
          clearError: true,
        ),
      );
    } catch (e, s) {
      _handleItemError('deleteExpenseNature', e, s);
    }
  }

  Future<TenantItemData?> createCompanyBody(
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
          companyBodies: _replaceOrAppend(state.companyBodies, created),
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

  Future<TenantItemData?> createPartner(
      String label, {
        String? cnpj,
      }) {
    return createCompanyBody(
      label,
      cnpj: cnpj,
    );
  }

  Future<TenantItemData?> updateCompanyBodyName(
      String id,
      String label,
      ) async {
    try {
      final updated = await _repo.updateCompanyBodyName(id, label);

      emit(
        state.copyWith(
          companyBodies: _replaceOrAppend(state.companyBodies, updated),
          clearError: true,
        ),
      );

      return updated;
    } catch (e, s) {
      _handleItemError('updateCompanyBodyName', e, s);
      return null;
    }
  }

  Future<TenantItemData?> updatePartnerName(
      String id,
      String label,
      ) {
    return updateCompanyBodyName(id, label);
  }

  Future<TenantItemData?> updateCompanyBodyData(
      String id, {
        String? label,
        String? cnpj,
      }) async {
    try {
      final updated = await _repo.updateCompanyBodyData(
        id,
        label: label,
        cnpj: cnpj,
      );

      emit(
        state.copyWith(
          companyBodies: _replaceOrAppend(state.companyBodies, updated),
          clearError: true,
        ),
      );

      return updated;
    } catch (e, s) {
      _handleItemError('updateCompanyBodyData', e, s);
      return null;
    }
  }

  Future<TenantItemData?> updatePartnerData(
      String id, {
        String? label,
        String? cnpj,
      }) {
    return updateCompanyBodyData(
      id,
      label: label,
      cnpj: cnpj,
    );
  }

  Future<void> deleteCompanyBody(String id) async {
    try {
      await _repo.deleteCompanyBody(id);

      emit(
        state.copyWith(
          companyBodies: _removeById(state.companyBodies, id),
          clearError: true,
        ),
      );
    } catch (e, s) {
      _handleItemError('deleteCompanyBody', e, s);
    }
  }

  Future<void> deletePartner(String id) {
    return deleteCompanyBody(id);
  }

  void _handleItemError(
      String method,
      Object e,
      StackTrace s,
      ) {
    if (e is FirebaseException) {
      debugPrint('$method FirebaseException: ${e.code} - ${e.message}');
      debugPrintStack(stackTrace: s);

      emit(
        state.copyWith(
          error: 'Firebase (${e.code}): ${e.message}',
        ),
      );

      return;
    }

    debugPrint('$method error: $e');
    debugPrintStack(stackTrace: s);

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