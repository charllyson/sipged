// ==============================
// lib/_blocs/documents/contracts/apostilles/apostilles_controller.dart
// ==============================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

import 'package:siged/_blocs/documents/contracts/apostilles/apostilles_store.dart';
import 'package:siged/_blocs/documents/contracts/apostilles/apostilles_data.dart';
import 'package:siged/_blocs/documents/contracts/apostilles/apostilles_storage_bloc.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';

import 'package:siged/_utils/date_utils.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/handle_selection_utils.dart';

class ApostillesController extends ChangeNotifier with FormValidationMixin {
  // Injetados
  final ApostillesStore store;
  final ContractData contract;
  final ApostillesStorageBloc apostillesStorageBloc;

  // User (via UserBloc)
  StreamSubscription<UserState>? _userSub;
  UserData? _currentUser;

  // Estado
  late Future<List<ApostillesData>> futureApostilles;
  List<ApostillesData> _lastSnapshot = [];
  ApostillesData? selectedApostille;

  bool isSaving = false;
  bool editingMode = false;
  bool formValidated = false;
  bool isEditable = false;

  String? currentApostilleId;
  int? selectedLine;

  // Controllers
  final orderCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final processCtrl = TextEditingController();

  // ====== SideListBox (arquivos) ======
  /// Nomes dos arquivos exibidos
  final List<String> fileNames = [];
  /// URLs/paths reais dos arquivos (mesmo índice de fileNames)
  final List<String> fileUrls = [];
  /// Índice selecionado (para destaque visual)
  int? selectedFileIndex;

  ApostillesController({
    required this.store,
    required this.contract,
    ApostillesStorageBloc? storageBloc,
  }) : apostillesStorageBloc = storageBloc ?? ApostillesStorageBloc() {
    _init();
  }

  // INIT
  void _init() {
    futureApostilles = _getAll();
    _setNextOrder();
    setupValidation([dateCtrl, valueCtrl, processCtrl], _validateForm);
  }

  /// Pós-frame: depende de BuildContext
  Future<void> postFrameInit(BuildContext context) async {
    final userBloc = context.read<UserBloc>();
    _currentUser = userBloc.state.current;
    isEditable = _canEditUser(_currentUser);
    notifyListeners();

    _userSub?.cancel();
    _userSub = userBloc.stream.listen((st) {
      final newEditable = _canEditUser(st.current);
      if (newEditable != isEditable) {
        isEditable = newEditable;
        _currentUser = st.current;
        notifyListeners();
      }
    });
  }

  bool _canEditUser(UserData? user) {
    if (user == null) return false;
    final base = (user.baseProfile ?? '').toLowerCase();
    if (base == 'administrador' || base == 'colaborador') return true;

    final perms = user.modulePermissions['apostilles'];
    if (perms != null) {
      return (perms['edit'] == true) || (perms['create'] == true);
    }
    return false;
  }

  // LOADS
  Future<List<ApostillesData>> _getAll() async {
    if (contract.id == null) return [];
    await store.ensureFor(contract.id!);
    return store.listFor(contract.id!);
  }

  Future<void> reload() async {
    if (contract.id == null) return;
    await store.refreshFor(contract.id!);
    futureApostilles = Future.value(store.listFor(contract.id!));
    notifyListeners();
  }

  // VALIDATION
  void _validateForm() {
    final valid = dateCtrl.text.isNotEmpty &&
        valueCtrl.text.isNotEmpty &&
        processCtrl.text.isNotEmpty;

    if (formValidated != valid) {
      formValidated = valid;
      notifyListeners();
    }
  }

  // FILL / CLEAR
  Future<void> _setNextOrder() async {
    if (contract.id == null) return;
    await store.ensureFor(contract.id!);
    final list = store.listFor(contract.id!);
    final last = list.map((e) => e.apostilleOrder ?? 0).fold(0, (a, b) => a > b ? a : b);
    orderCtrl.text = (last + 1).toString();
    notifyListeners();
  }

  void fillFields(ApostillesData data) {
    selectedApostille = data;
    editingMode = true;
    currentApostilleId = data.id;

    orderCtrl.text = (data.apostilleOrder ?? '').toString();
    dateCtrl.text = data.apostilleData != null
        ? dateTimeToDDMMYYYY(data.apostilleData!)
        : '';
    valueCtrl.text = priceToString(data.apostilleValue);
    processCtrl.text = data.apostilleNumberProcess ?? '';

    _validateForm();

    // 🆕 Carrega arquivos vinculados à apostila atual
    _loadFilesForCurrentApostille();

    notifyListeners();
  }

  void createNew() {
    editingMode = false;
    currentApostilleId = null;
    selectedApostille = null;

    dateCtrl.clear();
    valueCtrl.clear();
    processCtrl.clear();

    // limpa lista de arquivos
    fileNames.clear();
    fileUrls.clear();
    selectedFileIndex = null;

    _setNextOrder();
    _validateForm();
    notifyListeners();
  }

