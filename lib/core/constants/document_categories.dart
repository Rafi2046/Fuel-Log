import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Preset categories for vehicle documents and personal licenses.
enum DocumentCategory {
  registration,
  taxToken,
  fitness,
  insurance,
  drivingLicense,
  routePermit,
  pollution,
  nid,
  invoice,
  other,
}

extension DocumentCategoryX on DocumentCategory {
  String get code {
    switch (this) {
      case DocumentCategory.registration:
        return 'registration';
      case DocumentCategory.taxToken:
        return 'tax_token';
      case DocumentCategory.fitness:
        return 'fitness';
      case DocumentCategory.insurance:
        return 'insurance';
      case DocumentCategory.drivingLicense:
        return 'driving_license';
      case DocumentCategory.routePermit:
        return 'route_permit';
      case DocumentCategory.pollution:
        return 'pollution';
      case DocumentCategory.nid:
        return 'nid';
      case DocumentCategory.invoice:
        return 'invoice';
      case DocumentCategory.other:
        return 'other';
    }
  }

  String get displayNameKey {
    switch (this) {
      case DocumentCategory.registration:
        return 'docRegistration';
      case DocumentCategory.taxToken:
        return 'docTaxToken';
      case DocumentCategory.fitness:
        return 'docFitness';
      case DocumentCategory.insurance:
        return 'docInsurance';
      case DocumentCategory.drivingLicense:
        return 'docDrivingLicense';
      case DocumentCategory.routePermit:
        return 'docRoutePermit';
      case DocumentCategory.pollution:
        return 'docPollution';
      case DocumentCategory.nid:
        return 'docNid';
      case DocumentCategory.invoice:
        return 'docInvoice';
      case DocumentCategory.other:
        return 'docOther';
    }
  }

  String get localizedName => displayNameKey.tr();

  IconData get icon {
    switch (this) {
      case DocumentCategory.registration:
        return LucideIcons.fileText;
      case DocumentCategory.taxToken:
        return LucideIcons.ticket;
      case DocumentCategory.fitness:
        return LucideIcons.checkCircle;
      case DocumentCategory.insurance:
        return LucideIcons.shieldCheck;
      case DocumentCategory.drivingLicense:
        return LucideIcons.idCard;
      case DocumentCategory.routePermit:
        return LucideIcons.route;
      case DocumentCategory.pollution:
        return LucideIcons.leaf;
      case DocumentCategory.nid:
        return LucideIcons.userCheck;
      case DocumentCategory.invoice:
        return LucideIcons.receipt;
      case DocumentCategory.other:
        return LucideIcons.file;
    }
  }

  /// Whether this category represents a personal driver document (vs vehicle-specific paper)
  bool get isPersonalDocument =>
      this == DocumentCategory.drivingLicense || this == DocumentCategory.nid;

  static DocumentCategory fromCode(String code) {
    for (final cat in DocumentCategory.values) {
      if (cat.code == code) return cat;
    }
    return DocumentCategory.other;
  }
}

/// Document Expiry Status
enum DocumentExpiryStatus {
  valid,
  expiringSoon,
  expired,
  noExpiry,
}

class DocumentExpiryHelper {
  DocumentExpiryHelper._();

  static const int expiringSoonDaysThreshold = 30;

  static DocumentExpiryStatus calculateStatus(DateTime? expiryDate) {
    if (expiryDate == null) return DocumentExpiryStatus.noExpiry;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    final difference = expiry.difference(today).inDays;

    if (difference < 0) {
      return DocumentExpiryStatus.expired;
    } else if (difference <= expiringSoonDaysThreshold) {
      return DocumentExpiryStatus.expiringSoon;
    } else {
      return DocumentExpiryStatus.valid;
    }
  }

  static int? daysRemaining(DateTime? expiryDate) {
    if (expiryDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }
}
