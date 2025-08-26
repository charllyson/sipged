import 'dart:async';
import 'dart:io';

mixin LoginValidators {
  ///Validando email via Stream
  final StreamTransformer<String, String> validateEmail = StreamTransformer<String, String>.fromHandlers(handleData: (email, sink) {
    const Pattern pattern =
        r"^(([^<>()[\]\\.,;:\s@\']+(\.[^<>()[\]\\.,;:\s@\']+)*)|(\'.+\',))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$";
    final RegExp regex = RegExp(pattern as String,);
    if (email.isEmpty) {
      sink.addError("Campo obrigatório",);
    } else if (!regex.hasMatch(email)) {
      sink.addError("E-mail inválido",);
    } else {
      sink.add(email);
    }
  },);

  ///Validando password via Stream
  final StreamTransformer<String, String> validatePassword =
      StreamTransformer<String, String>.fromHandlers(handleData: (pass, sink) {
    if (pass.isEmpty) {
      sink.addError('Insira a sua senha',);
    } else if (pass.length > 5) {
      sink.add(pass);
    } else {
      sink.addError('A senha não pode ser menor que 6 dígitos',);
    }
  },);

  ///Validação de usuário
  String? validateImage(File? images) {
    return null;
  }

  String? validateName(String? text) {
    if (text!.isEmpty) return 'Você deve informar um nome';
    return null;
  }

  String? validateSurname(String? text) {
    if (text!.isEmpty) return 'Você deve informar um sobrenome';
    return null;
  }

  String? validatePhoto(String text) {
    if (text.isEmpty) return 'Você deve inserir uma photo';
    return null;
  }

  String? Function(DateTime?)? validateDateToBirthday = (date) {
    if (date == null) return 'Selecione uma data';
    if (date.isAfter(DateTime.now())) return 'Data não pode ser no futuro';
    return null;
  };

  String? validateEmailLogin(String? text) {
    const Pattern pattern =
        r"^(([^<>()[\]\\.,;:\s@\']+(\.[^<>()[\]\\.,;:\s@\']+)*)|(\'.+\',))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$";
    if (text!.isEmpty || !text.contains(RegExp(pattern as String,),)) {
      return 'Você deve informar um email válido';
    }
    return null;
  }

  /*String? validateCpf({String? text}) {
    if (!CPFValidator.isValid(text)) {
      return text;
    }return null;
  }*/


  String? validateCellPhone(String? text) {
    if (text!.length < 14) return 'Você deve informar um telefone válido';
    return null;
  }

  String? validatePasswordLogin(String? text) {
    if (text!.isEmpty) return 'Você deve informar uma senha válida';
    return null;
  }
}