  // SAVE / UPDATE
  Future<void> saveOrUpdate(BuildContext context) async {
    if (contract.id == null) return;

    isSaving = true;
    notifyListeners();

    try {
      final novo = ApostillesData(
        id: currentApostilleId,
        apostilleOrder: int.tryParse(orderCtrl.text),
        apostilleData: convertDDMMYYYYToDateTime(dateCtrl.text),
        apostilleValue: stringToDouble(valueCtrl.text),
        apostilleNumberProcess: processCtrl.text,
      );

      await store.saveOrUpdate(contract.id!, novo);
      futureApostilles = Future.value(store.listFor(contract.id!));
      createNew();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              editingMode
                  ? 'Apostilamento atualizado com sucesso!'
                  : 'Apostilamento salvo com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // DELETE
  Future<void> deleteApostille(BuildContext context, String id) async {
    if (contract.id == null) return;
    await store.delete(contract.id!, id);
    await reload();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apostilamento removido com sucesso!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // TABLE / GRAPH selection
  void applySnapshot(List<ApostillesData> list) => _lastSnapshot = list;

  void onSelectGraphIndex(int index) {
    selectedLine = index;
    if (index >= 0 && index < _lastSnapshot.length) {
      handleApostilleSelection(_lastSnapshot[index]);
    } else {
      notifyListeners();
    }
  }

  void handleApostilleSelection(ApostillesData data) {
    handleGenericSelection<ApostillesData>(
      data: data,
      list: _lastSnapshot,
      getOrder: (e) => e.apostilleOrder,
      onSetState: (index) {
        selectedApostille = data;
        currentApostilleId = data.id;
        editingMode = true;
        selectedLine = index;
        fillFields(data);
      },
    );
  }

  // ====== Upload/listagem de arquivos (SideListBox) ======

  /// Carrega a lista de arquivos da apostila selecionada.
  /// 1) tenta URL do Storage (oficial)
  /// 2) fallback para metadado legado `pdfUrl` salvo no Firestore
  Future<void> _loadFilesForCurrentApostille() async {
    fileNames.clear();
    fileUrls.clear();
    selectedFileIndex = null;

    final c = contract;
    final a = selectedApostille;
    if (c.id == null || a?.id == null) {
      notifyListeners();
      return;
    }

    try {
      // 1) Storage (caminho padrão)
      final storageUrl = await apostillesStorageBloc.getPdfUrlDaApostila(
        contract: c,
        apostille: a!,
      );

      if (storageUrl != null && storageUrl.isNotEmpty) {
        fileNames.add(apostillesStorageBloc.fileName(c, a));
        fileUrls.add(storageUrl);
      } else if ((a.pdfUrl ?? '').isNotEmpty) {
        // 2) metadado legado
        fileNames.add('Documento do apostilamento');
        fileUrls.add(a.pdfUrl!);
      }
    } catch (_) {
      // mantém silencioso; apenas não lista nada
    }

    notifyListeners();
  }

  /// Abre o seletor, faz upload via StorageBloc, salva URL e adiciona na lista da UI.
  Future<void> addFile(BuildContext context) async {
    final c = contract;
    final a = selectedApostille;
    if (c.id == null || a?.id == null) return;

    try {
      String? lastProgressMsg;

      final url = await apostillesStorageBloc.uploadWithPicker(
        contract: c,
        apostille: a!,
        onProgress: (p) {
          final msg = 'Enviando arquivo ${(p * 100).toStringAsFixed(0)}%';
          if (msg != lastProgressMsg && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), duration: const Duration(milliseconds: 700)),
            );
            lastProgressMsg = msg;
          }
        },
      );

      if (url.isNotEmpty) {
        await apostillesStorageBloc.salvarUrlPdfDaApostila(
          contractId: c.id!,
          apostilleId: a.id!,
          url: url,
        );

        fileNames.add(apostillesStorageBloc.fileName(c, a));
        fileUrls.add(url);
        selectedFileIndex = fileNames.length - 1;
        notifyListeners();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Arquivo adicionado!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao adicionar arquivo: $e')),
        );
      }
    }
  }

  /// Abre o arquivo selecionado (URL externa). Se preferir, substitua pelo seu viewer interno.
  Future<void> openFileAt(int i, BuildContext context) async {
    if (i < 0 || i >= fileUrls.length) return;
    selectedFileIndex = i;
    notifyListeners();

    final url = fileUrls[i];
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // alternativa: chamar seu viewer interno
      // Navigator.of(context).push(...);
    }
  }

  /// Remove item da UI. (Se quiser remover do Storage, implemente no StorageBloc.)
  Future<void> removeFileAt(int i, BuildContext context) async {
    if (i < 0 || i >= fileUrls.length) return;

    try {
      // TODO(opcional): se quiser remover também no storage, crie método por URL/path
      // await apostillesStorageBloc.deletarArquivoDaApostilaPorUrl(fileUrls[i]);

      fileNames.removeAt(i);
      fileUrls.removeAt(i);

      if (selectedFileIndex != null) {
        if (fileNames.isEmpty) {
          selectedFileIndex = null;
        } else if (selectedFileIndex! >= fileNames.length) {
          selectedFileIndex = fileNames.length - 1;
        }
      }
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arquivo removido.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    removeValidation([dateCtrl, valueCtrl, processCtrl], _validateForm);
    orderCtrl.dispose();
    dateCtrl.dispose();
    valueCtrl.dispose();
    processCtrl.dispose();
    super.dispose();
  }
}
