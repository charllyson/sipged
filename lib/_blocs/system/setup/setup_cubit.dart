import 'package:flutter_bloc/flutter_bloc.dart';

import 'setup_data.dart';
import 'setup_repository.dart';
import 'setup_state.dart';

class SetupCubit extends Cubit<SetupState> {
  final SetupRepository _repo;

  SetupCubit({
    SetupRepository? repository,
    String? tenantId,
  })  : _repo = repository ?? SetupRepository(tenantId: tenantId),
        super(SetupState.initial());

  String get tenantId => _repo.tenantId;

  Future<void> loadSystemSetup() async {
    try {
      emit(
        state.copyWith(
          isLoading: true,
          clearError: true,
        ),
      );

      final data = await _repo.loadAll();

      emit(
        state.copyWith(
          isLoading: false,
          hasLoadedSystem: true,
          modules: data[SetupGroup.modules] ?? <SetupData>[],
          profiles: data[SetupGroup.profiles] ?? <SetupData>[],
          permissions: data[SetupGroup.permissions] ?? <SetupData>[],
          parameters: data[SetupGroup.parameters] ?? <SetupData>[],
          integrations: data[SetupGroup.integrations] ?? <SetupData>[],
          featureFlags: data[SetupGroup.featureFlags] ?? <SetupData>[],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          hasLoadedSystem: true,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> ensureSystemSetupLoaded() async {
    if (state.hasLoadedSystem) return;

    await loadSystemSetup();
  }

  Future<void> reloadGroup(SetupGroup group) async {
    try {
      emit(
        state.copyWith(
          isLoading: true,
          clearError: true,
        ),
      );

      final items = await _repo.loadGroup(group);

      emit(_stateWithGroup(group, items).copyWith(isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> reloadAll() {
    return loadSystemSetup();
  }

  Future<SetupData?> createItem({
    required SetupGroup group,
    required String key,
    required String label,
    String? description,
    String? type,
    dynamic value,
    bool enabled = true,
    int order = 0,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    try {
      emit(
        state.copyWith(
          isLoading: true,
          clearError: true,
        ),
      );

      final created = await _repo.createItem(
        group: group,
        key: key,
        label: label,
        description: description,
        type: type,
        value: value,
        enabled: enabled,
        order: order,
        metadata: metadata,
      );

      final current = List<SetupData>.from(state.itemsByGroup(group));
      current.removeWhere((item) => item.id == created.id);
      current.add(created);
      current.sort(_sortItems);

      emit(_stateWithGroup(group, current).copyWith(isLoading: false));

      return created;
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );

      return null;
    }
  }

  Future<SetupData?> updateItem({
    required SetupGroup group,
    required String id,
    String? key,
    String? label,
    String? description,
    String? type,
    dynamic value,
    bool? enabled,
    int? order,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      emit(
        state.copyWith(
          isLoading: true,
          clearError: true,
        ),
      );

      final updated = await _repo.updateItem(
        group: group,
        id: id,
        key: key,
        label: label,
        description: description,
        type: type,
        value: value,
        enabled: enabled,
        order: order,
        metadata: metadata,
      );

      final current = state.itemsByGroup(group).map((item) {
        return item.id == updated.id ? updated : item;
      }).toList();

      current.sort(_sortItems);

      emit(_stateWithGroup(group, current).copyWith(isLoading: false));

      return updated;
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );

      return null;
    }
  }

  Future<SetupData?> toggleItem({
    required SetupGroup group,
    required String id,
    required bool enabled,
  }) {
    return updateItem(
      group: group,
      id: id,
      enabled: enabled,
    );
  }

  Future<void> deleteItem({
    required SetupGroup group,
    required String id,
  }) async {
    try {
      emit(
        state.copyWith(
          isLoading: true,
          clearError: true,
        ),
      );

      await _repo.deleteItem(
        group: group,
        id: id,
      );

      final current = state
          .itemsByGroup(group)
          .where((item) => item.id != id)
          .toList();

      emit(_stateWithGroup(group, current).copyWith(isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  List<SetupData> getItems(SetupGroup group) {
    return state.itemsByGroup(group);
  }

  List<SetupData> getEnabledItems(SetupGroup group) {
    return state.itemsByGroup(group).where((item) => item.enabled).toList();
  }

  SetupData? findByKey({
    required SetupGroup group,
    required String key,
  }) {
    final cleanKey = key.trim();

    if (cleanKey.isEmpty) return null;

    for (final item in state.itemsByGroup(group)) {
      if (item.key == cleanKey) return item;
    }

    return null;
  }

  dynamic parameterValue(
      String key, {
        dynamic fallback,
      }) {
    final item = findByKey(
      group: SetupGroup.parameters,
      key: key,
    );

    return item?.value ?? fallback;
  }

  bool featureEnabled(
      String key, {
        bool fallback = false,
      }) {
    final item = findByKey(
      group: SetupGroup.featureFlags,
      key: key,
    );

    if (item == null) return fallback;

    if (!item.enabled) return false;

    final value = item.value;

    if (value is bool) return value;

    return true;
  }

  SetupState _stateWithGroup(
      SetupGroup group,
      List<SetupData> items,
      ) {
    switch (group) {
      case SetupGroup.modules:
        return state.copyWith(modules: items);

      case SetupGroup.profiles:
        return state.copyWith(profiles: items);

      case SetupGroup.permissions:
        return state.copyWith(permissions: items);

      case SetupGroup.parameters:
        return state.copyWith(parameters: items);

      case SetupGroup.integrations:
        return state.copyWith(integrations: items);

      case SetupGroup.featureFlags:
        return state.copyWith(featureFlags: items);
    }
  }

  int _sortItems(SetupData a, SetupData b) {
    final byOrder = a.order.compareTo(b.order);

    if (byOrder != 0) return byOrder;

    return a.label.toLowerCase().compareTo(b.label.toLowerCase());
  }

  void clearError() {
    if (state.error == null) return;

    emit(
      state.copyWith(
        clearError: true,
      ),
    );
  }
}