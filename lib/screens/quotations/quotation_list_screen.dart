import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../utils/money_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../services/export_service.dart';
import '../../models/quotation_model.dart';

import '../../utils/snackbar_utils.dart';
import 'package:bahi_khata/widgets/app_scaffold.dart';
class QuotationListScreen extends ConsumerWidget {
  const QuotationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(currentAppUserProvider).value;
    final org = ref.watch(currentOrganizationProvider).value;

    if (appUser == null || org == null) return const AppScaffold(body: ShimmerLoadingList());

    final quotationsAsync = ref.watch(quotationsProvider(org.id));

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Quotations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/quotations/add'),
          ),
        ],
      ),
      body: quotationsAsync.when(
        data: (quotations) {
          if (quotations.isEmpty) {
            return EmptyState(
              icon: Icons.request_quote,
              title: 'No quotations found',
              subtitle: 'Create a new quotation for your customers',
              actionLabel: 'Create Quotation',
              onAction: () => context.push('/quotations/add'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: quotations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final quotation = quotations[index];
              return _QuotationCard(
                quotation: quotation,
                orgId: org.id,
                currency: org.currency,
              );
            },
          );
        },
        loading: () => const ShimmerLoadingList(),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/quotations/add'),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _QuotationCard extends ConsumerWidget {
  final Quotation quotation;
  final String orgId;
  final String currency;

  const _QuotationCard({
    required this.quotation,
    required this.orgId,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quotation.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => context.push('/quotations/edit/${quotation.id}'),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    try {
                      final org = ref.read(currentOrganizationProvider).value;
                      if (org == null) return;
                      await ExportService().exportQuotationPdf(
                        quotation: quotation,
                        organizationName: org.name,
                        address: org.address ?? '',
                        contact: org.contact ?? '',
                        logoBase64: org.logoBase64,
                        currency: org.currency,
                      );
                    } catch (e) {
                      AppSnackBar.showError(context, 'Failed to export quotation');
}
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('PDF'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Quotation'),
                        content: const Text('Are you sure you want to delete this quotation?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(firestoreServiceProvider).deleteQuotation(orgId, quotation.id);
                    }
                  },
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
