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
import 'document_image_viewer.dart';

/// Survives Android activity recreation while camera/gallery is open.
/// Without this, Two-Sided flips back to Single File after picking an image.
class _EDocSheetDraft {
  _EDocSheetDraft._();
  static final _EDocSheetDraft instance = _EDocSheetDraft._();

  final ValueNotifier<int> revision = ValueNotifier(0);

  bool sessionActive = false;
  bool picking = false;
  bool isTwoSided = true;
  String? frontPath;
  String? backPath;
  String? singlePath;
  EDocumentType docType = EDocumentType.taxToken;
  int? vehicleId;
  DateTime? expiryDate;
  bool noExpiry = false;

  void bump() => revision.value++;

  void startNew({int? initialVehicleId}) {
    if (picking) return;
    sessionActive = true;
    isTwoSided = true;
    frontPath = null;
    backPath = null;
    singlePath = null;
    docType = EDocumentType.taxToken;
    vehicleId = initialVehicleId;
    expiryDate = null;
    noExpiry = false;
    bump();
  }

  void clear() {
    if (picking) return;
    sessionActive = false;
    isTwoSided = true;
    frontPath = null;
    backPath = null;
    singlePath = null;
    docType = EDocumentType.taxToken;
    vehicleId = null;
    expiryDate = null;
    noExpiry = false;
  }
}

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

    _EDocSheetDraft.instance.startNew(initialVehicleId: initialVehicleId);

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEDocumentSheet(initialVehicleId: initialVehicleId),
    ).whenComplete(() {
      if (!_EDocSheetDraft.instance.picking) {
        _EDocSheetDraft.instance.clear();
      }
    });
  }

  @override
  ConsumerState<AddEDocumentSheet> createState() => _AddEDocumentSheetState();
}

enum _UploadSlot { front, back, single }

class _AddEDocumentSheetState extends ConsumerState<AddEDocumentSheet> {
  final _formKey = GlobalKey<FormState>();

  late EDocumentType _selectedType;
  late int? _selectedVehicleId;
  late DateTime? _expiryDate;
  late bool _noExpiry;
  late String? _frontFilePath;
  late String? _backFilePath;
  late String? _singleFilePath;
  late bool _isTwoSided;

  bool _isSaving = false;
  final _imagePicker = ImagePicker();

  String? _attachmentError;
  String? _expiryError;

  @override
  void initState() {
    super.initState();
    final draft = _EDocSheetDraft.instance;
    if (!draft.sessionActive) {
      draft.startNew(initialVehicleId: widget.initialVehicleId);
    }
    _hydrateFromDraft();
    draft.revision.addListener(_onDraftChanged);
  }

  @override
  void dispose() {
    _EDocSheetDraft.instance.revision.removeListener(_onDraftChanged);
    super.dispose();
  }

  void _onDraftChanged() {
    if (!mounted) return;
    setState(_hydrateFromDraft);
  }

  void _hydrateFromDraft() {
    final draft = _EDocSheetDraft.instance;
    _selectedType = draft.docType;
    _selectedVehicleId = draft.vehicleId ?? widget.initialVehicleId;
    _expiryDate = draft.expiryDate;
    _noExpiry = draft.noExpiry;
    _frontFilePath = draft.frontPath;
    _backFilePath = draft.backPath;
    _singleFilePath = draft.singlePath;
    _isTwoSided = draft.isTwoSided;
  }

  void _persistDraft({bool notify = false}) {
    final draft = _EDocSheetDraft.instance;
    draft.sessionActive = true;
    draft.isTwoSided = _isTwoSided;
    draft.frontPath = _frontFilePath;
    draft.backPath = _backFilePath;
    draft.singlePath = _singleFilePath;
    draft.docType = _selectedType;
    draft.vehicleId = _selectedVehicleId;
    draft.expiryDate = _expiryDate;
    draft.noExpiry = _noExpiry;
    if (notify) draft.bump();
  }

  void _setTwoSided(bool value) {
    setState(() {
      _isTwoSided = value;
      _attachmentError = null;
    });
    _persistDraft();
  }

