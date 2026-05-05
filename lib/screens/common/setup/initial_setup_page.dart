// lib/screens/common/setup/initial_setup_page.dart

import 'dart:typed_data';
import 'dart:ui';

import 'package:cpf_cnpj_validator/cnpj_validator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_data.dart';
import 'package:sipged/_blocs/system/tenant/tenant_state.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/dialog/windows/window_dialog.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/screens/common/setup/initial_setup_form.dart';
import 'package:sipged/screens/common/setup/initial_setup_header.dart';

enum InitialSetupPresentationMode {
  dialog,
  page,
}

enum _CatalogKind {
  unit,
  road,
  region,
  fundingSource,
  program,
  expenseNature,
  companyBody,
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

  final _tenantFantasyCtrl = TextEditingController();
  final _tenantNameCtrl = TextEditingController();
  final _tenantCnpjCtrl = TextEditingController();

  final _unitCtrl = TextEditingController();
  final _roadCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _fundingSourceCtrl = TextEditingController();
  final _programCtrl = TextEditingController();
  final _expenseNatureCtrl = TextEditingController();
  final _companyBodyCtrl = TextEditingController();

  Uint8List? _logoBytes;
  String? _logoFileName;
  String? _logoContentType;

  String? _existingLogoUrl;
  String? _existingLogoPath;

  bool _removeCurrentLogo = false;
  bool _saving = false;
  bool _didInit = false;

