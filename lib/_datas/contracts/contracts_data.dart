// ignore_for_file: unused_import

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

class ContractData extends ChangeNotifier {
  ///Informações do contrato
  String? uid;
  String? managerid;
  String? contractnumber;
  String? maincontracthighway;
  String? restriction;
  String? contractservices;
  String? contractmanagerartnumber;
  String? summarysubjectcontract;
  String? regionofstate;
  String? managerphonenumber;
  String? contractcompanyleader;
  String? generalnumber;
  String? contractbiddingprocessnumber;
  String? automaticnumbersiafe;
  double? fisicalpercentage;
  String? regionalmanager;
  String? contractstatus;
  String? contractobjectdescription;
  String? contracttype;
  String? contractcompaniesinvolved;
  String? urlpdf;
  String? cnonumber;

  int? cnpjnumber;
  int? initialvalidityexecutiondays;
  int? initialvaliditycontractdays;
  int? cpfcontractmanager;

  bool? existecontrato;

  DateTime? initialvalidityexecutiondate;
  DateTime? initialvaliditycontractdate;
  DateTime? datapublicacaodoe;
  double? valorinicialdocontrato;
  double? financialpercentage;
  double? contractextkm;

  ContractData({
    this.uid,
    this.managerid,
    this.summarysubjectcontract,
    this.contractnumber,
    this.maincontracthighway,
    this.restriction,
    this.contractservices,
    this.contractmanagerartnumber,
    this.contractextkm,
    this.regionofstate,
    this.managerphonenumber,
    this.contractcompanyleader,
    this.generalnumber,
    this.contractbiddingprocessnumber,
    this.automaticnumbersiafe,
    this.fisicalpercentage,
    this.regionalmanager,
    this.contractstatus,
    this.contractobjectdescription,
    this.contracttype,
    this.contractcompaniesinvolved,
    this.urlpdf,
    this.initialvalidityexecutiondays,
    this.initialvaliditycontractdays,
    this.cpfcontractmanager,
    this.cnonumber,
    this.cnpjnumber,
    this.existecontrato,
    this.initialvalidityexecutiondate,
    this.datapublicacaodoe,
    this.valorinicialdocontrato,
    this.initialvaliditycontractdate,
    this.financialpercentage,
});

  ///Recuperando informações no banco de dados
  factory ContractData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) {
      throw Exception("Contrato não encontrado");
    }

    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception("Os dados do contrato estão vazios");
    }

    return ContractData(
      uid: snapshot.id,
      contractnumber: data['contractnumber'].toString(),
      summarysubjectcontract: data['summarysubjectcontract'].toString(),
      contractbiddingprocessnumber: data['contractbiddingprocessnumber'].toString(),
      managerid: data['managerid'].toString(),
      maincontracthighway: data['maincontracthighway'].toString(),
      restriction: data['restriction'].toString(),
      contractservices: data['services'].toString(),
      contractmanagerartnumber: data['contractmanagerartnumber'].toString(),
      regionofstate: data['regionofstate'].toString(),
      managerphonenumber: data['managerphonenumber'].toString(),
      contractcompanyleader: data['companyleader'].toString(),
      generalnumber: data['generalnumber'].toString(),
      automaticnumbersiafe: data['automaticnumbersiafe'].toString(),
      regionalmanager: data['regionalmanager'].toString(),
      contractstatus: data['contractstatus'].toString(),
      contractobjectdescription: data['objectcontractdescription'].toString(),
      contracttype: data['contracttype'].toString(),
      contractcompaniesinvolved: data['companiesinvolved'].toString(),
      urlpdf: data['urlpdf'].toString(),
      cnonumber: data['cnonumber'],

      initialvalidityexecutiondate: data['initialvalidityexecutiondate'].toDate() as DateTime,
      datapublicacaodoe: data['datapublicacaodoe'].toDate() as DateTime,
      initialvaliditycontractdate: data['initialvaliditycontractdate'].toDate() as DateTime,

      valorinicialdocontrato: data['valorinicialdocontrato'].toDouble() ?? 0.0,
      fisicalpercentage: data['fisicalpercentage'].toDouble() ?? 0.0,
      financialpercentage: data['financialpercentage'].toDouble() ?? 0.0,
      contractextkm: data['extkm'].toDouble() ?? 0.0,

      cnpjnumber: (data['cnpjnumber'] as num).toInt(),
      cpfcontractmanager: (data['cpfcontractmanager'] as num).toInt(),
      initialvalidityexecutiondays: (data['initialvalidityexecutiondays'] as num).toInt(),
      initialvaliditycontractdays: (data['initialvaliditycontractdays'] as num).toInt(),

      existecontrato: data['existecontrato'],

    );
  }

}
