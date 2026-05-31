import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/data_providers.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../utils/money_utils.dart';
import '../widgets/summary_card.dart';
import '../widgets/analytics_chart.dart';
import '../widgets/sync_indicator.dart';
import '../widgets/loading_view.dart';
import '../models/enums.dart';

/// Dashboard screen with summary cards and quick actions.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUserAsync = ref.watch(currentAppUserProvider);
    final orgAsync = ref.watch(currentOrganizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(Constants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: appUserAsync.when(
        loading: () => const LoadingView(message: 'Loading...'),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (appUser) {
          if (appUser == null) {
            return const Center(
              child: Text('User not found. Please contact admin.'),
            );
          }

          final orgId = appUser.organizationId;
          final calendarType = orgAsync.value?.calendarType ?? 'AD';
          final today = AppDateUtils.today(calendarType: calendarType);
          final currentMonth = AppDateUtils.currentMonth(calendarType: calendarType);

          // For staff role, show only their own data
          final staffFilter =
              appUser.role == UserRole.staff ? appUser.staffId : null;

          return Column(
            children: [
              const SyncIndicator(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(currentAppUserProvider);
                  },
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome
                        Text(
                          'Welcome, ${appUser.name}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          '${appUser.role.displayName} • ${AppDateUtils.displayDate(today)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),

                        // Summary Cards
                        _DashboardSummary(
                          orgId: orgId,
                          today: today,
                          currentMonth: currentMonth,
                          staffId: staffFilter,
                          currency: orgAsync.value?.currency ?? '\$',
                        ),

                        // Analytics Chart (Owner Only)
                        if (appUser.role == UserRole.owner) ...[
                          const SizedBox(height: 24),
                          _DashboardAnalytics(
                            orgId: orgId,
                            currentMonth: currentMonth,
                            currency: orgAsync.value?.currency ?? '\$',
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Quick Actions
                        if (appUser.role.canAddEntries) ...[
                          Text(
                            'Quick Actions',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          _QuickActionsGrid(role: appUser.role),
                        ],

                        // Navigation Section
                        const SizedBox(height: 24),
                        Text(
                          'Navigation',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                            _NavigationGrid(role: appUser.role),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardSummary extends ConsumerWidget {
  final String orgId;
  final String today;
  final String currentMonth;
  final String? staffId;
  final String currency;

  const _DashboardSummary({
    required this.orgId,
    required this.today,
    required this.currentMonth,
    this.staffId,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Today's production
    final todayProdQuery = DateStaffQuery(orgId,
        date: today, staffId: staffId);
    final todayProd = ref.watch(productionEntriesProvider(todayProdQuery));

    // Today's money
    final todayMoneyQuery = DateStaffQuery(orgId,
        date: today, staffId: staffId);
    final todayMoney = ref.watch(moneyEntriesProvider(todayMoneyQuery));

    // Monthly production
    final monthProdQuery = DateStaffQuery(orgId,
        month: currentMonth, staffId: staffId);
    final monthProd = ref.watch(productionEntriesProvider(monthProdQuery));

    // Monthly money
    final monthMoneyQuery = DateStaffQuery(orgId,
        month: currentMonth, staffId: staffId);
    final monthMoney = ref.watch(moneyEntriesProvider(monthMoneyQuery));

    final isLoadingInitial = (todayProd.isLoading && !todayProd.hasValue) ||
                             (todayMoney.isLoading && !todayMoney.hasValue) ||
                             (monthProd.isLoading && !monthProd.hasValue) ||
                             (monthMoney.isLoading && !monthMoney.hasValue);

    if (isLoadingInitial) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(),
      );
    }

    // Calculate today's totals
    double todayProduction = 0;
    int todayItems = 0;
    double todayPayments = 0;
    todayProd.whenData((entries) {
      for (final e in entries) {
        todayProduction += e.totalAmount;
        todayItems += e.totalQuantity;
      }
    });
    todayMoney.whenData((entries) {
      for (final e in entries) {
        if (e.effect == MoneyEffect.decreasePayable) {
          todayPayments += e.amount;
        }
      }
    });

    // Calculate monthly totals
    double monthProduction = 0;
    double monthPayments = 0;
    double monthBonus = 0;
    monthProd.whenData((entries) {
      for (final e in entries) {
        monthProduction += e.totalAmount;
      }
    });
    monthMoney.whenData((entries) {
      for (final e in entries) {
        if (e.effect == MoneyEffect.decreasePayable) {
          monthPayments += e.amount;
        } else {
          monthBonus += e.amount;
        }
      }
    });

    final monthRemaining = monthProduction + monthBonus - monthPayments;

    return Column(
      children: [
        // Today row
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: "Today's Production",
                value: MoneyUtils.formatCurrencyCompact(todayProduction, currency),
                subtitle: '$todayItems items',
                icon: Icons.trending_up,
                gradient: AppTheme.primaryGradient,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                title: "Today's Payments",
                value: MoneyUtils.formatCurrencyCompact(todayPayments, currency),
                icon: Icons.payments_outlined,
                gradient: AppTheme.warningGradient,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Month row
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Month Production',
                value: MoneyUtils.formatCurrencyCompact(monthProduction, currency),
                subtitle: AppDateUtils.displayMonth(currentMonth),
                icon: Icons.calendar_month,
                gradient: AppTheme.accentGradient,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                title: 'Month Remaining',
                value: MoneyUtils.formatCurrencyCompact(monthRemaining, currency),
                subtitle: 'Payable',
                icon: Icons.account_balance_wallet,
                gradient: monthRemaining > 0
                    ? AppTheme.dangerGradient
                    : AppTheme.primaryGradient,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final UserRole role;
  const _QuickActionsGrid({required this.role});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickActionButton(
          icon: Icons.add_chart,
          label: 'Add\nProduction',
          gradient: AppTheme.primaryGradient,
          onTap: () => context.push('/production/add'),
        ),
        const SizedBox(width: 12),
        _QuickActionButton(
          icon: Icons.payments,
          label: 'Add\nPayment',
          gradient: AppTheme.accentGradient,
          onTap: () => context.push('/money/add'),
        ),
        if (role.canManageRates) ...[
          const SizedBox(width: 12),
          _QuickActionButton(
            icon: Icons.price_change,
            label: 'Manage\nRates',
            gradient: AppTheme.warningGradient,
            onTap: () => context.push('/rates'),
          ),
        ],
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationGrid extends StatelessWidget {
  final UserRole role;
  const _NavigationGrid({required this.role});

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      _NavItem(Icons.assessment, 'Daily Report', '/reports/daily'),
      _NavItem(Icons.bar_chart, 'Monthly Report', '/reports/monthly'),
      _NavItem(Icons.receipt_long, 'Staff Ledger', '/ledger'),
      if (role.canViewAllData)
        _NavItem(Icons.list_alt, 'Production Entries', '/production'),
      if (role.canViewAllData)
        _NavItem(Icons.payments_outlined, 'Payment Entries', '/money'),
      if (role.canManageStaff)
        _NavItem(Icons.people, 'Staff', '/staff'),
      if (role.canManageStaff)
        _NavItem(Icons.category, 'Item Types', '/item-types'),
      if (role.canViewAllData)
        _NavItem(Icons.history, 'Past Records', '/past-records'),
      if (role.canViewAllData)
        _NavItem(Icons.request_quote, 'Quotations', '/quotations'),
      if (role == UserRole.owner)
        _NavItem(Icons.manage_accounts, 'Manage Users', '/users'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => context.push(item.route),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  _NavItem(this.icon, this.label, this.route);
}

class _DashboardAnalytics extends ConsumerWidget {
  final String orgId;
  final String currentMonth;
  final String currency;

  const _DashboardAnalytics({
    required this.orgId,
    required this.currentMonth,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch production entries for the month
    final monthProdQuery = DateStaffQuery(orgId, month: currentMonth);
    final monthProdAsync = ref.watch(productionEntriesProvider(monthProdQuery));

    // Fetch money entries for the month
    final monthMoneyQuery = DateStaffQuery(orgId, month: currentMonth);
    final monthMoneyAsync = ref.watch(moneyEntriesProvider(monthMoneyQuery));

    if (monthProdAsync.isLoading || monthMoneyAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final prodEntries = monthProdAsync.value ?? [];
    final moneyEntries = monthMoneyAsync.value ?? [];

    return AnalyticsChart(
      productionEntries: prodEntries,
      moneyEntries: moneyEntries,
      currency: currency,
    );
  }
}

