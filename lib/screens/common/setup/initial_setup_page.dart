import 'dart:typed_data';
import 'dart:ui';

import 'package:brasil_fields/brasil_fields.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/setup/setup_cubit.dart';
import 'package:sipged/_blocs/system/setup/setup_data.dart';
import 'package:sipged/_blocs/system/setup/setup_state.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_blocs/system/notification/local/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/local/notification_data.dart';
import 'package:sipged/_blocs/system/notification/local/notification_type.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/dialog/windows/window_dialog.dart';
import 'package:sipged/screens/common/setup/initial_setup_form.dart';
import 'package:sipged/screens/common/setup/initial_setup_header.dart';
import 'package:sipged/screens/modules/contracts/hiring/1Dfd/setup_region_map.dart';

enum InitialSetupPresentationMode {
  dialog,
  page,
}

class InitialSetupPage extends StatefulWidget {
  final UserData user;
  final InitialSetupPresentationMode presentationMode;

  const InitialSetupPage({
    super.key,
    required this.user,
    this.presentationMode = InitialSetupPresentationMode.dialog,
  });

  bool get isDialog => presentationMode == InitialSetupPresentationMode.dialog;

  bool get isPage => presentationMode == InitialSetupPresentationMode.page;

  @override
  State<InitialSetupPage> createState() => _InitialSetupPageState();
}

class _InitialSetupPageState extends State<InitialSetupPage> {
  final _formKey = GlobalKey<FormState>();

  final _empresaFantasiaCtrl = TextEditingController();
  final _empresaNomeCtrl = TextEditingController();
  final _empresaCnpjCtrl = TextEditingController();

  final _newUnitCtrl = TextEditingController();
  final _newRoadCtrl = TextEditingController();
  final _newRegionCtrl = TextEditingController();
  final _newFundingCtrl = TextEditingController();
  final _newProgramCtrl = TextEditingController();
  final _newExpenseNatureCtrl = TextEditingController();

  List<String> _selectedMunicipios = [];

  Uint8List? _logoBytes;
  String? _logoFileName;
  String? _logoContentType;

  String? _existingLogoUrl;
  String? _existingLogoPath;
  bool _removeCurrentLogo = false;
  bool _saving = false;
  bool _hydratedFromState = false;

  SetupData? _selectedUnit;
  SetupData? _selectedRoad;
  SetupData? _selectedRegion;
  SetupData? _selectedFunding;
  SetupData? _selectedProgram;
  SetupData? _selectedExpenseNature;

  @override
  void initState() {
    super.initState();

    _newUnitCtrl.addListener(_refresh);
    _newRoadCtrl.addListener(_refresh);
    _newRegionCtrl.addListener(_refresh);
    _newFundingCtrl.addListener(_refresh);
    _newProgramCtrl.addListener(_refresh);
    _newExpenseNatureCtrl.addListener(_refresh);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SetupCubit>().loadSystemSetup();
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _newUnitCtrl.removeListener(_refresh);
    _newRoadCtrl.removeListener(_refresh);
    _newRegionCtrl.removeListener(_refresh);
    _newFundingCtrl.removeListener(_refresh);
    _newProgramCtrl.removeListener(_refresh);
    _newExpenseNatureCtrl.removeListener(_refresh);

    _empresaFantasiaCtrl.dispose();
    _empresaNomeCtrl.dispose();
    _empresaCnpjCtrl.dispose();
    _newUnitCtrl.dispose();
    _newRoadCtrl.dispose();
    _newRegionCtrl.dispose();
    _newFundingCtrl.dispose();
    _newProgramCtrl.dispose();
    _newExpenseNatureCtrl.dispose();

    super.dispose();
  }

  void _hydrateFromCompany(SetupData? company) {
    if (company == null) return;
    if (_hydratedFromState && _empresaNomeCtrl.text.isNotEmpty) return;

    _empresaFantasiaCtrl.text = company.fantasyName ?? '';
    _empresaNomeCtrl.text = company.companyName ?? company.label;
    _empresaCnpjCtrl.text = company.cnpj ?? company.cnpjCompanyContracted ?? '';
    _existingLogoUrl = company.logoUrl;
    _existingLogoPath = company.logoPath;
    _logoBytes = null;
    _logoFileName = null;
    _logoContentType = null;
    _removeCurrentLogo = false;
    _hydratedFromState = true;
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      withData: true,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
    );

