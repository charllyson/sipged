import 'dart:ui';

import 'package:brasil_fields/brasil_fields.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/setup/setup_cubit.dart';
import 'package:sipged/_blocs/system/setup/setup_data.dart';
import 'package:sipged/screens/modules/contracts/hiring/1Dfd/setup_region_map.dart';
import 'package:sipged/_blocs/system/setup/setup_state.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_widgets/input/drop_down_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/windows/window_dialog.dart';

class InitialSetupPage extends StatefulWidget {
  final UserData user;

  const InitialSetupPage({
    super.key,
    required this.user,
  });

  @override
  State<InitialSetupPage> createState() => _InitialSetupPageState();
}

class _InitialSetupPageState extends State<InitialSetupPage> {
  final _formKey = GlobalKey<FormState>();

  final _empresaNomeCtrl = TextEditingController();
  final _empresaCnpjCtrl = TextEditingController();

  final _newUnitCtrl = TextEditingController();
  final _newRoadCtrl = TextEditingController();

  final _newRegionCtrl = TextEditingController();
  List<String> _selectedMunicipios = [];

  final _newFundingCtrl = TextEditingController();
  final _newProgramCtrl = TextEditingController();
  final _newExpenseNatureCtrl = TextEditingController();

  Uint8List? _logoBytes;
  String? _logoFileName;
  String? _logoContentType;

  String? _selectedCompanyId;
  String? _existingLogoUrl;
  String? _existingLogoPath;
  bool _removeCurrentLogo = false;

  bool _saving = false;

