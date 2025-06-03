import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sisgeo/_datas/contracts/contracts_data.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';

import '../../../_widgets/input/custom_text_field.dart';
import '../../../_widgets/input/custom_text_max_lines_field.dart';

class MainInformationPage extends StatelessWidget {
  const MainInformationPage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              CustomTextField(
                labelText: 'Nº do processo',
                initialValue: contractData?.contractbiddingprocessnumber ?? '',
              ),
              CustomTextField(
                labelText: 'Nº SIAFE',
                initialValue: contractData?.automaticnumbersiafe ?? '',
              ),
              CustomTextField(
                labelText: 'Tipo de contrato',
                initialValue: contractData?.contracttype ?? '',
              ),
              CustomTextField(
                labelText: 'Nº do contrato',
                initialValue: contractData?.contractnumber ?? '',
              ),
              CustomTextField(
                labelText: 'Resumo do objeto do contrato',
                initialValue: contractData?.summarysubjectcontract ?? '',
              ),
              CustomTextField(
                labelText: 'Serviço',
                initialValue: contractData?.contractservices ?? '',
              ),
              CustomTextField(
                labelText: 'Rodovia',
                initialValue: contractData?.maincontracthighway ?? '',
              ),
              CustomTextField(
                labelText: 'Extensão',
                initialValue: contractData?.contractextkm.toString() ?? '',
              ),
              CustomTextField(
                labelText: 'Região',
                initialValue: contractData?.regionofstate ?? '',
              ),
              CustomTextField(
                labelText: 'Status',
                initialValue: contractData?.contractstatus ?? '',
              ),
              CustomTextField(
                labelText: '% Financeiro',
                initialValue: contractData?.financialpercentage.toString() ?? '',
              ),
              CustomTextField(
                labelText: '% Físico',
                initialValue: contractData?.fisicalpercentage.toString() ?? '',
              ),
              CustomTextField(
                labelText: 'Latitude do início',
                initialValue: '',
              ),
              CustomTextField(
                labelText: 'Longitude do início',
                initialValue: '',
              ),
              CustomTextField(
                labelText: 'Latitude do final',
                initialValue: '',
              ),
              CustomTextField(
                labelText: 'Longitude do final',
                initialValue: '',
              ),
              CustomTextField(
                labelText: 'Empresa líder',
                initialValue: contractData?.contractcompanyleader ?? '',
              ),
              CustomTextField(
                labelText: 'Empresas envolvidas',
                initialValue: contractData?.contractcompaniesinvolved ?? '',
              ),
              CustomTextField(
                labelText: 'CNPJ',
                initialValue: contractData?.cnpjnumber.toString() ?? '',
              ),
              CustomTextField(
                labelText: 'CNO',
                initialValue: contractData?.cnonumber.toString() ?? '',
              ),
              CustomTextField(
                labelText: 'Gerente Regional',
                initialValue: contractData?.regionalmanager ?? '',
              ),
              CustomTextField(
                labelText: 'Data de publicação no DOE',
                initialValue: convertDateTimeToDDMMYYYY(contractData!.datapublicacaodoe!) ?? '',
              ),
              CustomTextField(
                labelText: 'Fiscal',
                initialValue: contractData?.managerid ?? '',
              ),
              CustomTextField(
                labelText: 'CPF do Responsável',
                initialValue: addFormatCpfDynamicToString(contractData?.cpfcontractmanager) ?? '',
              ),
              CustomTextField(
                labelText: 'Nº da ART',
                initialValue: contractData?.contractmanagerartnumber ?? '',
              ),
              CustomTextField(
                labelText: 'Telefone do fiscal',
                initialValue: contractData?.managerphonenumber ?? '',
              ),
              CustomTextField(
                labelText: 'Valor contratado',
                initialValue: contractData?.valorinicialdocontrato.toString() ?? '',
              ),
              CustomTextMaxLinesField(
                labelText: 'Descrição do objeto',
                maxLines: 5,
                maxLength: 200,
                initialValue: contractData?.contractobjectdescription ?? '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
