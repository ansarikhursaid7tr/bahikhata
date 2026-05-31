import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/staff/staff_list_screen.dart';
import 'screens/staff/staff_form_screen.dart';
import 'screens/item_types/item_type_list_screen.dart';
import 'screens/item_types/item_type_form_screen.dart';
import 'screens/rates/monthly_rate_screen.dart';
import 'screens/production_entries/production_list_screen.dart';
import 'screens/production_entries/add_production_screen.dart';
import 'screens/money_entries/money_list_screen.dart';
import 'screens/money_entries/add_money_entry_screen.dart';
import 'screens/money_entries/past_records_screen.dart';
import 'screens/quotations/quotation_list_screen.dart';
import 'screens/quotations/add_quotation_screen.dart';
import 'screens/reports/daily_report_screen.dart';
import 'screens/reports/monthly_report_screen.dart';
import 'screens/ledger/staff_ledger_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/users/manage_users_screen.dart';
import 'screens/users/add_user_screen.dart';

/// GoRouter configuration with auth-based redirect.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/staff',
        name: 'staffList',
        builder: (context, state) => const StaffListScreen(),
      ),
      GoRoute(
        path: '/staff/add',
        name: 'addStaff',
        builder: (context, state) => const StaffFormScreen(),
      ),
      GoRoute(
        path: '/staff/edit/:staffId',
        name: 'editStaff',
        builder: (context, state) => StaffFormScreen(
          staffId: state.pathParameters['staffId'],
        ),
      ),
      GoRoute(
        path: '/item-types',
        name: 'itemTypes',
        builder: (context, state) => const ItemTypeListScreen(),
      ),
      GoRoute(
        path: '/item-types/add',
        name: 'addItemType',
        builder: (context, state) => const ItemTypeFormScreen(),
      ),
      GoRoute(
        path: '/item-types/edit/:itemTypeId',
        name: 'editItemType',
        builder: (context, state) => ItemTypeFormScreen(
          itemTypeId: state.pathParameters['itemTypeId'],
        ),
      ),
      GoRoute(
        path: '/rates',
        name: 'rates',
        builder: (context, state) => const MonthlyRateScreen(),
      ),
      GoRoute(
        path: '/production',
        name: 'productionList',
        builder: (context, state) => const ProductionListScreen(),
      ),
      GoRoute(
        path: '/production/add',
        name: 'addProduction',
        builder: (context, state) => const AddProductionScreen(),
      ),
      GoRoute(
        path: '/production/edit/:id',
        name: 'editProduction',
        builder: (context, state) => AddProductionScreen(
          entryId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/money',
        name: 'moneyList',
        builder: (context, state) => const MoneyListScreen(),
      ),
      GoRoute(
        path: '/money/add',
        name: 'addMoney',
        builder: (context, state) => const AddMoneyEntryScreen(),
      ),
      GoRoute(
        path: '/money/edit/:id',
        name: 'editMoney',
        builder: (context, state) => AddMoneyEntryScreen(
          entryId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/past-records',
        name: 'pastRecords',
        builder: (context, state) => const PastRecordsScreen(),
      ),
      GoRoute(
        path: '/quotations',
        name: 'quotations',
        builder: (context, state) => const QuotationListScreen(),
      ),
      GoRoute(
        path: '/quotations/add',
        name: 'addQuotation',
        builder: (context, state) => const AddQuotationScreen(),
      ),
      GoRoute(
        path: '/quotations/edit/:id',
        name: 'editQuotation',
        builder: (context, state) => AddQuotationScreen(
          quotationId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/users',
        name: 'manageUsers',
        builder: (context, state) => const ManageUsersScreen(),
      ),
      GoRoute(
        path: '/users/add',
        name: 'addUser',
        builder: (context, state) => const AddUserScreen(),
      ),
      GoRoute(
        path: '/reports/daily',
        name: 'dailyReport',
        builder: (context, state) => const DailyReportScreen(),
      ),
      GoRoute(
        path: '/reports/monthly',
        name: 'monthlyReport',
        builder: (context, state) => const MonthlyReportScreen(),
      ),
      GoRoute(
        path: '/ledger',
        name: 'staffLedger',
        builder: (context, state) => StaffLedgerScreen(
          staffId: state.uri.queryParameters['staffId'],
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
