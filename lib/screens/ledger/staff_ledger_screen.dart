import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../services/report_service.dart';
import '../../services/export_service.dart';
import '../../models/enums.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../utils/money_utils.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/empty_state.dart';

import '../../utils/snackbar_utils.dart';
import 'package:bahi_khata/widgets/app_scaffold.dart';
class StaffLedgerScreen extends ConsumerStatefulWidget {
  final String? staffId;
  const StaffLedgerScreen({super.key, this.staffId});

  @override
  ConsumerState<StaffLedgerScreen> createState() => _StaffLedgerScreenState();
}

class _StaffLedgerScreenState extends ConsumerState<StaffLedgerScreen> {
  String? _selectedStaffId;
  String? _selectedMonth;
  List<LedgerEntry>? _ledgerEntries;
  bool _isLoading = false;
  String _staffName = '';

  @override
  void initState() {
    super.initState();
    _selectedStaffId = widget.staffId;

    // For staff role, auto-select their own ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appUser = ref.read(currentAppUserProvider).value;
      final org = ref.read(currentOrganizationProvider).value;
      if (org != null) {
        setState(() {
          _selectedMonth = AppDateUtils.currentMonth(calendarType: org.calendarType);
        });
      }

      if (appUser != null && appUser.role == UserRole.staff) {
        setState(() {
          _selectedStaffId = appUser.staffId;
          _staffName = appUser.name;
        });
        _loadLedger();
      } else if (_selectedStaffId != null) {
        _loadLedger();
      }
    });
  }

  Future<void> _loadLedger() async {
    if (_selectedStaffId == null || _selectedMonth == null) return;

    final appUser = ref.read(currentAppUserProvider).value;
    if (appUser == null) return;

    setState(() => _isLoading = true);

    try {
      final reportService = ref.read(reportServiceProvider);
      final entries = await reportService.getStaffLedger(
        appUser.organizationId,
        _selectedStaffId!,
        month: _selectedMonth!,
      );
      if (mounted) setState(() => _ledgerEntries = entries);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to load ledger. Please try again.');
}
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_ledgerEntries == null || _ledgerEntries!.isEmpty || _selectedMonth == null) return;
    final org = ref.read(currentOrganizationProvider).value;
    final exportService = ExportService();
    await exportService.exportStaffLedgerPdf(
      _ledgerEntries!,
      _staffName,
      _selectedMonth!,
      org?.name ?? 'BahiKhata',
      org?.currency ?? '\$',
      logoBase64: org?.logoBase64,
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
        
    if (appUser == null || org == null || _selectedMonth == null) {
      return const AppScaffold(body: LoadingView());
    }

    final currency = org.currency;
    final isStaffRole = appUser.role == UserRole.staff;

    return AppScaffold(
      appBar: AppBar(
        title: Text(isStaffRole ? 'My Ledger' : 'Staff Ledger'),
        actions: [
          if (_ledgerEntries != null && _ledgerEntries!.isNotEmpty)
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
            padding: const EdgeInsets.all(12),
            color: AppTheme.surface,
            child: Column(
              children: [
                // Staff selector (hidden for staff role)
                if (!isStaffRole)
                  staffAsync?.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const SizedBox(),
                        data: (staffList) => DropdownButtonFormField<String>(
                          value: _selectedStaffId,
                          hint: const Text('Select Staff'),
                          isExpanded: true,
                          items: staffList
                              .map((s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.name),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            final staff =
                                staffList.firstWhere((s) => s.id == v);
                            setState(() {
                              _selectedStaffId = v;
                              _staffName = staff.name;
                            });
                            _loadLedger();
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
                const SizedBox(height: 8),
                // Month navigation
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = AppDateUtils.previousMonth(_selectedMonth!);
                        });
                        _loadLedger();
                      },
                    ),
                    Expanded(
                      child: Text(
                        AppDateUtils.displayMonth(_selectedMonth!),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
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
                        _loadLedger();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Ledger content
          Expanded(
            child: _selectedStaffId == null
                ? const EmptyState(
                    icon: Icons.person_search,
                    title: 'Select a staff member',
                  )
                : _isLoading
                    ? const LoadingView()
                    : _ledgerEntries == null || _ledgerEntries!.isEmpty
                        ? const EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'No entries found',
                            subtitle: 'No records for this month',
                          )
                        : _buildLedger(context, currency),
          ),
        ],
      ),
    );
  }

  Widget _buildLedger(BuildContext context, String currency) {
    final entries = _ledgerEntries!;
    final finalBalance = entries.isNotEmpty ? entries.last.balance : 0.0;

    return Column(
      children: [
        // Final balance header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: finalBalance > 0
                ? AppTheme.dangerGradient
                : AppTheme.accentGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _staffName.isNotEmpty ? _staffName : 'Staff',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    MoneyUtils.formatCurrencyCompact(finalBalance, currency),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    finalBalance > 0 ? 'Payable' : 'Settled',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Ledger table
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    SizedBox(
                      width: 52,
                      child: Text(
                        entry.date.substring(5), // MM-DD
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Description
                    Expanded(
                      child: Text(
                        entry.description,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    // Earned
                    SizedBox(
                      width: 60,
                      child: Text(
                        entry.earned > 0
                            ? '+${entry.earned.toStringAsFixed(0)}'
                            : '',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Paid
                    SizedBox(
                      width: 60,
                      child: Text(
                        entry.paid > 0
                            ? '-${entry.paid.toStringAsFixed(0)}'
                            : '',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Balance
                    SizedBox(
                      width: 60,
                      child: Text(
                        entry.balance.toStringAsFixed(0),
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
