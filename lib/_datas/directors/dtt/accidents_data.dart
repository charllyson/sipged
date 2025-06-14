import 'package:latlong2/latlong.dart';

class AccidentsData {
  final int? idAccident;
  final DateTime? dataAccident;
  final String? workstationAccident;
  final String? highwayAccident;
  final String? typeAccident;
  final LatLng? accidentLatLng;
  final String? accidentDescription;
  final String? accidentCause;
  final String? accidentSeverity;
  final List<String>? accidentVehicles;
  final String? accidentDead;
  final String? accidentVehiclesType;
  final String? accidentVehiclesBrand;
  final String? accidentVehiclesModel;
  final String? accidentVehiclesColor;

  AccidentsData({
    this.idAccident,
    this.dataAccident,
    this.workstationAccident,
    this.highwayAccident,
    this.typeAccident,
    this.accidentLatLng,
    this.accidentDescription,
    this.accidentCause,
    this.accidentSeverity,
    this.accidentVehicles,
    this.accidentDead,
    this.accidentVehiclesType,
    this.accidentVehiclesBrand,
    this.accidentVehiclesModel,
    this.accidentVehiclesColor,
  });

  factory AccidentsData.fromFeature(Map<String, dynamic> feature) {
    return AccidentsData(
      idAccident: feature['id'],
      dataAccident: DateTime.parse(feature['dataAccident']),
      workstationAccident: feature['workstationAccident'],
      highwayAccident: feature['highwayAccident'],
      typeAccident: feature['typeAccident'],
      accidentLatLng: LatLng(feature['accidentLatLng']['latitude'], feature['accidentLatLng']['longitude']),
      accidentDescription: feature['accidentDescription'],
      accidentCause: feature['accidentCause'],
      accidentSeverity: feature['accidentSeverity'],
      accidentVehicles: feature['accidentVehicles'],
      accidentDead: feature['accidentDead'],
      accidentVehiclesType: feature['accidentVehiclesType'],
      accidentVehiclesBrand: feature['accidentVehiclesBrand'],
      accidentVehiclesModel: feature['accidentVehiclesModel'],
      accidentVehiclesColor: feature['accidentVehiclesColor'],

    );
  }
}
