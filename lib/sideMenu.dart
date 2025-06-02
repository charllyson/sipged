import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final void Function(int index) onTap;

  const SideMenu({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 220,
      backgroundColor: const Color(0xFF1B2033),
      child: ListView(
        children: [
          const DrawerHeader(
              child: Text('SISGEO', style: TextStyle(color: Colors.white, fontSize: 24))),
          _buildItem(Icons.home, 'Início', 0),
          _buildItem(Icons.list, 'Contratos', 1),
          _buildItem(Icons.map, 'Malha Rodoviária', 2)
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
