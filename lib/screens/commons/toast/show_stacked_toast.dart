import 'package:flutter/material.dart';
import 'package:sisged/_widgets/registers/register_class.dart';
import 'package:sisged/_widgets/formats/format_field.dart';
import 'package:sisged/_widgets/toast/slide_transition_toast.dart';

class StackedToastNotification extends StatelessWidget {
  final Registro registro;
  final int index;
  final String? tipoAlteracao;

  const StackedToastNotification({
    super.key,
    required this.registro,
    required this.index,
    this.tipoAlteracao,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 74.0 + (index * 80.0),
      right: 20.0,
      child: SlideTransitionToast(
        child: Material(
          elevation: 6,
          color: Colors.transparent,
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 6),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notifications, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tipoAlteracao ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        registro.contractData?.summarySubjectContract ??
                            'Sem título',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        registro.titulo,
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        dateAndTimeHumanized(registro.data),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
