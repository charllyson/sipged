import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sisgeo/_datas/user/user_data.dart';

class UserProvider extends ChangeNotifier {
  UserData? _userData;
  List<UserData> _userDataList = [];

  UserData? get userData => _userData;
  UserData? get user => _userData; // <- ADICIONADO AQUI
  List<UserData> get userDataList => _userDataList;

  void setUserData(UserData data) {
    _userData = data;
    notifyListeners();
  }

  void clearUserData() {
    _userData = null;
    notifyListeners();
  }

  void setUserDataList(List<UserData> users) {
    _userDataList = users;
    notifyListeners();
  }

  Future<void> loadAllUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    _userDataList = snapshot.docs.map((doc) => UserData.fromDocument(snapshot: doc)).toList();
    notifyListeners();
  }
}
