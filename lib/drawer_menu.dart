import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sisgeo/screens/commons/upBar/pup_up_menu.dart';

import '_blocs/user/user_bloc.dart';
import '_datas/user/user_data.dart';

class DrawerMenu extends StatefulWidget {
  final void Function(int index) onTap;

  const DrawerMenu({super.key, required this.onTap});

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  late UserBloc userBloc = UserBloc();
  User? firebaseUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 250,
      backgroundColor: const Color(0xFF1B2033),
      child: ListView(
        children: [
          DrawerHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('SISGEO', style: TextStyle(color: Colors.white, fontSize: 24)),
                        PopUpMenu()
                      ],
                    ),
                    SizedBox(height: 12),
                    Text('Sistema Integrado de Gerenciamento de obra', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
                SizedBox(height: 12),
                FutureBuilder<UserData?>(
                    future: userBloc.getUserData(uid: firebaseUser!.uid),
                    builder: (context, userData) {
                      if (!userData.hasData) {
                        return Text('');
                      }
                    return Text('Olá, ${userData.data!.name}', style: TextStyle(color: Colors.white, fontSize: 12));
                  }
                ),
              ],
            ),
          ),
          _buildExpandableItem(Icons.list, 'GESTÃO', [
            _buildSubItem('CONTRATOS', 0),
            _buildSubItem('MALHA RODOVIÁRIA', 1),
          ]),
          _buildExpandableItem(Icons.list, 'DIORC', [
            _buildSubItem('CRONOGRAMA FÍSICO', 2),
            _buildSubItem('DESAPROPRIAÇÃO', 3),
          ]),
          _buildExpandableItem(Icons.open_with_rounded, 'DITT', [
            _buildSubItem('ACIDENTES', 3),
            _buildSubItem('INFRAÇÕES', 4),
          ]),
          //_buildExpandableItem(Icons.open_with_rounded, 'ADMINISTRATIVO', [_buildSubItem('DASHBOARD', 30)]),
          //_buildExpandableItem(Icons.open_with_rounded, 'PLANEJAMENTO', [_buildSubItem('DASHBOARD', 40)]),
          //_buildExpandableItem(Icons.open_with_rounded, 'FINANCEIRO', [_buildSubItem('DASHBOARD', 50)]),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String label, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () => widget.onTap(index),
    );
  }

  Widget _buildExpandableItem(IconData icon, String label, List<Widget> children) {
    return Theme(
      data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        children: children,
      ),
    );
  }

  Widget _buildSubItem(String label, int index) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 16),
      title: Text(label, style: const TextStyle(color: Colors.white70)),
      onTap: () => widget.onTap(index),
    );
  }
}