    if (!mounted || result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      _error('Não foi possível ler a imagem selecionada.');
      return;
    }

    final ext = (file.extension ?? '').toLowerCase();

    String contentType = 'image/png';

    if (ext == 'jpg' || ext == 'jpeg') {
      contentType = 'image/jpeg';
    }

    if (ext == 'webp') {
      contentType = 'image/webp';
    }

    setState(() {
      _logoBytes = bytes;
      _logoFileName = file.name;
      _logoContentType = contentType;
      _removeCurrentLogo = false;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving) return;

    setState(() => _saving = true);

    final setup = context.read<SetupCubit>();

    final saved = await setup.saveCompanyProfile(
      label: _empresaNomeCtrl.text.trim(),
      fantasyName: _empresaFantasiaCtrl.text.trim(),
      cnpj: _empresaCnpjCtrl.text.trim(),
      logoBytes: _logoBytes,
      logoFileName: _logoFileName,
      logoContentType: _logoContentType,
      removeLogo: _removeCurrentLogo,
      oldLogoPath: _existingLogoPath,
    );

    if (!mounted) return;

    if (saved == null) {
      final msg =
          setup.state.error ?? 'Falha ao salvar configurações do sistema.';
      _error(msg);
      return;
    }

    await setup.reloadChildren();

    if (!mounted) return;

    if (setup.state.error != null) {
      _error(setup.state.error!);
      return;
    }

    setState(() {
      _saving = false;
      _hydrateFromCompany(saved);
    });

    _success('Configurações salvas com sucesso.');
  }

  void _error(String msg) {
    if (!mounted) return;

    setState(() => _saving = false);

    context.read<NotificationCubit>().show(
      NotificationData(
        title: 'Erro',
        subtitle: msg,
        type: NotificationType.error,
        leadingLabel: 'Sistema',
      ),
    );
  }

  void _success(String msg) {
    if (!mounted) return;

    context.read<NotificationCubit>().show(
      NotificationData(
        title: 'Sucesso',
        subtitle: msg,
        type: NotificationType.success,
        leadingLabel: 'Sistema',
      ),
    );
  }

  void _clearUnitSelection() {
    setState(() {
      _selectedUnit = null;
      _newUnitCtrl.clear();
    });
  }

  void _clearRoadSelection() {
    setState(() {
      _selectedRoad = null;
      _newRoadCtrl.clear();
    });
  }

  void _clearRegionSelection() {
    setState(() {
      _selectedRegion = null;
      _newRegionCtrl.clear();
      _selectedMunicipios = [];
    });
  }

  void _clearFundingSelection() {
    setState(() {
      _selectedFunding = null;
      _newFundingCtrl.clear();
    });
  }

  void _clearProgramSelection() {
    setState(() {
      _selectedProgram = null;
      _newProgramCtrl.clear();
    });
  }

  void _clearExpenseNatureSelection() {
    setState(() {
      _selectedExpenseNature = null;
      _newExpenseNatureCtrl.clear();
    });
  }

  void _selectUnit(SetupData item) {
    setState(() {
      _selectedUnit = item;
      _newUnitCtrl.text = item.label;
    });
  }

  void _selectRoad(SetupData item) {
    setState(() {
      _selectedRoad = item;
      _newRoadCtrl.text = item.label;
    });
  }

  void _selectRegion(SetupData item) {
    setState(() {
      _selectedRegion = item;
      _newRegionCtrl.text = item.label;
      _selectedMunicipios = List<String>.from(item.municipios ?? []);
    });
  }

  void _selectFunding(SetupData item) {
    setState(() {
      _selectedFunding = item;
      _newFundingCtrl.text = item.label;
    });
  }

  void _selectProgram(SetupData item) {
    setState(() {
      _selectedProgram = item;
      _newProgramCtrl.text = item.label;
    });
  }

