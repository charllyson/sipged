import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../_datas/system/system_data.dart';
import '../../_datas/user/user_data.dart';

class SystemBloc extends BlocBase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> organList = [];
  List<Map<String, dynamic>> directorsList = [];
  List<Map<String, dynamic>> sectorList = [];
  bool isLoading = true;

  /// Carrega órgãos
  Future<List<SystemData>> loadOrgans() async {
    List<SystemData> organs = [];
    try {
      final snapshotOrgans = await _firestore.collection('organ').get();

      organs = snapshotOrgans.docs.map((doc) {
        return SystemData.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Erro ao carregar órgãos: $e');
    }
    print(organs);
    return organs;
  }


  /// Carrega diretorias
  Future<List<SystemData>> loadDirectors(String idOrgan) async {
    List<SystemData> directors = [];
    try {
      final snapshotDirectors = await _firestore
          .collection('organ')
          .doc(idOrgan)
          .collection('directors')
          .get();

      directors = snapshotDirectors.docs.map((doc) {
        return SystemData.fromFirestore(doc);
      }).toList();

      directorsList = snapshotDirectors.docs.map((doc) {
        return {
          'idDirectors': doc.id,
          'acronymDirectors': doc['acronymDirectors'],
        };
      }).toList();
    } catch (e) {
      print('Erro ao carregar diretorias: $e');
    }

    return directors;
  }

  /// Carrega setores
  Future<List<SystemData>> loadSectors({
    required String idOrgan,
    required String idDirectors,
  }) async {
    List<SystemData> sectors = [];
    try {
      final snapshot = await _firestore
          .collection('organ')
          .doc(idOrgan)
          .collection('directors')
          .doc(idDirectors)
          .collection('sectors')
          .get();
      sectors = snapshot.docs.map((doc) {
        return SystemData.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Erro ao carregar setores: $e');
    }

    return sectors;
  }

  /// Cria órgão
  Future<void> createOrgan(String acronymOrgan) async {
    if (acronymOrgan.isEmpty) return;

    final docRef = await _firestore.collection('organ').add({
      'acronymOrgan': acronymOrgan,
      'dateCreateOrgan': DateTime.now(),
      'dateUpdateOrgan': DateTime.now(),
      'statusOrgan': 'ativo',
    });

    await docRef.update({'uidOrgan': docRef.id});
    await loadOrgans();
  }

  /// Cria diretoria
  Future<void> createDirectors({
    required String idOrgan,
    required String acronymDirectors,
  }) async {
    if (idOrgan.isEmpty || acronymDirectors.isEmpty) {
      print('ID do órgão ou sigla da diretoria está vazio');
      return;
    }

    final docRef = await _firestore
        .collection('organ')
        .doc(idOrgan)
        .collection('directors')
        .add({
      'acronymDirectors': acronymDirectors,
      'descriptionDirectors': '',
      'dateCreateDirectors': DateTime.now(),
      'dateUpdateDirectors': DateTime.now(),
      'statusDirectors': 'ativo',
      'idOrgao': idOrgan,
    });

    await docRef.update({'idDirectors': docRef.id});
    await loadDirectors(idOrgan);
  }

  /// Cria setor
  Future<void> createSector({
    required String idOrgan,
    required String idDirectors,
    required String acronymSectors,
  }) async {
    final docRef = await _firestore
        .collection('organ')
        .doc(idOrgan)
        .collection('directors')
        .doc(idDirectors)
        .collection('sectors')
        .add({
      'acronymSectors': acronymSectors,
      'descriptionSector': '',
      'dateCreateSectors': DateTime.now(),
      'dateUpdateSectors': DateTime.now(),
      'statusSectors': 'ativo',
      'idOrgan': idOrgan,
      'idDirectors': idDirectors,
    });

    await docRef.update({'idSectors': docRef.id});
    await loadSectors(idOrgan: idOrgan, idDirectors: idDirectors);
  }

  Future<List<SystemData>> loadStructureWithPermissions(UserData user) async {
    final organs = await loadOrgans();

    // Paraleliza carregamento de diretorias e setores
    await Future.wait(organs.map((organ) async {
      organ.isSelectedOrgan = user.permissionOrgan?.contains(organ.idOrgan) ?? false;

      final directors = await loadDirectors(organ.idOrgan ?? '');
      organ.directors = directors;

      await Future.wait(directors.map((director) async {
        director.isSelectedDirector = user.permissionDirector?.contains(director.idDirectors) ?? false;

        final sectors = await loadSectors(
          idOrgan: organ.idOrgan ?? '',
          idDirectors: director.idDirectors ?? '',
        );
        director.sectors = sectors;

        for (final sector in sectors) {
          sector.isSelectedSector = user.permissionSector?.contains(sector.idSector) ?? false;
        }
      }));
    }));

    return organs;
  }


}
