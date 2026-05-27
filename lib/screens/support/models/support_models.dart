import 'package:flutter/material.dart';

class SupportCategory {
  const SupportCategory({
    required this.title,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    this.links = const [],
  });

  final String title;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> links;
}

class SupportFAQ {
  const SupportFAQ({required this.question, required this.answer});

  final String question;
  final String answer;
}

class SupportAction {
  const SupportAction({required this.title, required this.icon, required this.route});

  final String title;
  final IconData icon;
  final String route;
}
