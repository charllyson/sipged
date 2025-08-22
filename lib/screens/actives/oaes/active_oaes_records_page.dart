import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sisged/_utils/date_utils.dart';
import 'package:sisged/_widgets/background/background_cleaner.dart';

import 'package:sisged/_datas/actives/oaes/active_oaes_store.dart'; // Store das OAEs
import 'package:sisged/_datas/documents/contracts/contracts/contract_data.dart';
import 'package:sisged/_widgets/charts/barGraph/bar_chart_changed.dart';
import 'package:sisged/_widgets/charts/pieGraph/pie_chart_changed.dart';
import 'package:sisged/_widgets/texts/divider_text.dart';
import 'package:sisged/_widgets/validates/form_validation_mixin.dart';
import 'package:sisged/_blocs/system/user_provider.dart';
import 'package:sisged/screens/commons/footBar/foot_bar.dart';

import 'active_oaes_controller.dart';
import 'active_oaes_form.dart';
import 'active_oaes_records_table_section.dart';

class ActiveOaesRecordsPage extends StatefulWidget {
  const ActiveOaesRecordsPage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  State<ActiveOaesRecordsPage> createState() => _ActiveOaesRecordsPageState();
}

class _ActiveOaesRecordsPageState extends State<ActiveOaesRecordsPage>
    with FormValidationMixin {
  final _orderCtrl = TextEditingController();
  final _scoreCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _roadCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _extensionCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _structureCtrl = TextEditingController();
  final _contractsCtrl = TextEditingController();
  final _linearCostCtrl = TextEditingController();
  final _estimateCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _latitudeCtrl = TextEditingController();
  final _longitudeCtrl = TextEditingController();
  final _altitudeCtrl = TextEditingController();

  int? _selectedLine;
  bool _didInit = false; // evita init repetido

  @override
  void initState() {
    super.initState();
    setupValidation(
      [_orderCtrl, _nameCtrl, _latitudeCtrl, _longitudeCtrl],
      _onUiChangedValidateForm,
    );
  }

  void _onUiChangedValidateForm() {
    final ctrl = context.read<ActiveOaesController>();
    ctrl.updateField<int>(int.tryParse(_orderCtrl.text), (v) => ctrl.form.order = v);
    ctrl.updateField<String>(_nameCtrl.text, (v) => ctrl.form.identificationName = v);
    ctrl.updateField<double>(double.tryParse(_latitudeCtrl.text), (v) => ctrl.form.latitude = v);
    ctrl.updateField<double>(double.tryParse(_longitudeCtrl.text), (v) => ctrl.form.longitude = v);
  }

  @override
  void dispose() {
    removeValidation(
      [_orderCtrl, _nameCtrl, _latitudeCtrl, _longitudeCtrl],
      _onUiChangedValidateForm,
    );
    _orderCtrl.dispose();
    _scoreCtrl.dispose();
    _stateCtrl.dispose();
    _roadCtrl.dispose();
    _regionCtrl.dispose();
    _nameCtrl.dispose();
    _extensionCtrl.dispose();
    _widthCtrl.dispose();
    _areaCtrl.dispose();
    _structureCtrl.dispose();
    _contractsCtrl.dispose();
    _linearCostCtrl.dispose();
    _estimateCtrl.dispose();
    _companyCtrl.dispose();
    _dateCtrl.dispose();
    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    _altitudeCtrl.dispose();
    super.dispose();
  }

  void _fillUiFromForm(ActiveOaesController c) {
    _orderCtrl.text     = (c.form.order ?? '').toString();
    _nameCtrl.text      = c.form.identificationName ?? '';
    _latitudeCtrl.text  = (c.form.latitude ?? '').toString();
    _longitudeCtrl.text = (c.form.longitude ?? '').toString();
    _scoreCtrl.text     = (c.form.score ?? '').toString();
    _stateCtrl.text     = c.form.state ?? '';
    _roadCtrl.text      = c.form.road ?? '';
    _regionCtrl.text    = c.form.region ?? '';
    _extensionCtrl.text = (c.form.extension ?? '').toString();
    _widthCtrl.text     = (c.form.width ?? '').toString();
    _areaCtrl.text      = (c.form.area ?? '').toString();
    _structureCtrl.text = c.form.structureType ?? '';
    _contractsCtrl.text = c.form.relatedContracts ?? '';
    _linearCostCtrl.text= (c.form.linearCostMedia ?? '').toString();
    _estimateCtrl.text  = (c.form.costEstimate ?? '').toString();
    _companyCtrl.text   = c.form.companyBuild ?? '';
    _dateCtrl.text      = c.form.lastDateIntervention != null
        ? convertDateTimeToDDMMYYYY(c.form.lastDateIntervention!)
        : '';
    _altitudeCtrl.text  = (c.form.altitude ?? '').toString();
  }


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ActiveOaesController>(
      create: (ctx) => ActiveOaesController(
        store: ctx.read<ActiveOaesStore>(),
        currentUser: context.read<UserProvider>().userData!, // ✅ apenas o Store (sem UserBloc)
      ),
      builder: (context, _) {
        final c = context.watch<ActiveOaesController>();

        if (!_didInit) {
          _didInit = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final user = context.read<UserProvider>().userData;
            if (user != null) {
              await context.read<ActiveOaesController>().init(user);
            }
          });
        }

        // Reflete form -> UI sem loops
        WidgetsBinding.instance.addPostFrameCallback((_) => _fillUiFromForm(c));

        final oaesValue = c.all.map((e) => e.valueIntervention ?? 0).toList(growable: false);
        final oaesOrder = c.all.map((e) => (e.order ?? '').toString()).toList(growable: false);

        return Stack(
          children: [
            const BackgroundClean(),
            Column(
              children: [
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        const DividerText(title: 'Cadastrar OAE no sistema'),
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          child: ActiveOaesForm(),
                        ),
                        const SizedBox(height: 12),
                        const DividerText(title: 'Gráfico das OAEs cadastradas'),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              PieChartChanged(
                                labels: oaesOrder,
                                values: oaesValue,
                                selectedIndex: _selectedLine,
                                larguraGrafico: 300,
                                onTouch: (index) {
                                  if (index == null) return;
                                  setState(() {
                                    _selectedLine = index;
                                    c.selectByIndex(index);
                                  });
                                },
                              ),
                              const SizedBox(width: 12),
                              BarChartChanged(
                                selectedIndex: _selectedLine,
                                labels: oaesOrder,
                                values: oaesValue,
                                onBarTap: (label) {
                                  final index = c.all.indexWhere(
                                        (e) => (e.order ?? '').toString() == label,
                                  );
                                  if (index != -1) {
                                    setState(() {
                                      _selectedLine = index;
                                      c.selectByIndex(index);
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const DividerText(title: 'OAEs cadastradas no sistema'),
                        const SizedBox(height: 12),
                        ActiveOaesRecordsTableSection(
                          onTapItem: (item) {
                            final idx = c.all.indexWhere((e) => e.id == item.id);
                            if (idx != -1) {
                              setState(() => _selectedLine = idx);
                              c.selectByIndex(idx);
                            }
                          },
                          onDelete: (id) async {
                            final err = await c.deleteById(id);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err ?? 'OAE deletado com sucesso!'),
                                backgroundColor: err == null ? Colors.red : Colors.orange,
                              ),
                            );
                          },
                          futureOaes: Future.value(c.all),
                        ),
                      ],
                    ),
                  ),
                ),
                const FootBar(),
              ],
            ),
            if (c.saving)
              Stack(
                children: [
                  ModalBarrier(
                    dismissible: false,
                    color: Colors.black.withOpacity(0.4),
                  ),
                  const Center(child: CircularProgressIndicator()),
                ],
              ),
          ],
        );
      },
    );
  }
}
