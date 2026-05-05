import 'package:flutter/material.dart';

import '../../../screens/common/login/sign_up/widgets/group_counter_badge.dart';

class PermissionGroupExpansion extends StatelessWidget {
  const PermissionGroupExpansion({
    super.key,
    required this.title,
    required this.total,
    required this.checkedCount,
    required this.value,
    required this.isSuper,
    required this.onChanged,
    required this.children,
  });

  final String title;
  final int total;
  final int checkedCount;
  final bool? value;
  final bool isSuper;
  final ValueChanged<bool?>? onChanged;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: const Color(0xFFEEF4FF),
        highlightColor: const Color(0xFFEEF4FF),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          maintainState: false,
          tilePadding: const EdgeInsets.fromLTRB(12, 6, 14, 6),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          iconColor: const Color(0xFF2563EB),
          collapsedIconColor: const Color(0xFF667085),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.folder_special_rounded,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Checkbox(
                tristate: true,
                value: value,
                onChanged: onChanged,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: .3,
                    color: Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              GroupCounterBadge(
                checkedCount: checkedCount,
                total: total,
                isSuper: isSuper,
              ),
            ],
          ),
          children: children,
        ),
      ),
    );
  }
}