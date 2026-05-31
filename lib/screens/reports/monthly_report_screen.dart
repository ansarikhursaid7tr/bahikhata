import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../services/report_service.dart';
import '../../services/export_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../utils/money_utils.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/empty_state.dart';

import '../../utils/snackbar_utils.dart';
import 'package:bahi_khata/widgets/app_scaffold.dart';
class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  ConsumerState<MonthlyReportScreen> createState() =>
      _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  String? _selectedMonth;
  String? _staffFilter;
  MonthlyReportData? _reportData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final org = ref.read(currentOrganizationProvider).value;
      if (org != null) {
        setState(() {
          _selectedMonth = AppDateUtils.currentMonth(calendarType: org.calendarType);
        });
        _loadReport();
      }
    });
  }

  Future<void> _loadReport() async {
    final appUser = ref.read(currentAppUserProvider).value;
    if (appUser == null || _selectedMonth == null) return;

    setState(() => _isLoading = true);

    try {
      final reportService = ref.read(reportServiceProvider);
      final data = await reportService.getMonthlyReport(
        appUser.organizationId,
        _selectedMonth!,
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
    await exportService.exportMonthlyReportPdf(
      _reportData!,
      org?.name ?? 'BahiKhata',
      org?.currency ?? '\$',
      logoBase64: org?.logoBase64,
      address: org?.address,
      contact: org?.contact,
    );
  }

  Future<void> _exportCsv() async {
    if (_reportData == null) return;
    final org = ref.read(currentOrganizationProvider).value;
    final exportService = ExportService();
    await exportService.exportMonthlyReportCsv(
      _reportData!,
      org?.currency ?? '\$',
    );
  }

  @override
  Widget build(BuildContext context) {
    final appUser = ref.watch(currentAppUserProvider).value;
    final org = ref.watch(currentOrganizationProvider).value;
    final staffAsync = appUser != null
        ? ref.watch(staffListProvider(appUser.organizationId))
        : null;
        
    if (appUser == null || org == null || _selectedMonth == null) {
      return const AppScaffold(body: LoadingView());
    }

    final currency = org.currency;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Monthly Report'),
        actions: [
          if (_reportData != null) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _exportPdf,
              tooltip: 'Export PDF',
            ),
            IconButton(
              icon: const Icon(Icons.table_chart),
              onPressed: _exportCsv,
              tooltip: 'Export CSV',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Month navigation + Staff filter
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.surface,
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = AppDateUtils.previousMonth(_selectedMonth!);
                        });
                        _loadReport();
                      },
                    ),
                    Expanded(
                      child: Text(
                        AppDateUtils.displayMonth(_selectedMonth!),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        final parts = _selectedMonth!.split('-');
                        int y = int.parse(parts[0]);
                        int m = int.parse(parts[1]);
                        m++;
                        if (m > 12) {
                          m = 1;
                          y++;
                        }
                        setState(() {
                          _selectedMonth = '$y-${m.toString().padLeft(2, '0')}';
                        });
                        _loadReport();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                staffAsync?.when(
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                      data: (staffList) => DropdownButtonFormField<String?>(
                        value: _staffFilter,
                        hint: const Text('All Staff'),
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
              ],
            ),
          ),
          // Report content
          Expanded(
            child: _isLoading
                ? const LoadingView()
                : _reportData == null ||
                        _reportData!.staffData.isEmpty
                    ? const EmptyState(
                        icon: Icons.bar_chart_outlined,
                        title: 'No data for this month',
                      )
                    : _buildReport(context, currency),
          ),
        ],
      ),
    );
  }

  Widget _buildReport(BuildContext context, String currency) {
    final report = _reportData!;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: report.staffData.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _GrandSummaryItem(
                        'Production',
                        MoneyUtils.formatCurrencyCompact(
                            report.totalGrossProduction, currency)),
                    Container(width: 1, height: 36, color: Colors.white24),
                    _GrandSummaryItem(
                        'Payments',
                        MoneyUtils.formatCurrencyCompact(
                            report.totalPayments, currency)),
                    Container(width: 1, height: 36, color: Colors.white24),
                    _GrandSummaryItem(
                        'Payable',
                        MoneyUtils.formatCurrencyCompact(
                            report.totalPayable, currency)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        }

        final staff = report.staffData[index - 1];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(staff.staffName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        MoneyUtils.formatCurrencyCompact(
                            staff.finalPayable, currency),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Item breakdown table
                ...staff.itemBreakdown.values.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 3,
                              child: Text(item.itemTypeName,
                                  style: const TextStyle(fontSize: 13))),
                          Expanded(
                            flex: 4,
                            child: Text(
                              '${item.totalQuantity} × ${item.rate.toStringAsFixed(0)} = ${MoneyUtils.formatCurrencyCompact(item.totalAmount, currency)}',
                              style: const TextStyle(fontSize: 13),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 16),
                _ReportRow('Gross Production',
                    MoneyUtils.formatCurrencyCompact(staff.grossProduction, currency)),
                if (staff.totalBonus > 0)
                  _ReportRow('Bonus (+)',
                      MoneyUtils.formatCurrencyCompact(staff.totalBonus, currency),
                      color: AppTheme.success),
                if (staff.totalAdvance > 0)
                  _ReportRow('Advance (-)',
                      MoneyUtils.formatCurrencyCompact(staff.totalAdvance, currency),
                      color: AppTheme.warning),
                if (staff.totalPartialPayment > 0)
                  _ReportRow(
                      'Partial Payment (-)',
                      MoneyUtils.formatCurrencyCompact(
                          staff.totalPartialPayment, currency),
                      color: AppTheme.warning),
                if (staff.totalFinalPayment > 0)
                  _ReportRow(
                      'Final Payment (-)',
                      MoneyUtils.formatCurrencyCompact(
                          staff.totalFinalPayment, currency),
                      color: AppTheme.warning),
                if (staff.totalDeduction > 0)
                  _ReportRow('Deduction (-)',
                      MoneyUtils.formatCurrencyCompact(staff.totalDeduction, currency),
                      color: AppTheme.danger),
                const Divider(height: 12),
                _ReportRow(
                  'Final Payable',
                  MoneyUtils.formatCurrencyCompact(staff.finalPayable, currency),
                  bold: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GrandSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _GrandSummaryItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
      ],
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _ReportRow(this.label, this.value,
      {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: color ?? AppTheme.textPrimary,
              )),
          Text(value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: color ?? AppTheme.textPrimary,
              )),
        ],
      ),
    );
  }
}
