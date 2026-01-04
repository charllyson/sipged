import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';

import 'publicacao_extrato_data.dart';
import 'publicacao_extrato_repository.dart';
import 'publicacao_extrato_state.dart';

class PublicacaoExtratoCubit extends Cubit<PublicacaoExtratoState> {
  final PublicacaoExtratoRepository repo;

  /// Construtor agora aceita repo opcional:
  /// - `PublicacaoExtratoCubit()` -> cria PublicacaoExtratoRepository() internamente
  /// - `PublicacaoExtratoCubit(meuRepo)` -> usa o repo passado
  PublicacaoExtratoCubit([PublicacaoExtratoRepository? repository])
      : repo = repository ?? PublicacaoExtratoRepository(),
        super(PublicacaoExtratoState.initial());

  // ===========================================================
  // HELPER PÚBLICO: obter PublicacaoExtratoData pelo contractId
  // ===========================================================
  ///
  /// Uso:
  ///   final pub = await context
  ///       .read<PublicacaoExtratoCubit>()
  ///       .getDataForContract(contractId);
  ///
  Future<PublicacaoExtratoData?> getDataForContract(String contractId) {
    return repo.readDataForContract(contractId);
  }

  // ===========================================================
  // LOAD
  // ===========================================================
  Future<void> load(String contractId) async {
    emit(
      state.copyWith(
        loading: true,
        error: null,
        saveSuccess: false,
      ),
    );

    try {
      // estrutura fixa: pubId = "main", sectionIds = {sec: "main"}
      final ids = await repo.ensureStructure(contractId);

      final data = await repo.loadAllSections(
        contractId: contractId,
        pubId: ids.pubId,
        sectionIds: ids.sectionIds,
      );

      emit(
        state.copyWith(
          loading: false,
          pubId: ids.pubId,
          sectionIds: ids.sectionIds,
          sectionsData: data,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          loading: false,
          error: err.toString(),
        ),
      );
    }
  }

  // ===========================================================
  // SAVE ALL SECTIONS
  // ===========================================================
  Future<void> saveAll({
    required String contractId,
    required SectionsMap sectionsData,
  }) async {
    if (!state.hasValidPath) return;

    emit(
      state.copyWith(
        saving: true,
        saveSuccess: false,
        error: null,
      ),
    );

    try {
      await repo.saveSectionsBatch(
        contractId: contractId,
        pubId: state.pubId!,
        sectionIds: state.sectionIds,
        sectionsData: sectionsData,
      );

      // Faz merge no estado local
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

  // ===========================================================
  // SAVE ONE SECTION
  // ===========================================================
  Future<void> saveOneSection({
    required String contractId,
    required String sectionKey,
    required Map<String, dynamic> data,
  }) async {
    if (!state.hasValidPath) return;

    final sectionId = state.sectionIds[sectionKey];
    if (sectionId == null) {
      emit(state.copyWith(error: 'Seção inválida: $sectionKey'));
      return;
    }

    emit(
      state.copyWith(
        saving: true,
        saveSuccess: false,
        error: null,
      ),
    );

    try {
      await repo.saveSection(
        contractId: contractId,
        pubId: state.pubId!,
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

  // ===========================================================
  // CLEAR SUCCESS FLAG
  // ===========================================================
  void clearSuccessFlag() {
    if (state.saveSuccess) {
      emit(state.copyWith(saveSuccess: false));
    }
  }
}
