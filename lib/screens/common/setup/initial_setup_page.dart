import 'dart:typed_data';
import 'dart:ui';

import 'package:cpf_cnpj_validator/cnpj_validator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_data.dart';
import 'package:sipged/_blocs/system/tenant/tenant_state.dart';

import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/dialog/windows/window_dialog.dart';

import 'package:sipged/screens/common/setup/initial_setup_header.dart';

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

  final _tenantFantasyCtrl = TextEditingController();
  final _tenantNameCtrl = TextEditingController();
  final _tenantCnpjCtrl = TextEditingController();

  Uint8List? _logoBytes;
  String? _logoFileName;
  String? _logoContentType;

  String? _existingLogoUrl;
  String? _existingLogoPath;

  bool _removeCurrentLogo = false;
  bool _saving = false;
  bool _hydratedFromTenant = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<TenantCubit>().loadTenantProfile();
    });
  }

  @override
  void dispose() {
    _tenantFantasyCtrl.dispose();
    _tenantNameCtrl.dispose();
    _tenantCnpjCtrl.dispose();

    super.dispose();
  }

  void _hydrateFromTenant(TenantData? tenant) {
    if (tenant == null) return;

    if (_hydratedFromTenant && _tenantNameCtrl.text.trim().isNotEmpty) {
      return;
    }

    _tenantFantasyCtrl.text = tenant.fantasyName ?? '';
    _tenantNameCtrl.text = tenant.companyName ?? tenant.label;
    _tenantCnpjCtrl.text = tenant.cnpj ?? '';

    _existingLogoUrl = tenant.logoUrl;
    _existingLogoPath = tenant.logoPath;

    _logoBytes = null;
    _logoFileName = null;
    _logoContentType = null;
    _removeCurrentLogo = false;

    _hydratedFromTenant = true;
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving) return;

    setState(() => _saving = true);

    final tenantCubit = context.read<TenantCubit>();

    final saved = await tenantCubit.saveTenantProfile(
      label: _tenantNameCtrl.text.trim(),
      fantasyName: _tenantFantasyCtrl.text.trim(),
      cnpj: _tenantCnpjCtrl.text.trim(),
      logoBytes: _logoBytes,
      logoFileName: _logoFileName,
      logoContentType: _logoContentType,
      removeLogo: _removeCurrentLogo,
      oldLogoPath: _existingLogoPath,
    );

    if (!mounted) return;

    if (saved == null) {
      final msg = tenantCubit.state.error ??
          'Falha ao salvar configurações do tenant.';

      _error(msg);
      return;
    }

    setState(() {
      _saving = false;
      _hydrateFromTenant(saved);
    });

    _success('Configurações salvas com sucesso.');
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
            label: Text(
              pageMode ? 'Salvar configurações' : 'Salvar e entrar',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupContent({
    required TenantState tenantState,
    required EdgeInsets padding,
  }) {
    final isLoadingTenant = tenantState.isLoading && !_hydratedFromTenant;

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
                          cnpjValidator: (value) {
                            final raw =
                                value?.replaceAll(RegExp(r'\D'), '') ?? '';

                            if (raw.isEmpty) return 'Informe o CNPJ';
                            if (raw.length != 14) return 'CNPJ inválido';
                            if (!CNPJValidator.isValid(raw)) {
                              return 'CNPJ inválido';
                            }

                            return null;
                          },
                        ),
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
                520.0,
                860.0,
              );

              final dialogHeight = (constraints.maxHeight * 0.9).clamp(
                360.0,
                620.0,
              );

              return WindowDialog(
                width: width,
                title: 'Configurações iniciais do SIPGED',
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
            child: BlocBuilder<TenantCubit, TenantState>(
              builder: (context, tenantState) {
                final media = MediaQuery.of(context);
                final topSafe = media.padding.top;

                const appBarHeight = 56.0;
                final topOffset = topSafe + appBarHeight + 12;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth >= 1500
                        ? 920.0
                        : constraints.maxWidth >= 1100
                        ? 820.0
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
                            child: _buildSetupContent(
                              tenantState: tenantState,
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                20,
                                20,
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
    return BlocListener<TenantCubit, TenantState>(
      listener: (context, state) {
        _hydrateFromTenant(state.tenantProfile);
      },
      child: widget.isPage ? _buildPageMode() : _buildDialogMode(),
    );
  }
}