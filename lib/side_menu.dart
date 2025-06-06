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
            child: Text('SISGEO', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          _buildExpandableItem(Icons.list, 'GESTÃO', [_buildSubItem('CONTRATOS', 0),]),
          _buildItem(Icons.map, 'OPERAÇÕES', 1),
          _buildItem(Icons.map, 'ADMINISTRATIVO', 20),
          _buildItem(Icons.map, 'FINANCEIRO', 30),
          _buildItem(Icons.map, 'PLANEJAMENTO', 40),
          _buildItem(Icons.map, 'MALHA RODOVIÁRIA', 50),
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
      onTap: () => onTap(index),
    );
  }
}
