import 'dart:io';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/database/app_database.dart';
import '../../../../viewmodels/e_document_viewmodel.dart';
import '../../../widgets/app_app_bar.dart';

/// Full-screen in-app document viewer for Images & PDFs.
/// - PDFs: Rendered in-app via Syncfusion SfPdfViewer (Memory bytes - 100% reliable)
/// - Images: Rendered in-app via InteractiveViewer (pinch-to-zoom)
/// - Features auto-max brightness for traffic police QR scanning.
class EDocumentViewerScreen extends StatefulWidget {
  const EDocumentViewerScreen({
    super.key,
    required this.document,
    this.vehicleName,
  });

  final EDocument document;
  final String? vehicleName;

  static Future<void> open(
    BuildContext context, {
    required EDocument document,
    String? vehicleName,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => EDocumentViewerScreen(
          document: document,
          vehicleName: vehicleName,
        ),
      ),
    );
  }

  @override
  State<EDocumentViewerScreen> createState() => _EDocumentViewerScreenState();
}

class _EDocumentViewerScreenState extends State<EDocumentViewerScreen> {
  double? _previousBrightness;
  bool _brightnessMaximized = false;

  Uint8List? _pdfBytes;
  bool _isLoadingBytes = true;
  String? _pdfLoadError;

  @override
  void initState() {
    super.initState();
    _maximizeBrightnessForScanner();
    _loadPdfBytesIfApplicable();
  }

  Future<void> _loadPdfBytesIfApplicable() async {
    final isPdf = widget.document.filePath.toLowerCase().endsWith('.pdf');
    if (!isPdf) {
      if (mounted) setState(() => _isLoadingBytes = false);
      return;
    }

    try {
      final file = File(widget.document.filePath);
      if (!file.existsSync()) {
        if (mounted) {
          setState(() {
            _pdfLoadError = 'File does not exist on device';
            _isLoadingBytes = false;
          });
        }
        return;
      }

      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _isLoadingBytes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pdfLoadError = 'Failed to load PDF file: $e';
          _isLoadingBytes = false;
        });
      }
    }
  }

  /// Auto-max brightness for traffic police QR scanning in daylight.
  Future<void> _maximizeBrightnessForScanner() async {
    try {
      final brightnessService = ScreenBrightness();
      _previousBrightness = await brightnessService.application;
      await brightnessService.setApplicationScreenBrightness(1.0);
      if (mounted) {
        setState(() => _brightnessMaximized = true);
      }
    } catch (e) {
      debugPrint('Screen brightness adjustment error: $e');
    }
  }

  @override
  void dispose() {
    _restoreBrightness();
    super.dispose();
  }

  Future<void> _restoreBrightness() async {
    try {
      final brightnessService = ScreenBrightness();
      if (_previousBrightness != null) {
        await brightnessService
            .setApplicationScreenBrightness(_previousBrightness!);
      } else {
        await brightnessService.resetApplicationScreenBrightness();
      }
    } catch (e) {
      debugPrint('Screen brightness restore error: $e');
    }
  }

  void _shareDocument() {
    final file = File(widget.document.filePath);
    if (!file.existsSync()) return;

    final docType = EDocumentType.fromCode(widget.document.docType);
    final expiry = widget.document.expiryDate != null
        ? ' (Expires: ${DateFormat('dd MMM yyyy').format(widget.document.expiryDate!)})'
        : '';

    Share.shareXFiles(
      [XFile(file.path)],
      text:
          '${docType.displayName}$expiry - ${widget.vehicleName ?? 'Personal Document'}',
      subject: docType.displayName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.document.filePath);
    final exists = file.existsSync();
    final docType = EDocumentType.fromCode(widget.document.docType);
    final isPdf = widget.document.filePath.toLowerCase().endsWith('.pdf');

    final expiry = widget.document.expiryDate;
    final isExpired = expiry != null && expiry.isBefore(DateTime.now());
    final isExpiringSoon = expiry != null &&
        !isExpired &&
        expiry.difference(DateTime.now()).inDays <= 30;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A10),
      appBar: AppAppBar(
        leading: const AppBackButton(),
        title: docType.displayName,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _shareDocument,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2A2A3E)),
                ),
                child: const Icon(
                  LucideIcons.share2,
                  color: Color(0xFFFF7A50),
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. In-App Document Renderer
          Positioned.fill(
            child: !exists
                ? _buildError('Document file not found on device')
                : (isPdf
                    ? _buildPdfViewer()
                    : _buildImageViewer(file)),
          ),

          // 2. Expiry Warning Overlay
          if (isExpired || isExpiringSoon)
            Positioned(
              top: 14,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isExpired
                      ? const Color(0xFFEF4444).withValues(alpha: 0.94)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpired
                          ? LucideIcons.alertCircle
                          : LucideIcons.alertTriangle,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isExpired
                            ? 'Document expired on ${DateFormat('dd MMM yyyy').format(expiry)}'
                            : 'Expires in ${expiry.difference(DateTime.now()).inDays} days (${DateFormat('dd MMM yyyy').format(expiry)})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 3. Max Brightness Badge for Police / QR Scanner
          if (_brightnessMaximized)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161622).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF7A50).withValues(alpha: 0.6),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.sunMedium,
                        color: Color(0xFFFF7A50),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Max Brightness Active for QR Scanner',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF8FAFC),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    if (_isLoadingBytes) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFFFF7A50),
              strokeWidth: 2.5,
            ),
            SizedBox(height: 14),
            Text(
              'Loading PDF...',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (_pdfLoadError != null || _pdfBytes == null) {
      return _buildError(_pdfLoadError ?? 'Failed to load PDF document');
    }

    return SfPdfViewer.memory(
      _pdfBytes!,
      canShowScrollHead: true,
      canShowScrollStatus: true,
      enableDoubleTapZooming: true,
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        setState(() {
          _pdfLoadError = details.description;
        });
      },
    );
  }

  Widget _buildImageViewer(File file) {
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 5.0,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (_, e, st) =>
                _buildError('Unable to render image file'),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.fileX,
                size: 40,
                color: Color(0xFF71717A),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Document not available',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF222232),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
