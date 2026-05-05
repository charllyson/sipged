import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:sipged/_blocs/system/login/login_cubit.dart';
import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_blocs/system/user/user_repository.dart';

import 'package:sipged/_utils/formatters/sipged_format_numbers.dart';
import 'package:sipged/_utils/validates/sipged_validation.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/screens/common/login/sign_up/widgets/blocking_overlay.dart';
import 'package:sipged/screens/common/login/sign_up/widgets/sign_up_card.dart';

enum SignUpMode {
  selfRegister,
  adminCreateUser,
  editUser,
}

class SignUp extends StatefulWidget {
  const SignUp({
    super.key,
    required this.userData,
    this.mode = SignUpMode.selfRegister,
  });

  final UserData userData;
  final SignUpMode mode;

  bool get isSelfRegister => mode == SignUpMode.selfRegister;
  bool get isAdminCreateUser => mode == SignUpMode.adminCreateUser;
  bool get isEditUser => mode == SignUpMode.editUser;

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> with SipGedValidation {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _repeatPassController = TextEditingController();

  late final LoginCubit _loginCubit;

  final ValueNotifier<bool> _loading = ValueNotifier<bool>(false);

  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _photoBytes;
  String? _photoName;

  bool get _hasLoggedUser {
    return FirebaseAuth.instance.currentUser != null;
  }

  bool get _isUserInactive {
    return widget.userData.isActive == false &&
        widget.userData.isBlocked != true &&
        widget.userData.isDeleted != true;
  }

  bool get _isUserBlocked {
    return widget.userData.isBlocked == true &&
        widget.userData.isDeleted != true;
  }

  bool get _isUserDeleted {
    return widget.userData.isDeleted == true;
  }

  bool get _hasStatusRestriction {
    return _isUserInactive || _isUserBlocked || _isUserDeleted;
  }

  String get _overlayMessage {
    if (widget.isEditUser) return 'Salvando usuário…';
    if (widget.isAdminCreateUser) return 'Criando usuário…';
    return 'Criando conta…';
  }

  @override
  void initState() {
    super.initState();

    _loginCubit = context.read<LoginCubit>();

    _emailController.text = widget.userData.email ?? '';
    _nameController.text = widget.userData.name ?? '';
    _surnameController.text = widget.userData.surname ?? '';

    final cpfDigits = (widget.userData.cpf ?? '').replaceAll(RegExp(r'\D'), '');
    _cpfController.text =
    cpfDigits.isEmpty ? '' : SipGedFormatNumbers.formatCPF(cpfDigits);

    final birthday = widget.userData.dateToBirthday;
    if (birthday != null) {
      _birthdayController.text = _dateFormat.format(birthday);
    }
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
    _loading.dispose();

    super.dispose();
  }

  void _notify(
      String title, {
        String? subtitle,
        NotificationStatus status = NotificationStatus.info,
      }) {
    if (!mounted) return;

    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        leadingLabel: widget.isEditUser ? 'Usuário' : 'Cadastro',
        status: status,
        duration: const Duration(seconds: 4),
        extra: <String, dynamic>{
          'module': widget.isEditUser ? 'edit_user' : 'signup',
          'source': 'sign_up_page',
        },
      ),
    );
  }

  String? _validateRequiredText(
      String? value,
      String label,
      ) {
    final text = (value ?? '').trim();

    if (text.isEmpty) {
      return 'Informe $label.';
    }

    return null;
  }

  String? _validateNameRequired(String? value) {
    final requiredError = _validateRequiredText(value, 'o nome');
    if (requiredError != null) return requiredError;

    return validateName(value);
  }

  String? _validateSurnameRequired(String? value) {
    final requiredError = _validateRequiredText(value, 'o sobrenome');
    if (requiredError != null) return requiredError;

    return validateSurname(value);
  }

  String? _validateEmailRequired(String? value) {
    final email = (value ?? '').trim().toLowerCase();

    if (email.isEmpty) {
      return 'Informe o e-mail.';
    }

    if (email.contains(' ')) {
      return 'O e-mail não pode conter espaços.';
    }

    final emailRegex = RegExp(
      r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$',
      caseSensitive: false,
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Informe um e-mail válido.';
    }

    final parts = email.split('@');

    if (parts.length != 2) {
      return 'Informe um e-mail válido.';
    }

    final localPart = parts[0];
    final domain = parts[1];

    if (localPart.isEmpty || domain.isEmpty) {
      return 'Informe um e-mail válido.';
    }

    if (localPart.startsWith('.') || localPart.endsWith('.')) {
      return 'Informe um e-mail válido.';
    }

    if (domain.startsWith('.') || domain.endsWith('.')) {
      return 'Informe um e-mail válido.';
    }

    if (localPart.contains('..') || domain.contains('..')) {
      return 'Informe um e-mail válido.';
    }

    return null;
  }

  String? _validatePasswordRequired(String? value) {
    if (widget.isEditUser) return null;

    final requiredError = _validateRequiredText(value, 'a senha');
    if (requiredError != null) return requiredError;

    return validatePasswordLogin(value);
  }

  String? _validateRepeatPassword(String? value) {
    if (widget.isEditUser) return null;

    final requiredError = _validateRequiredText(value, 'a confirmação da senha');
    if (requiredError != null) return requiredError;

    if (_passController.text != (value ?? '')) {
      return 'As senhas não coincidem.';
    }

    return validatePasswordLogin(value);
  }

  String? _validateBirthdayRequired(DateTime? value) {
    if (value == null) {
      return 'Informe a data de nascimento.';
    }

    final today = DateTime.now();

    final selectedDate = DateTime(
      value.year,
      value.month,
      value.day,
    );

    final todayDate = DateTime(
      today.year,
      today.month,
      today.day,
    );

    if (selectedDate.isAfter(todayDate)) {
      return 'A data de nascimento não pode ser no futuro.';
    }

    final minDate = DateTime(
      today.year - 120,
      today.month,
      today.day,
    );

    if (selectedDate.isBefore(minDate)) {
      return 'Informe uma data de nascimento válida.';
    }

    return null;
  }

  bool _isValidCpf(String? value) {
    final cpf = (value ?? '').replaceAll(RegExp(r'\D'), '');

    if (cpf.length != 11) return false;

    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;

    int calcDigit(String base, int factor) {
      var total = 0;

      for (var i = 0; i < base.length; i++) {
        total += int.parse(base[i]) * factor;
        factor--;
      }

      final rest = total % 11;
      return rest < 2 ? 0 : 11 - rest;
    }

    final firstDigit = calcDigit(cpf.substring(0, 9), 10);
    final secondDigit = calcDigit(cpf.substring(0, 10), 11);

    return cpf[9] == firstDigit.toString() &&
        cpf[10] == secondDigit.toString();
  }

  String? _validateCpf(String? value) {
    final clean = (value ?? '').trim();

    if (clean.isEmpty) {
      return 'Informe o CPF.';
    }

    final digits = clean.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 11) {
      return 'CPF deve conter 11 números.';
    }

    if (!_isValidCpf(clean)) {
      return 'CPF inválido.';
    }

    return null;
  }

  void _formatCpfOnChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      if (_cpfController.text.isNotEmpty) {
        _cpfController.value = const TextEditingValue(text: '');
      }
      return;
    }

    final limitedDigits = digits.length > 11 ? digits.substring(0, 11) : digits;
    final formatted = SipGedFormatNumbers.formatCPF(limitedDigits);

    if (formatted == value) return;

    _cpfController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<bool> _emailAlreadyExists(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty) return false;

    final currentUid = widget.userData.uid?.trim();

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: cleanEmail)
        .limit(2)
        .get();

    if (!widget.isEditUser) {
      return snapshot.docs.isNotEmpty;
    }

    return snapshot.docs.any((doc) {
      if (currentUid == null || currentUid.isEmpty) return true;
      return doc.id != currentUid;
    });
  }

  Future<UserCredential> _createUserWithSecondaryAuth({
    required String email,
    required String password,
  }) async {
    final defaultApp = Firebase.app();

    final secondaryAppName =
        'sipged-admin-create-user-${DateTime.now().microsecondsSinceEpoch}';

    final secondaryApp = await Firebase.initializeApp(
      name: secondaryAppName,
      options: defaultApp.options,
    );

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(
        app: secondaryApp,
      );

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await secondaryAuth.signOut();

      return credential;
    } finally {
      await secondaryApp.delete();
    }
  }

  String _firebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado no Firebase Auth.';

      case 'invalid-email':
        return 'O e-mail informado é inválido.';

      case 'weak-password':
        return 'A senha informada é muito fraca.';

      case 'operation-not-allowed':
        return 'O cadastro por e-mail e senha não está habilitado no Firebase Auth.';

      case 'network-request-failed':
        return 'Falha de conexão. Verifique a internet e tente novamente.';

      default:
        return e.message ?? 'Não foi possível criar o usuário.';
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1200,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _photoBytes = bytes;
        _photoName = image.name;
      });
    } catch (e) {
      _notify(
        'Erro ao selecionar foto',
        subtitle: e.toString(),
        status: NotificationStatus.error,
      );
    }
  }

  void _clearPhoto() {
    setState(() {
      _photoBytes = null;
      _photoName = null;
    });
  }

  Future<String?> _uploadProfilePhoto({
    required String uid,
  }) async {
    final bytes = _photoBytes;

    if (bytes == null || uid.trim().isEmpty) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('users')
        .child(uid)
        .child('profile')
        .child('profile_photo.jpg');

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: <String, String>{
        'uid': uid,
        'source': 'sign_up_page',
        if (_photoName != null && _photoName!.trim().isNotEmpty)
          'originalName': _photoName!.trim(),
      },
    );

    await ref.putData(bytes, metadata);

    return ref.getDownloadURL();
  }

  Future<void> _saveProfilePhotoUrl({
    required String uid,
    required String photoUrl,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      <String, dynamic>{
        'photo': photoUrl,
        'photoUrl': photoUrl,
        'photoURL': photoUrl,
        'profilePhotoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _showPasswordMismatchDialog() async {
    if (!mounted) return;

    await showWindowDialog<void>(
      context: context,
      title: 'Erro na senha',
      width: 420,
      child: Builder(
        builder: (dialogCtx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'As senhas digitadas não coincidem. Por favor, digite novamente.',
                  style: TextStyle(
                    color: Color(0xFF344054),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool> _confirmDangerAction({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    if (!mounted) return false;

    final result = await showWindowDialog<bool>(
      context: context,
      title: title,
      width: 460,
      child: Builder(
        builder: (dialogCtx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF344054),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: confirmColor,
                      ),
                      onPressed: () => Navigator.of(dialogCtx).pop(true),
                      child: Text(confirmLabel),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return result == true;
  }

  Future<void> _submit() async {
    if (_loading.value) return;

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      _notify(
        'Formulário incompleto',
        subtitle: 'Preencha todos os campos obrigatórios corretamente.',
        status: NotificationStatus.warning,
      );
      return;
    }

    if (!widget.isEditUser &&
        _passController.text != _repeatPassController.text) {
      _passController.clear();
      _repeatPassController.clear();

      await _showPasswordMismatchDialog();
      return;
    }

    _formKey.currentState?.save();

    _loading.value = true;

    try {
      final navigator = Navigator.of(context);

      final repo = context.read<UserRepository>();
      final userCubit = context.read<UserCubit>();

      final email = _emailController.text.trim().toLowerCase();
      _emailController.text = email;

      final cpfDigits = _cpfController.text.replaceAll(RegExp(r'\D'), '');

      final exists = await _emailAlreadyExists(email);

      if (!mounted) return;

      if (exists) {
        _notify(
          'E-mail já cadastrado',
          subtitle: 'Já existe um usuário utilizando este e-mail.',
          status: NotificationStatus.warning,
        );

        return;
      }

      if (widget.isEditUser) {
        final uid = widget.userData.uid?.trim();

        if (uid == null || uid.isEmpty) {
          _notify(
            'Erro ao salvar',
            subtitle: 'O usuário editado não possui UID válido.',
            status: NotificationStatus.error,
          );
          return;
        }

        final editedUser = widget.userData
          ..uid = uid
          ..email = email
          ..name = _nameController.text.trim()
          ..surname = _surnameController.text.trim()
          ..cpf = cpfDigits;

        await repo.save(editedUser);

        final photoUrl = await _uploadProfilePhoto(uid: uid);

        if (photoUrl != null && photoUrl.trim().isNotEmpty) {
          editedUser.urlPhoto = photoUrl;

          await _saveProfilePhotoUrl(
            uid: uid,
            photoUrl: photoUrl,
          );
        }

        await userCubit.fetchById(uid);
        await userCubit.refreshUsers();

        if (!mounted) return;

        _notify(
          'Usuário atualizado com sucesso!',
          status: NotificationStatus.success,
        );

        navigator.pop(true);
        return;
      }

      final newUser = widget.userData
        ..email = email
        ..name = _nameController.text.trim()
        ..surname = _surnameController.text.trim()
        ..cpf = cpfDigits
        ..isActive = true
        ..isBlocked = false
        ..isDeleted = false;

      String? uid;

      if (widget.isAdminCreateUser) {
        final credential = await _createUserWithSecondaryAuth(
          email: email,
          password: _passController.text,
        );

        uid = credential.user?.uid.trim();
      } else {
        final ok = await _loginCubit.signUp(
          userData: newUser,
          pass: _passController.text,
        );

        if (!mounted) return;

        if (!ok) {
          _notify(
            'Erro ao cadastrar',
            subtitle: _loginCubit.state.errorMessage ??
                'Verifique os dados e tente novamente. O e-mail pode já estar cadastrado no Firebase Auth.',
            status: NotificationStatus.error,
          );

          return;
        }

        uid = _loginCubit.state.firebaseUser?.uid.trim();
      }

      if (uid == null || uid.isEmpty) {
        _notify(
          'Erro ao cadastrar',
          subtitle: 'O Firebase Auth não retornou o ID do usuário criado.',
          status: NotificationStatus.error,
        );

        return;
      }

      newUser.uid = uid;

      await repo.save(newUser);

      final photoUrl = await _uploadProfilePhoto(uid: uid);

      if (photoUrl != null && photoUrl.trim().isNotEmpty) {
        newUser.urlPhoto = photoUrl;

        await _saveProfilePhotoUrl(
          uid: uid,
          photoUrl: photoUrl,
        );
      }

      await userCubit.fetchById(uid);
      await userCubit.refreshUsers();

      if (!widget.isAdminCreateUser) {
        await userCubit.setCurrentUserBindEnabled(true);
      }

      if (!mounted) return;

      _notify(
        widget.isAdminCreateUser
            ? 'Usuário criado com sucesso!'
            : 'Cadastro realizado com sucesso!',
        status: NotificationStatus.success,
      );

      navigator.pop(true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      _notify(
        widget.isEditUser ? 'Erro ao salvar usuário' : 'Erro ao cadastrar',
        subtitle: _firebaseAuthErrorMessage(e),
        status: NotificationStatus.error,
      );
    } catch (e) {
      if (!mounted) return;

      _notify(
        widget.isEditUser
            ? 'Erro inesperado ao salvar usuário'
            : 'Erro inesperado ao cadastrar',
        subtitle: e.toString(),
        status: NotificationStatus.error,
      );
    } finally {
      if (mounted) {
        _loading.value = false;
      }
    }
  }

  Future<void> _deactivateUser() async {
    final uid = widget.userData.uid?.trim();

    if (uid == null || uid.isEmpty) return;

    final isInactive = _isUserInactive;

    final confirmed = await _confirmDangerAction(
      title: isInactive ? 'Reativar usuário' : 'Desativar usuário',
      message: isInactive
          ? 'Este usuário será reativado e voltará a aparecer como ativo no sistema.'
          : 'Este usuário ficará temporariamente desativado e aparecerá com aparência de inativo na lista.',
      confirmLabel: isInactive ? 'Reativar' : 'Desativar',
      confirmColor:
      isInactive ? const Color(0xFF2563EB) : const Color(0xFF667085),
    );

    if (!confirmed) return;

    _loading.value = true;

    try {
      if (isInactive) {
        await context.read<UserCubit>().reactivateUser(uid);

        widget.userData
          ..isActive = true
          ..isBlocked = false
          ..isDeleted = false
          ..deactivatedAt = null
          ..deactivatedReason = null;
      } else {
        await context.read<UserCubit>().deactivateUser(uid);

        widget.userData
          ..isActive = false
          ..isBlocked = false
          ..isDeleted = false
          ..deactivatedAt = DateTime.now()
          ..deactivatedReason = 'Desativado temporariamente pelo administrador.';
      }

      if (!mounted) return;

      _notify(
        isInactive ? 'Usuário reativado' : 'Usuário desativado',
        status: NotificationStatus.success,
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      _notify(
        isInactive ? 'Erro ao reativar usuário' : 'Erro ao desativar usuário',
        subtitle: e.toString(),
        status: NotificationStatus.error,
      );
    } finally {
      if (mounted) {
        _loading.value = false;
      }
    }
  }

  Future<void> _blockUser() async {
    final uid = widget.userData.uid?.trim();

    if (uid == null || uid.isEmpty) return;

    final isBlocked = _isUserBlocked;

    final confirmed = await _confirmDangerAction(
      title: isBlocked ? 'Desbloquear usuário' : 'Bloquear usuário',
      message: isBlocked
          ? 'Este usuário será desbloqueado, reativado e poderá receber permissões novamente.'
          : 'Este usuário será bloqueado, ficará inativo e terá permissões básicas removidas no documento de usuário.',
      confirmLabel: isBlocked ? 'Desbloquear' : 'Bloquear',
      confirmColor:
      isBlocked ? const Color(0xFF2563EB) : const Color(0xFFDC2626),
    );

    if (!confirmed) return;

    _loading.value = true;

    try {
      if (isBlocked) {
        await context.read<UserCubit>().reactivateUser(uid);

        widget.userData
          ..isActive = true
          ..isBlocked = false
          ..isDeleted = false
          ..blockedAt = null
          ..blockedReason = null;
      } else {
        await context.read<UserCubit>().blockUser(uid);

        widget.userData
          ..isActive = false
          ..isBlocked = true
          ..isDeleted = false
          ..blockedAt = DateTime.now()
          ..blockedReason = 'Bloqueado pelo administrador.';
      }

      if (!mounted) return;

      _notify(
        isBlocked ? 'Usuário desbloqueado' : 'Usuário bloqueado',
        status: NotificationStatus.success,
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      _notify(
        isBlocked ? 'Erro ao desbloquear usuário' : 'Erro ao bloquear usuário',
        subtitle: e.toString(),
        status: NotificationStatus.error,
      );
    } finally {
      if (mounted) {
        _loading.value = false;
      }
    }
  }

  Future<void> _deleteUser() async {
    final uid = widget.userData.uid?.trim();

    if (uid == null || uid.isEmpty) return;

    final confirmed = await _confirmDangerAction(
      title: 'Apagar usuário',
      message:
      'Esta ação apagará o documento do usuário no Firestore e os arquivos de perfil no Storage. Para apagar também do Firebase Auth, use uma Firebase Function com Admin SDK.',
      confirmLabel: 'Apagar',
      confirmColor: const Color(0xFF991B1B),
    );

    if (!confirmed) return;

    _loading.value = true;

    try {
      await context.read<UserCubit>().hardDeleteUserDocument(uid);

      if (!mounted) return;

      widget.userData
        ..isActive = false
        ..isBlocked = true
        ..isDeleted = true
        ..deletedAt = DateTime.now()
        ..deletedReason = 'Excluído pelo administrador.';

      _notify(
        'Usuário apagado',
        status: NotificationStatus.success,
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      _notify(
        'Erro ao apagar usuário',
        subtitle: e.toString(),
        status: NotificationStatus.error,
      );
    } finally {
      if (mounted) {
        _loading.value = false;
      }
    }
  }

  void _closePage() {
    if (!mounted) return;

    Navigator.of(context).maybePop(false);
  }

  Color _pageTintColor() {
    if (_isUserDeleted) return const Color(0xFF991B1B);
    if (_isUserBlocked) return const Color(0xFFDC2626);
    if (_isUserInactive) return const Color(0xFF667085);
    return const Color(0xFF2563EB);
  }

  @override
  Widget build(BuildContext context) {
    final hasLoggedUser = _hasLoggedUser;

    final cardBackgroundColor =
    _hasStatusRestriction ? const Color(0xFFF8FAFC) : Colors.white;

    final cardBorderColor =
    _hasStatusRestriction ? const Color(0xFFCBD5E1) : Colors.transparent;

    return Scaffold(
      appBar: UpBar(
        leading: const CircleButtonChange(),
        showNotificationBell: hasLoggedUser,
        showPhotoMenu: hasLoggedUser,
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
                              width: _hasStatusRestriction ? 1.4 : 0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _pageTintColor().withValues(
                                  alpha: _hasStatusRestriction ? 0.10 : 0.06,
                                ),
                                blurRadius: _hasStatusRestriction ? 22 : 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            autovalidateMode:
                            AutovalidateMode.onUserInteraction,
                            child: SignUpCard(
                              mode: widget.mode,
                              photoBytes: _photoBytes,
                              photoName: _photoName,
                              existingPhotoUrl: widget.userData.urlPhoto,
                              nameController: _nameController,
                              surnameController: _surnameController,
                              cpfController: _cpfController,
                              birthdayController: _birthdayController,
                              emailController: _emailController,
                              passController: _passController,
                              repeatPassController: _repeatPassController,
                              loading: _loading,
                              isDeactivateSelected: _isUserInactive,
                              isBlockSelected: _isUserBlocked,
                              isDeleteSelected: _isUserDeleted,
                              onPickPhoto: _pickPhoto,
                              onClearPhoto: _clearPhoto,
                              onCpfChanged: _formatCpfOnChanged,
                              onSubmit: _submit,
                              onCancel: _closePage,
                              onDeactivateUser:
                              widget.isEditUser ? _deactivateUser : null,
                              onBlockUser:
                              widget.isEditUser ? _blockUser : null,
                              onDeleteUser:
                              widget.isEditUser ? _deleteUser : null,
                              onSaveName: (v) {
                                widget.userData.name = v;
                              },
                              onSaveSurname: (v) {
                                widget.userData.surname = v;
                              },
                              onSaveCpf: (v) {
                                widget.userData.cpf =
                                    v?.replaceAll(RegExp(r'\D'), '');
                              },
                              onSaveEmail: (v) {
                                widget.userData.email =
                                    v?.trim().toLowerCase();
                              },
                              onSaveBirthday: (v) {
                                widget.userData.dateToBirthday = v;
                              },
                              validateName: _validateNameRequired,
                              validateSurname: _validateSurnameRequired,
                              validateCpf: _validateCpf,
                              validateEmail: _validateEmailRequired,
                              validateBirthday: _validateBirthdayRequired,
                              validatePassword: _validatePasswordRequired,
                              validateRepeatPassword: _validateRepeatPassword,
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
          ValueListenableBuilder<bool>(
            valueListenable: _loading,
            builder: (_, loading, _) {
              if (!loading) return const SizedBox.shrink();

              return BlockingOverlay(
                message: _overlayMessage,
              );
            },
          ),
        ],
      ),
    );
  }
}