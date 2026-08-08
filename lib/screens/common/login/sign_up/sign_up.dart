// lib/screens/common/login/sign_up/sign_up.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_utils/formatters/sipged_format_numbers.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/screens/common/login/sign_up/sign_up_cubit.dart';
import 'package:sipged/screens/common/login/sign_up/sign_up_data.dart';
import 'package:sipged/screens/common/login/sign_up/sign_up_state.dart';

import 'widgets/blocking_overlay.dart';
import 'widgets/sign_up_card.dart';

class SignUp extends StatelessWidget {
  const SignUp({
    super.key,
    required this.userData,
    this.mode = SignUpMode.selfRegister,
    this.cubit,
  });

  final UserData userData;
  final SignUpMode mode;

  /// Opcional para teste, injeção externa ou reaproveitamento em outro sistema.
  final SignUpCubit? cubit;

  bool get isSelfRegister => mode == SignUpMode.selfRegister;
  bool get isAdminCreateUser => mode == SignUpMode.adminCreateUser;
  bool get isEditUser => mode == SignUpMode.editUser;

  @override
  Widget build(BuildContext context) {
    final externalCubit = cubit;

    if (externalCubit != null) {
      externalCubit.initialize(
        userData: userData,
        mode: mode,
      );

      return BlocProvider<SignUpCubit>.value(
        value: externalCubit,
        child: const _SignUpView(),
      );
    }

    return BlocProvider<SignUpCubit>(
      create: (_) => SignUpCubit()
        ..initialize(
          userData: userData,
          mode: mode,
        ),
      child: const _SignUpView(),
    );
  }
}

class _SignUpView extends StatefulWidget {
  const _SignUpView();

  @override
  State<_SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<_SignUpView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _emailController;
  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _cpfController;
  late final TextEditingController _birthdayController;
  late final TextEditingController _passController;
  late final TextEditingController _repeatPassController;

  bool _didBindInitialData = false;

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController();
    _nameController = TextEditingController();
    _surnameController = TextEditingController();
    _cpfController = TextEditingController();
    _birthdayController = TextEditingController();
    _passController = TextEditingController();
    _repeatPassController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _cpfController.dispose();
    _birthdayController.dispose();
    _passController.dispose();
    _repeatPassController.dispose();

