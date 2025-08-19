import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../_widgets/background/background_cleaner.dart';
import '../../../commons/footBar/foot_bar.dart';
import '../../../commons/upBar/up_bar.dart';
import 'infractions_controller.dart';
import 'infractions_form_section.dart';
import 'infractions_selector_dates_section.dart';
import 'infractions_table_section.dart';

class InfractionsRecordsPage extends StatefulWidget {
  const InfractionsRecordsPage({super.key});

  @override
  State<InfractionsRecordsPage> createState() => _InfractionsRecordsPageState();
}

class _InfractionsRecordsPageState extends State<InfractionsRecordsPage> {
  late final InfractionsController c = InfractionsController();

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
                  child: Consumer<InfractionsController>(
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
                                    child: Text(
                                      'Cadastrar infrações de trânsito',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.grey)),
                                ],
                              ),
                            ),

                            // Formulário
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 9.0),
                              child: InfractionsFormSection(
                                isEditable: ctrl.isEditable,
                                formValidated: ctrl.formValidated,
                                currentInfractionId: ctrl.currentInfractionId,
                                orderCtrl: ctrl.orderCtrl,
                                aitNumberCtrl: ctrl.aitNumberCtrl,
                                dateCtrl: ctrl.dateCtrl,
                                timeCtrl: ctrl.timeCtrl,
                                codeCtrl: ctrl.codeCtrl,
                                descriptionCtrl: ctrl.descriptionCtrl,
                                organCodeCtrl: ctrl.organCodeCtrl,
                                organAuthorityCtrl: ctrl.organAuthorityCtrl,
                                addressCtrl: ctrl.addressCtrl,
                                bairroCtrl: ctrl.bairroCtrl,
                                latitudeCtrl: ctrl.latitudeCtrl,
                                longitudeCtrl: ctrl.longitudeCtrl,
                                onSave: () async {
                                  final ok = await ctrl.confirm(context, 'Deseja salvar esta infração?');
                                  if (ok) await ctrl.saveOrUpdate(context);
                                },
                                onClear: ctrl.createNew,
                                onGetLocation: () => ctrl.fillFromUserLocation(context),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Seletor de Datas
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: InfractionsSelectorDatesSection(
                                allInfractions: ctrl.selectorUniverseAll,
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
                                child: Text('Nenhuma infração encontrada'),
                              )
                            else ...[
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: const [
                                    Expanded(child: Divider(color: Colors.grey)),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12),
                                      child: Text('Infrações cadastradas no sistema', style: TextStyle(fontSize: 16)),
                                    ),
                                    Expanded(child: Divider(color: Colors.grey)),
                                  ],
                                ),
                              ),
                              InfractionsTableSection(
                                listData: ctrl.pageItems,
                                selectedItem: ctrl.selectedInfraction,
                                onTapItem: (item) {
                                  final idx = ctrl.pageItems.indexOf(item);
                                  if (idx != -1) ctrl.selectFromTable(item, idx);
                                },
                                onDelete: (id) async {
                                  final ok = await ctrl.confirm(context, 'Deseja apagar esta infração?');
                                  if (ok) await ctrl.deleteInfraction(context, id);
                                },
                                currentPage: ctrl.currentPage,
                                totalPages: ctrl.totalPages,
                                onPageChange: ctrl.loadPage, // paginação local, sem reset
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
            Consumer<InfractionsController>(
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
