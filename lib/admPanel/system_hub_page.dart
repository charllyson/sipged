import 'package:flutter/material.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/admPanel/firebase/firebase_settings_page.dart';
import 'package:sipged/admPanel/system/manager_system_page.dart';

class SystemHubPage extends StatelessWidget {
  const SystemHubPage({super.key});

  int _gridCountForWidth(double width) {
    if (width >= 1300) return 4;
    if (width >= 980) return 3;
    if (width >= 680) return 2;
    return 1;
  }

  double _aspectRatioForWidth(double width) {
    if (width >= 1300) return 1.35;
    if (width >= 980) return 1.28;
    if (width >= 680) return 1.18;
    return 1.85;
  }

  @override
  Widget build(BuildContext context) {
    final items = <_SystemHubItem>[
      _SystemHubItem(
        title: 'Firebase',
        subtitle:
        'Firestore, Storage, migrações, importações e manutenção da base.',
        icon: Icons.cloud_queue_rounded,
        color: const Color(0xFF2563EB),
        pageBuilder: (_) => const FirebaseSettingsPage(),
      ),
      _SystemHubItem(
        title: 'Sistema',
        subtitle: 'Usuários, permissões, empresas e configurações iniciais.',
        icon: Icons.admin_panel_settings_rounded,
        color: const Color(0xFF059669),
        pageBuilder: (_) => const ManagerSystemPage(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: UpBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: CircleButtonChange(),
        ),
        titleWidgets: const [
          Text(
            'Painel administrativo',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final cross = _gridCountForWidth(width);

                return SliverGrid.builder(
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cross,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: _aspectRatioForWidth(width),
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return _SystemHubCard(
                      item: item,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: item.pageBuilder,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemHubItem {
  const _SystemHubItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.pageBuilder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder pageBuilder;
}

class _SystemHubCard extends StatelessWidget {
  const _SystemHubCard({
    required this.item,
    required this.onTap,
  });

  final _SystemHubItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF101828).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -22,
                top: -22,
                child: Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.color.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Positioned(
                right: 18,
                top: 18,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: item.color.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: 28,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 62),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF101828),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _OpenBadge(color: item.color),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Acessar',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.arrow_forward_rounded,
            color: color,
            size: 16,
          ),
        ],
      ),
    );
  }
}