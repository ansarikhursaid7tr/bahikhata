import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import 'package:bahi_khata/widgets/app_scaffold.dart';

class ItemTypeListScreen extends ConsumerWidget {
  const ItemTypeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(currentAppUserProvider).value;
    if (appUser == null) return const ShimmerLoadingList();

    final itemsAsync =
        ref.watch(allItemTypeListProvider(appUser.organizationId));

    return AppScaffold(
      appBar: AppBar(title: const Text('Item Types')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/item-types/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Item Type'),
      ),
      body: itemsAsync.when(
        loading: () => const ShimmerLoadingList(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.category_outlined,
              title: 'No Item Types Yet',
              subtitle: 'Add item types like Coat, Pant, Shirt, etc.',
              actionLabel: 'Add Item Type',
              onAction: () => context.push('/item-types/add'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: item.active
                        ? AppTheme.accent.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.category,
                      color: item.active ? AppTheme.accent : Colors.grey,
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: item.active ? null : Colors.grey,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      if (item.category != null) ...[
                        Text(item.category!),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.active
                              ? AppTheme.success.withValues(alpha: 0.1)
                              : AppTheme.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.active ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: item.active
                                ? AppTheme.success
                                : AppTheme.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/item-types/edit/${item.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
