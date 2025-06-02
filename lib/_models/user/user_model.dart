import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:scoped_model/scoped_model.dart';

import '../../_datas/user/user_data.dart';

class UserModel extends Model {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? firebaseUser = FirebaseAuth.instance.currentUser;
  late UserData userData = UserData();
  late DocumentSnapshot<Map<String, dynamic>> docUser;

  bool isLoading = false;

  static UserModel of(BuildContext context) => ScopedModel.of<UserModel>(context);

  Future<UserData?> loadCurrentUser() async {
    if (firebaseUser != null) {
      firebaseUser = _auth.currentUser!;
    } else {
       await FirebaseFirestore.instance
            .collection("users")
            .doc(firebaseUser?.uid)
            .get().then((e){
              userData = UserData.fromDocument(snapshot: e);
       });
        return userData;
      }
      notifyListeners();
      return null;
    }
}
