import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sisged/_datas/documents/contracts/contracts/contract_rules.dart';
import '../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../../_datas/system/user_data.dart';
import '../../../../_widgets/formats/format_field.dart';

class ContractsBloc extends BlocBase {
  late ContractData? contractsData;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final _createdController = BehaviorSubject<bool>();
  final _loadingController = BehaviorSubject<bool>();

  Stream<bool> get outLoading => _loadingController.stream;
  Stream<bool> get outCreated => _createdController.stream;

  final BehaviorSubject<String> _searchSubject = BehaviorSubject<String>.seeded('');
  Stream<String> get searchStream => _searchSubject.stream;
  Function(String) get setSearch => _searchSubject.sink.add;
  String get currentSearch => _searchSubject.value;
  void clearSearch() => _searchSubject.add('');

  List<ContractData>? _cachedContracts;

  ContractsBloc();

  String getNomePadronizadoPdfContrato(ContractData contract) {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final contractProcess = contract.contractNumberProcess ?? 'processo';
    return '$contractNumber-$contractProcess.pdf';
  }

  Future<bool> verificarSePdfExiste(ContractData contract) async {
    try {
      final fileName = getNomePadronizadoPdfContrato(contract);
      final ref = FirebaseStorage.instance
          .ref('contracts/${contract.id}/mainInformation/$fileName');
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> salvarUrlPdfDoContrato(String contractId, String url) async {
    try {
      await _db.collection('contracts').doc(contractId).update({
        'urlContractPdf': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    } catch (e) {
      debugPrint('Erro ao salvar URL do PDF do contrato no Firestore: $e');
    }
  }

  Future<void> sendContractPdfWeb({
    required ContractData? contract,
    required void Function(double) onProgress,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) {
        throw Exception('Nenhum arquivo PDF selecionado ou arquivo vazio.');
      }

      final fileBytes = result.files.single.bytes!;
      final fileName = getNomePadronizadoPdfContrato(contract!);
      final path = 'contracts/${contract.id}/mainInformation/$fileName';

      final ref = FirebaseStorage.instance.ref(path);
      final uploadTask = ref.putData(fileBytes, SettableMetadata(contentType: 'application/pdf'));

      uploadTask.snapshotEvents.listen((event) {
        onProgress(event.bytesTransferred / event.totalBytes);
      });

      await uploadTask;
      final url = await ref.getDownloadURL();

      await salvarUrlPdfDoContrato(contract.id!, url);
    } catch (e) {
      debugPrint('Erro ao enviar PDF do contrato: $e');
      rethrow;
    }
  }

  Future<String?> getFirstContractPdfUrl(ContractData? contract) async {
    try {
      final fileName = getNomePadronizadoPdfContrato(contract!);
      final ref = FirebaseStorage.instance.ref(
        'contracts/${contract.id}/mainInformation/$fileName',
      );
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Erro ao obter URL do PDF do contrato: $e');
      return null;
    }
  }

  Future<void> deleteContract(String contractId) async {
    await _db.collection('contracts').doc(contractId).delete();
  }

  Future<List<ContractData>> getAllContracts({
    String? statusFilter,
    String? searchQuery,
  }) async {
    if (_cachedContracts != null) return _cachedContracts!;

    Query query = _db.collection('contracts');
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('contractstatus', isEqualTo: statusFilter);
    }

    final snapshot = await query.limit(500).get();
    final contracts = snapshot.docs.map((e) => ContractData.fromDocument(snapshot: e)).toList();
    _cachedContracts = contracts;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final queryNormalized = normalize(searchQuery);
      return contracts.where((c) {
        final title = normalize(c.summarySubjectContract ?? '');
        return title.contains(queryNormalized);
      }).toList();
    }

    return contracts;
  }

  Future<ContractData> getSpecificContract({required String uidContract}) async {
    final snapshot = await _db.collection('contracts').doc(uidContract).get();
    return ContractData.fromDocument(snapshot: snapshot);
  }

  Future<ContractData> salvarOuAtualizarContrato(ContractData contrato) async {
    if (contrato.id != null) {
      await _db.collection('contracts').doc(contrato.id).update(contrato.toMap()
        ..addAll({
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        }));
    } else {
      final docRef = await _db.collection('contracts').add(contrato.toMap()
        ..addAll({
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        }));
      contrato.id = docRef.id;
    }
    return contrato;
  }

  Future<void> updateContractPermissions({
    required String contractId,
    required String userId,
    required String permissionType,
    required bool value,
  }) async {
    try {
      _loadingController.add(true);
      await _db.collection('contracts').doc(contractId).update({
        'permissionContractId.$userId.$permissionType': value,
      });
    } catch (e) {
      debugPrint('Erro ao atualizar permissões do usuário para contrato: $e');
    } finally {
      _loadingController.add(false);
    }
  }

  Future<ContractData?> getContractById(String id) async {
    try {
      final doc = await _db.collection('contracts').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        return ContractData.fromJson(data)..id = doc.id;
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao buscar contrato por ID: $e');
      return null;
    }
  }

  Future<bool> deleteContractPdf(ContractData? contract) async {
    try {
      final fileName = getNomePadronizadoPdfContrato(contract!);
      final path = 'contracts/${contract.id}/mainInformation/$fileName';

      await FirebaseStorage.instance.ref(path).delete();
      await _db.collection('contracts').doc(contract.id).update({
        'urlContractPdf': FieldValue.delete(),
      });
      return true;
    } catch (e) {
      debugPrint('Erro ao deletar PDF do contrato: $e');
      return false;
    }
  }

  Future<void> saveContractPermissions(ContractData contractData) async {
    if (contractData.id == null) return;
    try {
      _loadingController.add(true);
      await _db.collection('contracts').doc(contractData.id).update({
        'permissionContractId': contractData.permissionContractId,
      });
    } catch (e) {
      print('Erro ao salvar permissões: $e');
    } finally {
      _loadingController.add(false);
    }
  }

  Future<List<ContractData>> getFilteredContracts({
    required UserData currentUser,
    String? statusFilter,
    String? searchQuery,
  }) async {
    final uid = currentUser.id!;
    final perfil = currentUser.baseProfile?.toLowerCase();

    final todos = await getAllContracts(statusFilter: statusFilter, searchQuery: searchQuery);

    if (perfil == 'administrador' || perfil == 'colaborador') {
      return todos;
    }

    final contratosPermitidos = todos.where((contract) {
      final permMap = contract.permissionContractId;
      if (!permMap.containsKey(uid)) return false;

      final perms = permMap[uid];
      if (perms == null) return false;

      if (perfil == 'colaborador') {
        return perms['edit'] == true || perms['read'] == true || perms['delete'] == true;
      }
      if (perfil == 'leitor') {
        return perms['read'] == true;
      }
      return false;
    }).toList();

    return contratosPermitidos;
  }

  Future<Map<String, double>> getValoresTotaisPorStatus(List<ContractData> contratos) {
    final Map<String, double> totais = {
      for (final tipo in ContractRules.statusTypes) tipo.toUpperCase(): 0.0,
    };
    for (final c in contratos) {
      final status = c.contractStatus?.toUpperCase();
      if (status != null && totais.containsKey(status)) {
        totais[status] = (totais[status]! + (c.initialValueContract ?? 0));
      }
    }
    return Future.value(totais);
  }

  Future<Map<String, double>> getValoresPorRegiao(List<ContractData> contratos) {
    final Map<String, double> valores = {for (var r in ContractRules.regions) r: 0.0};
    for (final c in contratos) {
      final regiaoStr = c.regionOfState?.toUpperCase() ?? '';
      final valor = c.initialValueContract ?? 0;
      for (var r in ContractRules.regions) {
        if (regiaoStr.contains(r)) {
          valores[r] = (valores[r]! + valor);
        }
      }
    }
    return Future.value(valores);
  }

  Future<Map<String, double>> getValoresPorEmpresa({
    required List<ContractData> contratos,
    String? selectedRegion,
    required List<String> empresas,
  }) {
    final Map<String, double> mapa = {for (var e in empresas) e: 0.0};

    for (final c in contratos) {
      final empresa = (c.companyLeader ?? 'NÃO INFORMADO').trim().toUpperCase();
      final pertenceRegiao = selectedRegion == null ||
          (c.regionOfState?.toUpperCase().contains(selectedRegion.toUpperCase()) ?? false);

      if (pertenceRegiao && mapa.containsKey(empresa)) {
        mapa[empresa] = (mapa[empresa]! + (c.initialValueContract ?? 0));
      }
    }
    return Future.value(mapa);
  }

  Future<double> getValorPorStatus(List<ContractData> contratos, String statusDesejado) async {
    double total = 0.0;
    for (final contrato in contratos) {
      final status = contrato.contractStatus?.toUpperCase();
      if (status == statusDesejado.toUpperCase()) {
        total += contrato.initialValueContract ?? 0.0;
      }
    }
    return total;
  }

  @override
  void dispose() {
    super.dispose();
    _searchSubject.close();
    _loadingController.close();
    _createdController.close();
  }
}
