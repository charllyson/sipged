import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TimelineEventModel {
  final DateTime date;
  final String description;
  final String status;

  TimelineEventModel({
    required this.date,
    required this.description,
    required this.status,
  });

  factory TimelineEventModel.fromFirestore(Map<String, dynamic> data) {
    return TimelineEventModel(
      date: DateTime.parse(data['date']),
      description: data['description'] ?? '',
      status: data['status'] ?? 'planejado',
    );
  }

  Color get color {
    switch (status) {
      case 'executado':
        return Colors.green;
      case 'atrasado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (status) {
      case 'executado':
        return Icons.check;
      case 'atrasado':
        return Icons.warning;
      default:
        return Icons.schedule;
    }
  }

  String get formattedDate => "${date.day}/${date.month}/${date.year}";
}
