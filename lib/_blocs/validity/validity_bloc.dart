import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../_datas/contracts/contracts_data.dart';

class ValidityBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;


  ValidityBloc();

  ///Recuperando todos os contratos
  Future<List<ContractData>> getAllContracts() {
    return _db.collection('contracts').get().then((snapshot) {
      return snapshot.docs.map((doc) {
        return ContractData.fromDocument(snapshot: doc);
      }).toList();
    });
  }

  Future<ContractData?> getSpecificContract({required String uid}) async {
    final snapshot = await FirebaseFirestore.instance.collection('contracts').doc(uid).get();

    if (!snapshot.exists) {
      print('Contrato com UID $uid não encontrado no Firestore');
      return null;
    }

    return ContractData.fromDocument(snapshot: snapshot);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