    super.dispose();
  }

  void _bindInitialData(SignUpState state) {
    if (_didBindInitialData) return;

    final data = state.data;

    _emailController.text = data.email;
    _nameController.text = data.name;
    _surnameController.text = data.surname;

    final cpfDigits = data.cpf.replaceAll(RegExp(r'\D'), '');
    _cpfController.text =
    cpfDigits.isEmpty ? '' : SipGedFormatNumbers.formatCPF(cpfDigits);

    _birthdayController.text = data.birthdayText;

    _didBindInitialData = true;
  }

  void _syncControllersFromState(SignUpState state) {
    final data = state.data;

    if (_emailController.text != data.email) {
      _emailController.text = data.email;
      _emailController.selection = TextSelection.fromPosition(
        TextPosition(offset: _emailController.text.length),
      );
    }

    if (_nameController.text != data.name) {
      _nameController.text = data.name;
      _nameController.selection = TextSelection.fromPosition(
        TextPosition(offset: _nameController.text.length),
      );
    }

    if (_surnameController.text != data.surname) {
      _surnameController.text = data.surname;
      _surnameController.selection = TextSelection.fromPosition(
        TextPosition(offset: _surnameController.text.length),
      );
    }

    if (_cpfController.text != data.cpfFormatted) {
      _cpfController.text = data.cpfFormatted;
      _cpfController.selection = TextSelection.fromPosition(
        TextPosition(offset: _cpfController.text.length),
      );
    }

    if (_birthdayController.text != data.birthdayText) {
      _birthdayController.text = data.birthdayText;
      _birthdayController.selection = TextSelection.fromPosition(
        TextPosition(offset: _birthdayController.text.length),
      );
    }
  }

  void _notify(
      String title, {
        String? subtitle,
        NotificationStatus status = NotificationStatus.info,
        required bool isEditUser,
      }) {
    if (!mounted) return;

    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        leadingLabel: isEditUser ? 'Usuário' : 'Cadastro',
        status: status,
        duration: const Duration(seconds: 4),
        extra: <String, dynamic>{
          'module': isEditUser ? 'edit_user' : 'signup',
          'source': 'sign_up_page',
        },
      ),
    );
  }

  Future<void> _submit(SignUpState state) async {
    if (state.isLoading) return;

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      _notify(
        'Formulário incompleto',
        subtitle: 'Preencha todos os campos obrigatórios corretamente.',
        status: NotificationStatus.warning,
        isEditUser: state.data.isEditUser,
      );
      return;
    }

    _formKey.currentState?.save();

    final ok = await context.read<SignUpCubit>().submit(
      name: _nameController.text,
      surname: _surnameController.text,
      cpf: _cpfController.text,
      birthdayText: _birthdayController.text,
      email: _emailController.text,
      password: _passController.text,
      repeatPassword: _repeatPassController.text,
    );

    if (!mounted) return;

    final currentState = context.read<SignUpCubit>().state;

    if (ok) {
      _notify(
        currentState.successMessage ??
            (currentState.data.isEditUser
                ? 'Usuário atualizado com sucesso!'
                : currentState.data.isAdminCreateUser
                ? 'Usuário criado com sucesso!'
                : 'Cadastro realizado com sucesso!'),
        status: NotificationStatus.success,
        isEditUser: currentState.data.isEditUser,
      );

      Navigator.of(context).pop(true);
      return;
    }

    if (currentState.clearPasswordFields) {
      _passController.clear();
      _repeatPassController.clear();
    }

    final error = currentState.errorMessage;

    if (error != null && error.trim().isNotEmpty) {
      _notify(
        currentState.data.isEditUser ? 'Erro ao salvar usuário' : 'Erro ao cadastrar',
        subtitle: error,
        status: NotificationStatus.error,
        isEditUser: currentState.data.isEditUser,
      );
    }
  }

  Future<void> _deactivateUser(SignUpState state) async {
    final ok = await context.read<SignUpCubit>().deactivateOrReactivateUser();

    if (!mounted) return;

    final currentState = context.read<SignUpCubit>().state;

    if (ok) {
      _notify(
        currentState.successMessage ?? 'Status do usuário atualizado',
        status: NotificationStatus.success,
        isEditUser: true,
      );

      Navigator.of(context).pop(true);
      return;
    }

    final error = currentState.errorMessage;

    if (error != null && error.trim().isNotEmpty) {
      _notify(
        'Erro ao atualizar status',
        subtitle: error,
        status: NotificationStatus.error,
        isEditUser: true,
      );
    }
  }

  Future<void> _blockUser(SignUpState state) async {
    final ok = await context.read<SignUpCubit>().blockOrUnblockUser();

    if (!mounted) return;

    final currentState = context.read<SignUpCubit>().state;

    if (ok) {
      _notify(
        currentState.successMessage ?? 'Status do usuário atualizado',
        status: NotificationStatus.success,
        isEditUser: true,
      );

      Navigator.of(context).pop(true);
      return;
    }

    final error = currentState.errorMessage;

    if (error != null && error.trim().isNotEmpty) {
      _notify(
        'Erro ao bloquear/desbloquear usuário',
        subtitle: error,
        status: NotificationStatus.error,
        isEditUser: true,
      );
    }
  }

  Future<void> _deleteUser(SignUpState state) async {
    final ok = await context.read<SignUpCubit>().deleteUser();

    if (!mounted) return;

    final currentState = context.read<SignUpCubit>().state;

    if (ok) {
      _notify(
        currentState.successMessage ?? 'Usuário apagado',
        status: NotificationStatus.success,
        isEditUser: true,
      );

      Navigator.of(context).pop(true);
      return;
    }

    final error = currentState.errorMessage;

    if (error != null && error.trim().isNotEmpty) {
      _notify(
        'Erro ao apagar usuário',
        subtitle: error,
        status: NotificationStatus.error,
        isEditUser: true,
      );
    }
  }

  void _closePage() {
    if (!mounted) return;

    Navigator.of(context).maybePop(false);
  }

  Color _pageTintColor(SignUpState state) {
    if (state.data.isUserDeleted) return const Color(0xFF991B1B);
    if (state.data.isUserBlocked) return const Color(0xFFDC2626);
    if (state.data.isUserInactive) return const Color(0xFF667085);

    return const Color(0xFF2563EB);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignUpCubit, SignUpState>(
      listenWhen: (previous, current) {
        return previous.data != current.data ||
            previous.photoBytes != current.photoBytes ||
            previous.status != current.status;
      },
      listener: (context, state) {
        _bindInitialData(state);
        _syncControllersFromState(state);
      },
      builder: (context, state) {
        _bindInitialData(state);

        final cardBackgroundColor = state.data.hasStatusRestriction
            ? const Color(0xFFF8FAFC)
            : Colors.white;

        final cardBorderColor = state.data.hasStatusRestriction
            ? const Color(0xFFCBD5E1)
            : Colors.transparent;

        return Scaffold(
          appBar: UpBar(
            leading: const CircleButtonChange(),
            showNotificationBell: state.data.hasLoggedUser,
            showPhotoMenu: state.data.hasLoggedUser,
          ),
          body: Stack(
            children: [
              const BackgroundChange(),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    final cardWidth = maxWidth >= 980 ? 900.0 : maxWidth;

                    return ListView(
                      keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: cardWidth,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: EdgeInsets.zero,
                              decoration: BoxDecoration(
                                color: cardBackgroundColor,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: cardBorderColor,
                                  width: state.data.hasStatusRestriction ? 1.4 : 0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _pageTintColor(state).withValues(
                                      alpha: state.data.hasStatusRestriction
                                          ? 0.10
                                          : 0.06,
                                    ),
                                    blurRadius:
                                    state.data.hasStatusRestriction ? 22 : 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                                child: SignUpCard(
                                  mode: state.data.mode,
                                  photoBytes: state.photoBytes,
                                  photoName: state.photoName,
                                  existingPhotoUrl: state.data.existingPhotoUrl,
                                  nameController: _nameController,
                                  surnameController: _surnameController,
                                  cpfController: _cpfController,
                                  birthdayController: _birthdayController,
                                  emailController: _emailController,
                                  passController: _passController,
                                  repeatPassController: _repeatPassController,
                                  loading: state.loadingNotifier,
                                  isDeactivateSelected: state.data.isUserInactive,
                                  isBlockSelected: state.data.isUserBlocked,
                                  isDeleteSelected: state.data.isUserDeleted,
                                  onPickPhoto: () {
                                    context.read<SignUpCubit>().pickPhoto();
                                  },
                                  onClearPhoto: () {
                                    context.read<SignUpCubit>().clearPhoto();
                                  },
                                  onCpfChanged: (value) {
                                    context.read<SignUpCubit>().changeCpf(value);
                                  },
                                  onSubmit: () => _submit(state),
                                  onCancel: _closePage,
                                  onDeactivateUser: state.data.isEditUser
                                      ? () => _deactivateUser(state)
                                      : null,
                                  onBlockUser: state.data.isEditUser
                                      ? () => _blockUser(state)
                                      : null,
                                  onDeleteUser: state.data.isEditUser
                                      ? () => _deleteUser(state)
                                      : null,
                                  onSaveName: (value) {
                                    context.read<SignUpCubit>().changeName(value);
                                  },
                                  onSaveSurname: (value) {
                                    context
                                        .read<SignUpCubit>()
                                        .changeSurname(value);
                                  },
                                  onSaveCpf: (value) {
                                    context.read<SignUpCubit>().changeCpf(value);
                                  },
                                  onSaveEmail: (value) {
                                    context.read<SignUpCubit>().changeEmail(value);
                                  },
                                  onSaveBirthday: (value) {
                                    context
                                        .read<SignUpCubit>()
                                        .changeBirthday(value);
                                  },
                                  validateName: context
                                      .read<SignUpCubit>()
                                      .validateNameRequired,
                                  validateSurname: context
                                      .read<SignUpCubit>()
                                      .validateSurnameRequired,
                                  validateCpf:
                                  context.read<SignUpCubit>().validateCpf,
                                  validateEmail:
                                  context.read<SignUpCubit>().validateEmail,
                                  validateBirthday:
                                  context.read<SignUpCubit>().validateBirthday,
                                  validatePassword:
                                  context.read<SignUpCubit>().validatePassword,
                                  validateRepeatPassword: (value) {
                                    return context
                                        .read<SignUpCubit>()
                                        .validateRepeatPassword(
                                      password: _passController.text,
                                      repeatPassword: value,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (state.isLoading)
                BlockingOverlay(
                  message: state.overlayMessage,
                ),
            ],
          ),
        );
      },
    );
  }
}