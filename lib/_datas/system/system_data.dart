import 'package:cloud_firestore/cloud_firestore.dart';

class SystemData {
  // Campos do banco
  final String? idOrgan;
  final String? descriptionOrgan;
  final String? acronymOrgan;
  final DateTime? dateCreateOrgan;
  final DateTime? dateUpdateOrgan;
  final String? statusOrgan;

  final String? idDirectors;
  final String? descriptionDirectors;
  final String? acronymDirectors;
  final DateTime? dateCreateDirectors;
  final DateTime? dateUpdateDirectors;
  final String? statusDirectors;

  final String? idSector;
  final String? descriptionSectors;
  final String? acronymSectors;
  final DateTime? dateCreateSectors;
  final DateTime? dateUpdateSectors;
  final String? statusSector;

  // ✅ Campos auxiliares para checkbox
  bool isSelectedOrgan;
  bool isSelectedDirector;
  bool isSelectedSector;

  // ✅ Relacionamentos
  List<SystemData>? directors;
  List<SystemData>? sectors;

  SystemData({
    this.idOrgan,
    this.descriptionOrgan,
    this.acronymOrgan,
    this.dateCreateOrgan,
    this.dateUpdateOrgan,
    this.statusOrgan,
    this.idDirectors,
    this.descriptionDirectors,
    this.acronymDirectors,
    this.dateCreateDirectors,
    this.dateUpdateDirectors,
    this.statusDirectors,
    this.idSector,
    this.descriptionSectors,
    this.acronymSectors,
    this.dateCreateSectors,
    this.dateUpdateSectors,
    this.statusSector,
    this.directors,
    this.sectors,
    this.isSelectedOrgan = false,
    this.isSelectedDirector = false,
    this.isSelectedSector = false,
  });


  factory SystemData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SystemData(
      idOrgan: doc.id,
      descriptionOrgan: data['descriptionOrgan'] as String? ?? '',
      acronymOrgan: data['acronymOrgan'] as String? ?? '',
      dateCreateOrgan: (data['dateCreateOrgan'] as Timestamp?)?.toDate(),
      dateUpdateOrgan: (data['dateUpdateOrgan'] as Timestamp?)?.toDate(),
      statusOrgan: data['statusOrgan'] as String? ?? '',

      idDirectors: doc.id,
      descriptionDirectors: data['descriptionDirectors'] as String? ?? '',
      acronymDirectors: data['acronymDirectors'] as String? ?? '',
      dateCreateDirectors: (data['dateCreateDirectors'] as Timestamp?)?.toDate(),
      dateUpdateDirectors: (data['dateUpdateDirectors'] as Timestamp?)?.toDate(),
      statusDirectors: data['statusDirectors'] as String? ?? '',

      idSector: doc.id,
      descriptionSectors: data['descriptionSectors'] as String? ?? '',
      acronymSectors: data['acronymSectors'] as String? ?? '',
      dateCreateSectors: (data['dateCreateSectors'] as Timestamp?)?.toDate(),
      dateUpdateSectors: (data['dateUpdateSectors'] as Timestamp?)?.toDate(),
      statusSector: data['statusSector'] as String? ?? '',

    );
  }


  Map<String, dynamic> toMap() {
    return {
      'idOrgan': idOrgan,
      'descriptionOrgan': descriptionOrgan,
      'acronymOrgan': acronymOrgan,
      'idDirectors': idDirectors,
      'descriptionDirectors': descriptionDirectors,
      'acronymDirectors': acronymDirectors,
      'idSector': idSector,
      'descriptionSectors': descriptionSectors,
      'acronymSectors': acronymSectors,
    };
  }

  @override
  String toString() {
    return 'SystemData(Organ: $acronymOrgan, Directors: $acronymDirectors, Sector: $acronymSectors)';
  }
}