  void _selectExpenseNature(SetupData item) {
    setState(() {
      _selectedExpenseNature = item;
      _newExpenseNatureCtrl.text = item.label;
    });
  }

  Future<void> _saveUnit() async {
    final name = _newUnitCtrl.text.trim();
    if (name.isEmpty) return;

    final cubit = context.read<SetupCubit>();

    if (_selectedUnit == null) {
      final created = await cubit.createUnit(name);

      if (created != null && mounted) {
        _success('Unidade adicionada com sucesso.');
        _clearUnitSelection();
      }

      return;
    }

    final unitId = _selectedUnit!.unitId ?? _selectedUnit!.id;
    final updated = await cubit.updateUnitName(unitId, name);

    if (updated != null && mounted) {
      _success('Unidade atualizada com sucesso.');

      setState(() {
        _selectedUnit = updated;
        _newUnitCtrl.text = updated.label;
      });
    }
  }

  Future<void> _deleteUnit() async {
    if (_selectedUnit == null) return;

    final unitId = _selectedUnit!.unitId ?? _selectedUnit!.id;

    await context.read<SetupCubit>().deleteUnit(unitId);

    if (!mounted) return;

    final cubit = context.read<SetupCubit>();

    if (cubit.state.error == null) {
      _success('Unidade removida com sucesso.');
      _clearUnitSelection();
    } else {
      _error(cubit.state.error!);
    }
  }

  Future<void> _saveRoad() async {
    final name = _newRoadCtrl.text.trim();
    if (name.isEmpty) return;

    final cubit = context.read<SetupCubit>();

    if (_selectedRoad == null) {
      final created = await cubit.createRoad(name);

      if (created != null && mounted) {
        _success('Rodovia adicionada com sucesso.');
        _clearRoadSelection();
      }

      return;
    }

    final roadId = _selectedRoad!.roadId ?? _selectedRoad!.id;
    final updated = await cubit.updateRoadName(roadId, name);

    if (updated != null && mounted) {
      _success('Rodovia atualizada com sucesso.');

      setState(() {
        _selectedRoad = updated;
        _newRoadCtrl.text = updated.label;
      });
    }
  }

  Future<void> _deleteRoad() async {
    if (_selectedRoad == null) return;

    final roadId = _selectedRoad!.roadId ?? _selectedRoad!.id;

    await context.read<SetupCubit>().deleteRoad(roadId);

    if (!mounted) return;

    final cubit = context.read<SetupCubit>();

    if (cubit.state.error == null) {
      _success('Rodovia removida com sucesso.');
      _clearRoadSelection();
    } else {
      _error(cubit.state.error!);
    }
  }

  Future<void> _saveRegion() async {
    final name = _newRegionCtrl.text.trim();
    if (name.isEmpty) return;

    final cubit = context.read<SetupCubit>();

    if (_selectedRegion == null) {
      final created = await cubit.createRegion(
        name,
        municipios: _selectedMunicipios,
      );

      if (created != null && mounted) {
        _success('Região adicionada com sucesso.');
        _clearRegionSelection();
      }

      return;
    }

    final regionId = _selectedRegion!.regionId ?? _selectedRegion!.id;

    final updatedName = await cubit.updateRegionName(regionId, name);

    if (updatedName == null) {
      if (mounted && cubit.state.error != null) {
        _error(cubit.state.error!);
      }

      return;
    }

    final updatedRegion = await cubit.updateRegionMunicipios(
      regionId,
      _selectedMunicipios,
    );

    if (updatedRegion != null && mounted) {
      _success('Região atualizada com sucesso.');

      setState(() {
        _selectedRegion = updatedRegion;
        _newRegionCtrl.text = updatedRegion.label;
        _selectedMunicipios = List<String>.from(
          updatedRegion.municipios ?? [],
        );
      });
    }
  }

  Future<void> _deleteRegion() async {
    if (_selectedRegion == null) return;

    final regionId = _selectedRegion!.regionId ?? _selectedRegion!.id;

    await context.read<SetupCubit>().deleteRegion(regionId);

    if (!mounted) return;

    final cubit = context.read<SetupCubit>();

    if (cubit.state.error == null) {
      _success('Região removida com sucesso.');
      _clearRegionSelection();
    } else {
      _error(cubit.state.error!);
    }
  }

