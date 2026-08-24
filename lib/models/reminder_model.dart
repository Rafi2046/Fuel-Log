import 'package:flutter/material.dart';

/// Supported vehicle maintenance reminder types
enum ServiceType {
  engineOil,
  generalService,
  airFilter,
  sparkPlug,
  brakeFluid,
  coolant,
  tireRotation,
  battery,
  taxToken,
  insurance,
  custom;

  String get displayName {
    switch (this) {
      case ServiceType.engineOil:
        return 'Engine Oil & Filter';
      case ServiceType.generalService:
        return 'Periodic Servicing';
      case ServiceType.airFilter:
        return 'Air / Cabin Filter';
      case ServiceType.sparkPlug:
        return 'Spark Plug Check';
      case ServiceType.brakeFluid:
        return 'Brake Pads & Fluid';
      case ServiceType.coolant:
        return 'Radiator Coolant';
      case ServiceType.tireRotation:
        return 'Tire Pressure & Rotation';
      case ServiceType.battery:
        return 'Battery Health Check';
      case ServiceType.taxToken:
        return 'Tax Token Renewal';
      case ServiceType.insurance:
        return 'Insurance Renewal';
      case ServiceType.custom:
        return 'Custom Maintenance';
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceType.engineOil:
        return Icons.oil_barrel_rounded;
      case ServiceType.generalService:
        return Icons.build_rounded;
      case ServiceType.airFilter:
        return Icons.air_rounded;
      case ServiceType.sparkPlug:
        return Icons.flash_on_rounded;
      case ServiceType.brakeFluid:
        return Icons.disc_full_rounded;
      case ServiceType.coolant:
        return Icons.water_drop_rounded;
      case ServiceType.tireRotation:
        return Icons.tire_repair_rounded;
      case ServiceType.battery:
        return Icons.battery_charging_full_rounded;
      case ServiceType.taxToken:
      case ServiceType.insurance:
        return Icons.assignment_rounded;
      case ServiceType.custom:
        return Icons.miscellaneous_services_rounded;
    }
  }
}

/// Status of a maintenance reminder
enum ReminderStatus {
  healthy,
  dueSoon,
  overdue;

  Color get color {
    switch (this) {
      case ReminderStatus.healthy:
        return const Color(0xFF10B981); // Emerald Green
      case ReminderStatus.dueSoon:
        return const Color(0xFFF59E0B); // Amber / Yellow
      case ReminderStatus.overdue:
        return const Color(0xFFEF4444); // Urgent Red
    }
  }

  String get label {
    switch (this) {
      case ReminderStatus.healthy:
        return 'Healthy';
      case ReminderStatus.dueSoon:
        return 'Due Soon';
      case ReminderStatus.overdue:
        return 'Overdue';
    }
  }
}

/// Service and maintenance reminder model with dual-trigger smart tracking (KM & Days)
class ServiceReminder {
  final String id;
  final int vehicleId;
  final String title;
  final ServiceType serviceType;
  final double lastServiceOdo;
  final DateTime lastServiceDate;
  final double? intervalKm;
  final int? intervalDays;
  final double? targetOdo;
  final DateTime? targetDate;
  final double? lastCost;
  final String? notes;
  final bool isRecurring;
  final bool isCompleted;

  const ServiceReminder({
    required this.id,
    required this.vehicleId,
    required this.title,
    required this.serviceType,
    required this.lastServiceOdo,
    required this.lastServiceDate,
    this.intervalKm,
    this.intervalDays,
    this.targetOdo,
    this.targetDate,
    this.lastCost,
    this.notes,
    this.isRecurring = true,
    this.isCompleted = false,
  });

  /// Computed target odometer
  double get effectiveTargetOdo {
    if (targetOdo != null) return targetOdo!;
    if (intervalKm != null) return lastServiceOdo + intervalKm!;
    return lastServiceOdo;
  }

  /// Computed target date
  DateTime get effectiveTargetDate {
    if (targetDate != null) return targetDate!;
    if (intervalDays != null) {
      return lastServiceDate.add(Duration(days: intervalDays!));
    }
    return lastServiceDate.add(const Duration(days: 90));
  }

  /// Remaining kilometers based on current vehicle odometer
  double? remainingKm(double currentOdo) {
    if (intervalKm == null && targetOdo == null) return null;
    return effectiveTargetOdo - currentOdo;
  }

  /// Remaining days based on current date
  int remainingDays([DateTime? now]) {
    final current = now ?? DateTime.now();
    return effectiveTargetDate.difference(current).inDays;
  }