  String? get _effectiveCompanyId => _selectedCompanyId?.trim().isEmpty ?? true
      ? null
      : _selectedCompanyId!.trim();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SetupCubit>().loadCompanies();
    });
  }

  @override
  void dispose() {
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
    if (ext == 'jpg' || ext == 'jpeg') contentType = 'image/jpeg';
    if (ext == 'webp') contentType = 'image/webp';

    setState(() {
      _logoBytes = bytes;
      _logoFileName = file.name;
      _logoContentType = contentType;
      _removeCurrentLogo = false;
    });
  }

  void _removeLogo() {
    setState(() {
      _logoBytes = null;
      _logoFileName = null;
      _logoContentType = null;
      _existingLogoUrl = null;
      _existingLogoPath = null;
      _removeCurrentLogo = true;
    });
  }

  Future<String?> _askNewLabel(
      BuildContext dialogContext, {
        required String title,
        required String initialValue,
        String labelText = 'Novo nome',
      }) async {
    final ctrl = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: dialogContext,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(labelText: labelText),
            onSubmitted: (value) => Navigator.of(ctx).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    ctrl.dispose();

    if (result == null) return null;
    final trimmed = result.trim();
    if (trimmed.isEmpty || trimmed == initialValue.trim()) return null;
    return trimmed;
  }

  void _applySelectedCompany(SetupData company) {
    setState(() {
      _selectedCompanyId = company.companyId ?? company.id;
      _empresaNomeCtrl.text = company.companyName ?? company.label;
      _empresaCnpjCtrl.text = company.cnpj ?? company.cnpjCompanyContracted ?? '';
      _existingLogoUrl = company.logoUrl;
      _existingLogoPath = company.logoPath;
      _logoBytes = null;
      _logoFileName = null;
      _logoContentType = null;
      _removeCurrentLogo = false;
    });
  }

  void _clearSelectedCompany() {
    setState(() {
      _selectedCompanyId = null;
      _empresaNomeCtrl.clear();
      _empresaCnpjCtrl.clear();
      _existingLogoUrl = null;
      _existingLogoPath = null;
      _logoBytes = null;
      _logoFileName = null;
      _logoContentType = null;
      _removeCurrentLogo = false;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving) return;

    setState(() => _saving = true);

    final setup = context.read<SetupCubit>();

    final saved = await setup.saveCompanyProfile(
      companyId: _effectiveCompanyId,
      label: _empresaNomeCtrl.text.trim(),
      cnpj: _empresaCnpjCtrl.text.trim(),
      logoBytes: _logoBytes,
      logoFileName: _logoFileName,
      logoContentType: _logoContentType,
      removeLogo: _removeCurrentLogo,
      oldLogoPath: _existingLogoPath,
    );

    if (saved == null) {
      _error('Falha ao salvar empresa.');
      return;
    }

    final companyId = saved.companyId ?? saved.id;

    await setup.selectCompany(companyId);
    await setup.loadCompanies();

    if (!mounted) return;

    _applySelectedCompany(saved);

    setState(() => _saving = false);
  }

  void _error(String msg) {
    if (!mounted) return;

    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Widget _buildLogoPreview() {
    Widget child;

    if (_logoBytes != null) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _logoBytes!,
          fit: BoxFit.contain,
        ),
      );
    } else if ((_existingLogoUrl ?? '').isNotEmpty) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _existingLogoUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) =>
          const Icon(Icons.image_not_supported_outlined, size: 34),
        ),
      );
    } else {
      child = const Icon(Icons.image_outlined, size: 38);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _saving ? null : _pickLogo,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
            color: Colors.white,
          ),
          child: Stack(
            children: [
              Positioned.fill(child: child),
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (_logoBytes != null || (_existingLogoUrl ?? '').isNotEmpty)
                        ? Icons.edit
                        : Icons.add,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(SetupState state) {
    final setupCubit = context.read<SetupCubit>();
    final companies = state.companies;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.withValues(alpha: 0.05),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogoPreview(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                DropDownChange(
                  labelText: 'Razão social',
                  controller: _empresaNomeCtrl,
                  enabled: !_saving,
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) {
                      return 'Informe a razão social';
                    }
                    return null;
                  },
                  items: companies.map((e) => e.label).toList(),
                  specialItemLabel: 'Adicionar razão social',
                  menuMaxHeight: 260,
                  onChanged: (label) async {
                    if (_saving) return;

                    if (label == null || label.trim().isEmpty) {
                      _clearSelectedCompany();
                      return;
                    }

                    final selected = companies.firstWhere(
                          (c) => c.label == label,
                      orElse: () => companies.first,
                    );

                    _applySelectedCompany(selected);
                    await setupCubit.selectCompany(selected.companyId ?? selected.id);
                  },
                  onCreateNewItem: !_saving
                      ? (label) async {
                    final created = await setupCubit.createCompany(label.trim());
                    if (!mounted || created == null) return;

                    _applySelectedCompany(created);
                    await setupCubit.selectCompany(created.companyId ?? created.id);
                  }
                      : null,
                  onEditItem: !_saving
                      ? (ctx, label) async {
                    final list = setupCubit.state.companies;
                    if (list.isEmpty) return;

                    final target = list.firstWhere(
                          (c) => c.label == label,
                      orElse: () => list.first,
                    );

                    final id = target.companyId ?? target.id;
                    if (id.isEmpty) return;

                    final newLabel = await _askNewLabel(
                      ctx,
                      title: 'Editar razão social',
                      initialValue: label,
                      labelText: 'Razão social',
                    );
                    if (newLabel == null) return;

                    final updated = await setupCubit.updateCompanyName(id, newLabel);
                    if (!mounted || updated == null) return;

                    if (_selectedCompanyId == id) {
                      _applySelectedCompany(updated);
                    }
                  }
                      : null,
                  onDeleteItem: !_saving
                      ? (ctx, label) async {
                    final list = setupCubit.state.companies;
                    if (list.isEmpty) return;

                    final target = list.firstWhere(
                          (c) => c.label == label,
                      orElse: () => list.first,
                    );

                    final id = target.companyId ?? target.id;
                    if (id.isEmpty) return;

                    await setupCubit.deleteCompany(id);
                    if (!mounted) return;

                    if (_selectedCompanyId == id) {
                      _clearSelectedCompany();
                    }
                  }
                      : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _empresaCnpjCtrl,
                  labelText: 'CNPJ',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(14),
                  ],
                  validator: (v) {
                    final raw = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                    if (raw.isEmpty) return 'Informe o CNPJ';
                    if (raw.length != 14) return 'CNPJ inválido';
                    if (!CNPJValidator.isValid(raw)) return 'CNPJ inválido';
                    return null;
                  },
                ),
                if (_logoBytes != null || (_existingLogoUrl ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _saving ? null : _removeLogo,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Remover logo'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _plusButton(Future<void> Function() onPressed) {
    return IconButton(
      onPressed: _saving ? null : onPressed,
      icon: const Icon(Icons.add),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Colors.black12),
        ),
        boxShadow: [
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
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.check),
            label: const Text('Salvar e entrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                title: 'Configurações iniciais do SIGED',
                onClose: null,
                showMinimize: false,
                contentPadding: EdgeInsets.zero,
                child: SizedBox(
                  height: dialogHeight,
                  child: BlocBuilder<SetupCubit, SetupState>(
                    builder: (context, state) {
                      final companyId = _effectiveCompanyId ?? state.selectedCompanyId;
                      final hasCompany = (companyId ?? '').isNotEmpty;

                      return Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Expanded(
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildHeaderCard(state),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: state.units
                                            .map((e) => Chip(label: Text(e.label)))
                                            .toList(),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CustomTextField(
                                              controller: _newUnitCtrl,
                                              labelText: 'Nome da unidade',
                                              enabled: hasCompany && !_saving,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          _plusButton(() async {
                                            final name = _newUnitCtrl.text.trim();
                                            if (name.isEmpty || !hasCompany) return;

                                            final created = await context
                                                .read<SetupCubit>()
                                                .createUnit(companyId!, name);

                                            if (created != null && mounted) {
                                              _newUnitCtrl.clear();
                                            }
                                          }),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: state.roads
                                            .map((e) => Chip(label: Text(e.label)))
                                            .toList(),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CustomTextField(
                                              controller: _newRoadCtrl,
                                              labelText: 'Nome da estrada/rodovia',
                                              enabled: hasCompany && !_saving,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          _plusButton(() async {
                                            final name = _newRoadCtrl.text.trim();
                                            if (name.isEmpty || !hasCompany) return;

                                            final created = await context
                                                .read<SetupCubit>()
                                                .createRoad(companyId!, name);

                                            if (created != null && mounted) {
                                              _newRoadCtrl.clear();
                                            }
                                          }),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: state.regions
                                            .map((e) => Chip(label: Text(e.label)))
                                            .toList(),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CustomTextField(
                                              controller: _newRegionCtrl,
                                              labelText: 'Nome da região',
                                              enabled: hasCompany && !_saving,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          IconButton(
                                            onPressed: !hasCompany || _saving
                                                ? null
                                                : () async {
                                              final selected =
                                              await setupRegionMap(context);
                                              if (selected != null && mounted) {
                                                setState(() {
                                                  _selectedMunicipios = selected;
                                                });
                                              }
                                            },
                                            icon: const Icon(Icons.search),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (_selectedMunicipios.isNotEmpty)
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: _selectedMunicipios
                                              .map((e) => Chip(label: Text(e)))
                                              .toList(),
                                        ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: _plusButton(() async {
                                          final name = _newRegionCtrl.text.trim();
                                          if (name.isEmpty || !hasCompany) return;

                                          final created = await context
                                              .read<SetupCubit>()
                                              .createRegion(
                                            companyId!,
                                            name,
                                            municipios: _selectedMunicipios,
                                          );

                                          if (created != null && mounted) {
                                            _newRegionCtrl.clear();
                                            setState(() => _selectedMunicipios = []);
                                          }
                                        }),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: state.fundingSources
                                            .map((e) => Chip(label: Text(e.label)))
                                            .toList(),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CustomTextField(
                                              controller: _newFundingCtrl,
                                              labelText: 'Nome da fonte',
                                              enabled: hasCompany && !_saving,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          _plusButton(() async {
                                            final name = _newFundingCtrl.text.trim();
                                            if (name.isEmpty || !hasCompany) return;

                                            final created = await context
                                                .read<SetupCubit>()
                                                .createFundingSource(companyId!, name);

                                            if (created != null && mounted) {
                                              _newFundingCtrl.clear();
                                            }
                                          }),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: state.programs
                                            .map((e) => Chip(label: Text(e.label)))
                                            .toList(),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CustomTextField(
                                              controller: _newProgramCtrl,
                                              labelText: 'Nome do programa',
                                              enabled: hasCompany && !_saving,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          _plusButton(() async {
                                            final name = _newProgramCtrl.text.trim();
                                            if (name.isEmpty || !hasCompany) return;

                                            final created = await context
                                                .read<SetupCubit>()
                                                .createProgram(companyId!, name);

                                            if (created != null && mounted) {
                                              _newProgramCtrl.clear();
                                            }
                                          }),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: state.expenseNatures
                                            .map((e) => Chip(label: Text(e.label)))
                                            .toList(),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CustomTextField(
                                              controller: _newExpenseNatureCtrl,
                                              labelText: 'Nome da natureza de despesa',
                                              enabled: hasCompany && !_saving,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          _plusButton(() async {
                                            final name =
                                            _newExpenseNatureCtrl.text.trim();
                                            if (name.isEmpty || !hasCompany) return;

                                            final created = await context
                                                .read<SetupCubit>()
                                                .createExpenseNature(companyId!, name);

                                            if (created != null && mounted) {
                                              _newExpenseNatureCtrl.clear();
                                            }
                                          }),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            _buildBottomBar(),
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
}