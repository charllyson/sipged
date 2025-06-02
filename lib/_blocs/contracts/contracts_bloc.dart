import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sisgeo/_datas/additive/additive_data.dart';
import 'package:sisgeo/_datas/apostilles/apostilles_data.dart';
import 'package:sisgeo/_datas/validity/validity_data.dart';
import '../../_datas/contracts/contracts_data.dart';

class ContractsBloc extends BlocBase {
  late ContractData? contractsData;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final _createdController = BehaviorSubject<bool>();
  final _loadingController = BehaviorSubject<bool>();

  Stream<bool> get outLoading => _loadingController.stream;
  Stream<bool> get outCreated => _createdController.stream;

  ContractsBloc();

  ///Recuperando todos os contratos
  Future<List<ContractData>> getAllContracts() {
    return _db.collection('contracts').get().then((snapshot) {
      return snapshot.docs.map((doc) {
        return ContractData.fromDocument(snapshot: doc);
      }).toList();
    });
  }

  ///valor de todos os contratos
  Future<double> getAllContractsValue() async {
    double soma = 0.0;

    final snapshot = await _db.collection('contracts').get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final valor = data['valorinicialdocontrato'];

      if (valor is num) {
        soma += valor.toDouble();
      }
    }
    return soma;
  }


  Future<ContractData?> getSpecificContract({required String uid}) async {
    final snapshot = await FirebaseFirestore.instance.collection('contracts').doc(uid).get();

    if (!snapshot.exists) {
      print('Contrato com UID $uid não encontrado no Firestore');
      return null;
    }

    return ContractData.fromDocument(snapshot: snapshot);
  }

  Future<List<AdditiveData>> getAllAdditivesOfContract({required String uidContract}) async {
    final snapshot = await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('additives')
        .orderBy('additiveorder')
        .get();
    print('Quantidade de aditivos: ${snapshot.docs.length}');

    final list = snapshot.docs.map((doc) {
      return AdditiveData.fromDocument(snapshot: doc);
    }).toList();

    print('Lista convertida com ${list.length} aditivos');

    return list;
  }
  Future<List<ApostillesData>> getAllApostillesOfContract({required String uidContract}) async {
    final snapshot = await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('apostilles')
        .orderBy('apostilleorder')
        .get();
    print('Quantidade de apostilamenots: ${snapshot.docs.length}');

    final list = snapshot.docs.map((doc) {
      return ApostillesData.fromDocument(snapshot: doc);
    }).toList();

    print('Lista convertida com ${list.length} apostilamentos');

    return list;
  }

  Future<List<ValidityData>> getAllValidityOfContract({required String uidContract}) async {
    final snapshot = await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('orders')
        .get();
    print('Quantidade de apostilamenots: ${snapshot.docs.length}');

    final list = snapshot.docs.map((doc) {
      return ValidityData.fromDocument(snapshot: doc);
    }).toList();

    print('Lista convertida com ${list.length} apostilamentos');

    return list;
  }




  @override
  void dispose() {
    super.dispose();
    _loadingController.close();
    _createdController.close();
  }
}
