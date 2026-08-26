import 'package:flutter/material.dart';

/// Category chips + title presets for Add Cost / Service sheet.
const List<Map<String, dynamic>> kCostServiceCategories = [
  {
    'id': 'Maintenance',
    'label': 'Maintenance',
    'icon': Icons.build_rounded,
    'presets': [
      'Engine Oil Change',
      'Brake Pad Replacement',
      'Tire Alignment',
      'Air Filter',
      'General Servicing',
      'Battery Change',
      'Custom Title...',
    ],
  },
  {
    'id': 'Parking & Toll',
    'label': 'Parking & Toll',
    'icon': Icons.local_parking_rounded,
    'presets': [
      'Parking Fee',
      'Highway Toll',
      'Bridge Toll',
      'Custom Title...',
    ],
  },
  {
    'id': 'Tax & Legal',
    'label': 'Tax & Legal',
    'icon': Icons.description_rounded,
    'presets': [
      'Tax Token Renewal',
      'Fitness Certificate',
      'Insurance Premium',
      'Traffic Fine',
      'Custom Title...',
    ],
  },
  {
    'id': 'Wash & Detailing',
    'label': 'Wash & Detailing',
    'icon': Icons.clean_hands_rounded,
    'presets': [
      'Express Wash',
      'Full Detailing',
      'Polish & Wax',
      'Custom Title...',
    ],
  },
  {
    'id': 'Parts & Accessories',
    'label': 'Parts & Accessories',
    'icon': Icons.shopping_bag_rounded,
    'presets': [
      'Spare Parts',
      'Helmet',
      'Dashcam',
      'Seat Covers',
      'New Tires',
      'Custom Title...',
    ],
  },
  {
    'id': 'Other',
    'label': 'Other',
    'icon': Icons.more_horiz_rounded,
    'presets': [
      'Miscellaneous Expense',
      'Custom Title...',
    ],
  },
];

