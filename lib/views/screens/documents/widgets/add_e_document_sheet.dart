import 'dart:io';
import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../viewmodels/e_document_viewmodel.dart';
import '../../../../viewmodels/vehicle_viewmodel.dart';
import '../../../components/forms/sheet_action_bar.dart';

/// Modal bottom sheet to upload and record a new E-Document (supports Front & Back for NID/DL).
class AddEDocumentSheet extends ConsumerStatefulWidget {
  const AddEDocumentSheet({super.key, this.initialVehicleId});

  final int? initialVehicleId;

  static Future<bool?> show(
    BuildContext context, {
    int? initialVehicleId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121218),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddEDocumentSheet(
        initialVehicleId: initialVehicleId,
      ),
    );
  }

  @override
  ConsumerState<AddEDocumentSheet> createState() => _AddEDocumentSheetState();
}

class _AddEDocumentSheetState extends ConsumerState<AddEDocumentSheet> {
  final _formKey = GlobalKey<FormState>();

  EDocumentType _selectedType = EDocumentType.taxToken;
  int? _selectedVehicleId;
  DateTime? _expiryDate;
  bool _noExpiry = false;

  // Single file or Front side path
  String? _frontFilePath;
  // Optional back side path for two-sided documents (NID / Driving License)
  String? _backFilePath;
  bool _isTwoSided = false;