  Future<void> _saveFunding() async {
    final name = _newFundingCtrl.text.trim();
    if (name.isEmpty) return;

    final cubit = context.read<SetupCubit>();

    if (_selectedFunding == null) {
      final created = await cubit.createFundingSource(name);

      if (created != null && mounted) {
        _success('Fonte adicionada com sucesso.');
        _clearFundingSelection();
      }

      return;
    }

    final sourceId = _selectedFunding!.genericId ?? _selectedFunding!.id;
    final updated = await cubit.updateFundingSourceName(sourceId, name);

    if (updated != null && mounted) {
      _success('Fonte atualizada com sucesso.');

      setState(() {
        _selectedFunding = updated;
        _newFundingCtrl.text = updated.label;
      });
    }
  }

  Future<void> _deleteFunding() async {
    if (_selectedFunding == null) return;

    final sourceId = _selectedFunding!.genericId ?? _selectedFunding!.id;

    await context.read<SetupCubit>().deleteFundingSource(sourceId);

    if (!mounted) return;

    final cubit = context.read<SetupCubit>();

    if (cubit.state.error == null) {
      _success('Fonte removida com sucesso.');
      _clearFundingSelection();
    } else {
      _error(cubit.state.error!);
    }
  }

  Future<void> _saveProgram() async {
    final name = _newProgramCtrl.text.trim();
    if (name.isEmpty) return;

    final cubit = context.read<SetupCubit>();

    if (_selectedProgram == null) {
      final created = await cubit.createProgram(name);

      if (created != null && mounted) {
        _success('Programa adicionado com sucesso.');
        _clearProgramSelection();
      }

      return;
    }

    final programId = _selectedProgram!.genericId ?? _selectedProgram!.id;
    final updated = await cubit.updateProgramName(programId, name);

    if (updated != null && mounted) {
      _success('Programa atualizado com sucesso.');

      setState(() {
        _selectedProgram = updated;
        _newProgramCtrl.text = updated.label;
      });
    }
  }

  Future<void> _deleteProgram() async {
    if (_selectedProgram == null) return;

    final programId = _selectedProgram!.genericId ?? _selectedProgram!.id;

    await context.read<SetupCubit>().deleteProgram(programId);

    if (!mounted) return;

    final cubit = context.read<SetupCubit>();

    if (cubit.state.error == null) {
      _success('Programa removido com sucesso.');
      _clearProgramSelection();
    } else {
      _error(cubit.state.error!);
    }
  }

  Future<void> _saveExpenseNature() async {
    final name = _newExpenseNatureCtrl.text.trim();
    if (name.isEmpty) return;

    final cubit = context.read<SetupCubit>();

    if (_selectedExpenseNature == null) {
      final created = await cubit.createExpenseNature(name);

      if (created != null && mounted) {
        _success('Natureza de despesa adicionada com sucesso.');
        _clearExpenseNatureSelection();
      }

      return;
    }

    final natureId =
        _selectedExpenseNature!.genericId ?? _selectedExpenseNature!.id;

    final updated = await cubit.updateExpenseNatureName(natureId, name);

    if (updated != null && mounted) {
      _success('Natureza de despesa atualizada com sucesso.');

      setState(() {
        _selectedExpenseNature = updated;
        _newExpenseNatureCtrl.text = updated.label;
      });
    }
  }

  Future<void> _deleteExpenseNature() async {
    if (_selectedExpenseNature == null) return;

    final natureId =
        _selectedExpenseNature!.genericId ?? _selectedExpenseNature!.id;

    await context.read<SetupCubit>().deleteExpenseNature(natureId);

    if (!mounted) return;

    final cubit = context.read<SetupCubit>();

    if (cubit.state.error == null) {
      _success('Natureza de despesa removida com sucesso.');
      _clearExpenseNatureSelection();
    } else {
      _error(cubit.state.error!);
    }
  }

