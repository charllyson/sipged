// lib/screens/profile/user_profile_page.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_event.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/menu/upBar/up_bar.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  static const double _cardsLift = 120; // ajuste fino aqui (ex.: 24 ~ 36)


  bool _saving = false;

  String? _currentPhoto;
  Uint8List? _previewBytes; // web
  XFile? _pickedFile;       // mobile

  bool _didPrefillOnce = false;

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    super.dispose();
  }

  // -------------------- UI helpers --------------------

  /// Header compacto, SEM avatar (para não duplicar com o card)
  Widget _header(UserData? user) {
    final theme = Theme.of(context);
    final displayName = _composeDisplayName(user);

    return SizedBox(
      height: 110,
      width: double.infinity,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Meu perfil',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayName.isEmpty ? 'Atualize suas informações' : displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassCard(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }

  String _composeDisplayName(UserData? u) {
    final name = (u?.name ?? '').trim();
    final surname = (u?.surname ?? '').trim();
    return [name, surname].where((s) => s.isNotEmpty).join(' ').trim();
  }

  // -------------------- Foto --------------------

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img == null) return;

    if (kIsWeb) {
      final bytes = await img.readAsBytes();
      setState(() {
        _previewBytes = bytes;
        _pickedFile = null;
      });
    } else {
      setState(() {
        _pickedFile = img;
        _previewBytes = null;
      });
    }
  }

  Future<String?> _uploadIfNeeded(String uid) async {
    if (_previewBytes == null && _pickedFile == null) return _currentPhoto;

    try {
      final ref = FirebaseStorage.instance.ref('users/$uid/profile.jpg');
      UploadTask task;
      if (kIsWeb) {
        task = ref.putData(_previewBytes!, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        task = ref.putData(await _pickedFile!.readAsBytes(), SettableMetadata(contentType: 'image/jpeg'));
      }
      final snap = await task.whenComplete(() => null);
      return await snap.ref.getDownloadURL();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível enviar a foto.')),
        );
      }
      return _currentPhoto;
    }
  }

  // -------------------- Salvar --------------------

  Future<void> _onSave(UserData current) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final uid = current.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) throw Exception('UID inválido');

      final photoUrl = await _uploadIfNeeded(uid);

      final updated = UserData(
        uid: uid,
        name: _firstCtrl.text.trim(),
        surname: _lastCtrl.text.trim(),
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
      );

      context.read<UserBloc>().add(UserSaveRequested(updated));

      final authUser = FirebaseAuth.instance.currentUser;
      final displayName = [_firstCtrl.text.trim(), _lastCtrl.text.trim()]
          .where((s) => s.isNotEmpty)
          .join(' ')
          .trim();
      if (authUser != null) {
        await authUser.updateDisplayName(displayName.isEmpty ? null : displayName);
        if ((photoUrl ?? '').isNotEmpty) {
          await authUser.updatePhotoURL(photoUrl);
        }
      }

      if (mounted) {
        setState(() {
          _currentPhoto = photoUrl ?? _currentPhoto;
          _pickedFile = null;
          _previewBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado!')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao salvar seu perfil.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // -------------------- Build --------------------

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (prev, curr) => prev.current != curr.current || prev.isLoadingUsers != curr.isLoadingUsers,
      builder: (context, state) {
        final user = state.current;

        if (!_didPrefillOnce && user != null) {
          _didPrefillOnce = true;
          _firstCtrl.text = (user.name ?? '').trim();
          _lastCtrl.text = (user.surname ?? '').trim();
          _currentPhoto = user.urlPhoto;
        }

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: UpBar(
              leading: const Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: BackCircleButton(),
              ),
              photoMenu: const SizedBox.shrink(),
            ),
          ),
          body: Stack(
            children: [
              const BackgroundClean(),
              Column(
                children: [
                  _header(user),
                  Expanded(
                    child: user == null
                        ? const Center(child: CircularProgressIndicator())
                        : LayoutBuilder(
                      builder: (context, c) {
                        final isWide = c.maxWidth >= 860;

                        // ----- Card da foto (sempre acima) -----
                        final photoCard = _glassCard(
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                            child: Row(
                              children: [
                                _AvatarEditable(
                                  radius: 60,
                                  photoUrl: _currentPhoto,
                                  previewBytes: _previewBytes,
                                  onTap: _pickImage,
                                ),
                                const SizedBox(width: 16),
                                FilledButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.photo),
                                  label: const Text('Trocar foto'),
                                ),
                              ],
                            ),
                          ),
                        );

                        // ----- Formulário -----
                        final formCard = _glassCard(
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.account_circle, color: Colors.black54),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Informações básicas',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  if (isWide)
                                    Row(
                                      children: [
                                        Expanded(child: _nameField()),
                                        const SizedBox(width: 12),
                                        Expanded(child: _surnameField()),
                                      ],
                                    )
                                  else ...[
                                    _nameField(),
                                    const SizedBox(height: 12),
                                    _surnameField(),
                                  ],
                                  const SizedBox(height: 16),
                                  _glassDivider(),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _infoChip(Icons.email, user.email ?? 'sem e-mail'),
                                      if ((user.cpf ?? '').isNotEmpty) _infoChip(Icons.badge, user.cpf!),
                                      if ((user.cellPhone ?? '').isNotEmpty)
                                        _infoChip(Icons.phone, user.cellPhone!),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );

                        final actions = Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FilledButton.icon(
                              onPressed: _saving ? null : () => _onSave(user),
                              icon: _saving
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white),
                              )
                                  : const Icon(Icons.save),
                              label: Text(_saving ? 'Salvando...' : 'Salvar alterações'),
                            ),
                          ],
                        );

                        // ----- ÚNICO layout: coluna (foto acima do form), centralizado -----
                        return Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              // limita para leitura confortável em wide, mas mantém coluna
                              maxWidth: isWide ? 980 : c.maxWidth,
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                              child: Transform.translate(
                                offset: const Offset(0, -_cardsLift),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    photoCard,
                                    const SizedBox(height: 10),
                                    formCard,
                                    const SizedBox(height: 12),
                                    Align(alignment: Alignment.centerRight, child: actions),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------- Widgets menores --------------------

  Widget _nameField() => CustomTextField(
    controller: _firstCtrl,
    labelText: 'Nome',
    hintText: 'Seu nome',
    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
  );

  Widget _surnameField() => CustomTextField(
    controller: _lastCtrl,
    labelText: 'Sobrenome',
    hintText: 'Seu sobrenome',
  );

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey.shade700),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: Colors.blueGrey.shade900)),
        ],
      ),
    );
  }

  Widget _glassDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(.06), Colors.transparent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }
}

class _AvatarEditable extends StatelessWidget {
  const _AvatarEditable({
    required this.photoUrl,
    required this.previewBytes,
    required this.onTap,
    this.radius = 46,
  });

  final String? photoUrl;
  final Uint8List? previewBytes;
  final VoidCallback onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final avatar = () {
      if (previewBytes != null) {
        return CircleAvatar(radius: radius, backgroundImage: MemoryImage(previewBytes!));
      }
      if ((photoUrl ?? '').isNotEmpty) {
        return CircleAvatar(radius: radius, backgroundImage: NetworkImage(photoUrl!));
      }
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.blueGrey.shade200,
        child: Icon(Icons.person, size: radius, color: Colors.white70),
      );
    }();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          bottom: -2,
          right: -2,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: Ink(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.18), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: const Icon(Icons.edit, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
