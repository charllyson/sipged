import 'package:flutter/material.dart';

class FirestoreExplorerPage extends StatelessWidget {
  const FirestoreExplorerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Firestore Explorer disponível apenas no Web.'),
      ),
    );
  }
}
