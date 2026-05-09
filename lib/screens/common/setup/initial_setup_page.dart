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

enum InitialSetupMode {
  editTenant,
  createTenant,
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
  final InitialSetupMode mode;

  const InitialSetupPage({
    super.key,
    required this.user,
    this.presentationMode = InitialSetupPresentationMode.dialog,
    this.mode = InitialSetupMode.editTenant,
  });

  bool get isDialog => presentationMode == InitialSetupPresentationMode.dialog;

  bool get isPage => presentationMode == InitialSetupPresentationMode.page;

  bool get isCreateMode => mode == InitialSetupMode.createTenant;

  bool get isEditMode => mode == InitialSetupMode.editTenant;

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

      if (widget.isCreateMode) {
        setState(() {
          _tenantFantasyCtrl.clear();
          _tenantNameCtrl.clear();
          _tenantCnpjCtrl.clear();

          _existingLogoUrl = null;
          _existingLogoPath = null;

          _logoBytes = null;
          _logoFileName = null;
          _logoContentType = null;

          _removeCurrentLogo = false;

          _clearCatalogFormSelections();
        });

        return;
      }

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

    setState(() => _saving = true);

    if (widget.isCreateMode) {
      final createdTenant = await tenantCubit.createTenantForCurrentUser(
        label: _tenantNameCtrl.text.trim(),
        fantasyName: _tenantFantasyCtrl.text.trim(),
        cnpj: _tenantCnpjCtrl.text.trim(),
      );

      if (!mounted) return;

      if (createdTenant == null) {
        final msg = tenantCubit.state.error ?? 'Falha ao criar empresa.';
        _error(msg);
        return;
      }

      await tenantCubit.selectTenant(
        createdTenant.id,
        persistSelection: true,
      );

      if (!mounted) return;
    } else {
      final activeTenantId = tenantCubit.selectedTenantId?.trim();

      if (activeTenantId == null || activeTenantId.isEmpty) {
        _error('Nenhuma empresa logada/selecionada foi encontrada.');
        return;
      }
    }

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