  String? _selectedUnit;
  String? _selectedRoad;
  String? _selectedRegion;
  String? _selectedFundingSource;
  String? _selectedProgram;
  String? _selectedExpenseNature;
  String? _selectedCompanyBody;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didInit) return;

      _didInit = true;

      final cubit = context.read<TenantCubit>();

      await cubit.ensureAvailableTenantsLoaded();

      if (!mounted) return;

      await cubit.ensureTenantProfileLoaded();

      if (!mounted) return;

      await cubit.ensureTenantItemsLoaded();

      if (!mounted) return;

      final tenant = cubit.state.tenantProfile ?? cubit.state.selectedTenant;

      if (tenant != null) {
        _hydrateFromTenant(tenant);
      }
    });
  }

  @override
  void dispose() {
    _tenantFantasyCtrl.dispose();
    _tenantNameCtrl.dispose();
    _tenantCnpjCtrl.dispose();

    _unitCtrl.dispose();
    _roadCtrl.dispose();
    _regionCtrl.dispose();
    _fundingSourceCtrl.dispose();
    _programCtrl.dispose();
    _expenseNatureCtrl.dispose();
    _companyBodyCtrl.dispose();

    super.dispose();
  }

  void _clearCatalogFormSelections() {
    _unitCtrl.clear();
    _roadCtrl.clear();
    _regionCtrl.clear();
    _fundingSourceCtrl.clear();
    _programCtrl.clear();
    _expenseNatureCtrl.clear();
    _companyBodyCtrl.clear();

    _selectedUnit = null;
    _selectedRoad = null;
    _selectedRegion = null;
    _selectedFundingSource = null;
    _selectedProgram = null;
    _selectedExpenseNature = null;
    _selectedCompanyBody = null;
  }

  void _hydrateFromTenant(TenantData tenant) {
    setState(() {
      _tenantFantasyCtrl.text = tenant.fantasyName ?? '';
      _tenantNameCtrl.text = tenant.companyName ?? tenant.label;
      _tenantCnpjCtrl.text = tenant.cnpj ?? '';

      _existingLogoUrl = tenant.logoUrl;
      _existingLogoPath = tenant.logoPath;

      _logoBytes = null;
      _logoFileName = null;
      _logoContentType = null;
      _removeCurrentLogo = false;

      _clearCatalogFormSelections();
    });
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

    var contentType = 'image/png';

    if (ext == 'jpg' || ext == 'jpeg') {
      contentType = 'image/jpeg';
    } else if (ext == 'webp') {
      contentType = 'image/webp';
    }

    setState(() {
      _logoBytes = bytes;
      _logoFileName = file.name;
      _logoContentType = contentType;
      _removeCurrentLogo = false;
    });
  }

  void _removeLogo() {
    if (_saving) return;

    setState(() {
      _logoBytes = null;
      _logoFileName = null;
      _logoContentType = null;
      _existingLogoUrl = null;
      _existingLogoPath = null;
      _removeCurrentLogo = true;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving) return;

    final tenantCubit = context.read<TenantCubit>();

    final activeTenantId = tenantCubit.selectedTenantId?.trim();

    if (activeTenantId == null || activeTenantId.isEmpty) {
      _error('Nenhuma empresa logada/selecionada foi encontrada.');
      return;
    }

    setState(() => _saving = true);

    final currentState = tenantCubit.state;

    final saved = await tenantCubit.saveTenantProfile(
      label: _tenantNameCtrl.text.trim(),
      fantasyName: _tenantFantasyCtrl.text.trim(),
      cnpj: _tenantCnpjCtrl.text.trim(),
      logoBytes: _logoBytes,
      logoFileName: _logoFileName,
      logoContentType: _logoContentType,
      removeLogo: _removeCurrentLogo,
      oldLogoPath: _existingLogoPath,
      units: currentState.units,
      roads: currentState.roads,
      regions: currentState.regions,
      fundingSources: currentState.fundingSources,
      programs: currentState.programs,
      expenseNatures: currentState.expenseNatures,
      companyBodies: currentState.companyBodies,
    );

    if (!mounted) return;

    if (saved == null) {
      final msg = tenantCubit.state.error ??
          'Falha ao salvar configurações da empresa.';

      _error(msg);
      return;
    }

    await tenantCubit.loadTenantItems();

    if (!mounted) return;

    _hydrateFromTenant(saved);

    setState(() => _saving = false);

    _success('Configurações da empresa salvas com sucesso.');
  }

  String? _validateCnpj(String? value) {
    final raw = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (raw.isEmpty) return 'Informe o CNPJ';
    if (raw.length != 14) return 'CNPJ inválido';
    if (!CNPJValidator.isValid(raw)) {
      return 'CNPJ inválido';
    }

    return null;
  }

  void _error(String msg) {
    if (!mounted) return;

    setState(() => _saving = false);

    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: 'Erro',
        subtitle: msg,
        status: NotificationStatus.error,
        leadingLabel: 'Sistema',
        extra: const <String, dynamic>{
          'module': 'initial_setup',
          'source': 'initial_setup_page',
        },
      ),
    );
  }

  void _success(String msg) {
    if (!mounted) return;

    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: 'Sucesso',
        subtitle: msg,
        status: NotificationStatus.success,
        leadingLabel: 'Sistema',
        extra: const <String, dynamic>{
          'module': 'initial_setup',
          'source': 'initial_setup_page',
        },
      ),
    );
  }

  String? _selectedOf(_CatalogKind kind) {
    switch (kind) {
      case _CatalogKind.unit:
        return _selectedUnit;
      case _CatalogKind.road:
        return _selectedRoad;
      case _CatalogKind.region:
        return _selectedRegion;
      case _CatalogKind.fundingSource:
        return _selectedFundingSource;
      case _CatalogKind.program:
        return _selectedProgram;
      case _CatalogKind.expenseNature:
        return _selectedExpenseNature;
      case _CatalogKind.companyBody:
        return _selectedCompanyBody;
    }
  }

  void _setSelectedOf(_CatalogKind kind, String? value) {
    switch (kind) {
      case _CatalogKind.unit:
        _selectedUnit = value;
        break;
      case _CatalogKind.road:
        _selectedRoad = value;
        break;
      case _CatalogKind.region:
        _selectedRegion = value;
        break;
      case _CatalogKind.fundingSource:
        _selectedFundingSource = value;
        break;
      case _CatalogKind.program:
        _selectedProgram = value;
        break;
      case _CatalogKind.expenseNature:
        _selectedExpenseNature = value;
        break;
      case _CatalogKind.companyBody:
        _selectedCompanyBody = value;
        break;
    }
  }

  TextEditingController _controllerOf(_CatalogKind kind) {
    switch (kind) {
      case _CatalogKind.unit:
        return _unitCtrl;
      case _CatalogKind.road:
        return _roadCtrl;
      case _CatalogKind.region:
        return _regionCtrl;
      case _CatalogKind.fundingSource:
        return _fundingSourceCtrl;
      case _CatalogKind.program:
        return _programCtrl;
      case _CatalogKind.expenseNature:
        return _expenseNatureCtrl;
      case _CatalogKind.companyBody:
        return _companyBodyCtrl;
    }
  }

  Future<void> _saveCatalogItem(_CatalogKind kind) async {
    if (_saving) return;

    final controller = _controllerOf(kind);
    final value = controller.text.trim();

    if (value.isEmpty) return;

    final selected = _selectedOf(kind);
    final cubit = context.read<TenantCubit>();

    setState(() => _saving = true);

    String? result;

    if (selected == null || selected.trim().isEmpty) {
      switch (kind) {
        case _CatalogKind.unit:
          result = await cubit.createUnit(value);
          break;
        case _CatalogKind.road:
          result = await cubit.createRoad(value);
          break;
        case _CatalogKind.region:
          result = await cubit.createRegion(value);
          break;
        case _CatalogKind.fundingSource:
          result = await cubit.createFundingSource(value);
          break;
        case _CatalogKind.program:
          result = await cubit.createProgram(value);
          break;
        case _CatalogKind.expenseNature:
          result = await cubit.createExpenseNature(value);
          break;
        case _CatalogKind.companyBody:
          result = await cubit.createCompanyBody(value);
          break;
      }
    } else {
      switch (kind) {
        case _CatalogKind.unit:
          result = await cubit.updateUnitName(selected, value);
          break;
        case _CatalogKind.road:
          result = await cubit.updateRoadName(selected, value);
          break;
        case _CatalogKind.region:
          result = await cubit.updateRegionName(selected, value);
          break;
        case _CatalogKind.fundingSource:
          result = await cubit.updateFundingSourceName(selected, value);
          break;
        case _CatalogKind.program:
          result = await cubit.updateProgramName(selected, value);
          break;
        case _CatalogKind.expenseNature:
          result = await cubit.updateExpenseNatureName(selected, value);
          break;
        case _CatalogKind.companyBody:
          result = await cubit.updateCompanyBodyName(selected, value);
          break;
      }
    }

    await cubit.loadTenantItems();

    if (!mounted) return;

    setState(() {
      _saving = false;

      if (result != null && result.trim().isNotEmpty) {
        controller.text = result.trim();
        _setSelectedOf(kind, result.trim());
      }
    });

    if (result == null) {
      _error(cubit.state.error ?? 'Falha ao salvar item.');
    }
  }

  Future<void> _removeCatalogItem(_CatalogKind kind) async {
    if (_saving) return;

    final selected = _selectedOf(kind);

    if (selected == null || selected.trim().isEmpty) return;

    final cubit = context.read<TenantCubit>();

    setState(() => _saving = true);

    switch (kind) {
      case _CatalogKind.unit:
        await cubit.deleteUnit(selected);
        break;
      case _CatalogKind.road:
        await cubit.deleteRoad(selected);
        break;
      case _CatalogKind.region:
        await cubit.deleteRegion(selected);
        break;
      case _CatalogKind.fundingSource:
        await cubit.deleteFundingSource(selected);
        break;
      case _CatalogKind.program:
        await cubit.deleteProgram(selected);
        break;
      case _CatalogKind.expenseNature:
        await cubit.deleteExpenseNature(selected);
        break;
      case _CatalogKind.companyBody:
        await cubit.deleteCompanyBody(selected);
        break;
    }

    await cubit.loadTenantItems();

    if (!mounted) return;

    setState(() {
      _saving = false;
      _controllerOf(kind).clear();
      _setSelectedOf(kind, null);
    });
  }

  Widget _buildCatalogCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Catálogos da empresa',
                  style: TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildCatalogsSection(TenantState tenantState) {
    final enabled = !_saving;

    Widget form({
      required _CatalogKind kind,
      required TextEditingController controller,
      required String labelText,
      required List<String> items,
      required String addLabel,
      required String saveLabel,
      required String removeLabel,
    }) {
      final selectedItem = _selectedOf(kind);

      return InitialSetupForm(
        controller: controller,
        labelText: labelText,
        enabled: enabled,
        items: items,
        selectedItem: selectedItem,
        onChanged: (_) => setState(() {}),
        onSelectItem: (item) {
          setState(() {
            _setSelectedOf(kind, item);
            controller.text = item;
          });
        },
        onClearSelection: () {
          setState(() {
            _setSelectedOf(kind, null);
            controller.clear();
          });
        },
        addLabel: addLabel,
        saveLabel: saveLabel,
        removeLabel: removeLabel,
        primaryEnabled: enabled && controller.text.trim().isNotEmpty,
        onPrimaryAction: () => _saveCatalogItem(kind),
        onRemoveAction: () => _removeCatalogItem(kind),
      );
    }

    return _buildCatalogCard(
      title: 'Catálogos da empresa',
      subtitle: 'Cadastre os itens padrão que serão usados nos módulos do SIPGED.',
      child: Column(
        children: [
          form(
            kind: _CatalogKind.unit,
            controller: _unitCtrl,
            labelText: 'Unidade / Setor',
            items: tenantState.units,
            addLabel: 'Adicionar unidade',
            saveLabel: 'Salvar unidade',
            removeLabel: 'Remover',
          ),
          const SizedBox(height: 18),
          form(
            kind: _CatalogKind.road,
            controller: _roadCtrl,
            labelText: 'Rodovia',
            items: tenantState.roads,
            addLabel: 'Adicionar rodovia',
            saveLabel: 'Salvar rodovia',
            removeLabel: 'Remover',
          ),
          const SizedBox(height: 18),
          form(
            kind: _CatalogKind.region,
            controller: _regionCtrl,
            labelText: 'Região / Área',
            items: tenantState.regions,
            addLabel: 'Adicionar região',
            saveLabel: 'Salvar região',
            removeLabel: 'Remover',
          ),
          const SizedBox(height: 18),
          form(
            kind: _CatalogKind.fundingSource,
            controller: _fundingSourceCtrl,
            labelText: 'Fonte de recurso',
            items: tenantState.fundingSources,
            addLabel: 'Adicionar fonte',
            saveLabel: 'Salvar fonte',
            removeLabel: 'Remover',
          ),
          const SizedBox(height: 18),
          form(
            kind: _CatalogKind.program,
            controller: _programCtrl,
            labelText: 'Programa de trabalho / Ação',
            items: tenantState.programs,
            addLabel: 'Adicionar programa',
            saveLabel: 'Salvar programa',
            removeLabel: 'Remover',
          ),
          const SizedBox(height: 18),
          form(
            kind: _CatalogKind.expenseNature,
            controller: _expenseNatureCtrl,
            labelText: 'Natureza da despesa',
            items: tenantState.expenseNatures,
            addLabel: 'Adicionar ND',
            saveLabel: 'Salvar ND',
            removeLabel: 'Remover',
          ),
          const SizedBox(height: 18),
          form(
            kind: _CatalogKind.companyBody,
            controller: _companyBodyCtrl,
            labelText: 'Órgão / Parceiro / Convenente',
            items: tenantState.companyBodies,
            addLabel: 'Adicionar órgão',
            saveLabel: 'Salvar órgão',
            removeLabel: 'Remover',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar({bool pageMode = false}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
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
                : const Icon(Icons.check_rounded),
            label: const Text('Salvar configurações'),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupContent({
    required TenantState tenantState,
    required EdgeInsets padding,
  }) {
    final isLoadingTenant = tenantState.isLoading && !_saving;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    padding: padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InitialSetupHeader(
                          empresaFantasiaCtrl: _tenantFantasyCtrl,
                          empresaNomeCtrl: _tenantNameCtrl,
                          empresaCnpjCtrl: _tenantCnpjCtrl,
                          saving: _saving,
                          logoBytes: _logoBytes,
                          existingLogoUrl: _existingLogoUrl,
                          onPickLogo: _pickLogo,
                          onRemoveLogo: (_logoBytes != null ||
                              (_existingLogoUrl ?? '').trim().isNotEmpty)
                              ? _removeLogo
                              : null,
                          cnpjValidator: _validateCnpj,
                        ),
                        const SizedBox(height: 18),
                        _buildCatalogsSection(tenantState),
                      ],
                    ),
                  ),
                ),
                if (isLoadingTenant)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x55FFFFFF),
                      child: Center(
                        child: LoadingTreeDots(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildBottomBar(pageMode: widget.isPage),
        ],
      ),
    );
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
              final width = (constraints.maxWidth * 0.9).clamp(
                560.0,
                960.0,
              );

              final dialogHeight = (constraints.maxHeight * 0.9).clamp(
                460.0,
                720.0,
              );

              return WindowDialog(
                width: width,
                title: 'Configurações da empresa',
                onClose: null,
                showMinimize: false,
                contentPadding: EdgeInsets.zero,
                child: SizedBox(
                  height: dialogHeight,
                  child: BlocBuilder<TenantCubit, TenantState>(
                    builder: (context, tenantState) {
                      return _buildSetupContent(
                        tenantState: tenantState,
                        padding: const EdgeInsets.fromLTRB(
                          12,
                          12,
                          12,
                          20,
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
            'Configurações da empresa',
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
            child: BlocBuilder<TenantCubit, TenantState>(
              builder: (context, tenantState) {
                final media = MediaQuery.of(context);
                final topSafe = media.padding.top;

                const appBarHeight = 56.0;
                final topOffset = topSafe + appBarHeight + 12;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth >= 1500
                        ? 1120.0
                        : constraints.maxWidth >= 1100
                        ? 1040.0
                        : constraints.maxWidth >= 800
                        ? constraints.maxWidth * 0.9
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
                              color: const Color(0xFFF6F7FB),
                              borderRadius: BorderRadius.circular(20),
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
                            child: _buildSetupContent(
                              tenantState: tenantState,
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                18,
                                18,
                                24,
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
    return widget.isPage ? _buildPageMode() : _buildDialogMode();
  }
}