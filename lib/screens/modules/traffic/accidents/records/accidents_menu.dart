import 'package:flutter/material.dart';
import 'package:sipged/_widgets/menu/bars/horizontal_menu_bar.dart';
import 'package:sipged/_widgets/menu/bars/menu_bar_item.dart';

class AccidentsMenu extends StatelessWidget {

  const AccidentsMenu({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final menus = <MenuBarItem>[
      MenuBarItem(
        label: 'Arquivo',
        children: [
          MenuBarItem(
            label: 'Importar',
            children: [
              MenuBarItem(
                label: 'Importar .xlsx',
                onTap: (){
                },
              ),
            ],
          ),
        ],
      ),
    ];
    return HorizontalMenuBar(menus: menus);
  }
}
