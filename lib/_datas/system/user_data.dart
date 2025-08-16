import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

import 'system_data.dart';

class UserData extends ChangeNotifier {
  /// Informações do usuário
  String? id;
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

  List<String>? permissionOrgan;
  List<String>? permissionDirector;
  List<String>? permissionSector;
  List<String>? departments;
  Map<String, List<String>>? departmentRoles = {};

  static List<String> profile = [
    'Convidado',
    'Colaborador',
    'Administrador'
  ];

  static List<String> permission = [
    'read',
    'create',
    'edit',
    'delete'
  ];

  /// Permissões híbridas
  String? baseProfile; // Ex: leitor, colaborador, administrador
  Map<String, Map<String, bool>> modulePermissions = {};

  /// Campos auxiliares para controle de permissão
  bool isSelectedOrgan = false;
  bool isSelectedDirector = false;
  bool isSelectedSector = false;

  /// Listas internas para hierarquia
  List<SystemData>? directors;
  List<SystemData>? sectors;

  /// Localização
  GeoPoint? geoPoint;

  /// Configuração do app
  bool? themeDark;

  UserData({
    this.id,
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
    this.geoPoint,
    this.themeDark,
    this.createUser,
    this.gender,
    this.permissionOrgan,
    this.permissionDirector,
    this.permissionSector,
    this.baseProfile,
    this.modulePermissions = const {},
    this.directors,
    this.sectors,
    this.isSelectedOrgan = false,
    this.isSelectedDirector = false,
    this.isSelectedSector = false,
    this.departments,
    this.departmentRoles,
  });

  /// Construtor a partir do documento do Firebase
  factory UserData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) throw Exception("Documento do usuário não encontrado");
    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) throw Exception("Dados do usuário estão vazios");

    // Compatibilidade com diferentes formatos de modulePermissions
    final rawPermissions = data['modulePermissions'] as Map<String, dynamic>? ?? {};
    final parsedPermissions = <String, Map<String, bool>>{};
    rawPermissions.forEach((module, permissions) {
      if (permissions is Map) {
        parsedPermissions[module] = permissions.map(
              (k, v) => MapEntry(k.toString(), v == true),
        );
      } else if (permissions is List) {
        parsedPermissions[module] = {
          for (var perm in permissions) perm.toString(): true,
        };
      } else {
        parsedPermissions[module] = {};
      }
    });

    return UserData(
      id: snapshot.id,
      urlPhoto: data['photo'] ?? '',
      name: data['name'] as String? ?? 'Sem nome',
      surname: data['surname'] as String? ?? 'Sem sobrenome',
      cpf: data['cpf'] as String? ?? 'Sem CPF',
      email: data['email'] as String? ?? 'Sem email',
      password: data['password'] as String?,
      dateToBirthday: (data['dateToBirthday'] as Timestamp?)?.toDate(),
      cellPhone: data['cellPhone'] as String?,
      themeDark: data['themeDark'] as bool? ?? false,
      createUser: (data['createUser'] as Timestamp?)?.toDate(),
      gender: data['gender'] as String?,
      permissionOrgan: (data['permissionOrgan'] as List?)?.map((e) => e.toString()).toList() ?? [],
      permissionDirector: (data['permissionDirector'] as List?)?.map((e) => e.toString()).toList() ?? [],
      permissionSector: (data['permissionSector'] as List?)?.map((e) => e.toString()).toList() ?? [],
      baseProfile: data['baseProfile'] as String?,
      modulePermissions: parsedPermissions,
      geoPoint: data['geoPoint'] as GeoPoint?,
      departments: (data['departments'] as List?)?.map((e) => e.toString()).toList() ?? [],
      departmentRoles: (data['departmentRoles'] as Map?)?.map((key, value) => MapEntry(key.toString(), (value as List).map((e) => e.toString()).toList())),
    );
  }

  /// Converte para mapa para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'surname': surname,
      'email': email,
      'dateToBirthday': dateToBirthday,
      'cpf': cpf,
      'createUser': createUser ?? DateTime.now(),
      'lastSignIn': DateTime.now(),
      'cellPhone': cellPhone,
      'gender': gender,
      'photo': urlPhoto,
      'themeDark': themeDark,
      'permissionOrgan': permissionOrgan,
      'permissionDirector': permissionDirector,
      'permissionSector': permissionSector,
      'baseProfile': baseProfile,
      'modulePermissions': modulePermissions,
      'geoPoint': geoPoint,
      'departments': departments,
      'departmentRoles': departmentRoles,
    };
  }
}