  Widget _buildBottomBar({bool pageMode = false}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Colors.black12),
        ),
        boxShadow: pageMode
            ? null
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: LoadingTreeDots(
                size: 18,
                centered: false,
              ),
            )
                : const Icon(Icons.check),
            label: Text(pageMode ? 'Salvar configurações' : 'Salvar e entrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildMunicipiosSelecionados() {
    if (_selectedMunicipios.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: _selectedMunicipios.map((e) {
          return Text(
            e,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildSections(SetupState state) {
    final hasCompany =
        state.companyProfile != null || _empresaNomeCtrl.text.trim().isNotEmpty;

    return [
      InitialSetupHeader(
        empresaFantasiaCtrl: _empresaFantasiaCtrl,
        empresaNomeCtrl: _empresaNomeCtrl,
        empresaCnpjCtrl: _empresaCnpjCtrl,
        saving: _saving,
        logoBytes: _logoBytes,
        existingLogoUrl: _existingLogoUrl,
        onPickLogo: _pickLogo,
        cnpjValidator: (v) {
          final raw = v?.replaceAll(RegExp(r'\D'), '') ?? '';

          if (raw.isEmpty) return 'Informe o CNPJ';
          if (raw.length != 14) return 'CNPJ inválido';
          if (!CNPJValidator.isValid(raw)) return 'CNPJ inválido';

          return null;
        },
      ),
      const SizedBox(height: 24),
      InitialSetupForm(
        controller: _newUnitCtrl,
        labelText: 'Nome da unidade',
        enabled: hasCompany && !_saving,
        items: state.units,
        selectedItem: _selectedUnit,
        onSelectItem: _selectUnit,
        onClearSelection: _clearUnitSelection,
        addLabel: 'Adicionar unidade',
        saveLabel: 'Atualizar unidade',
        removeLabel: 'Remover unidade',
        primaryEnabled: _newUnitCtrl.text.trim().isNotEmpty && hasCompany,
        onPrimaryAction: _saveUnit,
        onRemoveAction: _deleteUnit,
      ),
      const SizedBox(height: 30),
      InitialSetupForm(
        controller: _newRoadCtrl,
        labelText: 'Nome da estrada/rodovia',
        enabled: hasCompany && !_saving,
        items: state.roads,
        selectedItem: _selectedRoad,
        onSelectItem: _selectRoad,
        onClearSelection: _clearRoadSelection,
        addLabel: 'Adicionar rodovia',
        saveLabel: 'Atualizar rodovia',
        removeLabel: 'Remover rodovia',
        primaryEnabled: _newRoadCtrl.text.trim().isNotEmpty && hasCompany,
        onPrimaryAction: _saveRoad,
        onRemoveAction: _deleteRoad,
      ),
      const SizedBox(height: 30),
      InitialSetupForm(
        controller: _newRegionCtrl,
        labelText: 'Nome da região',
        enabled: hasCompany && !_saving,
        items: state.regions,
        selectedItem: _selectedRegion,
        onSelectItem: _selectRegion,
        onClearSelection: _clearRegionSelection,
        addLabel: 'Adicionar região',
        saveLabel: 'Atualizar região',
        removeLabel: 'Remover região',
        primaryEnabled: _newRegionCtrl.text.trim().isNotEmpty && hasCompany,
        onPrimaryAction: _saveRegion,
        onRemoveAction: _deleteRegion,
        trailingWidget: IconButton(
          onPressed: !hasCompany || _saving
              ? null
              : () async {
            final selected = await setupRegionMap(context);

            if (selected != null && mounted) {
              setState(() {
                _selectedMunicipios = selected;
              });
            }
          },
          icon: const Icon(Icons.search),
        ),
        extraBottom: _buildMunicipiosSelecionados(),
      ),
      const SizedBox(height: 30),
      InitialSetupForm(
        controller: _newFundingCtrl,
        labelText: 'Nome da fonte',
        enabled: hasCompany && !_saving,
        items: state.fundingSources,
        selectedItem: _selectedFunding,
        onSelectItem: _selectFunding,
        onClearSelection: _clearFundingSelection,
        addLabel: 'Adicionar fonte',
        saveLabel: 'Atualizar fonte',
        removeLabel: 'Remover fonte',
        primaryEnabled: _newFundingCtrl.text.trim().isNotEmpty && hasCompany,
        onPrimaryAction: _saveFunding,
        onRemoveAction: _deleteFunding,
      ),
      const SizedBox(height: 30),
      InitialSetupForm(
        controller: _newProgramCtrl,
        labelText: 'Nome do programa',
        enabled: hasCompany && !_saving,
        items: state.programs,
        selectedItem: _selectedProgram,
        onSelectItem: _selectProgram,
        onClearSelection: _clearProgramSelection,
        addLabel: 'Adicionar programa',
        saveLabel: 'Atualizar programa',
        removeLabel: 'Remover programa',
        primaryEnabled: _newProgramCtrl.text.trim().isNotEmpty && hasCompany,
        onPrimaryAction: _saveProgram,
        onRemoveAction: _deleteProgram,
      ),
      const SizedBox(height: 30),
      InitialSetupForm(
        controller: _newExpenseNatureCtrl,
        labelText: 'Nome da natureza de despesa',
        enabled: hasCompany && !_saving,
        items: state.expenseNatures,
        selectedItem: _selectedExpenseNature,
        onSelectItem: _selectExpenseNature,
        onClearSelection: _clearExpenseNatureSelection,
        addLabel: 'Adicionar natureza de despesa',
        saveLabel: 'Atualizar natureza de despesa',
        removeLabel: 'Remover natureza de despesa',
        primaryEnabled:
        _newExpenseNatureCtrl.text.trim().isNotEmpty && hasCompany,
        onPrimaryAction: _saveExpenseNature,
        onRemoveAction: _deleteExpenseNature,
      ),
    ];
  }

  Widget _buildDialogMode() {
    return Stack(
      fit: StackFit.expand,
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: Colors.black.withValues(alpha: 0.30),
          ),
        ),
        Center(
          child: LayoutBuilder(
            builder: (_, constraints) {
              final width = (constraints.maxWidth * 0.9).clamp(680.0, 1200.0);

              final dialogHeight =
              (constraints.maxHeight * 0.9).clamp(400.0, 800.0);

              return WindowDialog(
                width: width,
                title: 'Configurações iniciais do SIPGED',
                onClose: null,
                showMinimize: false,
                contentPadding: EdgeInsets.zero,
                child: SizedBox(
                  height: dialogHeight,
                  child: BlocBuilder<SetupCubit, SetupState>(
                    builder: (context, state) {
                      return Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Expanded(
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    12,
                                    12,
                                    20,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: _buildSections(state),
                                  ),
                                ),
                              ),
                            ),
                            _buildBottomBar(pageMode: false),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPageMode() {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: UpBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: CircleButtonChange(),
        ),
        titleWidgets: const [
          Text(
            'Configurações iniciais do SIPGED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: BackgroundChange(),
          ),
          SafeArea(
            top: false,
            child: BlocBuilder<SetupCubit, SetupState>(
              builder: (context, state) {
                final media = MediaQuery.of(context);
                final topSafe = media.padding.top;

                const appBarHeight = 56.0;

                final topOffset = topSafe + appBarHeight + 12;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth >= 1500
                        ? 1200.0
                        : constraints.maxWidth >= 1100
                        ? 1000.0
                        : constraints.maxWidth >= 800
                        ? constraints.maxWidth * 0.88
                        : constraints.maxWidth - 24;

                    return Padding(
                      padding: EdgeInsets.fromLTRB(12, topOffset, 12, 12),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxWidth,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.06),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Scrollbar(
                                      thumbVisibility: true,
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          20,
                                          20,
                                          24,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: _buildSections(state),
                                        ),
                                      ),
                                    ),
                                  ),
                                  _buildBottomBar(pageMode: true),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SetupCubit, SetupState>(
      listener: (context, state) {
        _hydrateFromCompany(state.companyProfile);
      },
      child: widget.isPage ? _buildPageMode() : _buildDialogMode(),
    );
  }
}