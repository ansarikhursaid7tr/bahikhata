import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../models/monthly_rate_model.dart';
import '../../models/item_type_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/app_button.dart';

import '../../utils/snackbar_utils.dart';
import 'package:bahi_khata/widgets/app_scaffold.dart';
class MonthlyRateScreen extends ConsumerStatefulWidget {
  const MonthlyRateScreen({super.key});

  @override
  ConsumerState<MonthlyRateScreen> createState() => _MonthlyRateScreenState();
}

class _MonthlyRateScreenState extends ConsumerState<MonthlyRateScreen> {
  String _selectedMonth = AppDateUtils.currentMonth();
  final Map<String, TextEditingController> _rateControllers = {};
  bool _isSaving = false;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (final c in _rateControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveRates() async {
    final appUser = ref.read(currentAppUserProvider).value;
    if (appUser == null) return;

    setState(() => _isSaving = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final rates = <MonthlyRate>[];
      final now = DateTime.now();

      for (final entry in _rateControllers.entries) {
        final itemTypeId = entry.key;
        final rateStr = entry.value.text.trim();
        if (rateStr.isEmpty) continue;

        final rate = double.tryParse(rateStr);
        if (rate == null || rate < 0) continue;

        // Look up item type name
        final itemTypes = ref
            .read(itemTypeListProvider(appUser.organizationId))
            .value ?? [];
        final itemType = itemTypes.firstWhere(
          (i) => i.id == itemTypeId,
          orElse: () => ItemType(
              id: itemTypeId, name: 'Unknown', createdAt: now, updatedAt: now),
        );

        rates.add(MonthlyRate(
          id: MonthlyRate.generateId(_selectedMonth, itemTypeId),
          month: _selectedMonth,
          itemTypeId: itemTypeId,
          itemTypeName: itemType.name,
          rate: rate,
          createdBy: appUser.uid,
          updatedBy: appUser.uid,
          createdAt: now,
          updatedAt: now,
        ));
      }

      if (rates.isNotEmpty) {
        await firestoreService.setRatesBatch(appUser.organizationId, rates);
      }

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Rates saved successfully');
}
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error: $e');
}
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _copyFromPreviousMonth() async {
    final appUser = ref.read(currentAppUserProvider).value;
    if (appUser == null) return;

    final prevMonth = AppDateUtils.previousMonth(_selectedMonth);
    final firestoreService = ref.read(firestoreServiceProvider);
    final prevRates = await firestoreService.getRatesForMonth(
        appUser.organizationId, prevMonth);

    if (prevRates.isEmpty) {
      if (mounted) {
        AppSnackBar.showSuccess(context, 'No rates found for ${AppDateUtils.displayMonth(prevMonth)}');
      }
      return;
    }

    setState(() {
      for (final rate in prevRates) {
        _rateControllers[rate.itemTypeId]?.text = rate.rate.toString();
      }
    });

    if (mounted) {
      AppSnackBar.showSuccess(context, 'Copied rates from ${AppDateUtils.displayMonth(prevMonth)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUser = ref.watch(currentAppUserProvider).value;
    final org = ref.watch(currentOrganizationProvider).value;
    if (appUser == null || org == null) return const AppScaffold(body: LoadingView());

    if (!_isInit) {
      _selectedMonth = AppDateUtils.currentMonth(calendarType: org.calendarType);
      _isInit = true;
    }

    final orgId = appUser.organizationId;
    final itemTypesAsync = ref.watch(itemTypeListProvider(orgId));
    final ratesAsync = ref.watch(
        monthlyRatesProvider(MonthQuery(orgId, _selectedMonth)));

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Monthly Rates'),
        actions: [
          TextButton.icon(
            onPressed: _copyFromPreviousMonth,
            icon: const Icon(Icons.content_copy, color: Colors.white, size: 18),
            label: const Text('Copy Prev',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Picker
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryDark.withValues(alpha: 0.05),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedMonth =
                          AppDateUtils.previousMonth(_selectedMonth);
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    AppDateUtils.displayMonth(_selectedMonth),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    final parts = _selectedMonth.split('-');
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
                  },
                ),
              ],
            ),
          ),
          // Rate List
          Expanded(
            child: itemTypesAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (itemTypes) {
                // Initialize controllers for each item type
                final existingRates = <String, double>{};
                ratesAsync.whenData((rates) {
                  for (final r in rates) {
                    existingRates[r.itemTypeId] = r.rate;
                  }
                });

                for (final item in itemTypes) {
                  if (!_rateControllers.containsKey(item.id)) {
                    _rateControllers[item.id] = TextEditingController();
                  }
                  if (existingRates.containsKey(item.id)) {
                    final ctrl = _rateControllers[item.id]!;
                    if (ctrl.text.isEmpty ||
                        double.tryParse(ctrl.text) !=
                            existingRates[item.id]) {
                      ctrl.text = existingRates[item.id].toString();
                    }
                  }
                }

                if (itemTypes.isEmpty) {
                  return const Center(
                    child: Text('No item types. Add some first.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: itemTypes.length,
                  itemBuilder: (context, index) {
                    final item = itemTypes[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (item.category != null)
                                    Text(
                                      item.category!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _rateControllers[item.id],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: '0',
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  prefixText: ref
                                          .watch(currentOrganizationProvider)
                                          .value
                                          ?.currency ??
                                      '\$ ',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Save Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(
              label: 'Save Rates',
              onPressed: _saveRates,
              isLoading: _isSaving,
              icon: Icons.save,
            ),
          ),
        ],
      ),
    );
  }
}
