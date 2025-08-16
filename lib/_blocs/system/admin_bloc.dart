import 'package:bloc_pattern/bloc_pattern.dart';

class AdminBloc extends BlocBase {
  AdminBloc();
  int _actualPage = 1;
  int get actualPage => _actualPage;

  void setPage(int numberPage) {
    _actualPage = numberPage;
    notifyListeners();
  }


}
