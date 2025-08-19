import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../_widgets/background/background_cleaner.dart';
import '../../../commons/footBar/foot_bar.dart';
import '../../../commons/upBar/up_bar.dart';
import 'accidents_controller.dart';
import 'accidents_form_section.dart';
import 'accidents_selector_dates_section.dart';
import 'accidents_table_section.dart';

class AccidentsRecordsPage extends StatefulWidget {
  const AccidentsRecordsPage({super.key});

  @override
  State<AccidentsRecordsPage> createState() => _AccidentsRecordsPageState();
}

class _AccidentsRecordsPageState extends State<AccidentsRecordsPage> {
  late final AccidentsController c = AccidentsController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => c.postFrameInit(context));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: c,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            const BackgroundClean(),
            Column(
              children: [
                Expanded(
                  child: Consumer<AccidentsController>(
                    builder: (_, ctrl, __) {
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const UpBar(),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              child: Row(
                                children: const [
                                  Expanded(child: Divider(color: Colors.grey)),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('Cadastrar acidentes', style: TextStyle(fontSize: 16)),
                                  ),
                                  Expanded(child: Divider(color: Colors.grey)),
                                ],
                              ),
                            ),
                            // Formulário
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 9.0),
                              child: AccidentsFormSection(
                                isEditable: ctrl.isEditable,
                                formValidated: ctrl.formValidated,
                                currentAccidentId: ctrl.currentAccidentId,
                                orderCtrl: ctrl.orderCtrl,
                                dateCtrl: ctrl.dateCtrl,
                                highwayCtrl: ctrl.highwayCtrl,
                                cityCtrl: ctrl.cityCtrl,
                                typeOfAccidentCtrl: ctrl.typeOfAccidentCtrl,
                                deathCtrl: ctrl.deathCtrl,
                                scoresVictimsCtrl: ctrl.scoresVictimsCtrl,
                                transportInvolvedCtrl: ctrl.transportInvolvedCtrl,
                                latitudeCtrl: ctrl.latitudeCtrl,
                                longitudeCtrl: ctrl.longitudeCtrl,
                                postalCodeCtrl: ctrl.postalCodeCtrl,
                                streetCtrl: ctrl.streetCtrl,
                                city2Ctrl: ctrl.city2Ctrl,
                                subLocalityCtrl: ctrl.subLocalityCtrl,
                                administrativeAreaCtrl: ctrl.administrativeAreaCtrl,
                                countryCtrl: ctrl.countryCtrl,
                                isoCountryCodeCtrl: ctrl.isoCountryCodeCtrl,
                                onSave: () async {
                                  final ok = await ctrl.confirm(context, 'Deseja salvar este acidente?');
                                  if (ok) await ctrl.saveOrUpdate(context);
                                },
                                onClear: ctrl.createNew,
                                onGetLocation: () => ctrl.fillFromUserLocation(context),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Seletor de Datas (usa universo completo)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: AccidentsSelectorDatesSection(
                                allAccidents: ctrl.selectorUniverse,
                                initialYear: ctrl.selectedYear,     // <- pode ser null (Todos os anos)
                                initialMonth: ctrl.selectedMonth,   // <- pode ser null (Todos os meses)
                                onSelectionChanged: (res) async {
                                  final y = res.selectedYear, m = res.selectedMonth;
                                  if (y == ctrl.selectedYear && m == ctrl.selectedMonth) return;
                                  await ctrl.applyDateFilter(
                                    year: y,
                                    month: m,
                                    resetToFirstPage: true,
                                    source: 'selector',
                                  );
                                },
                              ),

                            ),

                            if (ctrl.pageItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('Nenhum acidente encontrado'),
                              )
                            else ...[
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: const [
                                    Expanded(child: Divider(color: Colors.grey)),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12),
                                      child: Text('Acidentes cadastrados no sistema', style: TextStyle(fontSize: 16)),
                                    ),
                                    Expanded(child: Divider(color: Colors.grey)),
                                  ],
                                ),
                              ),
                              AccidentsTableSection(
                                listData: ctrl.pageItems,
                                selectedItem: ctrl.selectedAccident,
                                currentPage: ctrl.currentPage,
                                totalPages: ctrl.totalPages,
                                onPageChange: ctrl.loadPage, // paginação local
                                onTapItem: (item) {
                                  final idx = ctrl.pageItems.indexOf(item);
                                  if (idx != -1) ctrl.selectFromTable(item, idx);
                                },
                                onDelete: (id) async {
                                  final ok = await ctrl.confirm(context, 'Deseja apagar este acidente?');
                                  if (ok) await ctrl.deleteAccident(context, id);
                                },
                              ),
                            ],
                            const SizedBox(height: 12),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const FootBar(),
              ],
            ),

            // Overlay de "salvando..."
            Consumer<AccidentsController>(
              builder: (_, ctrl, __) => ctrl.isSaving
                  ? Stack(
                children: [
                  ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.4)),
                  const Center(child: CircularProgressIndicator()),
                ],
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
