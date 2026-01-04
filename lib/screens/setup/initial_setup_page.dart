/*
// lib/screens/system/setup/initial_setup_page.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:siged/_blocs/system/setup/setup_region_map.dart';

import 'package:siged/_widgets/windows/window_dialog.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_utils/formats/mask_class.dart';

import 'package:siged/_blocs/system/setup/setup_cubit.dart';
import 'package:siged/_blocs/system/setup/setup_state.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

class InitialSetupPage extends StatefulWidget {
  final UserData user;

  const InitialSetupPage({super.key, required this.user});

  @override
  State<InitialSetupPage> createState() => _InitialSetupPageState();
}

class _InitialSetupPageState extends State<InitialSetupPage> {
  // FORM PRINCIPAL
  final _formKey = GlobalKey<FormState>();

  // CAMPOS — seção 1
  final _empresaNomeCtrl = TextEditingController();
  final _empresaCnpjCtrl = TextEditingController();

  // CAMPOS — seção 2
  final _newCompanyBodyCtrl = TextEditingController();
  final _newCompanyBodyCnpjCtrl = TextEditingController();

  // CAMPOS — seção 3
  final _newUnitCtrl = TextEditingController();

  // CAMPOS — seção 4
  final _newRoadCtrl = TextEditingController();

  // CAMPOS — seção 5 (Regiões)
  final _newRegionCtrl = TextEditingController();
  List<String> _selectedMunicipios = [];

  // CAMPOS — seção 6 (Fontes)
  final _newFundingCtrl = TextEditingController();

  // CAMPOS — seção 7 (Programas)
  final _newProgramCtrl = TextEditingController();

  // CAMPOS — seção 8 (Naturezas)
  final _newExpenseNatureCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final setup = context.read<SetupCubit>();
    setup.loadCompanies();
  }

  @override
  void dispose() {
    _empresaNomeCtrl.dispose();
    _empresaCnpjCtrl.dispose();
    _newCompanyBodyCtrl.dispose();
    _newCompanyBodyCnpjCtrl.dispose();
    _newUnitCtrl.dispose();
    _newRoadCtrl.dispose();
    _newRegionCtrl.dispose();
    _newFundingCtrl.dispose();
    _newProgramCtrl.dispose();
    _newExpenseNatureCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving) return;

    setState(() => _saving = true);

    final setup = context.read<SetupCubit>();

    // 1) cria empresa principal
    final company = await setup.createCompany(
      _empresaNomeCtrl.text.trim(),
      cnpj: _empresaCnpjCtrl.text.trim(),
    );

    if (company == null) {
      _error('Falha ao salvar empresa principal.');
      return;
    }

    final id = company.id;

    // 2) recarrega estrutura
    await setup.selectCompany(id);

    setState(() => _saving = false);

    if (!mounted) return;
    Navigator.of(context).pop(); // volta ao sistema
  }

  void _error(String msg) {
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // FUNDO COM EFEITO DE VIDRO
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: Colors.black.withOpacity(0.30),
          ),
        ),

        Center(
          child: LayoutBuilder(
            builder: (_, constraints) {
              final width = (constraints.maxWidth * 0.9).clamp(680.0, 1200.0);
              // altura máxima do conteúdo do diálogo (para habilitar scroll)
              final dialogHeight =
              (constraints.maxHeight * 0.9).clamp(400.0, 800.0);

              return WindowDialog(
                width: width,
                title: 'Configurações iniciais do SIGED',
                onClose: null, // não permite fechar sem configurar
                showMinimize: false,
                contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: SizedBox(
                  height: dialogHeight,
                  child: BlocBuilder<SetupCubit, SetupState>(
                    builder: (context, state) {
                      return Form(
                        key: _formKey,
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                //
                                // ░░░ SEÇÃO 1 — EMPRESA PRINCIPAL ░░░
                                //
                                _sectionTitle('1) Empresa / Órgão principal'),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: CustomTextField(
                                        controller: _empresaNomeCtrl,
                                        labelText: 'Nome da organização',
                                        validator: (v) {
                                          if (v == null ||
                                              v.trim().isEmpty) {
                                            return 'Informe o nome';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 2,
                                      child: CustomTextField(
                                        controller: _empresaCnpjCtrl,
                                        labelText: 'CNPJ',
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(14),
                                          TextInputMask(
                                              mask:
                                              '99.999.999/9999-99'),
                                        ],
                                        validator: (v) {
                                          final raw = v?.replaceAll(
                                              RegExp(r'\D'),
                                              '') ??
                                              '';
                                          if (raw.isEmpty) {
                                            return 'Informe o CNPJ';
                                          }
                                          if (raw.length != 14) {
                                            return 'CNPJ inválido';
                                          }
                                          if (!CNPJValidator.isValid(raw)) {
                                            return 'CNPJ inválido';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                //
                                // ░░░ SEÇÃO 2 — EMPRESAS CONTRATADAS ░░░
                                //
                                _sectionTitle('2) Empresas contratadas'),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: state.companyBodies
                                      .map(
                                        (e) => Chip(
                                      label: Text(e.label),
                                      onDeleted: () {},
                                    ),
                                  )
                                      .toList(),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _newCompanyBodyCtrl,
                                        labelText: 'Nome/Razão social',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _newCompanyBodyCnpjCtrl,
                                        labelText: 'CNPJ',
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(14),
                                          TextInputMask(
                                            mask:
                                            '99.999.999/9999-99',
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton(
                                      onPressed: () async {
                                        final name = _newCompanyBodyCtrl.text
                                            .trim();
                                        if (name.isEmpty) return;
                                        final created = await context
                                            .read<SetupCubit>()
                                            .createCompanyBody(
                                          state.selectedCompanyId ??
                                              state.companies.first.id,
                                          name,
                                          cnpj:
                                          _newCompanyBodyCnpjCtrl.text
                                              .trim(),
                                        );
                                        if (created != null) {
                                          _newCompanyBodyCtrl.clear();
                                          _newCompanyBodyCnpjCtrl.clear();
                                        }
                                      },
                                      child: const Text('Adicionar'),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                //
                                // ░░░ SEÇÃO 3 — UNIDADES ░░░
                                //
                                _sectionTitle('3) Unidades / Setores'),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: state.units
                                      .map(
                                        (e) => Chip(
                                      label: Text(e.label),
                                      onDeleted: () {},
                                    ),
                                  )
                                      .toList(),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _newUnitCtrl,
                                        labelText: 'Nome da unidade',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton(
                                      onPressed: () async {
                                        final name =
                                        _newUnitCtrl.text.trim();
                                        if (name.isEmpty) return;

                                        final created = await context
                                            .read<SetupCubit>()
                                            .createUnit(
                                          state.selectedCompanyId ??
                                              state.companies.first.id,
                                          name,
                                        );

                                        if (created != null) {
                                          _newUnitCtrl.clear();
                                        }
                                      },
                                      child: const Text('Adicionar'),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                //
                                // ░░░ SEÇÃO 4 — RODOVIAS ░░░
                                //
                                _sectionTitle('4) Rodovias / Estradas'),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: state.roads
                                      .map(
                                        (e) => Chip(
                                      label: Text(e.label),
                                      onDeleted: () {},
                                    ),
                                  )
                                      .toList(),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _newRoadCtrl,
                                        labelText:
                                        'Nome da estrada/rodovia',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton(
                                      onPressed: () async {
                                        final name =
                                        _newRoadCtrl.text.trim();
                                        if (name.isEmpty) return;

                                        final created = await context
                                            .read<SetupCubit>()
                                            .createRoad(
                                          state.selectedCompanyId ??
                                              state.companies.first.id,
                                          name,
                                        );
                                        if (created != null) {
                                          _newRoadCtrl.clear();
                                        }
                                      },
                                      child: const Text('Adicionar'),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                //
                                // ░░░ SEÇÃO 5 — REGIÕES ░░░
                                //
                                _sectionTitle('5) Regiões e municípios'),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: state.regions
                                      .map(
                                        (e) => Chip(
                                      label: Text(e.label),
                                    ),
                                  )
                                      .toList(),
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _newRegionCtrl,
                                        labelText: 'Nome da região',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton(
                                      onPressed: () async {
                                        final selected =
                                        await setupRegionMap(context);

                                        if (selected != null) {
                                          setState(
                                                () => _selectedMunicipios =
                                                selected,
                                          );
                                        }
                                      },
                                      child: const Text(
                                          'Selecionar municípios'),
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
                                  child: FilledButton(
                                    onPressed: () async {
                                      final name =
                                      _newRegionCtrl.text.trim();
                                      if (name.isEmpty) return;

                                      final created = await context
                                          .read<SetupCubit>()
                                          .createRegion(
                                        state.selectedCompanyId ??
                                            state.companies.first.id,
                                        name,
                                        municipios: _selectedMunicipios,
                                      );

                                      if (created != null) {
                                        _newRegionCtrl.clear();
                                        setState(
                                                () => _selectedMunicipios = []);
                                      }
                                    },
                                    child: const Text('Adicionar região'),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                //
                                // ░░░ SEÇÃO 6 — FONTES DE RECURSO ░░░
                                //
                                _sectionTitle('6) Fontes de recurso'),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: state.fundingSources
                                      .map(
                                        (e) => Chip(
                                      label: Text(e.label),
                                    ),
                                  )
                                      .toList(),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _newFundingCtrl,
                                        labelText: 'Nome da fonte',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton(
                                      onPressed: () async {
                                        final name =
                                        _newFundingCtrl.text.trim();
                                        if (name.isEmpty) return;

                                        final created = await context
                                            .read<SetupCubit>()
                                            .createFundingSource(
                                          state.selectedCompanyId ??
                                              state.companies.first.id,
                                          name,
                                        );

                                        if (created != null) {
                                          _newFundingCtrl.clear();
                                        }
                                      },
                                      child: const Text('Adicionar'),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                //
                                // ░░░ SEÇÃO 7 — PROGRAMAS ░░░
                                //
                                _sectionTitle('7) Programas'),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: state.programs
                                      .map(
                                        (e) => Chip(
                                      label: Text(e.label),
                                    ),
                                  )
                                      .toList(),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _newProgramCtrl,
                                        labelText: 'Nome do programa',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton(
                                      onPressed: () async {
                                        final name =
                                        _newProgramCtrl.text.trim();
                                        if (name.isEmpty) return;

                                        final created = await context
                                            .read<SetupCubit>()
                                            .createProgram(
                                          state.selectedCompanyId ??
                                              state.companies.first.id,
                                          name,
                                        );
                                        if (created != null) {
                                          _newProgramCtrl.clear();
                                        }
                                      },
                                      child: const Text('Adicionar'),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                //
                                // ░░░ SEÇÃO 8 — NATUREZA DE DESPESA ░░░
                                //
                                _sectionTitle(
                                    '8) Naturezas de despesa'),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: state.expenseNatures
                                      .map(
                                        (e) => Chip(
                                      label: Text(e.label),
                                    ),
                                  )
                                      .toList(),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        controller:
                                        _newExpenseNatureCtrl,
                                        labelText:
                                        'Nome da natureza de despesa',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton(
                                      onPressed: () async {
                                        final name =
                                        _newExpenseNatureCtrl.text
                                            .trim();
                                        if (name.isEmpty) return;

                                        final created = await context
                                            .read<SetupCubit>()
                                            .createExpenseNature(
                                          state.selectedCompanyId ??
                                              state.companies.first.id,
                                          name,
                                        );
                                        if (created != null) {
                                          _newExpenseNatureCtrl.clear();
                                        }
                                      },
                                      child: const Text('Adicionar'),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 28),

                                //
                                // ░░░ RODAPÉ DO FORMULÁRIO ░░░
                                //
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.end,
                                  children: [
                                    FilledButton.icon(
                                      onPressed:
                                      _saving ? null : _submit,
                                      icon: _saving
                                          ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child:
                                        CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                          : const Icon(Icons.check),
                                      label: const Text(
                                          'Salvar e entrar'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
*/
