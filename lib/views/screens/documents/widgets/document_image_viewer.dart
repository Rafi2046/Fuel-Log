import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Fullscreen zoomable document image viewer.
class DocumentImageViewer extends StatelessWidget {
  const DocumentImageViewer({
    super.key,
    required this.imagePath,
    required this.title,
    this.subtitle,
  });

  final String imagePath;
  final String title;
  final String? subtitle;

  static void show(
    BuildContext context, {
    required String imagePath,
    required String title,
    String? subtitle,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => DocumentImageViewer(
          imagePath: imagePath,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    final exists = file.existsSync();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.75),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 1),
              Text(
                subtitle!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ],
        ),
      ),
      body: Center(
        child: exists
            ? InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => _buildError(),
                ),
              )
            : _buildError(),
      ),
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          LucideIcons.imageOff,
          size: 48,
          color: Color(0xFF71717A),
        ),
        const SizedBox(height: 12),
        Text(
          'Image file not available',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
