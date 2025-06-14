import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateDataPage extends StatefulWidget {
  const CreateDataPage({super.key});

  @override
  _CreateDataPageState createState() => _CreateDataPageState();
}

class _CreateDataPageState extends State<CreateDataPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _orgaoController = TextEditingController();
  final _diretoriaController = TextEditingController();
  final _setorController = TextEditingController();
  final _usuarioController = TextEditingController();
  final _usuarioEmailController = TextEditingController();

  // Função para criar um órgão
  Future<void> createOrgao() async {
    try {
      String orgaoName = _orgaoController.text.trim();
      if (orgaoName.isEmpty) return;

      // Adiciona um órgão na coleção `orgãos`
      await _firestore.collection('orgãos').add({
        'nome': orgaoName,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Órgão criado com sucesso!')));
    } catch (e) {
      print('Erro ao criar órgão: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao criar órgão!')));
    }
  }

  // Função para criar uma diretoria dentro de um órgão
  Future<void> createDiretoria(String orgaoId) async {
    try {
      String diretoriaName = _diretoriaController.text.trim();
      if (diretoriaName.isEmpty) return;

      // Adiciona uma diretoria na subcoleção `diretorias` de um órgão
      await _firestore.collection('orgãos').doc(orgaoId).collection('diretorias').add({
        'nome': diretoriaName,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Diretoria criada com sucesso!')));
    } catch (e) {
      print('Erro ao criar diretoria: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao criar diretoria!')));
    }
  }

  // Função para criar um setor dentro de uma diretoria
  Future<void> createSetor(String orgaoId, String diretoriaId) async {
    try {
      String setorName = _setorController.text.trim();
      if (setorName.isEmpty) return;

      // Adiciona um setor na subcoleção `setores` de uma diretoria
      await _firestore.collection('orgãos').doc(orgaoId).collection('diretorias').doc(diretoriaId).collection('setores').add({
        'nome': setorName,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Setor criado com sucesso!')));
    } catch (e) {
      print('Erro ao criar setor: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao criar setor!')));
    }
  }

  // Função para criar um usuário e atribuir privilégios de acesso
  Future<void> createUser() async {
    try {
      String usuarioName = _usuarioController.text.trim();
      String usuarioEmail = _usuarioEmailController.text.trim();
      if (usuarioName.isEmpty || usuarioEmail.isEmpty) return;

      // Adiciona um usuário na coleção `usuarios`
      await _firestore.collection('usuarios').add({
        'nome': usuarioName,
        'email': usuarioEmail,
        'diretorias': [],  // A lista de diretorias e setores será preenchida após a seleção do usuário
        'setores': [],
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Usuário criado com sucesso!')));
    } catch (e) {
      print('Erro ao criar usuário: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao criar usuário!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Criar Dados'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Campo para criar órgão
            TextField(
              controller: _orgaoController,
              decoration: InputDecoration(labelText: 'Nome do Órgão'),
            ),
            ElevatedButton(
              onPressed: createOrgao,
              child: Text('Criar Órgão'),
            ),

            // Campo para criar diretoria
            TextField(
              controller: _diretoriaController,
              decoration: InputDecoration(labelText: 'Nome da Diretoria'),
            ),
            ElevatedButton(
              onPressed: () async {
                String orgaoId = 'ID_DO_ORGÃO';  // Substitua com o ID do órgão ao qual você deseja adicionar a diretoria
                await createDiretoria(orgaoId);
              },
              child: Text('Criar Diretoria'),
            ),

            // Campo para criar setor
            TextField(
              controller: _setorController,
              decoration: InputDecoration(labelText: 'Nome do Setor'),
            ),
            ElevatedButton(
              onPressed: () async {
                String orgaoId = 'ID_DO_ORGÃO';  // Substitua com o ID do órgão
                String diretoriaId = 'ID_DA_DIRETORIA';  // Substitua com o ID da diretoria
                await createSetor(orgaoId, diretoriaId);
              },
              child: Text('Criar Setor'),
            ),

            // Campo para criar usuário
            TextField(
              controller: _usuarioController,
              decoration: InputDecoration(labelText: 'Nome do Usuário'),
            ),
            TextField(
              controller: _usuarioEmailController,
              decoration: InputDecoration(labelText: 'Email do Usuário'),
            ),
            ElevatedButton(
              onPressed: createUser,
              child: Text('Criar Usuário'),
            ),
          ],
        ),
      ),
    );
  }
}
