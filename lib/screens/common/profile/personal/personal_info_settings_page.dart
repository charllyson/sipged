import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/screens/common/profile/widgets/profile_hero.dart';
import 'package:sipged/screens/common/profile/widgets/modern_card.dart';
import 'package:sipged/screens/common/profile/widgets/name_field.dart';
import 'package:sipged/screens/common/profile/widgets/readonly_info_panel.dart';
import 'package:sipged/screens/common/profile/widgets/surname_field.dart';

class PersonalInfoSettingsPage extends StatefulWidget {
  const PersonalInfoSettingsPage({
    super.key,
    required this.initialUser,
  });

  final UserData initialUser;

  @override
  State<PersonalInfoSettingsPage> createState() =>
      _PersonalInfoSettingsPageState();
}

class _PersonalInfoSettingsPageState extends State<PersonalInfoSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();

  bool _saving = false;
  bool _hasChanges = false;

  String? _currentPhoto;
  Uint8List? _previewBytes;
  XFile? _pickedFile;

  @override
  void initState() {
    super.initState();

    _firstCtrl.text = (widget.initialUser.name ?? '').trim();
    _lastCtrl.text = (widget.initialUser.surname ?? '').trim();
    _currentPhoto = widget.initialUser.urlPhoto;

    _firstCtrl.addListener(_markChanged);
    _lastCtrl.addListener(_markChanged);
  }

  @override
  void dispose() {
    _firstCtrl.removeListener(_markChanged);
    _lastCtrl.removeListener(_markChanged);

    _firstCtrl.dispose();
    _lastCtrl.dispose();

    super.dispose();
  }

  void _markChanged() {
    if (_hasChanges) return;
    setState(() => _hasChanges = true);
  }

  void _notifySuccessWithCubit(
      NotificationLocalCubit notificationCubit,
      String message,
      ) {
    notificationCubit.show(
      NotificationData(
        title: 'Sucesso',
        subtitle: message,
        status: NotificationStatus.success,
        leadingLabel: 'Perfil',
      ),
    );
  }

  void _notifyErrorWithCubit(
      NotificationLocalCubit notificationCubit,
      String message,
      ) {
    notificationCubit.show(
      NotificationData(
        title: 'Erro',
        subtitle: message,
        status: NotificationStatus.error,
        leadingLabel: 'Perfil',
      ),
    );
  }

  String _composeDisplayName(UserData user) {
    final name = _firstCtrl.text.trim();
    final surname = _lastCtrl.text.trim();

    final display = [name, surname].where((e) => e.isNotEmpty).join(' ').trim();

    if (display.isNotEmpty) return display;

    final fallbackName = (user.name ?? '').trim();
    final fallbackSurname = (user.surname ?? '').trim();

    return [fallbackName, fallbackSurname]
        .where((e) => e.isNotEmpty)
        .join(' ')
        .trim();
  }

  Future<void> _pickImage() async {
    if (_saving) return;

    final notificationCubit = context.read<NotificationLocalCubit>();

    try {
      final picker = ImagePicker();

      final img = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1200,
      );

      if (!mounted) return;
      if (img == null) return;

      if (kIsWeb) {
        final bytes = await img.readAsBytes();

        if (!mounted) return;

        setState(() {
          _previewBytes = bytes;
          _pickedFile = null;
          _hasChanges = true;
        });
      } else {
        setState(() {
          _pickedFile = img;
          _previewBytes = null;
          _hasChanges = true;
        });
      }
    } catch (_) {
      if (!mounted) return;

      _notifyErrorWithCubit(
        notificationCubit,
        'Não foi possível selecionar a imagem.',
      );
    }
  }

  Future<String?> _uploadIfNeeded({
    required String uid,
    required NotificationLocalCubit notificationCubit,
  }) async {
    if (_previewBytes == null && _pickedFile == null) {
      return _currentPhoto;
    }

    try {
      final ref = FirebaseStorage.instance.ref('users/$uid/profile.jpg');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: <String, String>{
          'uid': uid,
          'module': 'profile',
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      final Uint8List bytes;

      if (kIsWeb) {
        bytes = _previewBytes!;
      } else {
        bytes = await _pickedFile!.readAsBytes();
      }

      final task = ref.putData(bytes, metadata);
      final snap = await task.whenComplete(() => null);

      return snap.ref.getDownloadURL();
    } catch (_) {
      if (mounted) {
        _notifyErrorWithCubit(
          notificationCubit,
          'Não foi possível enviar a foto.',
        );
      }

      return _currentPhoto;
    }
  }

  Future<void> _save(UserData current) async {
    if (_saving) return;

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final userCubit = context.read<UserCubit>();
    final notificationCubit = context.read<NotificationLocalCubit>();

    setState(() => _saving = true);

    try {
      final uid = current.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';

      if (uid.trim().isEmpty) {
        throw Exception('UID inválido');
      }

      final photoUrl = await _uploadIfNeeded(
        uid: uid,
        notificationCubit: notificationCubit,
      );

      final firstName = _firstCtrl.text.trim();
      final lastName = _lastCtrl.text.trim();

      final updated = UserData(
        uid: uid,
        name: firstName,
        surname: lastName,
        email: current.email,
        cpf: current.cpf,
        gender: current.gender,
        urlPhoto: photoUrl,
        cellPhone: current.cellPhone,
        themeDark: current.themeDark,
        geoPoint: current.geoPoint,
        dateToBirthday: current.dateToBirthday,
        createUser: current.createUser,
        baseProfile: current.baseProfile,
        baseRole: current.baseRole,
        profileWork: current.profileWork,
        profileLegal: current.profileLegal,
      );

      await userCubit.saveUser(updated);

      final authUser = FirebaseAuth.instance.currentUser;

      if (authUser != null) {
        final displayName = [firstName, lastName]
            .where((e) => e.isNotEmpty)
            .join(' ')
            .trim();

        await authUser.updateDisplayName(
          displayName.isEmpty ? null : displayName,
        );

        if ((photoUrl ?? '').isNotEmpty) {
          await authUser.updatePhotoURL(photoUrl);
        }
      }

      if (!mounted) return;

      setState(() {
        _currentPhoto = photoUrl ?? _currentPhoto;
        _pickedFile = null;
        _previewBytes = null;
        _hasChanges = false;
      });

      _notifySuccessWithCubit(
        notificationCubit,
        'Informações pessoais atualizadas.',
      );
    } catch (_) {
      if (!mounted) return;

      _notifyErrorWithCubit(
        notificationCubit,
        'Falha ao salvar as informações pessoais.',
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.initialUser;

    return Scaffold(
      appBar: UpBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: CircleButtonChange(),
        ),
      ),
      body: Stack(
        children: [
          const BackgroundChange(),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfileHero(
                      user: user,
                      displayName: _composeDisplayName(user),
                      currentPhoto: _currentPhoto,
                      previewBytes: _previewBytes,
                      hasChanges: _hasChanges,
                      onPickImage: _pickImage,
                      showEditButton: true,
                    ),
                    const SizedBox(height: 18),
                    ModernCard(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 680;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _SectionHeader(),
                                const SizedBox(height: 22),
                                if (isWide)
                                  Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: NameField(
                                          controller: _firstCtrl,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: SurnameField(
                                          controller: _lastCtrl,
                                        ),
                                      ),
                                    ],
                                  )
                                else ...[
                                  NameField(controller: _firstCtrl),
                                  const SizedBox(height: 14),
                                  SurnameField(controller: _lastCtrl),
                                ],
                                const SizedBox(height: 18),
                                ReadonlyInfoPanel(user: user),
                                const SizedBox(height: 22),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _hasChanges
                                            ? 'Você possui alterações não salvas.'
                                            : 'Nenhuma alteração pendente.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                          color: _hasChanges
                                              ? Colors.orange.shade800
                                              : Colors.blueGrey.shade500,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton.icon(
                                      onPressed: _saving || !_hasChanges
                                          ? null
                                          : () => _save(user),
                                      icon: _saving
                                          ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: LoadingTreeDots(
                                          size: 20,
                                          centered: false,
                                        ),
                                      )
                                          : const Icon(Icons.save_rounded),
                                      label: Text(
                                        _saving
                                            ? 'Salvando...'
                                            : 'Salvar alterações',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.person_rounded,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Informações pessoais',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}