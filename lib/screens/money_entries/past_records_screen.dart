import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../models/money_entry_model.dart';
import '../../models/enums.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/app_button.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/app_date_picker.dart';

import '../../utils/snackbar_utils.dart';
import 'package:bahi_khata/widgets/app_scaffold.dart';
class PastRecordsScreen extends ConsumerStatefulWidget {
  const PastRecordsScreen({super.key});

  @override
  ConsumerState<PastRecordsScreen> createState() => _PastRecordsScreenState();
}

class _PastRecordsScreenState extends ConsumerState<PastRecordsScreen> {
  String? _selectedDateStr;
  String? _selectedStaffId;
  String? _selectedStaffName;
  MoneyEntryType _selectedType = MoneyEntryType.advance; // Default to old payment
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  String _currentDate(String defaultCalendar) {
    if (_selectedDateStr != null) return _selectedDateStr!;
    return AppDateUtils.today(calendarType: defaultCalendar);
  }

  String _currentMonth(String defaultCalendar) {
    return AppDateUtils.getMonthFromDateString(_currentDate(defaultCalendar));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save(String orgId, String calendarType) async {
    if (_selectedStaffId == null) {
      AppSnackBar.showSuccess(context, 'Please select a staff member');
return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      AppSnackBar.showSuccess(context, 'Please enter a valid amount');
return;
    }

    setState(() => _isSaving = true);

    try {
      final appUser = ref.read(currentAppUserProvider).value!;
      final firestoreService = ref.read(firestoreServiceProvider);
      final now = DateTime.now();

      await firestoreService.addMoneyEntry(
        appUser.organizationId,
        MoneyEntry(
          id: '',
          date: _currentDate(calendarType),
          month: _currentMonth(calendarType),
          staffId: _selectedStaffId!,
          staffName: _selectedStaffName ?? '',
          type: _selectedType,
          effect: _selectedType == MoneyEntryType.advance || _selectedType == MoneyEntryType.partialPayment || _selectedType == MoneyEntryType.finalPayment || _selectedType == MoneyEntryType.deduction ? MoneyEffect.decreasePayable : MoneyEffect.increasePayable,
          amount: amount,
          notes: _notesController.text.trim().isEmpty ? 'Past Record Entry' : _notesController.text.trim(),
          createdBy: appUser.uid,
          createdAt: now,
          updatedAt: now,
        ),
      );

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Past record saved successfully');
context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to save record. Please try again.');
}
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUser = ref.watch(currentAppUserProvider).value;
    final org = ref.watch(currentOrganizationProvider).value;

    if (appUser == null || org == null) return const AppScaffold(body: LoadingView());

    final orgId = appUser.organizationId;
    final staffAsync = ref.watch(staffListProvider(orgId));

    final dateStr = _currentDate(org.calendarType);

    return AppScaffold(
      appBar: AppBar(title: const Text('Add Past Record')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Record Date', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final date = await AppDatePicker.show(
                        context,
                        calendarType: org.calendarType,
                        initialDate: dateStr,
                      );
                      if (date != null) {
                        setState(() => _selectedDateStr = date);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            AppDateUtils.displayDate(dateStr),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Text('Staff', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  staffAsync.when(
                    data: (staffList) {
                      if (staffList.isEmpty) {
                        return const Text('No staff found. Please add staff first.');
                      }
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          hintText: 'Select Staff',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        value: _selectedStaffId,
                        items: staffList.map((s) {
                          return DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedStaffId = val;
                            _selectedStaffName = staffList.firstWhere((s) => s.id == val).name;
                          });
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Error loading staff'),
                  ),
                  const SizedBox(height: 20),

                  Text('Record Type', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<MoneyEntryType>(
                          title: const Text('Past Payment (Decrease Balance)'),
                          subtitle: const Text('Money already paid to staff'),
                          value: MoneyEntryType.advance,
                          groupValue: _selectedType,
                          onChanged: (val) => setState(() => _selectedType = val!),
                        ),
                        const Divider(height: 1),
                        RadioListTile<MoneyEntryType>(
                          title: const Text('Past Production (Increase Balance)'),
                          subtitle: const Text('Staff work amount to be paid'),
                          value: MoneyEntryType.bonus,
                          groupValue: _selectedType,
                          onChanged: (val) => setState(() => _selectedType = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text('Amount', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixText: '${org.currency} ',
                      prefixStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text('Notes (Optional)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Cleared till last month',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: AppButton(
              label: 'Save Past Record',
              onPressed: () => _save(org.id, org.calendarType),
              isLoading: _isSaving,
              icon: Icons.history,
            ),
          ),
        ],
      ),
    );
  }
}
