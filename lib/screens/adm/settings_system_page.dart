import 'package:flutter/material.dart';
import 'package:sisgeo/screens/adm/users/manage_permissions_page.dart';
import 'package:sisgeo/screens/adm/users/manager_permissions_contracts_page.dart';
import 'package:sisgeo/screens/adm/users/manager_permissions_users_page.dart';
import 'firestore/firestore_explorer_page.dart';
import 'organs/manager_orgao_page.dart';

class SettingsSystemPage extends StatefulWidget {
  const SettingsSystemPage({super.key});

  @override
  State<SettingsSystemPage> createState() => _SettingsSystemPageState();
}

class _SettingsSystemPageState extends State<SettingsSystemPage> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text('Configurações'),
        ),

        body: SingleChildScrollView(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ListTile(
                leading: Icon(Icons.add),
                tileColor: Colors.white10,
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FirestoreExplorerPage()),
                  );
                },
                title: Text('Verificar Coleções e documentos do CloudFirestore'),
                subtitle: Text('Coleções e subcoleções'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
              ListTile(
                leading: Icon(Icons.add),
                tileColor: Colors.white10,
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ManageOrgansPage()),
                  );
                },
                title: Text('Gerenciar Órgão, Diretorias, e Setores'),
                subtitle: Text('Permissões e configurações'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
              ListTile(
                leading: Icon(Icons.add),
                tileColor: Colors.white10,
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ManagerPermissionsUsersPage()),
                  );
                },
                title: Text('Gerenciar permissões de usuário'),
                subtitle: Text('Permissões e configurações'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
