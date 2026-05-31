import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';
import '../../models/enums.dart';
import '../../utils/snackbar_utils.dart';
import 'package:bahi_khata/widgets/app_scaffold.dart';

class ManageUsersScreen extends ConsumerWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(currentAppUserProvider).value;
    if (appUser == null) return const ShimmerLoadingList();

    final usersAsync = ref.watch(usersProvider(appUser.organizationId));

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/users/add'),
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
      body: usersAsync.when(
        loading: () => const ShimmerLoadingList(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (users) {
          if (users.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'No users found',
              subtitle: 'Add users to grant them access to this organization.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      user.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('@${user.username}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: user.role == UserRole.owner
                              ? AppTheme.primary.withValues(alpha: 0.1)
                              : user.role == UserRole.manager
                                  ? Colors.purple.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.role.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: user.role == UserRole.owner
                                ? AppTheme.primary
                                : user.role == UserRole.manager
                                    ? Colors.purple
                                    : Colors.orange,
                          ),
                        ),
                      ),
                      if (user.uid != appUser.uid && appUser.role == UserRole.owner) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete User?'),
                                content: const Text('Are you sure you want to delete this user? This will instantly revoke their access to the organization.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      minimumSize: const Size(120, 48),
                                    ),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              try {
                                await ref.read(firestoreServiceProvider).deleteUserDocument(appUser.organizationId, user.uid);
                                if (context.mounted) {
                                  AppSnackBar.showSuccess(context, 'User deleted successfully');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  AppSnackBar.showError(context, 'Failed to delete user: $e');
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