      // Proteção essencial:
      // em modo criação, nunca reaproveita catálogos carregados do tenant anterior.
      units: widget.isCreateMode ? const <String>[] : currentState.units,
      roads: widget.isCreateMode ? const <String>[] : currentState.roads,
      regions: widget.isCreateMode ? const <String>[] : currentState.regions,
      fundingSources: widget.isCreateMode
          ? const <String>[]
          : currentState.fundingSources,
      programs: widget.isCreateMode ? const <String>[] : currentState.programs,
      expenseNatures: widget.isCreateMode
          ? const <String>[]
          : currentState.expenseNatures,
      companyBodies: widget.isCreateMode
          ? const <String>[]
          : currentState.companyBodies,
    );

    if (!mounted) return;

    if (saved == null) {
      final msg =
          tenantCubit.state.error ?? 'Falha ao salvar configurações da empresa.';

      _error(msg);
      return;
    }

    await tenantCubit.loadTenantItems();

    if (!mounted) return;

    _hydrateFromTenant(saved);

    setState(() => _saving = false);

    _success(
      widget.isCreateMode
          ? 'Empresa criada com sucesso.'
          : 'Configurações da empresa salvas com sucesso.',
    );

    if (widget.isCreateMode && mounted) {
      Navigator.of(context).pop(true);
    }
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

    if (widget.isCreateMode) {
      _error('Salve a empresa antes de cadastrar catálogos.');
      return;
    }

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

    if (widget.isCreateMode) {
      _error('Salve a empresa antes de remover catálogos.');
      return;
    }

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
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
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
    final enabled = !_saving && !widget.isCreateMode;

    final units = widget.isCreateMode ? const <String>[] : tenantState.units;
    final roads = widget.isCreateMode ? const <String>[] : tenantState.roads;
    final regions = widget.isCreateMode ? const <String>[] : tenantState.regions;
    final fundingSources = widget.isCreateMode
        ? const <String>[]
        : tenantState.fundingSources;
    final programs =
    widget.isCreateMode ? const <String>[] : tenantState.programs;
    final expenseNatures = widget.isCreateMode
        ? const <String>[]
        : tenantState.expenseNatures;
    final companyBodies = widget.isCreateMode
        ? const <String>[]
        : tenantState.companyBodies;

    Widget form({
      required _CatalogKind kind,
      required TextEditingController controller,
      required String labelText,
      required List<String> items,
      required String addLabel,
      required String saveLabel,
      required String removeLabel,
    }) {
      final selectedItem = widget.isCreateMode ? null : _selectedOf(kind);

      return InitialSetupForm(
        controller: controller,
        labelText: labelText,
        enabled: enabled,
        items: items,
        selectedItem: selectedItem,
        onChanged: (_) => setState(() {}),
        onSelectItem: (item) {
          if (widget.isCreateMode) return;

          setState(() {
            _setSelectedOf(kind, item);
            controller.text = item;
          });
        },
        onClearSelection: () {
          if (widget.isCreateMode) return;

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
      subtitle: widget.isCreateMode
          ? 'Após criar a empresa, abra-a novamente para cadastrar os catálogos.'
          : 'Cadastre os itens padrão que serão usados nos módulos do SIPGED.',
      child: Column(
        children: [
          if (widget.isCreateMode) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFDE68A),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFD97706),
                    size: 19,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Primeiro salve os dados principais da empresa. '
                          'Depois, edite a empresa criada para cadastrar unidades, rodovias, regiões, fontes e demais catálogos.',
                      style: TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          form(
            kind: _CatalogKind.unit,
            controller: _unitCtrl,
            labelText: 'Unidade / Setor',
            items: units,
            addLabel: 'Adicionar unidade',
            saveLabel: 'Salvar unidade',
            removeLabel: 'Remover',
          ),
          const SizedBox(height: 18),
          form(
            kind: _CatalogKind.road,
            controller: _roadCtrl,
            labelText: 'Rodovia',
            items: roads,
            addLabel: 'Adicionar rodovia',
            saveLabel: 'Salvar rodovia',
            removeLabel: 'Remover',
          ),
          const SizedBox(height: 18),
          form(
            kind: _CatalogKind.region,
            controller: _regionCtrl,
            labelText: 'Região / Área',
            items: regions,
            addLabel: 'Adicionar região',
            saveLabel: 'Salvar região',
            removeLabel: 'Remover',
          ),
          const SizedBox(height: 18),
          form(
            kind: _CatalogKind.fundingSource,
            controller: _fundingSourceCtrl,
            labelText: 'Fonte de recurso',
            items: fundingSources,
            addLabel: 'Adicionar fonte',
            saveLabel: 'Salvar fonte',
            removeLabel: 'Remover',
          ),
          const SizedBox(height: 18),
          form(
            kind: _CatalogKind.program,
            controller: _programCtrl,
            labelText: 'Programa de trabalho / Ação',
            items: programs,
            addLabel: 'Adicionar programa',
            saveLabel: 'Salvar programa',
            removeLabel: 'Remover',
          ),
          const SizedBox(height: 18),
          form(
            kind: _CatalogKind.expenseNature,
            controller: _expenseNatureCtrl,
            labelText: 'Natureza da despesa',
            items: expenseNatures,
            addLabel: 'Adicionar ND',
            saveLabel: 'Salvar ND',
            removeLabel: 'Remover',
          ),
          const SizedBox(height: 18),
          form(
            kind: _CatalogKind.companyBody,
            controller: _companyBodyCtrl,
            labelText: 'Órgão / Parceiro / Convenente',
            items: companyBodies,
            addLabel: 'Adicionar órgão',
            saveLabel: 'Salvar órgão',
            removeLabel: 'Remover',
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton({
    required bool floating,
  }) {
    final label = widget.isCreateMode ? 'Criar empresa' : 'Salvar configurações';

    final icon =
    widget.isCreateMode ? Icons.add_business_rounded : Icons.check_rounded;

    final child = FilledButton.icon(
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
          : Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: widget.isCreateMode
            ? const Color(0xFF059669)
            : const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF94A3B8),
        disabledForegroundColor: Colors.white,
        elevation: floating ? 8 : 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );

    if (!floating) return child;

    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: child,
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
          _buildSubmitButton(floating: false),
        ],
      ),
    );
  }

  Widget _buildSetupContent({
    required TenantState tenantState,
    required EdgeInsets padding,
    required bool showBottomBar,
    double scrollTopSpacing = 0,
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
                        if (scrollTopSpacing > 0)
                          SizedBox(height: scrollTopSpacing),
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
          if (showBottomBar) _buildBottomBar(pageMode: widget.isPage),
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
                title: widget.isCreateMode
                    ? 'Nova empresa'
                    : 'Configurações da empresa',
                onClose: null,
                showMinimize: false,
                contentPadding: EdgeInsets.zero,
                child: SizedBox(
                  height: dialogHeight,
                  child: BlocBuilder<TenantCubit, TenantState>(
                    builder: (context, tenantState) {
                      return _buildSetupContent(
                        tenantState: tenantState,
                        showBottomBar: true,
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
      floatingActionButton: _buildSubmitButton(floating: true),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: UpBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: CircleButtonChange(),
        ),
        titleWidgets: [
          Text(
            widget.isCreateMode ? 'Nova empresa' : 'Configurações da empresa',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          BackgroundChange(),
          BlocBuilder<TenantCubit, TenantState>(
            builder: (context, tenantState) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth >= 1500
                      ? 1120.0
                      : constraints.maxWidth >= 1100
                      ? 1040.0
                      : constraints.maxWidth >= 800
                      ? constraints.maxWidth * 0.9
                      : constraints.maxWidth - 24;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxWidth,
                      ),
                      child: _buildSetupContent(
                        tenantState: tenantState,
                        showBottomBar: false,
                        scrollTopSpacing: 12,
                        padding: const EdgeInsets.fromLTRB(
                          0,
                          0,
                          0,
                          92,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
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