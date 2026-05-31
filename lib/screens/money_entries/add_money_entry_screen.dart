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
class AddMoneyEntryScreen extends ConsumerStatefulWidget {
  final String? entryId;
  const AddMoneyEntryScreen({super.key, this.entryId});

  @override
  ConsumerState<AddMoneyEntryScreen> createState() =>
      _AddMoneyEntryScreenState();
}

class _AddMoneyEntryScreenState extends ConsumerState<AddMoneyEntryScreen> {
  String? _selectedDateStr;
  String? _selectedStaffId;
  String? _selectedStaffName;
  MoneyEntryType _selectedType = MoneyEntryType.advance;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;
  MoneyEntry? _editingEntry;

  @override
  void initState() {
    super.initState();
    if (widget.entryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadEntryForEdit();
      });
    }
  }

  Future<void> _loadEntryForEdit() async {
    final appUser = ref.read(currentAppUserProvider).value;
    if (appUser == null) return;
    
    final firestoreService = ref.read(firestoreServiceProvider);
    final entry = await firestoreService.getMoneyEntryById(appUser.organizationId, widget.entryId!);
    if (entry != null && mounted) {
      setState(() {
        _editingEntry = entry;
        _selectedDateStr = entry.date;
        _selectedStaffId = entry.staffId;
        _selectedStaffName = entry.staffName;
        _selectedType = entry.type;
        _amountController.text = entry.amount.toString();
        _notesController.text = entry.notes ?? '';
      });
    }
  }

  String _currentDate(String defaultCalendar) {
    if (_selectedDateStr != null) return _selectedDateStr!;
    return AppDateUtils.today(calendarType: defaultCalendar);
  }

  String _currentMonth(String defaultCalendar) {
    final month = AppDateUtils.getMonthFromDateString(_currentDate(defaultCalendar));
    return month;
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

      final entry = MoneyEntry(
        id: _editingEntry?.id ?? '',
        date: _currentDate(calendarType),
        month: _currentMonth(calendarType),
        staffId: _selectedStaffId!,
        staffName: _selectedStaffName ?? '',
        type: _selectedType,
        effect: _selectedType == MoneyEntryType.advance || _selectedType == MoneyEntryType.partialPayment || _selectedType == MoneyEntryType.finalPayment || _selectedType == MoneyEntryType.deduction ? MoneyEffect.decreasePayable : MoneyEffect.increasePayable,
        amount: amount,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdBy: _editingEntry?.createdBy ?? appUser.uid,
        createdAt: _editingEntry?.createdAt ?? now,
        updatedAt: now,
      );

      if (_editingEntry != null) {
        await firestoreService.updateMoneyEntry(appUser.organizationId, entry);
      } else {
        await firestoreService.addMoneyEntry(appUser.organizationId, entry);
      }

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Money entry saved successfully');
context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to save money entry. Please try again.');
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
      appBar: AppBar(title: Text(_editingEntry != null ? 'Edit Money Entry' : 'Add Money Entry')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date', style: Theme.of(context).textTheme.titleMedium),
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
                          const Icon(Icons.calendar_today, size: 20, color: AppTheme.textSecondary),
                          const SizedBox(width: 12),
                          Text(
                            AppDateUtils.displayDate(dateStr),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Staff', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  staffAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                    data: (staffList) {
                      return DropdownButtonFormField<String>(
                        value: _selectedStaffId,
                        hint: const Text('Select staff'),
                        items: staffList.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                        onChanged: (v) {
                          final staff = staffList.firstWhere((s) => s.id == v);
                          setState(() {
                            _selectedStaffId = v;
                            _selectedStaffName = staff.name;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  Text('Type', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<MoneyEntryType>(
                    value: _selectedType,
                    items: MoneyEntryType.values.map((type) {
                      final effect = type == MoneyEntryType.advance || type == MoneyEntryType.partialPayment || type == MoneyEntryType.finalPayment || type == MoneyEntryType.deduction ? MoneyEffect.decreasePayable : MoneyEffect.increasePayable;
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(
                              effect == MoneyEffect.increasePayable
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: effect == MoneyEffect.increasePayable
                                  ? AppTheme.primary
                                  : AppTheme.warning,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(type.displayName),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedType = v);
                    },
                  ),
                  Builder(
                    builder: (context) {
                      final effect = _selectedType == MoneyEntryType.advance || _selectedType == MoneyEntryType.partialPayment || _selectedType == MoneyEntryType.finalPayment || _selectedType == MoneyEntryType.deduction ? MoneyEffect.decreasePayable : MoneyEffect.increasePayable;
                      return Text(
                        effect == MoneyEffect.increasePayable
                            ? 'Increases Payable'
                            : 'Decreases Payable',
                        style: TextStyle(
                          color: effect == MoneyEffect.increasePayable
                              ? AppTheme.primary
                              : AppTheme.warning,
                          fontSize: 12,
                        ),
                      );
                    }
                  ),
                  const SizedBox(height: 16),

                  Text('Amount', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      prefixText: '${org.currency} ',
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Notes (Optional)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'Any additional notes...'),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(
              label: _editingEntry != null ? 'Update Money Entry' : 'Save Money Entry',
              onPressed: () => _save(org.id, org.calendarType),
              isLoading: _isSaving,
              icon: Icons.save,
            ),
          ),
        ],
      ),
    );
  }
}
