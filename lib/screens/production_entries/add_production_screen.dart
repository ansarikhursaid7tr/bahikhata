import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../models/item_type_model.dart';
import '../../models/production_entry_model.dart';
import '../../models/production_item_model.dart';
import '../../models/money_entry_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../utils/money_utils.dart';
import '../../widgets/app_button.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/app_date_picker.dart';
import '../../models/enums.dart';

import '../../utils/snackbar_utils.dart';
import 'package:bahi_khata/widgets/app_scaffold.dart';
class AddProductionScreen extends ConsumerStatefulWidget {
  final String? entryId;
  const AddProductionScreen({super.key, this.entryId});

  @override
  ConsumerState<AddProductionScreen> createState() =>
      _AddProductionScreenState();
}

class _AddProductionScreenState extends ConsumerState<AddProductionScreen> {
  String? _selectedDateStr;
  String? _selectedStaffId;
  String? _selectedStaffName;
  final _notesController = TextEditingController();
  final _paymentController = TextEditingController();
  final Map<String, TextEditingController> _qtyControllers = {};
  Map<String, double> _rateMap = {};
  bool _isSaving = false;
  bool _ratesLoaded = false;
  String _lastLoadedMonth = '';
  ProductionEntry? _editingEntry;

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
    final entry = await firestoreService.getProductionEntryById(appUser.organizationId, widget.entryId!);
    if (entry != null && mounted) {
      setState(() {
        _editingEntry = entry;
        _selectedDateStr = entry.date;
        _selectedStaffId = entry.staffId;
        _selectedStaffName = entry.staffName;
        _notesController.text = entry.notes ?? '';
      });
      for (var item in entry.items) {
        if (!_qtyControllers.containsKey(item.itemTypeId)) {
          _qtyControllers[item.itemTypeId] = TextEditingController(text: item.quantity.toString());
        } else {
          _qtyControllers[item.itemTypeId]!.text = item.quantity.toString();
        }
      }
      await _loadRates(appUser.organizationId, entry.month);
    }
  }

  String _currentDate(String defaultCalendar) {
    if (_selectedDateStr != null) return _selectedDateStr!;
    return AppDateUtils.today(calendarType: defaultCalendar);
  }

  String _currentMonth(String defaultCalendar) {
    return AppDateUtils.getMonthFromDateString(_currentDate(defaultCalendar));
  }

  @override
  void dispose() {
    _notesController.dispose();
    _paymentController.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadRates(String orgId, String month) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final rateMap = await firestoreService.getRateMap(orgId, month);

    if (mounted) {
      setState(() {
        _rateMap = rateMap;
        _ratesLoaded = true;
        _lastLoadedMonth = month;
      });
    }
  }

  double _calculateTotal(List<ItemType> itemTypes) {
    double total = 0;
    for (final item in itemTypes) {
      final qty = int.tryParse(_qtyControllers[item.id]?.text ?? '0') ?? 0;
      final rate = _rateMap[item.id] ?? 0;
      total += qty * rate;
    }
    return total;
  }

  int _totalItems(List<ItemType> itemTypes) {
    int total = 0;
    for (final item in itemTypes) {
      total += int.tryParse(_qtyControllers[item.id]?.text ?? '0') ?? 0;
    }
    return total;
  }

  Future<void> _save(List<ItemType> itemTypes, String orgId, String calendarType) async {
    if (_selectedStaffId == null) {
      AppSnackBar.showSuccess(context, 'Please select a staff member');
return;
    }

    final totalQty = _totalItems(itemTypes);
    if (totalQty == 0) {
      AppSnackBar.showSuccess(context, 'At least one item quantity must be > 0');
return;
    }

    final month = _currentMonth(calendarType);

    for (final item in itemTypes) {
      final qty = int.tryParse(_qtyControllers[item.id]?.text ?? '0') ?? 0;
      if (qty > 0 && !_rateMap.containsKey(item.id)) {
        AppSnackBar.showSuccess(context, 'Rate not set for ${item.name} in $month. Please set rates first.');
return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final appUser = ref.read(currentAppUserProvider).value!;
      final firestoreService = ref.read(firestoreServiceProvider);
      final now = DateTime.now();
      final dateStr = _currentDate(calendarType);

      final items = <ProductionItem>[];
      for (final item in itemTypes) {
        final qty = int.tryParse(_qtyControllers[item.id]?.text ?? '0') ?? 0;
        if (qty > 0) {
          final rate = _rateMap[item.id] ?? 0;
          items.add(ProductionItem(
            itemTypeId: item.id,
            itemTypeName: item.name,
            quantity: qty,
            rateSnapshot: rate,
          ));
        }
      }

      final totalAmount = items.fold(0.0, (sum, i) => sum + i.lineTotal);
      final totalQuantity = items.fold(0, (sum, i) => sum + i.quantity);

      final entry = ProductionEntry(
        id: _editingEntry?.id ?? '',
        date: dateStr,
        month: month,
        staffId: _selectedStaffId!,
        staffName: _selectedStaffName ?? '',
        totalAmount: totalAmount,
        totalQuantity: totalQuantity,
        items: items,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdBy: _editingEntry?.createdBy ?? appUser.uid,
        createdAt: _editingEntry?.createdAt ?? now,
        updatedAt: now,
      );

      if (_editingEntry != null) {
        await firestoreService.updateProductionEntry(appUser.organizationId, entry);
      } else {
        await firestoreService.addProductionEntry(appUser.organizationId, entry);
      }

      // Create money entry if payment added (works for both new and edited entries)
      final paymentAmount = double.tryParse(_paymentController.text) ?? 0.0;
      if (paymentAmount > 0) {
        await firestoreService.addMoneyEntry(
          appUser.organizationId,
          MoneyEntry(
            id: '',
            date: dateStr,
            month: month,
            staffId: _selectedStaffId!,
            staffName: _selectedStaffName ?? '',
            type: MoneyEntryType.partialPayment,
            effect: MoneyEffect.decreasePayable,
            amount: paymentAmount,
            notes: 'Payment during production entry',
            createdBy: appUser.uid,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Production entry saved successfully!');
context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to save production entry. Please try again.');
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
    final itemTypesAsync = ref.watch(itemTypeListProvider(orgId));

    final dateStr = _currentDate(org.calendarType);
    final monthStr = _currentMonth(org.calendarType);

    if (!_ratesLoaded || _lastLoadedMonth != monthStr) {
      _loadRates(orgId, monthStr);
    }

    return AppScaffold(
      appBar: AppBar(
        title: Text(_editingEntry != null ? 'Edit Production' : 'Add Production'),
      ),
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
                        setState(() {
                          _selectedDateStr = date;
                          _ratesLoaded = false; // Reload rates for new date's month
                        });
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
                          const Spacer(),
                          Text(
                            AppDateUtils.displayMonth(monthStr),
                            style: Theme.of(context).textTheme.bodyMedium,
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
                        decoration: const InputDecoration(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  Text('Items', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  itemTypesAsync.when(
                    loading: () => const LoadingView(),
                    error: (e, _) => Text('Error: $e'),
                    data: (itemTypes) {
                      for (final item in itemTypes) {
                        _qtyControllers.putIfAbsent(item.id, () => TextEditingController(text: ''));
                      }

                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 3, child: Text('Item', style: TextStyle(fontWeight: FontWeight.w600))),
                                Expanded(flex: 2, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600))),
                                Expanded(flex: 2, child: Text('Rate', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600))),
                                Expanded(flex: 2, child: Text('Amount', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.w600))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...itemTypes.map((item) {
                            final rate = _rateMap[item.id] ?? 0;
                            final qty = int.tryParse(_qtyControllers[item.id]?.text ?? '0') ?? 0;
                            final amount = qty * rate;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(flex: 3, child: Text(item.name, style: const TextStyle(fontSize: 14))),
                                  Expanded(
                                    flex: 2,
                                    child: SizedBox(
                                      height: 40,
                                      child: TextFormField(
                                        controller: _qtyControllers[item.id],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        onChanged: (_) => setState(() {}),
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          hintText: '0',
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      rate > 0 ? rate.toStringAsFixed(0) : '-',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: rate > 0 ? AppTheme.textSecondary : AppTheme.danger, fontSize: 13),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      amount > 0 ? amount.toStringAsFixed(0) : '-',
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total: ${_totalItems(itemTypes)} items', style: Theme.of(context).textTheme.titleMedium),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  MoneyUtils.formatCurrencyCompact(_calculateTotal(itemTypes), org.currency),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add Payment (Optional)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _paymentController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Payment Amount',
                      prefixIcon: Icon(Icons.payments),
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
            child: itemTypesAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (itemTypes) => AppButton(
                label: _editingEntry != null ? 'Update Production' : 'Save Production',
                onPressed: () => _save(itemTypes, org.id, org.calendarType),
                isLoading: _isSaving,
                icon: Icons.save,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
