import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

class UserData extends ChangeNotifier {
  ///Informações do usuário
  String? uid;
  DateTime? createUser;
  String? name;
  String? surname;
  String? cpf;
  String? gender;
  String? email;
  String? password;
  String? urlPhoto;
  XFile? filePhoto;
  DateTime? dateToBirthday;
  String? cellPhone;
  DocumentSnapshot<Map<String, dynamic>>? userSnap;

  ///device
  String? idPhone;

  ///Permissões da conta
  bool? userProfessional;
  bool? userCompany;
  bool? userCollaborator;
  bool? profileProfessional;
  bool? profileCompany;
  bool? profileCollaborator;


  ///Localização
  GeoPoint? geoPoint;
  //GeoData? address;
  String? postalCode;
  String? city;
  String? addressStreet;
  String? countryCode;
  String? state;
  String? streetNumber;
  String? country;

  ///configuracao do app
  bool? themeDark;

  UserData({
    this.uid,
    this.name,
    this.surname,
    this.cpf,
    this.email,
    this.password,
    this.urlPhoto,
    this.filePhoto,
    this.dateToBirthday,
    this.cellPhone,
    this.userSnap,
    this.idPhone,
    this.userProfessional,
    this.userCompany,
    this.userCollaborator,
    this.profileProfessional,
    this.profileCompany,
    this.profileCollaborator,
    this.geoPoint,
    this.postalCode,
    this.city,
    this.addressStreet,
    this.countryCode,
    this.state,
    this.streetNumber,
    this.country,
    this.themeDark,
    this.createUser,
    this.gender,

});

  ///Recuperando informações no banco de dados
  factory UserData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) {
      throw Exception("Documento do usuário não encontrado");
    }

    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception("Dados do usuário estão vazios");
    }

    return UserData(
      uid: snapshot.id,
      urlPhoto: data['photo'] ?? '',
      name: data['name'] as String?,
      surname: data['surname'] as String?,
      cpf: data['cpf'] as String?,
      email: data['email'] as String?,
      password: data['password'] as String?,
      dateToBirthday: data['dateToBirthday']?.toDate() as DateTime?,
      cellPhone: data['cellPhone'] as String?,
      idPhone: data['idPhone'] as String?,
      userProfessional: data['userProfessional'] as bool?,
      userCompany: data['userCompany'] as bool?,
      userCollaborator: data['userCollaborator'] as bool?,
      profileProfessional: data['profileProfessional'] as bool?,
      profileCompany: data['profileCompany'] as bool?,
      profileCollaborator: data['profileCollaborator'] as bool?,
      geoPoint: data['coords'] as GeoPoint?,
      postalCode: data['postalCode'] as String?,
      city: data['subThoroughfare'] as String?,
      addressStreet: data['adminArea'] as String?,
      countryCode: data['locality'] as String?,
      state: data['subLocality'] as String?,
      streetNumber: data['thoroughfare'] as String?,
      country: data['countryName'] as String?,
      themeDark: data['themeDark'] as bool?,
      createUser: data['createUser']?.toDate() as DateTime?,
      gender: data['gender'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'surname': surname,
      'email': email,
      'dateToBirthday': dateToBirthday,
      'cpf': cpf,
      "createUser": DateTime.now(),
      "lastSignIn": DateTime.now(),
      'cellPhone': cellPhone,
      'gender': gender,
    };
  }
}
