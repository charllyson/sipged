import 'package:flutter/material.dart';

class ModuleIdentity extends StatelessWidget {
  const ModuleIdentity({
    super.key,
    required this.title,
    required this.moduleId,
  });

  final String title;
  final String moduleId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F7),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.view_module_rounded,
            color: Color(0xFF475467),
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.isEmpty ? 'MÓDULO' : title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: .15,
                  color: Color(0xFF111827),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 3),
              Text(
                moduleId,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}