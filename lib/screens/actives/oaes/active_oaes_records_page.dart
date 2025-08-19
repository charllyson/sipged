import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sisged/_widgets/background/background_cleaner.dart';

import '../../../_blocs/system/user_bloc.dart';
import '../../../_datas/actives/oaes/active_oaes_store.dart'; // ⬅️ importa o store
import '../../../_datas/documents/contracts/contracts/contract_data.dart';
import '../../../_widgets/charts/barGraph/bar_chart_changed.dart';
import '../../../_widgets/charts/pieGraph/pie_chart_changed.dart';
import '../../../../_widgets/texts/divider_text.dart';
import '../../../../_widgets/validates/form_validation_mixin.dart';
import '../../commons/footBar/foot_bar.dart';
import '../../../_provider/user/user_provider.dart';
import '../../../../_utils/date_utils.dart';

import 'active_oaes_controller.dart';
import 'active_oaes_form.dart';
import 'active_oaes_records_table_section.dart';

class ActiveOaesRecordsPage extends StatefulWidget {
  const ActiveOaesRecordsPage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  State<ActiveOaesRecordsPage> createState() => _ActiveOaesRecordsPageState();
}

class _ActiveOaesRecordsPageState extends State<ActiveOaesRecordsPage> with FormValidationMixin {
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
    removeValidation([_orderCtrl, _nameCtrl, _latitudeCtrl, _longitudeCtrl], _onUiChangedValidateForm);
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
    _orderCtrl.text = (c.form.order ?? '').toString();
    _nameCtrl.text = c.form.identificationName ?? '';
    _latitudeCtrl.text = (c.form.latitude ?? '').toString();
    _longitudeCtrl.text = (c.form.longitude ?? '').toString();
    _scoreCtrl.text = (c.form.score ?? '').toString();
    _stateCtrl.text = c.form.state ?? '';
    _roadCtrl.text = c.form.road ?? '';
    _regionCtrl.text = c.form.region ?? '';
    _extensionCtrl.text = (c.form.extension ?? '').toString();
    _widthCtrl.text = (c.form.width ?? '').toString();
    _areaCtrl.text = (c.form.area ?? '').toString();
    _structureCtrl.text = c.form.structureType ?? '';
    _contractsCtrl.text = c.form.relatedContracts ?? '';
    _linearCostCtrl.text = (c.form.linearCostMedia ?? '').toString();
    _estimateCtrl.text = (c.form.costEstimate ?? '').toString();
    _companyCtrl.text = c.form.companyBuild ?? '';
    _dateCtrl.text = c.form.lastDateIntervention != null
        ? convertDateTimeToDDMMYYYY(c.form.lastDateIntervention!)
        : '';
    _altitudeCtrl.text = (c.form.altitude ?? '').toString();
  }

  void _pushOptionalFieldsToForm(ActiveOaesController c) {
    c.updateField<double>(double.tryParse(_scoreCtrl.text), (v) => c.form.score = v);
    c.updateField<String>(_stateCtrl.text, (v) => c.form.state = v);
    c.updateField<String>(_roadCtrl.text, (v) => c.form.road = v);
    c.updateField<String>(_regionCtrl.text, (v) => c.form.region = v);
    c.updateField<double>(double.tryParse(_extensionCtrl.text), (v) => c.form.extension = v);
    c.updateField<double>(double.tryParse(_widthCtrl.text), (v) => c.form.width = v);
    c.updateField<double>(double.tryParse(_areaCtrl.text), (v) => c.form.area = v);
    c.updateField<String>(_structureCtrl.text, (v) => c.form.structureType = v);
    c.updateField<String>(_contractsCtrl.text, (v) => c.form.relatedContracts = v);
    c.updateField<double>(double.tryParse(_linearCostCtrl.text), (v) => c.form.linearCostMedia = v);
    c.updateField<double>(double.tryParse(_estimateCtrl.text), (v) => c.form.costEstimate = v);
    c.updateField<String>(_companyCtrl.text, (v) => c.form.companyBuild = v);
    c.updateField<DateTime>(
      _dateCtrl.text.isNotEmpty ? convertDDMMYYYYToDateTime(_dateCtrl.text) : null,
          (v) => c.form.lastDateIntervention = v,
    );
    c.updateField<double>(double.tryParse(_altitudeCtrl.text), (v) => c.form.altitude = v);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ActiveOaesController>(
      create: (ctx) => ActiveOaesController(
        store: ctx.read<ActiveOaesStore>(),     // ⬅️ injeta o store
        userBloc: ctx.read<UserBloc>(),   // (opcional)
      ),
      builder: (context, _) {
        final c = context.watch<ActiveOaesController>();

        if (!_didInit) {
          _didInit = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final user = context.read<UserProvider>().userData;
            if (user != null) await context.read<ActiveOaesController>().init(user);
          });
        }

        // reflete form -> UI (sem loop, pois só escreve nos TextEditingControllers)
        WidgetsBinding.instance.addPostFrameCallback((_) => _fillUiFromForm(c));

        final oaesValue = c.all.map((e) => e.valueIntervention ?? 0).toList(growable: false);
        final oaesOrder = c.all.map((e) => (e.order ?? '').toString()).toList(growable: false);

        return Stack(
          children: [
            BackgroundClean(),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(err == null ? 'OAE deletado com sucesso!' : err),
                              backgroundColor: err == null ? Colors.red : Colors.orange,
                            ));
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
                  ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.4)),
                  const Center(child: CircularProgressIndicator()),
                ],
              ),
          ],
        );
      },
    );
  }


}
