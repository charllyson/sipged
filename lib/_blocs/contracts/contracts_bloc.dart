import 'dart:io';

import 'package:flutter/foundation.dart';
import 'dart:ui' as html;

import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sisgeo/_datas/additive/additive_data.dart';
import 'package:sisgeo/_datas/apostilles/apostilles_data.dart';
import 'package:sisgeo/_datas/measurement/measurement_data.dart';
import 'package:sisgeo/_datas/validity/validity_data.dart';
import '../../_datas/contracts/contracts_data.dart';
import '../../_datas/user/user_data.dart';

class ContractsBloc extends BlocBase {
  late ContractData? contractsData;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final _createdController = BehaviorSubject<bool>();
  final _loadingController = BehaviorSubject<bool>();

  Stream<bool> get outLoading => _loadingController.stream;
  Stream<bool> get outCreated => _createdController.stream;

  ContractsBloc();

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]', caseSensitive: false), 'a')
        .replaceAll(RegExp(r'[éèêë]', caseSensitive: false), 'e')
        .replaceAll(RegExp(r'[íìîï]', caseSensitive: false), 'i')
        .replaceAll(RegExp(r'[óòôõö]', caseSensitive: false), 'o')
        .replaceAll(RegExp(r'[úùûü]', caseSensitive: false), 'u')
        .replaceAll(RegExp(r'[ç]', caseSensitive: false), 'c');
  }
  ///---------------------------INÍCIO DOS PDF-------------------------------///

  String getNomePadronizadoPdfContrato(ContractData contract) {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final contractProcess = contract.contractNumberProcess ?? 'processo';
    return '$contractNumber-$contractProcess.pdf';
  }

  Future<bool> verificarSePdfExiste(ContractData contract) async {
    try {
      final fileName = getNomePadronizadoPdfContrato(contract);

      final ref = FirebaseStorage.instance
          .ref('contracts/${contract.id}/contract/$fileName');

      await ref.getMetadata(); // lança erro se não existir
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> salvarUrlPdfDoContrato(String contractId, String url) async {
    try {
      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .update({'urlContractPdf': url});
    } catch (e) {
      print('Erro ao salvar URL do PDF do contrato no Firestore: $e');
    }
  }

  ///
  Future<bool> deletarPdf(ContractData? contract) async {
    try {
      final contractNumber = contract!.contractNumber ?? 'contrato';
      final contractProcess = contract.contractNumberProcess ?? 'processo';
      final fileName = '$contractNumber-$contractProcess.pdf';

      final path = 'contracts/${contract.id}/contract/$fileName';

      // 🗑️ Deleta do Firebase Storage
      await FirebaseStorage.instance.ref(path).delete();

      // 🔄 Remove a URL do Firestore
      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contract.id)
          .update({'urlContractPdf': FieldValue.delete()});

      return true;
    } catch (e) {
      print('Erro ao deletar PDF do contrato: $e');
      return false;
    }
  }


  Future<void> enviarPdfWeb({
    required ContractData? contract,
    required void Function(double) onProgress,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      print('DEBUG: contract.id = ${contract?.id}');
      print('DEBUG: contract.contractNumber = ${contract?.contractNumber}');
      print('DEBUG: contract.contractNumberProcess = ${contract?.contractNumberProcess}');

      if (result == null || result.files.single.bytes == null) {
        throw Exception('Nenhum arquivo PDF selecionado ou arquivo vazio.');
      }

      if (contract == null || contract.id == null || contract.contractNumber == null || contract.contractNumberProcess == null) {
        throw Exception('Dados do contrato incompletos. Verifique número e processo.');
      }

      final fileBytes = result.files.single.bytes!;
      final fileName = '${contract.contractNumber}-${contract.contractNumberProcess}.pdf';
      final path = 'contracts/${contract.id}/contract/$fileName';

      final ref = FirebaseStorage.instance.ref(path);
      final metadata = SettableMetadata(contentType: 'application/pdf');

      final uploadTask = ref.putData(fileBytes, metadata);

      uploadTask.snapshotEvents.listen((event) {
        final progress = event.bytesTransferred / event.totalBytes;
        onProgress(progress);
      });

      await uploadTask;

      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contract.id)
          .update({'urlContractPdf': url});
    } catch (e) {
      print('Erro ao enviar PDF do contrato: $e');
      rethrow;
    }
  }


  ///
  Future<String?> getFirstPdfUrl(ContractData? contract) async {
    try {
      if (contract?.id == null || contract!.id!.isEmpty) {
        throw Exception('ID do contrato está ausente.');
      }

      final fileName = getNomePadronizadoPdfContrato(contract);
      final ref = FirebaseStorage.instance.ref(
        'contracts/${contract.id}/contract/$fileName',
      );

      return await ref.getDownloadURL();
    } catch (e) {
      print('Erro ao obter URL do PDF do contrato: $e');
      return null;
    }
  }


  ///------------------------------ FIM DOS PDF -----------------------------///
  ///------------------------ INÍCO DOS ADITIVOS ----------------------------///

  Future<void> selecionarEPDFDeAditivoComProgresso({
    required String contractId,
    required AdditiveData additiveData,
    required void Function(double progress) onProgress,
    required void Function(bool success) onComplete,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final Uint8List fileBytes = result.files.single.bytes!;

        final contractSnap = await FirebaseFirestore.instance
            .collection('contracts')
            .doc(contractId)
            .get();

        final contractNumber = contractSnap.data()?['contractnumber'] ?? 'contrato';
        final fileName = '$contractNumber-${additiveData.additiveOrder}-${additiveData.additiveNumberProcess}.pdf';

        final ref = FirebaseStorage.instance.ref('contracts/$contractId/additives/${additiveData.id}/$fileName');
        final metadata = SettableMetadata(contentType: 'application/pdf');

        final uploadTask = ref.putData(fileBytes, metadata);

        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });

        await uploadTask;
        final url = await ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('contracts')
            .doc(contractId)
            .collection('additives')
            .doc(additiveData.id)
            .update({'pdfUrl': url});

        onComplete(true);
      } else {
        onComplete(false);
      }
    } catch (e) {
      print('Erro ao enviar PDF do aditivo: $e');
      onComplete(false);
    }
  }

  Future<bool> verificarSePdfDeAditivoExiste({
    required ContractData contract,
    required AdditiveData additive,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final additiveOrder = additive.additiveOrder ?? '0';
    final additiveNumberProcess = additive.additiveNumberProcess ?? 'processo';

    final fileName = '$contractNumber-$additiveOrder-$additiveNumberProcess.pdf';
    final ref = FirebaseStorage.instance.ref(
      'contracts/${contract.id}/additives/${additive.id}/$fileName',
    );

    try {
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  ///
  Future<String?> getPdfUrlDoAditivo({
    required ContractData contract,
    required AdditiveData additive,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final additiveOrder = additive.additiveOrder ?? '0';
    final additiveNumberProcess = additive.additiveNumberProcess ?? 'processo';

    final fileName = '$contractNumber-$additiveOrder-$additiveNumberProcess.pdf';
    final ref = FirebaseStorage.instance.ref(
      'contracts/${contract.id}/additives/${additive.id}/$fileName',
    );

    try {
      return await ref.getDownloadURL();
    } catch (e) {
      print('Erro ao obter URL do PDF do aditivo: $e');
      return null;
    }
  }



  Future<bool> deletarPdfDoAditivo({
    required String contractId,
    required AdditiveData additiveData,
  }) async {
    try {
      final contractSnap = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .get();

      final contractNumber = contractSnap.data()?['contractnumber'] ?? 'contrato';
      final fileName = '$contractNumber-${additiveData.additiveOrder}-${additiveData.additiveNumberProcess}.pdf';
      final pdfPath = 'contracts/$contractId/additives/${additiveData.id}/$fileName';

      await FirebaseStorage.instance.ref(pdfPath).delete();

      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .collection('additives')
          .doc(additiveData.id)
          .update({'pdfUrl': FieldValue.delete()});

      return true;
    } catch (e) {
      print('Erro ao deletar PDF do aditivo: $e');
      return false;
    }
  }

  Future<void> salvarUrlPdfDoAditivo({
    required String contractId,
    required String additiveId,
    required String url,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .collection('additives')
          .doc(additiveId)
          .update({'pdfUrl': url});
    } catch (e) {
      print('Erro ao salvar URL do PDF do aditivo no Firestore: $e');
    }
  }


  ///--------------------------- FIM DOS ADITIVOS ---------------------------///

  ///----------------------- INÍCIO DOS APOSTILAMENTOS ----------------------///

  Future<void> salvarUrlPdfDaApostila({
    required String contractId,
    required String apostilleId,
    required String url,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .collection('apostilles')
          .doc(apostilleId)
          .update({'pdfUrl': url});
    } catch (e) {
      print('Erro ao salvar URL do PDF da apostila no Firestore: $e');
    }
  }


  Future<void> selecionarEPdfDeApostilaComProgresso({
    required String contractId,
    required ApostillesData apostilleData,
    required void Function(double progress) onProgress,
    required void Function(bool success) onComplete,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final Uint8List fileBytes = result.files.single.bytes!;

        final contractSnap = await FirebaseFirestore.instance
            .collection('contracts')
            .doc(contractId)
            .get();

        final contractNumber = contractSnap.data()?['contractnumber'] ?? 'contrato';
        final fileName = '$contractNumber-${apostilleData.apostilleOrder}-${apostilleData.apostilleNumberProcess}.pdf';

        final ref = FirebaseStorage.instance.ref('contracts/$contractId/apostilles/${apostilleData.id}/$fileName');
        final metadata = SettableMetadata(contentType: 'application/pdf');

        final uploadTask = ref.putData(fileBytes, metadata);

        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });

        await uploadTask;
        final url = await ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('contracts')
            .doc(contractId)
            .collection('apostilles')
            .doc(apostilleData.id)
            .update({'pdfUrl': url});

        onComplete(true);
      } else {
        onComplete(false);
      }
    } catch (e) {
      print('Erro ao enviar PDF da apostila: $e');
      onComplete(false);
    }
  }

  Future<bool> verificarSePdfDeApostilaExiste({
    required ContractData contract,
    required ApostillesData apostille,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final order = apostille.apostilleOrder ?? '0';
    final process = apostille.apostilleNumberProcess ?? 'processo';

    final fileName = '$contractNumber-$order-$process.pdf';
    final ref = FirebaseStorage.instance.ref(
      'contracts/${contract.id}/apostilles/${apostille.id}/$fileName',
    );

    try {
      await ref.getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getPdfUrlDaApostila({
    required ContractData contract,
    required ApostillesData apostille,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final order = apostille.apostilleOrder ?? '0';
    final process = apostille.apostilleNumberProcess ?? 'processo';

    final fileName = '$contractNumber-$order-$process.pdf';
    final ref = FirebaseStorage.instance.ref(
      'contracts/${contract.id}/apostilles/${apostille.id}/$fileName',
    );

    try {
      return await ref.getDownloadURL();
    } catch (e) {
      print('Erro ao obter URL da apostila: $e');
      return null;
    }
  }

  Future<bool> deletarPdfDaApostila({
    required String contractId,
    required ApostillesData apostilleData,
  }) async {
    try {
      final contractSnap = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .get();

      final contractNumber = contractSnap.data()?['contractnumber'] ?? 'contrato';
      final fileName = '$contractNumber-${apostilleData.apostilleOrder}-${apostilleData.apostilleNumberProcess}.pdf';

      final pdfPath = 'contracts/$contractId/apostilles/${apostilleData.id}/$fileName';

      await FirebaseStorage.instance.ref(pdfPath).delete();

      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .collection('apostilles')
          .doc(apostilleData.id)
          .update({'pdfUrl': FieldValue.delete()});

      return true;
    } catch (e) {
      print('Erro ao deletar PDF da apostila: $e');
      return false;
    }
  }


  ///---------------------- INÍCIO DOS PDF DE MEDIÇÕES ---------------------///

  ///------------------------ INÍCIO DAS MEDIÇÕES ------------------------///

  String getNomePadronizadoPdfDaMedicao({
    required String contractNumber,
    required MeasurementData measurement,
  }) {
    return '$contractNumber-${measurement.measurementorder}-${measurement.measurementadjustmentnumberprocess}.pdf';
  }


  Future<void> salvarUrlPdfDaMedicao({
    required String contractId,
    required String measurementId,
    required String url,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .collection('measurements')
          .doc(measurementId)
          .update({'pdfUrl': url});
    } catch (e) {
      print('Erro ao salvar URL do PDF da medição: $e');
    }
  }


  Future<void> selecionarEPdfDeMedicaoComProgresso({
    required String contractId,
    required MeasurementData measurementData,
    required void Function(double progress) onProgress,
    required void Function(bool success) onComplete,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final Uint8List fileBytes = result.files.single.bytes!;

        final contractSnap = await FirebaseFirestore.instance
            .collection('contracts')
            .doc(contractId)
            .get();
        final contractNumber = contractSnap.data()?['contractnumber'] ?? 'contrato';

        final fileName =
            '$contractNumber-${measurementData.measurementorder}-${measurementData.measurementadjustmentnumberprocess}.pdf';

        final ref = FirebaseStorage.instance.ref(
          'contracts/$contractId/measurements/${measurementData.id}/$fileName',
        );
        final metadata = SettableMetadata(contentType: 'application/pdf');

        final uploadTask = ref.putData(fileBytes, metadata);

        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });

        await uploadTask;
        final url = await ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('contracts')
            .doc(contractId)
            .collection('measurements')
            .doc(measurementData.id)
            .update({'pdfUrl': url});

        onComplete(true);
      } else {
        onComplete(false);
      }
    } catch (e) {
      print('Erro ao enviar PDF da medição: $e');
      onComplete(false);
    }
  }

  Future<bool> verificarSePdfDeMedicaoExiste({
    required ContractData contract,
    required MeasurementData measurement,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final fileName =
        '$contractNumber-${measurement.measurementorder}-${measurement.measurementadjustmentnumberprocess}.pdf';

    final ref = FirebaseStorage.instance.ref(
      'contracts/${contract.id}/measurements/${measurement.id}/$fileName',
    );

    try {
      await ref.getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getPdfUrlDaMedicao({
    required ContractData contract,
    required MeasurementData measurement,
  }) async {
    final contractNumber = contract.contractNumber ?? 'contrato';
    final fileName =
        '$contractNumber-${measurement.measurementorder}-${measurement.measurementadjustmentnumberprocess}.pdf';

    final ref = FirebaseStorage.instance.ref(
      'contracts/${contract.id}/measurements/${measurement.id}/$fileName',
    );

    try {
      return await ref.getDownloadURL();
    } catch (e) {
      print('Erro ao obter URL do PDF da medição: $e');
      return null;
    }
  }

  Future<bool> deletarPdfDaMedicao({
    required String contractId,
    required MeasurementData measurement,
  }) async {
    try {
      final contractSnap = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .get();

      final contractNumber = contractSnap.data()?['contractnumber'] ?? 'contrato';
      final fileName =
          '$contractNumber-${measurement.measurementorder}-${measurement.measurementadjustmentnumberprocess}.pdf';
      final path = 'contracts/$contractId/measurements/${measurement.id}/$fileName';

      await FirebaseStorage.instance.ref(path).delete();

      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .collection('measurements')
          .doc(measurement.id)
          .update({'pdfUrl': FieldValue.delete()});

      return true;
    } catch (e) {
      print('Erro ao deletar PDF da medição: $e');
      return false;
    }
  }


  ///---------------------- FIM DOS PDF DE MEDIÇÕES -------------------------///

  ///-------------------------INÍCIO DOS CONTRATOS---------------------------///

  ///deletando um contrato
  Future<void> deleteContract(String contractId) async {
    await FirebaseFirestore.instance
        .collection('contracts')
        .doc(contractId)
        .delete();
  }

  ///Recuperando todos os contratos
  Future<List<ContractData>> getAllContracts({
    String? statusFilter,
    String? searchQuery,
  }) async {
    Query query = _db.collection('contracts');


    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where(
        'contractstatus', isEqualTo: statusFilter,
      );
    }

    final snapshot = await query.get();
    final contracts = snapshot.docs.map((e) => ContractData.fromDocument(snapshot: e)).toList();

    // Filtro local pelo campo "summarysubjectcontract"
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final queryNormalized = _normalize(searchQuery);
      return contracts.where((c) {
        final title = _normalize(c.summarySubjectContract ?? '');
        return title.contains(queryNormalized);
      }).toList();
    }

    return contracts;
  }

  ///salvando ou atualizando um contrato
  Future<void> salvarOuAtualizarValidade(ValidityData validade) async {
    final uidContract = validade.uidContract;
    if (uidContract == null) {
      throw Exception("Contrato não informado");
    }

    final data = {
      'orderdate': validade.orderdate,
      'ordernumber': validade.orderNumber,
      'ordertype': validade.ordertype,
    };

    final ref = FirebaseFirestore.instance
        .collection('contracts')
        .doc(uidContract)
        .collection('orders');

    if (validade.id != null) {
      // Atualizar
      await ref.doc(validade.id).update(data);
    } else {
      // Criar novo
      await ref.add(data);
    }
  }

  ///deletando uma validade
  Future<void> deletarValidade(String uidContract, String uidValidade) async {
    try {
      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(uidContract)
          .collection('orders')
          .doc(uidValidade)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar validade: $e');
    }
  }

  ///valor de todos os contratos
  Future<double> getAllContractsfilterStatus(String statusContract) async {
    double soma = 0.0;

    try {
      final snapshot = await _db.collection('contracts')
          .where('contractstatus', isEqualTo: statusContract)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final valor = data['valorinicialdocontrato'];

        // Verifica se é número (int ou double)
        if (valor is num) {
          soma += valor.toDouble();
        } else if (valor is String) {
          // Tenta converter string para double, caso venha assim
          final parsed = double.tryParse(valor.replaceAll(',', '.'));
          if (parsed != null) {
            soma += parsed;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao calcular total dos contratos: $e');
      }
    }

    return soma;
  }


  Future<ContractData> getSpecificContract({required String uidContract}) async {
    final snapshot = await FirebaseFirestore.instance.collection('contracts').doc(uidContract).get();
    return ContractData.fromDocument(snapshot: snapshot);
  }

  Future<List<AdditiveData>> getAllAdditivesOfContract({required String uidContract}) async {
    final snapshot = await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('additives')
        .orderBy('additiveorder')
        .get();

    final list = snapshot.docs.map((doc) {
      return AdditiveData.fromDocument(snapshot: doc);
    }).toList();
    return list;
  }

  ///
  Future<List<ApostillesData>> getAllApostillesOfContract({required String uidContract}) async {
    final snapshot = await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('apostilles')
        .orderBy('apostilleorder')
        .get();

    final list = snapshot.docs.map((doc) {
      return ApostillesData.fromDocument(snapshot: doc);
    }).toList();

    return list;
  }

  Future<List<ValidityData>> getAllValidityOfContract({required String uidContract}) async {
    final snapshot = await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('orders')
        .orderBy('ordernumber')
        .get();

    final list = snapshot.docs.map((doc) {
      return ValidityData.fromDocument(snapshot: doc);
    }).toList();

    return list;
  }

  Future<void> salvarOuAtualizarAditivo(AdditiveData data, String uidContract) async {
    final Map<String, dynamic> newData = {
      'additivenumberprocess': data.additiveNumberProcess,
      'additiveorder': data.additiveOrder,
      'additivevaliditycontractdata': data.additionalAdditiveContractDays,
      'additivevalidityexecutiondata': data.additionalAdditiveExecutionDays,
      'additivedata': data.additiveData,
      'additivevalue': data.additiveValue,
      'typeOfAdditive': data.typeOfAdditive, // ✅ Adicionado
    };

    final ref = FirebaseFirestore.instance
        .collection('contracts')
        .doc(uidContract)
        .collection('additives');

    if (data.id != null) {
      await ref.doc(data.id).update(newData);
    } else {
      await ref.add(newData);
    }
  }

  Future<void> deleteAdditive(String uidContract, String uidAditivo) async {
    try {
      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(uidContract)
          .collection('additives')
          .doc(uidAditivo)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar aditivo: $e');
    }
  }

  Future<void> deletarApostille(String uidContract, String uidApostille) async {
    try {
      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(uidContract)
          .collection('apostilles')
          .doc(uidApostille)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar apostilamento: $e');
    }
  }


  Future<void> saveOrUpdateApostille(ApostillesData data, String uidContract) async {
    final Map<String, dynamic> newData = {

      'apostillenumberprocess': data.apostilleNumberProcess,
      'apostilleorder': data.apostilleOrder,
      'apostilledata': data.apostilleData,
      'apostillevalue': data.apostilleValue,
    };

    final ref = FirebaseFirestore.instance
        .collection('contracts')
        .doc(uidContract)
        .collection('apostilles');

    if (data.id != null) {
      await ref.doc(data.id).update(newData);
    } else {
      await ref.add(newData);
    }
  }

  Future<void> salvarOuAtualizarContrato(ContractData contractData) async {
    final db = FirebaseFirestore.instance;
    final collection = db.collection('contracts');
    if (contractData.id != null && contractData.id!.isNotEmpty) {
      await collection.doc(contractData.id).set(contractData.toMap(), SetOptions(merge: true));
    } else {
      final docRef = await collection.add(contractData.toMap());
      contractData.id = docRef.id; // Garante que o ID gerado fique salvo no objeto
    }
  }

  // Função para atualizar as permissões do usuário no Firestore
  Future<void> updateContractPermissions({
    required String contractId,
    required String userId,
    required String permissionType, // ex: 'read', 'edit', 'delete'
    required bool value,
  }) async {
    try {
      _loadingController.add(true);
      await _db.collection('contracts').doc(contractId).update({
        'permissionContractId.$userId.$permissionType': value,
      });
    } catch (e) {
      print('Erro ao atualizar permissões do usuário para contrato: $e');
    } finally {
      _loadingController.add(false);
    }
  }


  // Carrega as permissões do usuário a partir do Firestore
  Future<ContractData?> getContractPermissions(String id) async {
    try {
      final docSnapshot = await _db.collection('contracts').doc(id).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        return ContractData(
          id: id,
          permissionContractId: Map<String, Map<String, bool>>.from(data['permissionContractId'] ?? {}),
        );
      }
    } catch (e) {
      print('Erro ao carregar permissões: $e');
    }
    return null;
  }

  // Função para salvar as permissões no Firestore
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

  bool knowUserPermissionProfileAdm({
    required UserData userData,
    required ContractData contract,
  }) {
    final profile = userData.baseProfile?.toLowerCase();

    // ✅ Administrador pode apagar qualquer contrato
    if (profile == 'administrador' || profile == 'colaborador') return true;

    // 👇 Para os demais, verificar permissão específica no contrato
    final perms = contract.permissionContractId[userData.id];
    return perms != null && perms['delete'] == true;
  }

  ///Recebendo contratos filtrados
  Future<List<ContractData>> getFilteredContracts({
    required UserData currentUser,
    String? statusFilter,
    String? searchQuery,
  }) async {
    final uid = currentUser.id!;
    final perfil = currentUser.baseProfile?.toLowerCase();

    if (perfil == 'administrador' || perfil == 'colaborador') {
      return await getAllContracts(
        statusFilter: statusFilter,
        searchQuery: searchQuery,
      );
    }

    final contratosGestor = await getContractsWhereUserIsManager(
      uid: uid,
      statusFilter: statusFilter,
      searchQuery: searchQuery,
    );

    final contratosFiscal = await getContractsWhereUserIsRegionalManager(
      uid: uid,
      statusFilter: statusFilter,
      searchQuery: searchQuery,
    );

    final contratosComPermissao = await getAllContracts(
      statusFilter: statusFilter,
      searchQuery: searchQuery,
    );

    final contratosPermitidos = contratosComPermissao.where((contract) {
      final permMap = contract.permissionContractId;
      if (permMap == null || !permMap.containsKey(uid)) return false;

      final perms = permMap[uid];
      if (perms == null) return false;

      if (perfil == 'colaborador') {
        return perms['edit'] == true || perms['read'] == true || perms['delete'] == true;
      }
      if (perfil == 'leitor') {
        return perms['read'] == true;
      }
      return false;
    });

    final todosContratos = {
      ...contratosGestor,
      ...contratosFiscal,
      ...contratosPermitidos,
    };

    return todosContratos.toList();
  }


  /// Busca usuários com permissão para um contrato específico
  Future<List<Map<String, dynamic>>> buscarUsuariosComPermissao(
      String contractId, {
        bool incluirComPermissaoDeLeitura = true,
        bool incluirComPermissaoDeEdicao = true,
      }) async {
    final contratoSnapshot =
    await FirebaseFirestore.instance.collection('contracts').doc(contractId).get();

    final contractData = contratoSnapshot.data();
    if (contractData == null || contractData['permissionContractId'] == null) return [];

    final Map<String, dynamic> permissoes = Map<String, dynamic>.from(
        contractData['permissionContractId'] as Map);

    final List<String> uidsPermitidos = [];

    permissoes.forEach((uid, permissoesDoUsuario) {
      final p = Map<String, dynamic>.from(permissoesDoUsuario);
      final podeLer = p['read'] == true;
      final podeEditar = p['edit'] == true;

      if ((incluirComPermissaoDeLeitura && podeLer) ||
          (incluirComPermissaoDeEdicao && podeEditar)) {
        uidsPermitidos.add(uid);
      }
    });

    // Busca apenas os usuários com uid permitido
    final usuariosSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: uidsPermitidos.take(10).toList()) // limita para segurança
        .get();

    return usuariosSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'uid': doc.id,
        'name': data['name'],
        'email': data['email'],
      };
    }).toList();
  }

  Future<List<ContractData>> getContractsWhereUserIsManager({
    required String uid,
    String? statusFilter,
    String? searchQuery,
  }) async {
    Query query = _db.collection('contracts');

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('contractstatus', isEqualTo: statusFilter);
    }

    final snapshot = await query.get();
    final contracts = snapshot.docs
        .map((e) => ContractData.fromDocument(snapshot: e))
        .where((c) => c.managerId == uid)
        .toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final normalizedQuery = _normalize(searchQuery);
      return contracts.where((c) {
        final title = _normalize(c.summarySubjectContract ?? '');
        return title.contains(normalizedQuery);
      }).toList();
    }

    return contracts;
  }

  Future<List<ContractData>> getContractsWhereUserIsRegionalManager({
    required String uid,
    String? statusFilter,
    String? searchQuery,
  }) async {
    Query query = _db.collection('contracts');

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('contractstatus', isEqualTo: statusFilter);
    }

    final snapshot = await query.get();
    final contracts = snapshot.docs
        .map((e) => ContractData.fromDocument(snapshot: e))
        .where((c) => c.regionalManager == uid)
        .toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final normalizedQuery = _normalize(searchQuery);
      return contracts.where((c) {
        final title = _normalize(c.summarySubjectContract ?? '');
        return title.contains(normalizedQuery);
      }).toList();
    }

    return contracts;
  }



  @override
  void dispose() {
    super.dispose();
    _loadingController.close();
    _createdController.close();
  }
}
