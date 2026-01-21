import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';
import 'package:siged/_blocs/modules/contracts/hiring/1Dfd/dfd_state.dart';
import 'package:siged/_blocs/modules/contracts/hiring/_shared/sections_types.dart';

class DfdCubit extends Cubit<DfdState> {
  final DfdRepository repo;

  DfdCubit({DfdRepository? repository})
      : repo = repository ?? DfdRepository(),
        super(DfdState.initial());

  Future<DfdData?> getDataForContract(String contractId) {
    return repo.readDataForContract(contractId);
  }

  Future<void> load(String contractId) async {
    emit(
      state.copyWith(
        loading: true,
        error: null,
        saveSuccess: false,
        contractId: contractId,
      ),
    );

    try {
      final ids = await repo.ensureStructure(contractId);

      final data = await repo.loadAllSections(
        contractId: contractId,
        dfdId: ids.dfdId,
        sectionIds: ids.sectionIds,
      );

      emit(
        state.copyWith(
          loading: false,
          dfdId: ids.dfdId,
          sectionIds: ids.sectionIds,
          sectionsData: data,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          loading: false,
          saveSuccess: false,
          error: err.toString(),
        ),
      );
    }
  }

  Future<void> saveAll({
    required String contractId,
    required SectionsMap sectionsData,
  }) async {
    final ids = await repo.ensureStructure(contractId);

    emit(
      state.copyWith(
        saving: true,
        saveSuccess: false,
        error: null,
        contractId: contractId,
        dfdId: ids.dfdId,
        sectionIds: ids.sectionIds,
      ),
    );

    try {
      await repo.saveSectionsBatch(
        contractId: contractId,
        dfdId: ids.dfdId,
        sectionIds: ids.sectionIds,
        sectionsData: sectionsData,
      );

      final merged = {...state.sectionsData};
      sectionsData.forEach((key, value) {
        merged[key] = {
          ...(merged[key] ?? const <String, dynamic>{}),
          ...value,
        };
      });

      emit(
        state.copyWith(
          saving: false,
          saveSuccess: true,
          sectionsData: merged,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: err.toString(),
        ),
      );
    }
  }

  Future<String?> saveAllWithAutoContract({
    String? contractId,
    required DfdData data,
  }) async {
    emit(
      state.copyWith(
        saving: true,
        saveSuccess: false,
        error: null,
      ),
    );

    try {
      final finalContractId = await repo.ensureContractAndSaveDfd(
        contractId: contractId ?? state.contractId,
        data: data,
      );

      final ids = await repo.ensureStructure(finalContractId);

      emit(
        state.copyWith(
          saving: false,
          saveSuccess: true,
          contractId: finalContractId,
          dfdId: ids.dfdId,
          sectionIds: ids.sectionIds,
          sectionsData: data.toSectionsMap(),
        ),
      );

      return finalContractId;
    } catch (err) {
      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: err.toString(),
        ),
      );
      return null;
    }
  }

  Future<void> saveOneSection({
    required String contractId,
    required String sectionKey,
    required Map<String, dynamic> data,
  }) async {
    final ids = await repo.ensureStructure(contractId);
    final sectionId = ids.sectionIds[sectionKey];

    if (sectionId == null) {
      emit(state.copyWith(error: 'Seção inválida: $sectionKey'));
      return;
    }

    emit(
      state.copyWith(
        saving: true,
        saveSuccess: false,
        error: null,
        contractId: contractId,
        dfdId: ids.dfdId,
        sectionIds: ids.sectionIds,
      ),
    );

    try {
      await repo.saveSection(
        contractId: contractId,
        dfdId: ids.dfdId,
        sectionKey: sectionKey,
        sectionDocId: sectionId,
        data: data,
      );

      final merged = {...state.sectionsData};
      merged[sectionKey] = {
        ...(merged[sectionKey] ?? const <String, dynamic>{}),
        ...data,
      };

      emit(
        state.copyWith(
          saving: false,
          saveSuccess: true,
          sectionsData: merged,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: err.toString(),
        ),
      );
    }
  }

  void clearSuccessFlag() {
    if (state.saveSuccess) {
      emit(state.copyWith(saveSuccess: false));
    }
  }
}
