import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../models/station_search_filter.dart';

class StationSearchFilterBar extends StatefulWidget {
  const StationSearchFilterBar({
    super.key,
    required this.draft,
    required this.applied,
    required this.onDraftChanged,
    required this.onApply,
    required this.onReset,
    this.resultCount,
  });

  final StationSearchFilter draft;
  final StationSearchFilter applied;
  final ValueChanged<StationSearchFilter> onDraftChanged;
  final VoidCallback onApply;
  final VoidCallback onReset;
  final int? resultCount;

  @override
  State<StationSearchFilterBar> createState() => _StationSearchFilterBarState();
}

class _StationSearchFilterBarState extends State<StationSearchFilterBar> {
  late final TextEditingController _queryController;

  bool get _hasPendingChanges => widget.draft != widget.applied;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.draft.query);
  }

  @override
  void didUpdateWidget(covariant StationSearchFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft.query != widget.draft.query &&
        _queryController.text != widget.draft.query) {
      _queryController.value = TextEditingValue(
        text: widget.draft.query,
        selection: TextSelection.collapsed(offset: widget.draft.query.length),
      );
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final applied = widget.applied;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _queryController,
            onChanged: (value) =>
                widget.onDraftChanged(draft.copyWith(query: value)),
            style: AppTextStyles.body.copyWith(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search station, area, or fuel',
              hintStyle: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 18,
                color: AppColors.textTertiary,
              ),
              filled: true,
              fillColor: AppColors.inputFill,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Within ${draft.radiusKm.toStringAsFixed(0)} km',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.resultCount != null) ...[
                SizedBox(width: 8),
                Text(
                  _hasPendingChanges
                      ? '· tap Apply to update'
                      : '· ${widget.resultCount} shown',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.14),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: draft.radiusKm,
              min: 2,
              max: 15,
              divisions: 13,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                widget.onDraftChanged(
                  draft.copyWith(radiusKm: value.roundToDouble()),
                );
              },
            ),
          ),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final fuel in StationFuelFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child:                     _FilterChip(
                      label: fuel.label,
                      selected: draft.fuel == fuel,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onDraftChanged(draft.copyWith(fuel: fuel));
                      },
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: applied.hasActiveConstraints || _hasPendingChanges
                        ? widget.onReset
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: Text(
                      'Reset',
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _hasPendingChanges ? widget.onApply : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.control,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: Text(
                      _hasPendingChanges ? 'Apply filters' : 'Applied',
                      style: AppTextStyles.label.copyWith(
                        color: _hasPendingChanges
                            ? Colors.white
                            : AppColors.textTertiary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.16)
          : AppColors.control,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
