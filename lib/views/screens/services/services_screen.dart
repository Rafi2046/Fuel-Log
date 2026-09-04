import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../models/reminder_model.dart';
import '../../../viewmodels/fuel_log_viewmodel.dart';
import '../../../viewmodels/reminder_viewmodel.dart';
import '../../../viewmodels/service_log_viewmodel.dart';
import '../../../viewmodels/vehicle_viewmodel.dart';
import '../reminders/widgets/add_reminder_sheet.dart';
import '../reminders/widgets/reminder_card.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_shimmer.dart';
import 'widgets/add_cost_service_sheet.dart';
import 'widgets/service_log_detail_sheet.dart';

/// Full-featured Services & Maintenance Hub Screen
class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  static Future<void> open(BuildContext context, {int initialTabIndex = 0}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServicesScreen(initialTabIndex: initialTabIndex),
      ),
    );
  }

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategoryFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddCostSheet() {
    final vehicle = ref.read(activeVehicleProvider).valueOrNull;
    if (vehicle == null) return;
    final logs = ref.read(vehicleLogsProvider).valueOrNull ?? [];
    final currentOdo = logs.isNotEmpty ? logs.first.odometer : vehicle.startOdo;

    AddCostServiceSheet.show(
      context,
      vehicleId: vehicle.id,
      currentOdometer: currentOdo,
    );
  }

  void _openAddReminderSheet() {
    final vehicle = ref.read(activeVehicleProvider).valueOrNull;
    if (vehicle == null) return;
    final remindersState = ref.read(remindersProvider);

    AddReminderSheet.show(
      context,
      vehicleId: vehicle.id,
      currentOdometer: remindersState.currentOdometer,
      onSave: () {
        ref.read(remindersProvider.notifier).loadReminders();
      },
    );
  }

  void _confirmMarkDone(ServiceReminder reminder) {
    final costController = TextEditingController();
    final notesController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.appBar,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.wash,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complete Service',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          reminder.title,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Service Cost (Optional):',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  prefixText: '৳ ',
                  prefixStyle: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: 'e.g. 2500',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: const Color(0xFF1E1E2A),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFF2E2E3E)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Workshop / Notes (Optional):',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              TextField(
                controller: notesController,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Navana Toyota, Gulshan',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: const Color(0xFF1E1E2A),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFF2E2E3E)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Color(0xFF2E2E3E)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final cost = double.tryParse(costController.text.trim());
                        await ref.read(remindersProvider.notifier).markAsDone(
                              reminder.id,
                              cost: cost,
                              notes: notesController.text.trim().isEmpty
                                  ? null
                                  : notesController.text.trim(),
                            );
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.card,
                            content: Text(
                              '${reminder.title} marked completed',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('maintenance')) return Icons.build_rounded;
    if (lower.contains('repair')) return Icons.handyman_rounded;
    if (lower.contains('parking') || lower.contains('toll')) {
      return Icons.local_parking_rounded;
    }
    if (lower.contains('tax') ||
        lower.contains('legal') ||
        lower.contains('document')) {
      return Icons.description_rounded;
    }
    if (lower.contains('wash') || lower.contains('detailing')) {
      return Icons.clean_hands_rounded;
    }
    if (lower.contains('parts') || lower.contains('accessories')) {
      return Icons.shopping_bag_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  Color _getCategoryColor(String category) {
    // Muted mono accents — avoids rainbow clutter on a premium surface.
    final lower = category.toLowerCase();
    if (lower.contains('maintenance')) return AppColors.primary;
    if (lower.contains('repair')) return const Color(0xFFB45309);
    if (lower.contains('parking') || lower.contains('toll')) {
      return const Color(0xFF64748B);
    }
    if (lower.contains('tax') || lower.contains('document')) {
      return const Color(0xFF78716C);
    }
    if (lower.contains('wash')) return const Color(0xFF57534E);
    if (lower.contains('parts')) return const Color(0xFFA8A29E);
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final remindersState = ref.watch(remindersProvider);
    final serviceLogsAsync = ref.watch(serviceLogsProvider);
    final vehicle = ref.watch(activeVehicleProvider).valueOrNull;
    final serviceLogs = serviceLogsAsync.valueOrNull ?? [];

    final totalServiceSpend =
        serviceLogs.fold<double>(0.0, (sum, item) => sum + item.cost);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        leading: AppBackButton(),
        titleWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'servicesHubTitle'.tr(),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (vehicle != null)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      vehicle.name,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: AppSpacing.appBarBodyGap),
          // 1. Top Summary Banner
          _buildTopSummaryBanner(
              remindersState, totalServiceSpend, serviceLogs.length),

          // 2. Styled Segmented Tab Bar
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: 8,
            ),
            child: Container(
              height: 40,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.wash,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.hairline),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: AppColors.isDark ? 0.25 : 0.04,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelPadding: EdgeInsets.symmetric(horizontal: 4),
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textTertiary,
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.alarm_rounded, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'servicesSchedulesTab'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'servicesHistoryTab'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pie_chart_outline_rounded, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'servicesAnalyticsTab'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSchedulesView(remindersState),
                _buildHistoryView(serviceLogs, vehicle?.name),
                _buildAnalyticsView(serviceLogs, totalServiceSpend, vehicle),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(remindersState),
    );
  }

  Widget? _buildFloatingActionButton(RemindersState state) {
    if (_tabController.index == 0) {
      if (state.activeReminders.isEmpty) return null;
      return FloatingActionButton.extended(
        onPressed: _openAddReminderSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.alarm_add_rounded, size: 18),
        label: Text(
          'servicesAddReminder'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      );
    } else if (_tabController.index == 1) {
      return FloatingActionButton.extended(
        onPressed: _openAddCostSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(
          'servicesLogNew'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      );
    }
    return null;
  }

  Widget _buildTopSummaryBanner(
    RemindersState state,
    double totalSpend,
    int logCount,
  ) {
    final hasOverdue = state.overdueCount > 0;
    final hasDueSoon = state.dueSoonCount > 0;

    Color healthColor = AppColors.textSecondary;
    String healthTitle = 'All Systems Optimal';
    IconData healthIcon = LucideIcons.shieldCheck;
    final isNeutralHealth = !hasOverdue && !hasDueSoon;

    if (hasOverdue) {
      healthColor = AppColors.error;
      healthTitle = '${state.overdueCount} Overdue Schedule';
      healthIcon = LucideIcons.triangleAlert;
    } else if (hasDueSoon) {
      healthColor = AppColors.warning;
      healthTitle = '${state.dueSoonCount} Service Due Soon';
      healthIcon = LucideIcons.bellRing;
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: 4,
      ),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: hasOverdue
              ? AppColors.error.withValues(alpha: 0.28)
              : hasDueSoon
                  ? AppColors.warning.withValues(alpha: 0.28)
                  : AppColors.hairline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isNeutralHealth
                  ? AppColors.wash
                  : healthColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isNeutralHealth
                    ? AppColors.border
                    : healthColor.withValues(alpha: 0.22),
              ),
            ),
            child: Icon(
              healthIcon,
              color: isNeutralHealth ? AppColors.textSecondary : healthColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  healthTitle,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isNeutralHealth
                        ? AppColors.textPrimary
                        : healthColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  '${state.activeReminders.length} Schedules · $logCount Records',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppCurrency.format(totalSpend),
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Total Spend',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SUB TAB 1: SCHEDULES & REMINDERS ---
  Widget _buildSchedulesView(RemindersState state) {
    if (state.isLoading && state.reminders.isEmpty) {
      return const ServicesSkeleton();
    }

    final activeList = state.activeReminders;

    if (activeList.isEmpty) {
      return AppRefreshIndicator(
        onRefresh: () async {
          await ref.read(remindersProvider.notifier).loadReminders();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.2,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.wash,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        Icons.alarm_on_rounded,
                        size: 32,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Maintenance Schedules Set',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Set service reminders for engine oil, filters, brake pads, and tire rotation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppPrimaryButton(
                      label: 'servicesAddReminder'.tr(),
                      icon: Icons.add_rounded,
                      compact: true,
                      onPressed: _openAddReminderSheet,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AppRefreshIndicator(
      onRefresh: () async {
        await ref.read(remindersProvider.notifier).loadReminders();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
        itemCount: activeList.length,
        itemBuilder: (ctx, idx) {
          final reminder = activeList[idx];
          return ReminderCard(
            reminder: reminder,
            currentOdometer: state.currentOdometer,
            onMarkDone: () => _confirmMarkDone(reminder),
            onEdit: () async {
              final vehicle = ref.read(activeVehicleProvider).valueOrNull;
              if (vehicle == null) return;
              final numId = int.tryParse(reminder.id);
              if (numId == null) return;
              final db = ref.read(databaseProvider);
              final driftReminder = await db.getReminderById(numId);
              if (driftReminder == null || !mounted) return;
              AddReminderSheet.show(
                context,
                vehicleId: vehicle.id,
                currentOdometer: state.currentOdometer,
                existingReminder: driftReminder,
                onSave: () =>
                    ref.read(remindersProvider.notifier).loadReminders(),
              );
            },
            onDelete: () =>
                ref.read(remindersProvider.notifier).deleteReminder(reminder.id),
          );
        },
      ),
    );
  }

  // --- SUB TAB 2: SERVICE & EXPENSE HISTORY ---
  Widget _buildHistoryView(List<ServiceLog> logs, String? vehicleName) {
    final categories = [
      'All',
      'Maintenance',
      'Repair',
      'Parking/Toll',
      'Tax/Docs',
      'Washing',
      'Parts',
      'Other',
    ];

    final filteredLogs = _selectedCategoryFilter == 'All'
        ? logs
        : logs.where((l) {
            final cat = l.category.toLowerCase();
            final sel = _selectedCategoryFilter.toLowerCase();
            return cat.contains(sel) || sel.contains(cat);
          }).toList();

    final filteredSpend =
        filteredLogs.fold<double>(0.0, (sum, l) => sum + l.cost);

    return Column(
      children: [
        // Category Chips Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: 6,
          ),
          child: Row(
            children: categories.map((cat) {
              final isSelected = _selectedCategoryFilter == cat;
              return Padding(
                padding: EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategoryFilter = cat);
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.12),
                  backgroundColor: AppColors.card,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.hairline,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            }).toList(),
          ),
        ),

        // Filter Summary Info
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${filteredLogs.length} Records Found',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Total: ${AppCurrency.format(filteredSpend)}',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: AppRefreshIndicator(
            onRefresh: () async {
              ref.invalidate(serviceLogsProvider);
            },
            child: filteredLogs.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.18,
                      ),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 38,
                                color: AppColors.textTertiary,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No Service Logs Found',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tap + to log your maintenance or repair expense.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      6,
                      AppSpacing.screenPadding,
                      80,
                    ),
                  itemCount: filteredLogs.length,
                  itemBuilder: (ctx, idx) {
                    final log = filteredLogs[idx];
                    final catIcon = _getCategoryIcon(log.category);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Dismissible(
                        key: ValueKey(log.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        onDismissed: (_) async {
                          await ref
                              .read(serviceLogServiceProvider)
                              .deleteServiceLog(log.id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('logDeleted'.tr()),
                              backgroundColor: AppColors.control,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: InkWell(
                          onTap: () => ServiceLogDetailSheet.show(
                            context,
                            log: log,
                            vehicleName: vehicleName,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.hairline),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppColors.wash,
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Icon(
                                    catIcon,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        '${AppDateFormats.formatLogDate(log.date)}${log.odometer != null ? ' · ${log.odometer!.toStringAsFixed(0)} km' : ''}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                      if (log.note != null &&
                                          log.note!.isNotEmpty) ...[
                                        SizedBox(height: 2),
                                        Text(
                                          log.note!,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: AppColors.textSecondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppCurrency.format(log.cost),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ),
      ],
    );
  }

  // --- SUB TAB 3: COST ANALYTICS & INSIGHTS ---
  Widget _buildAnalyticsView(
    List<ServiceLog> logs,
    double totalSpend,
    Vehicle? vehicle,
  ) {
    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 40,
                color: AppColors.textTertiary,
              ),
              SizedBox(height: 12),
              Text(
                'No Expense Analytics Yet',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Log services and repairs to view category cost distribution.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Category aggregation
    final Map<String, double> categoryCosts = {};
    for (final l in logs) {
      categoryCosts[l.category] = (categoryCosts[l.category] ?? 0.0) + l.cost;
    }

    final sortedCats = categoryCosts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final avgPerService = totalSpend / logs.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        8,
        AppSpacing.screenPadding,
        80,
      ),
      children: [
        // Metrics Row
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Total Service Cost',
                value: AppCurrency.format(totalSpend),
                icon: Icons.account_balance_wallet_rounded,
                accent: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Avg Cost / Service',
                value: AppCurrency.format(avgPerService),
                icon: Icons.calculate_rounded,
                accent: AppColors.primary,
              ),
            ),
          ],
        ),

        SizedBox(height: AppSpacing.md),

        // Category Breakdown Card
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.donut_small_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Category Spending Breakdown',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...sortedCats.map((entry) {
                final cat = entry.key;
                final cost = entry.value;
                final pct = totalSpend > 0 ? (cost / totalSpend) : 0.0;
                final catColor = _getCategoryColor(cat);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: catColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${AppCurrency.format(cost)} (${(pct * 100).toStringAsFixed(1)}%)',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 5,
                          backgroundColor: AppColors.wash,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            catColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        SizedBox(height: AppSpacing.md),

        // Recent High Expenses
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top Service Expenses',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...(List<ServiceLog>.from(logs)
                    ..sort((a, b) => b.cost.compareTo(a.cost)))
                  .take(3)
                  .map((log) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(log.category),
                        size: 15,
                        color: AppColors.textTertiary,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          log.title,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        AppCurrency.format(log.cost),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.wash,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
