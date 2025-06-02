
import '../formats/format_field.dart';

mixin Validator {

  String? validateImage(dynamic images) {
    return null;
  }

  String? validateImages(dynamic images) {
    if (images.isEmpty) return 'Você deve inserir pelo menos uma imagem';
    return null;
  }

  String? validateTitle(String? text) {
    if (text!.isEmpty) return 'Você deve informar o título';
    return null;
  }

  String? validateCollaborator(String text) {
    if (text.isEmpty) return 'Você deve informar id do collaborador';
    return null;
  }

  String? validateDescription(String? text) {
    if (text!.isEmpty) return 'Você deve informar uma descrição';
    return null;
  }

  String? validateAdNumber(String text) {
    if (text.isEmpty) return 'Você deve informar o número do local';
    return null;
  }

  /*String? validateCpf(String? text) {
    if (text!.isEmpty || text.length < 11) {
      return 'Você deve informar um CPF';
    } else if (!CPFValidator.isValid(text)) {
      return 'CPF Inválido';
    }
    return null;
  }*/

  /*String? validateCnpj(String? text) {
    if (text!.isEmpty || text.length < 14) {
      return 'Você deve informar um Cnpj';
    } else if (!CNPJValidator.isValid(text)) {
      return 'CNPJ Inválido';
    }
    return null;
  }*/

  String? validateNoEmpty(String? text) {
    if (text!.isEmpty) return 'Este campo não pode ficar vazio';
    return null;
  }

  String? validateNoEmptyDate(DateTime? dateNoEmptyDate) {
    return null;
  }

  ///Validação de datas
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

  ///Validação de preço
  String? validatePrice(String? text) {
    if (text!.isEmpty) {
      return 'Você deve informar o preço da consulta';
    }
    //O VALOR RETORNA UM VALOR INTEIRO
    if (int.tryParse(getSanitizedText(text)) == null) {
      return 'Utilize valores válidos';
    }
    return null;
  }

  ///Validação de usuário
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

  String? validateEmail(String? text) {
    if (text!.isEmpty) return 'Você deve informar um email';
    return null;
  }

  String? validateCellPhone(String? text) {
    if (text!.isEmpty || text.length < 11) {
      return 'Você deve informar um número para contato';
    }
    return null;
  }

  String? Function(DateTime?)? validateDateToBirthday = (date) {
    if (date == null) return 'Selecione uma data';
    if (date.isBefore(DateTime.now())) return 'Data não pode ser no passado';
    return null;
  };

  ///Validações do History
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

  ///Validações de registros médicos
  String? validateCurrentState(String text) {
    if (text.isEmpty) return 'Informe o estado atual do paciente';
    return null;
  }

  String? validateMainComplaint(String? text) {
    if (text!.isEmpty) return 'Informe a queixa principal do paciente';
    return null;
  }

  String? validateCurrentHistory(String? text) {
    if (text!.isEmpty) return 'Informe a história da causa do paciente';
    return null;
  }

  String? validateSystemReview(String? text) {
    if (text!.isEmpty) {
      return 'Informe o que você diagnosticou sobre os sistemas';
    }
    return null;
  }

  String? validateTreatmentPlan(String? text) {
    if (text!.isEmpty) return 'Informe qual tratamento você seguirá';
    return null;
  }

  ///Rating page
  String validateComments(String? text) {
    if (text!.isEmpty || text.length < 5) {
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
}
