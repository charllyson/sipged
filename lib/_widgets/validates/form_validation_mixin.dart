import 'dart:async';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';

mixin FormValidationMixin {
  final Map<TextEditingController, VoidCallback> _listeners = {};

  void setupValidation(
      List<TextEditingController> controllers,
      VoidCallback callback,
      ) {
    for (final ctrl in controllers) {
      // evita duplicar listener se chamar duas vezes
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

  String? validateRequired(String? value, {String message = 'Campo obrigatório'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  String? Function(DateTime?)? validateDateToBirthday = (date) {
    if (date == null) return 'Selecione uma data';
    if (date.isBefore(DateTime.now())) return 'Data não pode ser no passado';
    return null;
  };

  String? validateNoEmptyDate(DateTime? date) {
    if (date == null) return 'Data obrigatória';
    return null;
  }

  String? validateEmail(String? email) {
    const String pattern =
        r"^(([^<>()[\]\\.,;:\s@']+(\.[^<>()[\]\\.,;:\s@']+)*)|('.+'))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$";
    final regex = RegExp(pattern);
    if (email == null || email.trim().isEmpty) return 'Campo obrigatório';
    if (!regex.hasMatch(email)) return 'E-mail inválido';
    return null;
  }

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
    if (text == null || !CPFValidator.isValid(text)) {
      return 'CPF inválido';
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
    for (var validator in validators) {
      final result = validator();
      if (result != null) return false;
    }
    return true;
  }

  String? validateDropdown(String? value, {String message = 'Campo obrigatório'}) {
    if (value == null || value.isEmpty) return message;
    return null;
  }
}
