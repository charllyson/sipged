// lib/_blocs/system/user/user_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

/// Modelo de usuário SEM responsabilidades de permissão.
///
/// Toda a lógica de papéis/permissões deve ficar em:
/// - lib/_utils/user_permission.dart  (BaseRole, helpers)
/// - lib/_utils/page_permission.dart  (Perms, checagem módulo/doc)
class UserData extends ChangeNotifier {
  // ===== Identificação e perfil =====
  String? id;
  String? name;
  String? surname;
  String? cpf;
  String? email;
  String? password;
  String? gender;

  // ===== Foto =====
  String? urlPhoto;
  XFile? filePhoto; // uso em runtime (upload), não persiste no Firestore

  // ===== Contato =====
  String? cellPhone;

  String? baseRole;
  String? baseProfile;

  // ===== Datas =====
  DateTime? createUser;
  DateTime? dateToBirthday;

  // ===== Preferências / localização =====
  bool? themeDark;
  GeoPoint? geoPoint;

  // ===== Snapshot bruto (opcional p/ debug) =====
  DocumentSnapshot<Map<String, dynamic>>? userSnap;

  UserData({
    this.id,
    this.name,
    this.surname,
    this.cpf,
    this.email,
    this.password,
    this.gender,
    this.urlPhoto,
    this.filePhoto,
    this.cellPhone,
    this.createUser,
    this.dateToBirthday,
    this.themeDark,
    this.geoPoint,
    this.userSnap,
    this.baseRole,
    this.baseProfile,
  });

  /// Construtor a partir do documento do Firebase.
  factory UserData.fromDocument({
    required DocumentSnapshot<Map<String, dynamic>> snapshot,
  }) {
    if (!snapshot.exists) {
      throw Exception("Documento do usuário não encontrado");
    }

    final data = snapshot.data();
    if (data == null) {
      throw Exception("Dados do usuário estão vazios");
    }

    return UserData(
      id: snapshot.id,
      name: data['name'] as String?,
      surname: data['surname'] as String?,
      cpf: data['cpf'] as String?,
      email: data['email'] as String?,
      password: data['password'] as String?,
      gender: data['gender'] as String?,
      urlPhoto: data['photo'] as String?,
      cellPhone: data['cellPhone'] as String?,
      themeDark: data['themeDark'] as bool? ?? false,
      dateToBirthday: (data['dateToBirthday'] as Timestamp?)?.toDate(),
      createUser: (data['createUser'] as Timestamp?)?.toDate(),
      geoPoint: data['geoPoint'] as GeoPoint?,
      baseRole: data['baseRole'] as String?,
      baseProfile: data['baseProfile'] as String?,
      userSnap: snapshot,
    );
  }

  /// Converte para mapa para salvar no Firestore.
  ///
  /// Observações:
  /// - Campos `filePhoto` e `userSnap` não são persistidos.
  /// - `lastSignIn` é atualizado no momento do save.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'surname': surname,
      'email': email,
      'cpf': cpf,
      'password': password,
      'gender': gender,
      'photo': urlPhoto,
      'cellPhone': cellPhone,
      'themeDark': themeDark,
      'geoPoint': geoPoint,
      'dateToBirthday':
      dateToBirthday != null ? Timestamp.fromDate(dateToBirthday!) : null,
      'createUser':
      createUser != null ? Timestamp.fromDate(createUser!) : Timestamp.now(),
      'lastSignIn': Timestamp.now(),
    };
  }

  /// Atualiza campos mutáveis e notifica ouvintes (útil na UI).
  void update({
    String? name,
    String? surname,
    String? cpf,
    String? email,
    String? gender,
    String? urlPhoto,
    XFile? filePhoto,
    String? cellPhone,
    bool? themeDark,
    GeoPoint? geoPoint,
    DateTime? dateToBirthday,
  }) {
    this.name = name ?? this.name;
    this.surname = surname ?? this.surname;
    this.cpf = cpf ?? this.cpf;
    this.email = email ?? this.email;
    this.gender = gender ?? this.gender;
    this.urlPhoto = urlPhoto ?? this.urlPhoto;
    this.filePhoto = filePhoto ?? this.filePhoto;
    this.cellPhone = cellPhone ?? this.cellPhone;
    this.themeDark = themeDark ?? this.themeDark;
    this.geoPoint = geoPoint ?? this.geoPoint;
    this.dateToBirthday = dateToBirthday ?? this.dateToBirthday;
    notifyListeners();
  }
}
