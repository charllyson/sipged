// lib/_blocs/system/user/user_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/screens/menus/menu_drawer.dart';

/// Modelo de usuário SEM responsabilidades de permissão.
///
/// Toda a lógica de papéis/permissões deve ficar em:
/// - lib/_utils/user_permission.dart
/// - lib/_utils/module_permission.dart
class UserData extends ChangeNotifier {
  // ===== Identificação e perfil =====
  String? uid;
  String? name;
  String? surname;
  String? cpf;
  String? email;
  String? password;
  String? gender;

  // ===== Foto =====
  String? urlPhoto;
  XFile? filePhoto; // uso em runtime, não persiste

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

  DocumentSnapshot<Map<String, dynamic>>? userSnap;

  bool? profileWork;
  bool? profileLegal;

  static BgPalette paletteForUser(UserData? user) {
    final isWorks = user?.profileWork == true;
    final isLegal = user?.profileLegal == true;

    if (isWorks) {
      return const BgPalette(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF7FBFF),
            Color(0xFFE3F2FD),
          ],
        ),
      );
    }

    if (isLegal) {
      return const BgPalette(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFEF6F8),
            Color(0xFFFDECEF),
          ],
        ),
      );
    }

    return const BgPalette(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFDFDFD),
          Color(0xFFF5F5F5),
        ],
      ),
    );
  }

  static DrawerPalette drawerPaletteForUser(UserData? user) {
    final isWorks = user?.profileWork == true;
    final isLegal = user?.profileLegal == true;

    if (isWorks) {
      return const DrawerPalette(
        background: Color(0xFF1B2033),
        sectionTitle: Colors.white70,
        sectionSubtitle: Colors.white38,
      );
    }

    if (isLegal) {
      return const DrawerPalette(
        background: Color(0xFF3B0012),
        sectionTitle: Colors.white70,
        sectionSubtitle: Colors.white38,
      );
    }

    return const DrawerPalette(
      background: Color(0xFF202124),
      sectionTitle: Colors.white70,
      sectionSubtitle: Colors.white38,
    );
  }

  UserData({
    this.uid,
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
    this.profileWork = false,
    this.profileLegal = false,
  });

  factory UserData.fromDocument({
    required DocumentSnapshot<Map<String, dynamic>> snapshot,
  }) {
    if (!snapshot.exists) {
      throw Exception('Documento do usuário não encontrado');
    }

    final data = snapshot.data();
    if (data == null) {
      throw Exception('Dados do usuário estão vazios');
    }

    return UserData(
      uid: snapshot.id,
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
      profileWork: data['profileWork'] as bool? ?? false,
      profileLegal: data['profileLegal'] as bool? ?? false,
    );
  }

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
      'themeDark': themeDark ?? false,
      'geoPoint': geoPoint,
      'dateToBirthday':
      dateToBirthday != null ? Timestamp.fromDate(dateToBirthday!) : null,
      'createUser':
      createUser != null ? Timestamp.fromDate(createUser!) : Timestamp.now(),
      'lastSignIn': Timestamp.now(),

      // CAMPOS IMPORTANTES QUE PRECISAM PERSISTIR
      'baseRole': baseRole,
      'baseProfile': baseProfile,
      'profileWork': profileWork ?? false,
      'profileLegal': profileLegal ?? false,
    };
  }

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
    String? baseRole,
    String? baseProfile,
    bool? profileWork,
    bool? profileLegal,
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
    this.baseRole = baseRole ?? this.baseRole;
    this.baseProfile = baseProfile ?? this.baseProfile;
    this.profileWork = profileWork ?? this.profileWork;
    this.profileLegal = profileLegal ?? this.profileLegal;

    notifyListeners();
  }

  static UserData empty() {
    return UserData(
      uid: null,
      name: '',
      surname: '',
      cpf: '',
      email: '',
      password: null,
      gender: null,
      urlPhoto: null,
      filePhoto: null,
      cellPhone: '',
      createUser: null,
      dateToBirthday: null,
      themeDark: false,
      geoPoint: null,
      userSnap: null,
      baseRole: null,
      baseProfile: null,
      profileWork: false,
      profileLegal: false,
    );
  }

  String get fullName {
    final n = (name ?? '').trim();
    final s = (surname ?? '').trim();
    return [n, s].where((e) => e.isNotEmpty).join(' ').trim();
  }

  bool get hasValidUid => (uid ?? '').trim().isNotEmpty;
}