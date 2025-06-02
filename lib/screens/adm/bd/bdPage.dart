// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:sisgeo/_blocs/admin/admin_bloc.dart';

import 'firestoreExplorerPage.dart';

class FirestoreDatabase extends StatefulWidget {
  const FirestoreDatabase({super.key});

  @override
  State<FirestoreDatabase> createState() => _FirestoreDatabaseState();
}

class _FirestoreDatabaseState extends State<FirestoreDatabase> {

  AdminBloc _adminBloc = AdminBloc();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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

        ],
      ),
    );
  }
}
