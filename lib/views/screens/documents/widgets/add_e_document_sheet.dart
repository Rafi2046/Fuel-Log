import 'dart:io';
import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  static Future<bool?> show(BuildContext context, {int? initialVehicleId}) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: AppColors.card,
        systemNavigationBarIconBrightness: AppColors.isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEDocumentSheet(initialVehicleId: initialVehicleId),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting file: $e')));
    }
  }

  void _showPickerOptions({required bool isFront}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
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
                leading: const Icon(
                  LucideIcons.camera,
                  color: Color(0xFFFF7A50),
                ),
                title: Text(
                  isFront
                      ? 'Take Front Photo with Camera'
                      : 'Take Back Photo with Camera',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImageForSlot(
                    source: ImageSource.camera,
                    isFront: isFront,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  LucideIcons.image,
                  color: Color(0xFF38BDF8),
                ),
                title: Text(
                  isFront
                      ? 'Choose Front Image from Gallery'
                      : 'Choose Back Image from Gallery',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImageForSlot(
                    source: ImageSource.gallery,
                    isFront: isFront,
                  );
                },
              ),
              if (!_isTwoSided || isFront)
                ListTile(
                  leading: const Icon(
                    LucideIcons.fileText,
                    color: Color(0xFF10B981),
                  ),
                  title: Text(
                    'Upload PDF / Document File',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
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
      initialDate: _expiryDate ?? DateTime.now().add(Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
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
  Future<String> _stitchFrontAndBackImages(
    String frontPath,
    String backPath,
  ) async {
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
      img.compositeImage(
        canvas,
        resizedBack,
        dstX: 0,
        dstY: resizedFront.height + gap,
      );

      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/stitched_doc_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save document: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final vehicles = vehiclesAsync.valueOrNull ?? [];

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Material(
            color: AppColors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad + 16),
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
                          color: AppColors.borderStrong,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

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
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(color: AppColors.hairline, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<EDocumentType>(
                          value: _selectedType,
                          dropdownColor: AppColors.card,
                          isExpanded: true,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          icon: Icon(
                            LucideIcons.chevronDown,
                            size: 16,
                            color: AppColors.textTertiary,
                          ),
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
                                  _selectedVehicleId =
                                      null; // Personal by default
                                  _isTwoSided =
                                      true; // Two-sided by default for NID / DL
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
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(color: AppColors.hairline, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: _selectedVehicleId,
                          dropdownColor: AppColors.card,
                          isExpanded: true,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          icon: Icon(
                            LucideIcons.chevronDown,
                            size: 16,
                            color: AppColors.textTertiary,
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                'Personal / User (Not Vehicle Specific)',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Document File Attachment',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildFormatTogglePill(
                              title: 'Two-Sided',
                              isSelected: _isTwoSided,
                              onTap: () => setState(() => _isTwoSided = true),
                            ),
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
                              onClear: () =>
                                  setState(() => _frontFilePath = null),
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
                              onClear: () =>
                                  setState(() => _backFilePath = null),
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
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _noExpiry ? null : _pickDate,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _noExpiry
                              ? AppColors.wash
                              : AppColors.inputFill,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.hairline,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: 16,
                              color: _noExpiry
                                  ? AppColors.textTertiary
                                  : const Color(0xFFFF7A50),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _noExpiry
                                    ? 'Lifetime / No Expiry'
                                    : (_expiryDate != null
                                          ? DateFormat(
                                              'dd MMMM yyyy',
                                            ).format(_expiryDate!)
                                          : 'Select Expiry Date'),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _noExpiry || _expiryDate == null
                                      ? AppColors.textSecondary
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
                          checkColor: Colors.white,
                          side: BorderSide(
                            color: AppColors.borderStrong,
                            width: 1.4,
                          ),
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
                            color: AppColors.textSecondary,
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
          ),
        ],
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
        duration: Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(0xFFFF7A50).withValues(alpha: 0.15)
              : AppColors.inputFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Color(0xFFFF7A50).withValues(alpha: 0.4)
                : AppColors.hairline,
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? const Color(0xFFFF7A50)
                : AppColors.textSecondary,
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
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: hasFile
                ? Color(0xFF10B981).withValues(alpha: 0.5)
                : AppColors.hairline,
            width: 1.2,
          ),
        ),
        child: hasFile
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.checkCircle2,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                  SizedBox(height: 6),
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
                    color: Color(0xFFFF7A50),
                    size: 22,
                  ),
                  SizedBox(height: 6),
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
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSingleUploadBox() {
    final hasFile = _frontFilePath != null;
    final isPdf =
        _frontFilePath != null &&
        _frontFilePath!.toLowerCase().endsWith('.pdf');

    return InkWell(
      onTap: () => _showPickerOptions(isFront: true),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: hasFile ? Color(0xFFFF7A50) : AppColors.hairline,
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
                  SizedBox(width: 12),
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
                  Icon(
                    LucideIcons.uploadCloud,
                    color: Color(0xFFFF7A50),
                    size: 28,
                  ),
                  SizedBox(height: 8),
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
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
