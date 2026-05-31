import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../utils/money_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../utils/snackbar_utils.dart';
import 'package:bahi_khata/widgets/app_scaffold.dart';

class MoneyListScreen extends ConsumerStatefulWidget {
  const MoneyListScreen({super.key});

  @override
  ConsumerState<MoneyListScreen> createState() => _MoneyListScreenState();
}

class _MoneyListScreenState extends ConsumerState<MoneyListScreen> {
  String? _selectedMonth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final org = ref.read(currentOrganizationProvider).value;
      if (org != null) {
        setState(() {
          _selectedMonth = AppDateUtils.currentMonth(calendarType: org.calendarType);
        });
      }
    });
  }

  Future<void> _deleteEntry(String entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('Are you sure you want to delete this payment entry? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final appUser = ref.read(currentAppUserProvider).value!;
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.deleteMoneyEntry(appUser.organizationId, entryId);
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Entry deleted');
}
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to delete entry');
}
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUser = ref.watch(currentAppUserProvider).value;
    final org = ref.watch(currentOrganizationProvider).value;

    if (appUser == null || org == null || _selectedMonth == null) {
      return const AppScaffold(body: ShimmerLoadingList());
    }

    final query = DateStaffQuery(appUser.organizationId, month: _selectedMonth);
    final entriesAsync = ref.watch(moneyEntriesProvider(query));

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Payment Entries'),
        actions: [
          if (appUser.role.canAddEntries)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/money/add'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Month picker
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    final parts = _selectedMonth!.split('-');
                    int y = int.parse(parts[0]);
                    int m = int.parse(parts[1]);
                    m--;
                    if (m < 1) {
                      m = 12;
                      y--;
                    }
                    setState(() {
                      _selectedMonth = '$y-${m.toString().padLeft(2, '0')}';
                    });
                  },
                ),
                Text(
                  AppDateUtils.displayMonth(_selectedMonth!),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: entriesAsync.when(
              loading: () => const ShimmerLoadingList(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (entries) {
                if (entries.isEmpty) {
                  return const EmptyState(
                    icon: Icons.payments_outlined,
                    title: 'No payment entries',
                    subtitle: 'No payment entries found for this month.',
                  );
                }

                return ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = entries[index];

                    return ListTile(
                      title: Text('${entry.staffName} - ${AppDateUtils.displayDate(entry.date)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.type.displayName, style: const TextStyle(color: Colors.black87)),
                          if (entry.notes != null && entry.notes!.isNotEmpty)
                            Text('Notes: ${entry.notes}', style: const TextStyle(fontStyle: FontStyle.italic)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(MoneyUtils.formatCurrencyCompact(entry.amount, org.currency),
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warning)),
                          if (appUser.role.canEditEntries) ...[
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                              onPressed: () => context.push('/money/edit/${entry.id}'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () => _deleteEntry(entry.id),
                            ),
                          ],
                        ],
                      ),
                      isThreeLine: entry.notes != null && entry.notes!.isNotEmpty,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