  Future<void> _pickImageForSlot({
    required ImageSource source,
    required _UploadSlot slot,
  }) async {
    final draft = _EDocSheetDraft.instance;
    draft.picking = true;
    _persistDraft();
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 88,
      );
      if (picked != null) {
        switch (slot) {
          case _UploadSlot.front:
            draft.frontPath = picked.path;
            break;
          case _UploadSlot.back:
            draft.backPath = picked.path;
            break;
          case _UploadSlot.single:
            draft.singlePath = picked.path;
            break;
        }
        draft.bump();
      }
      if (!mounted) return;
      setState(_hydrateFromDraft);
      _attachmentError = null;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
    } finally {
      draft.picking = false;
    }
  }

  Future<void> _pickPdf() async {
    final draft = _EDocSheetDraft.instance;
    draft.picking = true;
    _persistDraft();
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );
      if (result.isNotEmpty && result.first.path != null) {
        draft.singlePath = result.first.path;
        draft.bump();
      }
      if (!mounted) return;
      setState(_hydrateFromDraft);
      _attachmentError = null;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting file: $e')));
    } finally {
      draft.picking = false;
    }
  }

  void _showPickerOptions({required _UploadSlot slot}) {
    final isSingle = slot == _UploadSlot.single;
    final isFront = slot == _UploadSlot.front;

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
                  isSingle
                      ? 'Take Photo with Camera'
                      : (isFront
                          ? 'Take Front Photo with Camera'
                          : 'Take Back Photo with Camera'),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImageForSlot(
                    source: ImageSource.camera,
                    slot: slot,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  LucideIcons.image,
                  color: Color(0xFF38BDF8),
                ),
                title: Text(
                  isSingle
                      ? 'Choose Image from Gallery'
                      : (isFront
                          ? 'Choose Front Image from Gallery'
                          : 'Choose Back Image from Gallery'),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImageForSlot(
                    source: ImageSource.gallery,
                    slot: slot,
                  );
                },
              ),
              // PDF / single-file upload only in Single mode — offering it
              // while Two-Sided is on used to flip the toggle and drop the back.
              if (isSingle)
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
        _expiryError = null;
      });
      _persistDraft();
    }
  }

  bool _validateBeforeSave() {
    String? attachmentError;
    String? expiryError;

    if (_isTwoSided) {
      if (_frontFilePath == null && _backFilePath == null) {
        attachmentError = 'Please attach front and back photos';
      } else if (_frontFilePath == null) {
        attachmentError = 'Please attach the front side photo';
      } else if (_backFilePath == null) {
        attachmentError = 'Please attach the back side photo';
      }
    } else if (_singleFilePath == null) {
      attachmentError = 'Please attach a photo or PDF of the document';
    }

    if (!_noExpiry && _expiryDate == null) {
      expiryError = 'Select an expiry date, or check No Expiry';
    }

    setState(() {
      _attachmentError = attachmentError;
      _expiryError = expiryError;
    });

    return attachmentError == null && expiryError == null;
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
    if (_isSaving) return;
    if (!_validateBeforeSave()) return;

    setState(() => _isSaving = true);
    try {
      String finalSourcePath;
      if (_isTwoSided) {
        finalSourcePath = _frontFilePath!;
        if (_backFilePath != null) {
          finalSourcePath = await _stitchFrontAndBackImages(
            _frontFilePath!,
            _backFilePath!,
          );
        }
      } else {
        finalSourcePath = _singleFilePath!;
      }

      final controller = ref.read(eDocumentControllerProvider);
      await controller.addDocumentFromPath(
        vehicleId: _selectedVehicleId,
        docType: _selectedType.code,
        sourcePath: finalSourcePath,
        expiryDate: _noExpiry ? null : _expiryDate,
      );

      if (!mounted) return;
      _EDocSheetDraft.instance.picking = false;
      _EDocSheetDraft.instance.clear();
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
                                if (val == EDocumentType.nationalId) {
                                  _noExpiry = true;
                                  _expiryDate = null;
                                }
                              });
                              _persistDraft();
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
                          onChanged: (val) {
                            setState(() => _selectedVehicleId = val);
                            _persistDraft();
                          },
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
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormatTogglePill(
                                title: 'Two-Sided',
                                isSelected: _isTwoSided,
                                onTap: () => _setTwoSided(true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildFormatTogglePill(
                                title: 'Single File',
                                isSelected: !_isTwoSided,
                                onTap: () => _setTwoSided(false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isTwoSided
                              ? 'Front + back photos. Stays on Two-Sided until you switch.'
                              : 'One photo or PDF. Stays on Single File until you switch.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                            height: 1.3,
                          ),
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
                              hasError: _attachmentError != null &&
                                  _frontFilePath == null,
                              onTap: () => _showPickerOptions(slot: _UploadSlot.front),
                              onClear: () {
                                setState(() {
                                  _frontFilePath = null;
                                  _attachmentError = null;
                                });
                                _persistDraft();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Back Side Box
                          Expanded(
                            child: _buildSideUploadBox(
                              title: 'Back Side (পেছনে)',
                              filePath: _backFilePath,
                              isFront: false,
                              hasError: _attachmentError != null &&
                                  _backFilePath == null,
                              onTap: () => _showPickerOptions(slot: _UploadSlot.back),
                              onClear: () {
                                setState(() {
                                  _backFilePath = null;
                                  _attachmentError = null;
                                });
                                _persistDraft();
                              },
                            ),
                          ),
                        ],
                      )
                    else
                      _buildSingleUploadBox(
                        hasError: _attachmentError != null,
                      ),

                    if (_attachmentError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _attachmentError!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],

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
                            color: _expiryError != null
                                ? const Color(0xFFEF4444)
                                : AppColors.hairline,
                            width: _expiryError != null ? 1.2 : 1,
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
                    if (_expiryError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _expiryError!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),

                    InkWell(
                      onTap: () {
                        setState(() {
                          _noExpiry = !_noExpiry;
                          if (_noExpiry) {
                            _expiryDate = null;
                            _expiryError = null;
                          }
                        });
                        _persistDraft();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _noExpiry,
                                activeColor: const Color(0xFFFF7A50),
                                checkColor: Colors.white,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                side: BorderSide(
                                  color: AppColors.borderStrong,
                                  width: 1.4,
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _noExpiry = val ?? false;
                                    if (_noExpiry) {
                                      _expiryDate = null;
                                      _expiryError = null;
                                    }
                                  });
                                  _persistDraft();
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No Expiry Date (Lifetime)',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 5. Actions
                    SheetActionBar(
                      primaryLabel: _isSaving ? 'Saving...' : 'Save Document',
                      onPrimary: _isSaving ? () {} : _saveDocument,
                      onCancel: () {
                        _EDocSheetDraft.instance.clear();
                        Navigator.of(context).pop();
                      },
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF7A50).withValues(alpha: 0.15)
                : AppColors.inputFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF7A50).withValues(alpha: 0.55)
                  : AppColors.hairline,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFFFF7A50)
                  : AppColors.textSecondary,
            ),
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
    bool hasError = false,
  }) {
    final hasFile = filePath != null;
    final isPdf =
        filePath != null && filePath.toLowerCase().endsWith('.pdf');

    void openPreview() {
      if (filePath == null || isPdf) return;
      DocumentImageViewer.show(
        context,
        imagePath: filePath,
        title: title,
        subtitle: 'Pinch to zoom · tap X to close',
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasFile ? (isPdf ? onTap : openPreview) : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Ink(
          height: 132,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: hasFile
                  ? const Color(0xFF10B981).withValues(alpha: 0.55)
                  : hasError
                      ? const Color(0xFFEF4444)
                      : AppColors.hairline,
              width: hasError && !hasFile ? 1.4 : 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 1),
            child: hasFile
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      if (isPdf)
                        ColoredBox(
                          color: AppColors.wash,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.fileText,
                                color: AppColors.primary,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'PDF attached',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Image.file(
                          File(filePath),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => ColoredBox(
                            color: AppColors.wash,
                            child: Icon(
                              LucideIcons.imageOff,
                              color: AppColors.textTertiary,
                              size: 28,
                            ),
                          ),
                        ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0),
                                Colors.black.withValues(alpha: 0.75),
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      isPdf
                                          ? 'Tap to change'
                                          : 'Tap to enlarge',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF7DD3FC),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isPdf)
                                Material(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: onTap,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      child: Text(
                                        'Change',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onClear,
                            child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(
                                LucideIcons.x,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
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
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSingleUploadBox({bool hasError = false}) {
    final hasFile = _singleFilePath != null;
    final isPdf =
        _singleFilePath != null &&
        _singleFilePath!.toLowerCase().endsWith('.pdf');

    void openPreview() {
      final path = _singleFilePath;
      if (path == null || isPdf) return;
      DocumentImageViewer.show(
        context,
        imagePath: path,
        title: 'Document preview',
        subtitle: 'Pinch to zoom · tap X to close',
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasFile
            ? (isPdf ? () => _showPickerOptions(slot: _UploadSlot.single) : openPreview)
            : () => _showPickerOptions(slot: _UploadSlot.single),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: hasFile
                  ? const Color(0xFFFF7A50)
                  : hasError
                      ? const Color(0xFFEF4444)
                      : AppColors.hairline,
              width: hasError && !hasFile ? 1.4 : 1.2,
            ),
          ),
          child: hasFile
              ? Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: isPdf
                            ? ColoredBox(
                                color: AppColors.wash,
                                child: Icon(
                                  LucideIcons.fileText,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              )
                            : Image.file(
                                File(_singleFilePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => ColoredBox(
                                  color: AppColors.wash,
                                  child: Icon(
                                    LucideIcons.imageOff,
                                    color: AppColors.textTertiary,
                                    size: 22,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _singleFilePath!.split('/').last,
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
                            isPdf
                                ? 'PDF ready · tap to change'
                                : 'Tap to enlarge',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFFFF7A50),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showPickerOptions(slot: _UploadSlot.single),
                      tooltip: 'Change file',
                      icon: Icon(
                        LucideIcons.refreshCw,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _singleFilePath = null;
                          _attachmentError = null;
                        });
                        _persistDraft();
                      },
                      tooltip: 'Remove file',
                      icon: Icon(
                        LucideIcons.x,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
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
      ),
    );
  }
}
