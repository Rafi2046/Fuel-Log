import 'package:flutter/material.dart';

enum NotificationCategory { all, maintenance, weather, tips }

enum NotificationSeverity { urgent, warning, info, success }

/// Represents an in-app notification item with categorization, priority, and actions.
class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.severity,
    required this.icon,
    required this.timeAgo,
    this.actionLabel,
    this.onTap,
  });

  final String id;
  final String title;
  final String message;
  final NotificationCategory category;
  final NotificationSeverity severity;
  final IconData icon;
  final String timeAgo;
  final String? actionLabel;
  final VoidCallback? onTap;
}