  bool _isSaving = false;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.initialVehicleId;
  }

  Future<void> _pickImageForSlot({
    required ImageSource source,
    required bool isFront,
  }) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 88,
      );
      if (picked != null) {
        setState(() {
          if (isFront) {
            _frontFilePath = picked.path;
          } else {
            _backFilePath = picked.path;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );
      if (result.isNotEmpty && result.first.path != null) {
        setState(() {
          _frontFilePath = result.first.path;
          _backFilePath = null;
          _isTwoSided = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e')),
      );
    }
  }

  void _showPickerOptions({required bool isFront}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1B1B24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.camera, color: Color(0xFFFF7A50)),
                title: Text(
                  isFront ? 'Take Front Photo with Camera' : 'Take Back Photo with Camera',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImageForSlot(source: ImageSource.camera, isFront: isFront);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.image, color: Color(0xFF38BDF8)),
                title: Text(
                  isFront ? 'Choose Front Image from Gallery' : 'Choose Back Image from Gallery',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImageForSlot(source: ImageSource.gallery, isFront: isFront);
                },
              ),
              if (!_isTwoSided || isFront)
                ListTile(
                  leading: const Icon(LucideIcons.fileText, color: Color(0xFF10B981)),
                  title: const Text(
                    'Upload PDF / Document File',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickPdf();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF7A50),
              surface: Color(0xFF1E1E2A),
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
        _noExpiry = false;
      });
    }
  }

  /// Stitches front and back photos into a single vertical composite image.
  Future<String> _stitchFrontAndBackImages(String frontPath, String backPath) async {
    try {
      final frontBytes = await File(frontPath).readAsBytes();
      final backBytes = await File(backPath).readAsBytes();

      final frontImg = img.decodeImage(frontBytes);
      final backImg = img.decodeImage(backBytes);

      if (frontImg == null || backImg == null) {
        return frontPath;
      }

      // Match widths for clean look
      final targetWidth = math.max(frontImg.width, backImg.width);
      final resizedFront = img.copyResize(frontImg, width: targetWidth);
      final resizedBack = img.copyResize(backImg, width: targetWidth);

      const gap = 24;
      final canvas = img.Image(
        width: targetWidth,
        height: resizedFront.height + resizedBack.height + gap,
        numChannels: 4,
      );

      // Fill canvas with dark background
      img.fill(canvas, color: img.ColorRgba8(22, 22, 34, 255));

      // Composite front and back
      img.compositeImage(canvas, resizedFront, dstX: 0, dstY: 0);
      img.compositeImage(canvas, resizedBack, dstX: 0, dstY: resizedFront.height + gap);

      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/stitched_doc_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(img.encodeJpg(canvas, quality: 92));

      return outputPath;
    } catch (e) {
      debugPrint('Error stitching front & back images: $e');
      return frontPath;
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;

    if (_frontFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach a photo or PDF of the document'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      String finalSourcePath = _frontFilePath!;
      if (_isTwoSided && _backFilePath != null) {
        finalSourcePath = await _stitchFrontAndBackImages(
          _frontFilePath!,
          _backFilePath!,
        );
      }

      final controller = ref.read(eDocumentControllerProvider);
      await controller.addDocumentFromPath(
        vehicleId: _selectedVehicleId,
        docType: _selectedType.code,
        sourcePath: finalSourcePath,
        expiryDate: _noExpiry ? null : _expiryDate,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedType.displayName} saved to vault!'),
          backgroundColor: const Color(0xFFFF7A50),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save document: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final vehicles = vehiclesAsync.valueOrNull ?? [];

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF333348),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Text(
                'Add E-Document',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),

              // 1. Document Type Dropdown
              Text(
                'Document Type',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B24),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: const Color(0xFF262638), width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<EDocumentType>(
                    value: _selectedType,
                    dropdownColor: const Color(0xFF1B1B24),
                    isExpanded: true,
                    icon: const Icon(LucideIcons.chevronDown,
                        size: 16, color: Color(0xFFA1A1AA)),
                    items: EDocumentType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedType = val;
                          if (val == EDocumentType.drivingLicense ||
                              val == EDocumentType.nationalId) {
                            _selectedVehicleId = null; // Personal by default
                            _isTwoSided = true; // Two-sided by default for NID / DL
                          } else {
                            _isTwoSided = false;
                          }
                          if (val == EDocumentType.nationalId) {
                            _noExpiry = true;
                            _expiryDate = null;
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Vehicle Association Dropdown
              Text(
                'Associated Vehicle',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B24),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: const Color(0xFF262638), width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selectedVehicleId,
                    dropdownColor: const Color(0xFF1B1B24),
                    isExpanded: true,
                    icon: const Icon(LucideIcons.chevronDown,
                        size: 16, color: Color(0xFFA1A1AA)),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          'Personal / User (Not Vehicle Specific)',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      ...vehicles.map((v) {
                        return DropdownMenuItem<int?>(
                          value: v.id,
                          child: Text(
                            '${v.name} (${v.type})',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedVehicleId = val),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Document Format & Upload Options (Two-Sided vs Single File)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Document File Attachment',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  // Format toggle
                  Row(
                    children: [
                      _buildFormatTogglePill(
                        title: 'Two-Sided',
                        isSelected: _isTwoSided,
                        onTap: () => setState(() => _isTwoSided = true),
                      ),
                      const SizedBox(width: 6),
                      _buildFormatTogglePill(
                        title: 'Single / PDF',
                        isSelected: !_isTwoSided,
                        onTap: () => setState(() => _isTwoSided = false),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Dual-Box or Single-Box Upload Cards
              if (_isTwoSided)
                Row(
                  children: [
                    // Front Side Box
                    Expanded(
                      child: _buildSideUploadBox(
                        title: 'Front Side (সামনে)',
                        filePath: _frontFilePath,
                        isFront: true,
                        onTap: () => _showPickerOptions(isFront: true),
                        onClear: () => setState(() => _frontFilePath = null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Back Side Box
                    Expanded(
                      child: _buildSideUploadBox(
                        title: 'Back Side (পেছনে)',
                        filePath: _backFilePath,
                        isFront: false,
                        onTap: () => _showPickerOptions(isFront: false),
                        onClear: () => setState(() => _backFilePath = null),
                      ),
                    ),
                  ],
                )
              else
                _buildSingleUploadBox(),

              const SizedBox(height: 16),

              // 4. Expiry Date Picker
              Text(
                'Expiry Date',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _noExpiry ? null : _pickDate,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _noExpiry
                        ? const Color(0xFF121218)
                        : const Color(0xFF1B1B24),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border:
                        Border.all(color: const Color(0xFF262638), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 16,
                        color: _noExpiry
                            ? const Color(0xFF52525B)
                            : const Color(0xFFFF7A50),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _noExpiry
                              ? 'Lifetime / No Expiry'
                              : (_expiryDate != null
                                  ? DateFormat('dd MMMM yyyy')
                                      .format(_expiryDate!)
                                  : 'Select Expiry Date'),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _noExpiry || _expiryDate == null
                                ? const Color(0xFF94A3B8)
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),

              Row(
                children: [
                  Checkbox(
                    value: _noExpiry,
                    activeColor: const Color(0xFFFF7A50),
                    onChanged: (val) {
                      setState(() {
                        _noExpiry = val ?? false;
                        if (_noExpiry) _expiryDate = null;
                      });
                    },
                  ),
                  Text(
                    'No Expiry Date (Lifetime)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 5. Actions
              SheetActionBar(
                primaryLabel: _isSaving ? 'Saving...' : 'Save Document',
                onPrimary: _saveDocument,
                onCancel: () => Navigator.of(context).pop(),
                primaryColor: const Color(0xFFFF7A50),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatTogglePill({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF7A50).withValues(alpha: 0.15)
              : const Color(0xFF1B1B24),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF7A50).withValues(alpha: 0.4)
                : const Color(0xFF262638),
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFFFF7A50) : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildSideUploadBox({
    required String title,
    required String? filePath,
    required bool isFront,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final hasFile = filePath != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B24),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: hasFile
                ? const Color(0xFF10B981).withValues(alpha: 0.5)
                : const Color(0xFF262638),
            width: 1.2,
          ),
        ),
        child: hasFile
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.checkCircle2,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to Change',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: const Color(0xFF38BDF8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isFront ? LucideIcons.idCard : LucideIcons.rotateCcw,
                    color: const Color(0xFFFF7A50),
                    size: 22,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Camera / Gallery',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSingleUploadBox() {
    final hasFile = _frontFilePath != null;
    final isPdf = _frontFilePath != null && _frontFilePath!.toLowerCase().endsWith('.pdf');

    return InkWell(
      onTap: () => _showPickerOptions(isFront: true),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B24),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: hasFile ? const Color(0xFFFF7A50) : const Color(0xFF262638),
            width: 1.2,
          ),
        ),
        child: hasFile
            ? Row(
                children: [
                  Icon(
                    isPdf ? LucideIcons.fileText : LucideIcons.image,
                    color: const Color(0xFFFF7A50),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _frontFilePath!.split('/').last,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to change file',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFFFF7A50),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    LucideIcons.checkCircle2,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ],
              )
            : Column(
                children: [
                  const Icon(
                    LucideIcons.uploadCloud,
                    color: Color(0xFFFF7A50),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Attach Camera Photo, Gallery, or PDF',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'JPG, PNG, PDF up to 15MB',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
