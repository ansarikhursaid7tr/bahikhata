import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../models/enums.dart';
import '../../services/report_service.dart';
import '../../services/export_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../utils/money_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/app_date_picker.dart';

import '../../utils/snackbar_utils.dart';
import 'package:bahi_khata/widgets/app_scaffold.dart';
class DailyReportScreen extends ConsumerStatefulWidget {
  const DailyReportScreen({super.key});

  @override
  ConsumerState<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends ConsumerState<DailyReportScreen> {
  String? _selectedDateStr;
  String? _staffFilter;
  DailyReportData? _reportData;
  bool _isLoading = false;

  String _currentDate(String defaultCalendar) {
    if (_selectedDateStr != null) return _selectedDateStr!;
    return AppDateUtils.today(calendarType: defaultCalendar);
  }

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to get org context and load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReport();
    });
  }

  Future<void> _loadReport() async {
    final appUser = ref.read(currentAppUserProvider).value;
    final org = ref.read(currentOrganizationProvider).value;
    if (appUser == null || org == null) return;

    setState(() => _isLoading = true);

    try {
      final reportService = ref.read(reportServiceProvider);
      final data = await reportService.getDailyReport(
        appUser.organizationId,
        _currentDate(org.calendarType),
        staffId: _staffFilter,
      );
      if (mounted) setState(() => _reportData = data);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to load report. Please try again.');
}
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_reportData == null) return;
    final org = ref.read(currentOrganizationProvider).value;
    final exportService = ExportService();
    await exportService.exportDailyReportPdf(
      _reportData!,
      org?.name ?? 'BahiKhata',
      org?.currency ?? '\$',
      logoBase64: org?.logoBase64,
      date: _currentDate(org?.calendarType ?? 'AD'),
      address: org?.address,
      contact: org?.contact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appUser = ref.watch(currentAppUserProvider).value;
    final org = ref.watch(currentOrganizationProvider).value;
    final staffAsync = appUser != null
        ? ref.watch(staffListProvider(appUser.organizationId))
        : null;
        
    if (appUser == null || org == null) return const AppScaffold(body: LoadingView());
    
    final currency = org.currency;
    final dateStr = _currentDate(org.calendarType);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Daily Report'),
        actions: [
          if (_reportData != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _exportPdf,
              tooltip: 'Export PDF',
            ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surface,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await AppDatePicker.show(
                            context,
                            calendarType: org.calendarType,
                            initialDate: dateStr,
                          );
                          if (date != null) {
                            setState(() => _selectedDateStr = date);
                            _loadReport();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18),
                              const SizedBox(width: 8),
                              Text(AppDateUtils.displayDate(dateStr)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: staffAsync?.when(
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                            data: (staffList) => DropdownButtonFormField<String?>(
                              value: _staffFilter,
                              hint: const Text('All Staff', style: TextStyle(fontSize: 13)),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem(
                                    value: null, child: Text('All Staff')),
                                ...staffList.map((s) => DropdownMenuItem(
                                    value: s.id, child: Text(s.name))),
                              ],
                              onChanged: (v) {
                                setState(() => _staffFilter = v);
                                _loadReport();
                              },
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ) ??
                          const SizedBox(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Report Content
          Expanded(
            child: _isLoading
                ? const LoadingView()
                : _reportData == null
                    ? const EmptyState(
                        icon: Icons.assessment_outlined,
                        title: 'No Data',
                      )
                    : _buildReport(context, currency),
          ),
        ],
      ),
    );
  }

  Widget _buildReport(BuildContext context, String currency) {
    final report = _reportData!;

    if (report.productionEntries.isEmpty && report.moneyEntries.isEmpty) {
      return const EmptyState(
        icon: Icons.assessment_outlined,
        title: 'No entries for this date',
        subtitle: 'Select a different date or add entries',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              _SummaryChip('Items', report.totalItems.toString(), AppTheme.primary),
              const SizedBox(width: 8),
              _SummaryChip('Production',
                  MoneyUtils.formatCurrencyCompact(report.totalProduction, currency),
                  AppTheme.accent),
              const SizedBox(width: 8),
              _SummaryChip('Payments',
                  MoneyUtils.formatCurrencyCompact(report.totalPayments, currency),
                  AppTheme.warning),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Net Payable',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  MoneyUtils.formatCurrencyCompact(report.netPayable, currency),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Production entries
          if (report.productionEntries.isNotEmpty) ...[
            Text('Production', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            ...report.productionEntries.map((entry) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.staffName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(
                              MoneyUtils.formatCurrencyCompact(
                                  entry.totalAmount, currency),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: entry.items
                              .where((i) => i.quantity > 0)
                              .map((i) => Chip(
                                    label: Text(
                                      '${i.itemTypeName}: ${i.quantity} × ${i.rateSnapshot.toStringAsFixed(0)} = ${i.lineTotal.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                )),
          ],

          // Money entries
          if (report.moneyEntries.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Money Entries',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            ...report.moneyEntries.map((entry) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: entry.effect == MoneyEffect.decreasePayable
                          ? AppTheme.warning.withValues(alpha: 0.1)
                          : AppTheme.success.withValues(alpha: 0.1),
                      child: Icon(
                        entry.effect == MoneyEffect.decreasePayable
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: entry.effect == MoneyEffect.decreasePayable
                            ? AppTheme.warning
                            : AppTheme.success,
                      ),
                    ),
                    title: Text(entry.staffName),
                    subtitle: Text(
                        '${entry.type.displayName}${entry.notes != null ? " — ${entry.notes}" : ""}'),
                    trailing: Text(
                      MoneyUtils.formatCurrencyCompact(entry.amount, currency),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}