  /// Overall health ratio (1.0 = brand new oil/service, 0.0 = completely due/overdue)
  double healthProgress(double currentOdo, [DateTime? now]) {
    double? kmRatio;
    if (intervalKm != null && intervalKm! > 0) {
      final elapsedKm = (currentOdo - lastServiceOdo).clamp(0.0, double.infinity);
      kmRatio = 1.0 - (elapsedKm / intervalKm!).clamp(0.0, 1.0);
    }

    double? dayRatio;
    if (intervalDays != null && intervalDays! > 0) {
      final current = now ?? DateTime.now();
      final elapsedDays = current.difference(lastServiceDate).inDays.clamp(0, 9999);
      dayRatio = 1.0 - (elapsedDays / intervalDays!).clamp(0.0, 1.0);
    }

    if (kmRatio != null && dayRatio != null) {
      // Return lowest ratio (whichever threshold comes first)
      return kmRatio < dayRatio ? kmRatio : dayRatio;
    }
    return kmRatio ?? dayRatio ?? 1.0;
  }

  /// Current health status based on odometer and days
  ReminderStatus status(double currentOdo, [DateTime? now]) {
    final remKm = remainingKm(currentOdo);
    final remDays = remainingDays(now);

    // Overdue conditions
    if ((remKm != null && remKm <= 0) || remDays <= 0) {
      return ReminderStatus.overdue;
    }

    // Due Soon conditions (within 200 km or within 10 days)
    if ((remKm != null && remKm <= 200) || remDays <= 10) {
      return ReminderStatus.dueSoon;
    }

    return ReminderStatus.healthy;
  }

  /// Formatted subtitle message (e.g. "Due in 1,250 km or 45 days")
  String statusMessage(double currentOdo, [DateTime? now]) {
    final remKm = remainingKm(currentOdo);
    final remDays = remainingDays(now);
    final st = status(currentOdo, now);

    if (st == ReminderStatus.overdue) {
      if (remKm != null && remKm <= 0) {
        return 'Overdue by ${remKm.abs().toStringAsFixed(0)} km!';
      }
      return 'Overdue by ${remDays.abs()} days!';
    }

    if (remKm != null) {
      if (remDays > 0) {
        return 'Due in ${remKm.toStringAsFixed(0)} km or $remDays days';
      }
      return 'Due in ${remKm.toStringAsFixed(0)} km';
    }

    return '$remDays days remaining';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'title': title,
        'serviceType': serviceType.name,
        'lastServiceOdo': lastServiceOdo,
        'lastServiceDate': lastServiceDate.toIso8601String(),
        'intervalKm': intervalKm,
        'intervalDays': intervalDays,
        'targetOdo': targetOdo,
        'targetDate': targetDate?.toIso8601String(),
        'lastCost': lastCost,
        'notes': notes,
        'isRecurring': isRecurring,
        'isCompleted': isCompleted,
      };

  factory ServiceReminder.fromJson(Map<String, dynamic> json) {
    return ServiceReminder(
      id: json['id'] as String,
      vehicleId: (json['vehicleId'] as num).toInt(),
      title: json['title'] as String,
      serviceType: ServiceType.values.firstWhere(
        (e) => e.name == json['serviceType'],
        orElse: () => ServiceType.custom,
      ),
      lastServiceOdo: (json['lastServiceOdo'] as num).toDouble(),
      lastServiceDate: DateTime.parse(json['lastServiceDate'] as String),
      intervalKm: (json['intervalKm'] as num?)?.toDouble(),
      intervalDays: (json['intervalDays'] as num?)?.toInt(),
      targetOdo: (json['targetOdo'] as num?)?.toDouble(),
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'] as String)
          : null,
      lastCost: (json['lastCost'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? true,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  ServiceReminder copyWith({
    String? id,
    int? vehicleId,
    String? title,
    ServiceType? serviceType,
    double? lastServiceOdo,
    DateTime? lastServiceDate,
    double? intervalKm,
    int? intervalDays,
    double? targetOdo,
    DateTime? targetDate,
    double? lastCost,
    String? notes,
    bool? isRecurring,
    bool? isCompleted,
  }) {
    return ServiceReminder(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      title: title ?? this.title,
      serviceType: serviceType ?? this.serviceType,
      lastServiceOdo: lastServiceOdo ?? this.lastServiceOdo,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      intervalKm: intervalKm ?? this.intervalKm,
      intervalDays: intervalDays ?? this.intervalDays,
      targetOdo: targetOdo ?? this.targetOdo,
      targetDate: targetDate ?? this.targetDate,
      lastCost: lastCost ?? this.lastCost,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
