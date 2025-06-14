import 'package:flutter/material.dart';
import 'package:sisgeo/_datas/user/user_data.dart';

class UserProvider extends ChangeNotifier {
  UserData? _userData;
  List<UserData> _userDataList = [];

  UserData? get userData => _userData;
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
}
