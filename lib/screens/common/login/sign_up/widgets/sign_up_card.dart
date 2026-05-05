import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sipged/_widgets/DataTime/date_field_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/screens/common/login/sign_up/sign_up.dart';
import 'package:sipged/screens/common/login/sign_up/widgets/edit_user_danger_actions.dart';
import 'package:sipged/screens/common/login/sign_up/widgets/photo_picker_block.dart';
import 'package:sipged/screens/common/login/sign_up/widgets/sign_up_actions.dart';
import 'package:sipged/screens/common/login/sign_up/widgets/sign_up_section_title.dart';
import 'package:sipged/screens/common/login/sign_up/widgets/sign_up_top_banner.dart';

class SignUpCard extends StatelessWidget {
  const SignUpCard({
    super.key,
    required this.mode,
    required this.photoBytes,
    required this.photoName,
    required this.existingPhotoUrl,
    required this.nameController,
    required this.surnameController,
    required this.cpfController,
    required this.birthdayController,
    required this.emailController,
    required this.passController,
    required this.repeatPassController,
    required this.loading,
    required this.onPickPhoto,
    required this.onClearPhoto,
    required this.onCpfChanged,
    required this.onSubmit,
    required this.onCancel,
    required this.onSaveName,
    required this.onSaveSurname,
    required this.onSaveCpf,
    required this.onSaveEmail,
    required this.onSaveBirthday,
    required this.validateName,
    required this.validateSurname,
    required this.validateCpf,
    required this.validateEmail,
    required this.validateBirthday,
    required this.validatePassword,
    required this.validateRepeatPassword,
    this.isDeactivateSelected = false,
    this.isBlockSelected = false,
    this.isDeleteSelected = false,
    this.onDeactivateUser,
    this.onBlockUser,
    this.onDeleteUser,
  });

  final SignUpMode mode;

  final Uint8List? photoBytes;
  final String? photoName;
  final String? existingPhotoUrl;

  final TextEditingController nameController;
  final TextEditingController surnameController;
  final TextEditingController cpfController;
  final TextEditingController birthdayController;
  final TextEditingController emailController;
  final TextEditingController passController;
  final TextEditingController repeatPassController;

  final ValueNotifier<bool> loading;

  final VoidCallback onPickPhoto;
  final VoidCallback onClearPhoto;
  final ValueChanged<String> onCpfChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  final bool isDeactivateSelected;
  final bool isBlockSelected;
  final bool isDeleteSelected;

  final VoidCallback? onDeactivateUser;
  final VoidCallback? onBlockUser;
  final VoidCallback? onDeleteUser;

  final void Function(String?) onSaveName;
  final void Function(String?) onSaveSurname;
  final void Function(String?) onSaveCpf;
  final void Function(String?) onSaveEmail;
  final void Function(DateTime?) onSaveBirthday;

  final String? Function(String?) validateName;
  final String? Function(String?) validateSurname;
  final String? Function(String?) validateCpf;
  final String? Function(String?) validateEmail;
  final String? Function(DateTime?) validateBirthday;
  final String? Function(String?) validatePassword;
  final String? Function(String?) validateRepeatPassword;

  bool get isEditUser => mode == SignUpMode.editUser;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 18,
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;

            final horizontalPadding = wide ? 26.0 : 18.0;
            final contentWidth = constraints.maxWidth - (horizontalPadding * 2);

            final fieldWidth = wide ? ((contentWidth - 16) / 2) : contentWidth;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SignUpTopBanner(
                  mode: mode,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    24,
                    horizontalPadding,
                    22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PhotoPickerBlock(
                        photoBytes: photoBytes,
                        photoName: photoName,
                        existingPhotoUrl: existingPhotoUrl,
                        onPickPhoto: onPickPhoto,
                        onClearPhoto: onClearPhoto,
                      ),
                      const SizedBox(height: 24),
                      const SignUpSectionTitle(
                        icon: Icons.badge_rounded,
                        title: 'Dados pessoais',
                        subtitle:
                        'Informações básicas de identificação do usuário.',
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 16,
                        runSpacing: 14,
                        children: [
                          SizedBox(
                            width: fieldWidth,
                            child: CustomTextField(
                              controller: nameController,
                              onSaved: onSaveName,
                              labelText: 'Nome',
                              prefixIcon: const Icon(
                                Icons.account_circle_rounded,
                              ),
                              validator: validateName,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: CustomTextField(
                              controller: surnameController,
                              onSaved: onSaveSurname,
                              labelText: 'Sobrenome',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              validator: validateSurname,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 16,
                        runSpacing: 14,
                        children: [
                          SizedBox(
                            width: fieldWidth,
                            child: CustomTextField(
                              controller: cpfController,
                              onSaved: onSaveCpf,
                              onChanged: onCpfChanged,
                              labelText: 'CPF',
                              prefixIcon: const Icon(
                                Icons.credit_card_rounded,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(11),
                              ],
                              validator: validateCpf,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: DateFieldChange(
                              controller: birthdayController,
                              validator: validateBirthday,
                              onSaved: onSaveBirthday,
                              labelText: 'Data de nascimento',
                              prefix: const Icon(Icons.cake_rounded),
                              firstDate: DateTime(
                                DateTime.now().year - 120,
                              ),
                              lastDate: DateTime.now(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: emailController,
                        onSaved: onSaveEmail,
                        labelText: 'E-mail',
                        prefixIcon: const Icon(
                          Icons.alternate_email_rounded,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [
                          AutofillHints.email,
                        ],
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        ],
                        enabled: !isEditUser,
                        validator: validateEmail,
                        textInputAction: TextInputAction.next,
                      ),
                      if (!isEditUser) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 16,
                          runSpacing: 14,
                          children: [
                            SizedBox(
                              width: fieldWidth,
                              child: CustomTextField(
                                controller: passController,
                                labelText: 'Senha',
                                prefixIcon: const Icon(Icons.lock_rounded),
                                obscure: true,
                                validator: validatePassword,
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: CustomTextField(
                                controller: repeatPassController,
                                labelText: 'Repita a senha',
                                prefixIcon: const Icon(
                                  Icons.lock_reset_rounded,
                                ),
                                obscure: true,
                                validator: validateRepeatPassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => onSubmit(),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      ValueListenableBuilder<bool>(
                        valueListenable: loading,
                        builder: (_, isLoading, _) {
                          return SignUpActions(
                            loading: isLoading,
                            mode: mode,
                            onCancel: onCancel,
                            onSubmit: onSubmit,
                          );
                        },
                      ),
                      if (isEditUser) ...[
                        const SizedBox(height: 18),
                        ValueListenableBuilder<bool>(
                          valueListenable: loading,
                          builder: (_, isLoading, _) {
                            return EditUserDangerActions(
                              loading: isLoading,
                              isDeactivateSelected: isDeactivateSelected,
                              isBlockSelected: isBlockSelected,
                              isDeleteSelected: isDeleteSelected,
                              onDeactivateUser: onDeactivateUser,
                              onBlockUser: onBlockUser,
                              onDeleteUser: onDeleteUser,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}