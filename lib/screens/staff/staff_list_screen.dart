import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../models/staff_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';
import 'package:bahi_khata/widgets/app_scaffold.dart';

class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(currentAppUserProvider).value;
    if (appUser == null) return const ShimmerLoadingList();

    final staffAsync = ref.watch(allStaffListProvider(appUser.organizationId));

    return AppScaffold(
      appBar: AppBar(title: const Text('Staff Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/staff/add'),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
      body: staffAsync.when(
        loading: () => const ShimmerLoadingList(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (staffList) {
          if (staffList.isEmpty) {
            return EmptyState(
              icon: Icons.people_outline,
              title: 'No Staff Yet',
              subtitle: 'Add your first staff member',
              actionLabel: 'Add Staff',
              onAction: () => context.push('/staff/add'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: staffList.length,
            itemBuilder: (context, index) {
              final staff = staffList[index];
              return _StaffCard(staff: staff);
            },
          );
        },
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final Staff staff;
  const _StaffCard({required this.staff});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: staff.active
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          child: Icon(
            Icons.person,
            color: staff.active ? AppTheme.primary : Colors.grey,
          ),
        ),
        title: Text(
          staff.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: staff.active ? null : Colors.grey,
          ),
        ),
        subtitle: Row(
          children: [
            Text(staff.staffType.displayName),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: staff.active
                    ? AppTheme.success.withValues(alpha: 0.1)
                    : AppTheme.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                staff.active ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: staff.active ? AppTheme.success : AppTheme.danger,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/staff/edit/${staff.id}'),
      ),
    );
  }
}
