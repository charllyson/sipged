import 'dart:async';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_utils/input/sipged_sanitize.dart';

mixin SipGedValidation {
  final Map<TextEditingController, VoidCallback> _listeners = {};

  void setupValidation(
      List<TextEditingController> controllers,
      VoidCallback callback,
      ) {
    for (final ctrl in controllers) {
      if (_listeners[ctrl] != callback) {
        _listeners[ctrl] = callback;
        ctrl.addListener(callback);
      }
    }
  }

  void removeValidation(
      List<TextEditingController> controllers,
      VoidCallback callback,
      ) {
    for (final ctrl in controllers) {
      ctrl.removeListener(callback);
      _listeners.remove(ctrl);
    }
  }

  bool areFieldsFilled(
      List<TextEditingController> controllers, {
        int minLength = 1,
      }) {
    return controllers.every((ctrl) => ctrl.text.trim().length >= minLength);
  }

  bool isFieldInvalid(TextEditingController controller, {int minLength = 1}) {
    return controller.text.trim().length < minLength;
  }

  String? validateRequired(
      String? value, {
        String message = 'Campo obrigatório',
      }) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  String? validateDateToBirthday(DateTime? date) {
    if (date == null) return 'Selecione uma data';
    if (date.isBefore(DateTime.now())) return 'Data não pode ser no passado';
    return null;
  }

  String? validateNoEmptyDate(DateTime? date) {
    if (date == null) return 'Data obrigatória';
    return null;
  }

  final StreamTransformer<String, String> validateEmail =
  StreamTransformer<String, String>.fromHandlers(
    handleData: (email, sink) {
      const Pattern pattern =
          r"^(([^<>()[\]\\.,;:\s@\']+(\.[^<>()[\]\\.,;:\s@\']+)*)|(\'.+\',))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$";
      final RegExp regex = RegExp(pattern as String);
      if (email.isEmpty) {
        sink.addError("Campo obrigatório");
      } else if (!regex.hasMatch(email)) {
        sink.addError("E-mail inválido");
      } else {
        sink.add(email);
      }
    },
  );

  final StreamTransformer<String, String> validatePassword =
  StreamTransformer<String, String>.fromHandlers(
    handleData: (pass, sink) {
      if (pass.isEmpty) {
        sink.addError('Insira a sua senha');
      } else if (pass.length > 5) {
        sink.add(pass);
      } else {
        sink.addError('A senha não pode ser menor que 6 dígitos');
      }
    },
  );

  String? validateCpf(String? text) {
    if (text == null || text.isEmpty || text.length < 11) {
      return 'Você deve informar um CPF';
    } else if (!CPFValidator.isValid(text)) {
      return 'CPF Inválido';
    }
    return null;
  }

  String? validateCellPhone(String? text) {
    if (text == null || text.length < 14) return 'Telefone inválido';
    return null;
  }

  String? validateDouble(String? value, {bool allowZero = false}) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    final v = double.tryParse(value.replaceAll(',', '.'));
    if (v == null || (!allowZero && v == 0)) return 'Valor inválido';
    return null;
  }

  String? validateDate(DateTime? date) {
    if (date == null) return 'Data obrigatória';
    if (date.isAfter(DateTime.now())) return 'Data futura inválida';
    return null;
  }

  String? Function(String?) validatorFromController(
      TextEditingController controller,
      String? Function(String?) validatorFn,
      ) {
    return (_) => validatorFn(controller.text);
  }

  InputBorder getErrorBorder(bool hasError) {
    return OutlineInputBorder(
      borderSide: BorderSide(
        color: hasError ? Colors.red : Colors.grey,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(8),
    );
  }

  bool allFieldsValid(List<String? Function()> validators) {
    for (final validator in validators) {
      final result = validator();
      if (result != null) return false;
    }
    return true;
  }

  String? validateDropdown(
      String? value, {
        String message = 'Campo obrigatório',
      }) {
    if (value == null || value.isEmpty) return message;
    return null;
  }

  String? validateImage(dynamic images) {
    return null;
  }

  String? validateImages(dynamic images) {
    if (images.isEmpty) return 'Você deve inserir pelo menos uma imagem';
    return null;
  }

  String? validateTitle(String? text) {
    if (text == null || text.isEmpty) return 'Você deve informar o título';
    return null;
  }

  String? validateCollaborator(String text) {
    if (text.isEmpty) return 'Você deve informar id do collaborador';
    return null;
  }

  String? validateDescription(String? text) {
    if (text == null || text.isEmpty) {
      return 'Você deve informar uma descrição';
    }
    return null;
  }

  String? validateAdNumber(String text) {
    if (text.isEmpty) return 'Você deve informar o número do local';
    return null;
  }

  String? validateCnpj(String? text) {
    if (text == null || text.isEmpty || text.length < 14) {
      return 'Você deve informar um Cnpj';
    } else if (!CNPJValidator.isValid(text)) {
      return 'CNPJ Inválido';
    }
    return null;
  }

  String? validateNoEmpty(String? text) {
    if (text == null || text.isEmpty) {
      return 'Este campo não pode ficar vazio';
    }
    return null;
  }

  String? validateDurationConsult(DateTime dateDurationConsult) {
    return null;
  }

  String? validateStartConsult(DateTime? dateStartConsult) {
    return null;
  }

  String? validateEndConsult(DateTime? dateEndConsult) {
    return null;
  }

  String? validateBlockDay(DateTime? dateBlockDay) {
    return null;
  }

  String? validateBlockAfterDay(DateTime? dateBlockAfterDay) {
    return null;
  }

  String? validateBlockBeforeDay(DateTime? dateBlockBeforeDay) {
    return null;
  }

  String? validatePrice(String? text) {
    if (text == null || text.isEmpty) {
      return 'Você deve informar o preço da consulta';
    }
    if (int.tryParse(SipGedSanitize.onlyDigits(text)) == null) {
      return 'Utilize valores válidos';
    }
    return null;
  }

  String? validateName(String? text) {
    if (text == null || text.isEmpty) return 'Você deve informar um nome';
    return null;
  }

  String? validateSurname(String? text) {
    if (text == null || text.isEmpty) return 'Você deve informar um sobrenome';
    return null;
  }

  String? validatePhoto(String text) {
    if (text.isEmpty) return 'Você deve inserir uma photo';
    return null;
  }

  String? validateBloodGroup(String text) {
    if (text.isEmpty) return 'Informe o tipo sanguíneo';
    return null;
  }

  String? validateStature(String text) {
    if (text.isEmpty) return 'Informe sua altura';
    return null;
  }

  String? validateWidth(String text) {
    if (text.isEmpty) return 'Informe seu peso';
    return null;
  }

  String? validateCurrentState(String text) {
    if (text.isEmpty) return 'Informe o estado atual do paciente';
    return null;
  }

  String? validateMainComplaint(String? text) {
    if (text == null || text.isEmpty) {
      return 'Informe a queixa principal do paciente';
    }
    return null;
  }

  String? validateCurrentHistory(String? text) {
    if (text == null || text.isEmpty) {
      return 'Informe a história da causa do paciente';
    }
    return null;
  }

  String? validateSystemReview(String? text) {
    if (text == null || text.isEmpty) {
      return 'Informe o que você diagnosticou sobre os sistemas';
    }
    return null;
  }

  String? validateTreatmentPlan(String? text) {
    if (text == null || text.isEmpty) {
      return 'Informe qual tratamento você seguirá';
    }
    return null;
  }

  String validateComments(String? text) {
    if (text == null || text.isEmpty || text.length < 5) {
      return 'Escreva um commentário autentico';
    }
    return '';
  }

  String? validateCardNumber(String number) {
    if (number.isEmpty) {
      return 'Campo obrigatório';
    } else if (number.length != 19) {
      return 'Número incompleto';
    } else {
      return 'Cartão Inválido';
    }
  }

  String? validateCardDate(String date) {
    if (date.isEmpty) {
      return 'Campo obrigatório';
    } else if (date.length != 7) {
      return 'Data Incompleta';
    }
    return null;
  }

  String? validateCardCVV(String cvv) {
    if (cvv.isEmpty) {
      return 'Campo obrigatório';
    } else if (cvv.length != 3) {
      return 'Número Incompleto';
    }
    return null;
  }

  String? validateEmailLogin(String? text) {
    const Pattern pattern =
        r"^(([^<>()[\]\\.,;:\s@\']+(\.[^<>()[\]\\.,;:\s@\']+)*)|(\'.+\',))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$";
    if (text == null || text.isEmpty || !text.contains(RegExp(pattern as String))) {
      return 'Você deve informar um email válido';
    }
    return null;
  }

  String? validatePasswordLogin(String? text) {
    if (text == null || text.isEmpty) {
      return 'Você deve informar uma senha válida';
    }
    return null;
  }
}