import 'package:flutter/material.dart';

class SideMenuMap extends StatelessWidget {
  final void Function(int index) onTap;

  const SideMenuMap({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 180,
      backgroundColor: const Color(0xFF2C2F48),
      child: ListView(
        children: [
          const DrawerHeader(
            child: Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 22)),
          ),
          _buildItem(Icons.settings, 'Configurações', 0),
          _buildItem(Icons.people, 'Usuários', 1),
          _buildItem(Icons.lock, 'Permissões', 2),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String label, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () => onTap(index),
    );
  }
}
