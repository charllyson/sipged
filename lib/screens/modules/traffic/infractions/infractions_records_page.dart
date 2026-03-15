import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/windows/show_window_dialog.dart';

import '../../../../_blocs/modules/transit/infractions/infractions_bloc.dart';
import '../../../../_widgets/background/background_cleaner.dart';
import '../../../../_blocs/modules/transit/infractions/infractions_controller.dart';

// SEÇÕES
import 'infractions_form_section.dart';
import 'infractions_selector_dates_section.dart';
import 'infractions_table_section.dart';

// MAPA + OVERLAY (mesmo padrão usado em Acidentes)
import 'package:sipged/_widgets/map/flutter_map/map_interactive.dart';

class InfractionsRecordsPage extends StatefulWidget {
  const InfractionsRecordsPage({super.key});

  @override
  State<InfractionsRecordsPage> createState() => _InfractionsRecordsPageState();
}

class _InfractionsRecordsPageState extends State<InfractionsRecordsPage> {
  late final InfractionsController c = InfractionsController(
    bloc: InfractionsBloc(),
  );

  // Altura medida do formulário (desktop) para igualar o mapa dinamicamente
  double? _formHeight;
  static const double _minDeskHeight = 420;

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
                    builder: (_, ctrl, _) {
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const UpBar(),
                            SectionTitle(text: 'Cadastrar infrações de trânsito no sistema'),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 9.0),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final maxW = constraints.maxWidth;
                                  final isSmall = maxW <= 900;
                                  final double leftWidth  = isSmall ? maxW : (maxW - 12) / 2;
                                  final double rightWidth = isSmall ? maxW : (maxW - 12) / 2;

                                  if (isSmall) {
                                    // ===== MOBILE =====
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        InfractionsFormSection(
                                          itemsPerLineOverride: 1,
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
                                            final ok = await confirmDialog(context, 'Deseja salvar esta infração?');
                                            if (ok) await ctrl.saveOrUpdate(context);
                                          },
                                          onClear: ctrl.createNew,
                                          onGetLocation: () => ctrl.fillFromUserLocation(context),
                                        ),
                                        const SizedBox(height: 12),

                                        // Mapa no mobile (altura fixa confortável)
                                        SizedBox(
                                          width: double.infinity,
                                          height: 380,
                                          child: Card(
                                            elevation: 6,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: MapInteractivePage(
                                              initialZoom: 9,
                                              activeMap: true,
                                              showLegend: true,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  // ===== DESKTOP =====
                                  double mapH = _formHeight ?? _minDeskHeight;

                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // COLUNA ESQUERDA: FORM (altura natural medido por _SizeReporter)
                                      SizedBox(
                                        width: leftWidth,
                                        child: _SizeReporter(
                                          onSize: (size) {
                                            final h = size.height;
                                            if (_formHeight != h) {
                                              setState(() => _formHeight = h);
                                            }
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: InfractionsFormSection(
                                              itemsPerLineOverride: 2,
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
                                                final ok = await confirmDialog(context, 'Deseja salvar esta infração?');
                                                if (ok) await ctrl.saveOrUpdate(context);
                                              },
                                              onClear: ctrl.createNew,
                                              onGetLocation: () => ctrl.fillFromUserLocation(context),
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // COLUNA DIREITA: MAPA (segue a altura do form, com mínimo)
                                      SizedBox(
                                        width: rightWidth,
                                        height: mapH < _minDeskHeight ? _minDeskHeight : mapH,
                                        child: MapInteractivePage(
                                          initialZoom: 9,
                                          activeMap: true,
                                          showLegend: true,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            SectionTitle(text: 'Filtrar por data infrações de trânsito'),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: InfractionsSelectorDatesSection(
                                allInfractions: ctrl.selectorUniverseAll,
                                initialYear: ctrl.selectedYear,
                                initialMonth: ctrl.selectedMonth,
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

                            // ======= TABELA =======
                            if (ctrl.pageItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('Nenhuma infração encontrada'),
                              )
                            else ...[
                              SectionTitle(text: 'Infrações cadastradas no sistema'),
                              InfractionsTableSection(
                                listData: ctrl.pageItems,
                                selectedItem: ctrl.selectedInfraction,
                                onTapItem: (item) {
                                  final idx = ctrl.pageItems.indexOf(item);
                                  if (idx != -1) ctrl.selectFromTable(item, idx);
                                },
                                onDelete: (id) async {
                                  final ok = await confirmDialog(context, 'Deseja apagar esta infração?');
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
              builder: (_, ctrl, _) => ctrl.isSaving
                  ? Stack(
                children: [
                  ModalBarrier(dismissible: false, color: Colors.black.withValues(alpha: 0.4)),
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

/// Widget auxiliar para medir o tamanho do filho após o layout
class _SizeReporter extends StatefulWidget {
  const _SizeReporter({required this.child, required this.onSize});
  final Widget child;
  final ValueChanged<Size> onSize;

  @override
  State<_SizeReporter> createState() => _SizeReporterState();
}

class _SizeReporterState extends State<_SizeReporter> {
  Size? _old;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.size;
      if (s != null && s != _old) {
        _old = s;
        widget.onSize(s);
      }
    });
    return widget.child;
  }
}
