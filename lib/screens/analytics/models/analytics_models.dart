import 'package:flutter/material.dart';

class AnalyticsMetric {
  const AnalyticsMetric({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final Color color;
}

class AnalyticsPoint {
  const AnalyticsPoint(this.label, this.value);

  final String label;
  final double value;
}

class AnalyticsInsight {
  const AnalyticsInsight({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.actionLabel,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? actionLabel;
}

class AnalyticsCategory {
  const AnalyticsCategory({
    required this.label,
    required this.value,
    required this.color,
    required this.detail,
  });

  final String label;
  final double value;
  final Color color;
  final String detail;
}

class AnalyticsActivity {
  const AnalyticsActivity({
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String title;
  final String time;
  final IconData icon;
  final Color color;
}
