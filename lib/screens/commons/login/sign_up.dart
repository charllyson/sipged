import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../_blocs/login/login_bloc.dart';
import '../../../_blocs/user/user_bloc.dart';
import '../../../_datas/user/user_data.dart';
import '../../../_widgets/formats/format_field.dart';
import '../../../_widgets/input/custom_date_field.dart';
import '../../../_widgets/input/custom_text_field.dart';
import '../../../_widgets/validates/login_validators.dart';

class SignUp extends StatefulWidget {
  const SignUp({required this.userData});
  final UserData userData;

  @override
  _SignUpState createState() => _SignUpState();
}

final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

class _SignUpState extends State<SignUp> with LoginValidators {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _passController = TextEditingController();
  final _repeatPassController = TextEditingController();
  late UserBloc _userBloc;
  late LoginBloc _loginBloc;

  @override
  void initState() {
    _userBloc = UserBloc();
    _loginBloc = LoginBloc();
    _loginBloc.outState.listen((state) {
      switch (state) {
        case LoginState.successProfileCommom:
          break;
        case LoginState.successProfileGovernment:
          break;
        case LoginState.successProfileCollaborator:
          break;
        case LoginState.successProfileCompany:
          break;
        case LoginState.fail:
          break;
        case LoginState.loading:
        case LoginState.idle:
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _userBloc.dispose();
    _loginBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Stack(
          children: <Widget>[
            ListView(
              children: <Widget>[
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 16,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              CustomTextField(
                                controller: _nameController,
                                onSaved: (saveName){
                                  widget.userData.name = saveName;
                                },
                                labelText: 'Nome',
                                prefix: const Icon(
                                  Icons.account_circle,
                                ),
                                keyboardType:
                                TextInputType.emailAddress,
                                validator: validateName,
                              ),
                              CustomTextField(
                                controller: _surnameController,
                                onSaved: (saveSurname){
                                  widget.userData.surname = saveSurname;
                                },
                                labelText: 'Sobrenome',
                                prefix: const Icon(
                                  Icons.account_circle,
                                ),
                                validator: validateSurname,
                              ),
                              CustomTextField(
                                controller: _emailController,
                                stream: _loginBloc.outEmail,
                                onSaved: (saveEmail){
                                  widget.userData.email = saveEmail;
                                },
                                labelText: 'E-mail',
                                prefix: const Icon(Icons.account_circle),
                                keyboardType: TextInputType.emailAddress,
                                onChanged: _loginBloc.changeEmail,
                                enabled: true,
                                validator: validateEmailLogin,
                                /*suffix: validateEmailLogin != null ?
                                CustomIconButton(
                                  radius: 32,
                                  iconData: Icons.check_circle,
                                  icoColor: Colors.green,
                                ) :
                                CustomIconButton(
                                  radius: 32,
                                  iconData: Icons.clear,
                                  onTap: () {
                                    _emailController.clear();
                                  },
                                )*/
                              ),
                              CustomTextField(
                                initialValue: addFormatCpf(widget.userData.cpf!),
                                labelText: 'CPF',
                                enabled: false,
                                prefix: const Icon(Icons.account_box),
                                suffix: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [CpfInputFormatter()],
                              ),
                              CustomDateField(
                                validator: validateDateToBirthday,
                                onSaved: (saveDateToBirthDay){
                                  widget.userData.dateToBirthday = saveDateToBirthDay;
                                },
                                labelText: 'Data de nascimento',
                                prefix: const Icon(Icons.cake),
                              ),
                              CustomTextField(
                                controller: _passController,
                                labelText: 'Senha',
                                prefix: const Icon(Icons.lock),
                                obscure: true,
                                validator: validatePasswordLogin,
                              ),
                              CustomTextField(
                                controller: _repeatPassController,
                                labelText: 'Repita a Senha',
                                prefix: const Icon(Icons.lock),
                                obscure: true,
                                validator: validatePasswordLogin,
                              ),
                              StreamBuilder<bool>(
                                initialData: false,
                                stream: _userBloc.outLoading,
                                builder: (context, snapshot) {
                                  if (snapshot.data == null) {
                                    return Container();
                                  }
                                  return ElevatedButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(32),
                                      ),
                                    ),
                                    onPressed: snapshot.data! ? null : () async {
                                        ///Verificando se as senhas são iguais
                                        if (_passController.text != _repeatPassController.text) {
                                          _passController.clear();
                                          _repeatPassController.clear();
                                          showDialog(
                                            context: context,
                                            builder: (context) => CupertinoAlertDialog(
                                              title: const Text('Erro na senha'),
                                              content:
                                              const Text('As senhas digitadas não conicidem'),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('Tentar novamente', style: TextStyle(color: Colors.blue),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        ///Criando o usuário e salvando os dados
                                        if (_formKey.currentState!.validate()) {
                                          _formKey.currentState?.save();

                                          await _loginBloc.signUp(
                                            userBloc: _userBloc,
                                            userData: widget.userData,
                                            pass: _passController.text,
                                          );
                                        }
                                    },
                                    child: const Text(
                                      'Cadastrar',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              //TermsAndConditions(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            //BackButtonCircle(),
            //BlockScreenToSave(userBloc: _userBloc),
          ],
        ),
      ),
    );
  }
}
