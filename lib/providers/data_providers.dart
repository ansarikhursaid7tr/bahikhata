import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/staff_model.dart';
import '../models/item_type_model.dart';
import '../models/monthly_rate_model.dart';
import '../models/production_entry_model.dart';
import '../models/money_entry_model.dart';
import '../models/quotation_model.dart';
import '../models/quotation_model.dart';
import '../models/app_user_model.dart';
import '../services/firestore_service.dart';
import '../services/report_service.dart';
import 'auth_provider.dart';

/// Streams active staff for the current organization.
final staffListProvider =
    StreamProvider.family<List<Staff>, String>((ref, orgId) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamStaff(orgId);
});

/// Streams all app users for the organization.
final usersProvider =
    StreamProvider.family<List<AppUser>, String>((ref, orgId) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamUsers(orgId);
});

/// Streams all staff (including inactive) for the current organization.
final allStaffListProvider =
    StreamProvider.family<List<Staff>, String>((ref, orgId) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamStaff(orgId, activeOnly: false);
});

/// Streams active item types.
final itemTypeListProvider =
    StreamProvider.family<List<ItemType>, String>((ref, orgId) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamItemTypes(orgId);
});

/// Streams all item types (including inactive).
final allItemTypeListProvider =
    StreamProvider.family<List<ItemType>, String>((ref, orgId) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamItemTypes(orgId, activeOnly: false);
});

/// Composite key for month-based queries.
class MonthQuery {
  final String orgId;
  final String month;
  MonthQuery(this.orgId, this.month);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthQuery && orgId == other.orgId && month == other.month;

  @override
  int get hashCode => Object.hash(orgId, month);
}

/// Streams rates for a specific month.
final monthlyRatesProvider =
    StreamProvider.family<List<MonthlyRate>, MonthQuery>((ref, query) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamRatesForMonth(query.orgId, query.month);
});

/// Composite key for date + optional staff queries.
class DateStaffQuery {
  final String orgId;
  final String? date;
  final String? month;
  final String? staffId;
  DateStaffQuery(this.orgId, {this.date, this.month, this.staffId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateStaffQuery &&
          orgId == other.orgId &&
          date == other.date &&
          month == other.month &&
          staffId == other.staffId;

  @override
  int get hashCode => Object.hash(orgId, date, month, staffId);
}

/// Streams production entries.
final productionEntriesProvider =
    StreamProvider.family<List<ProductionEntry>, DateStaffQuery>((ref, query) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamProductionEntries(
    query.orgId,
    date: query.date,
    month: query.month,
    staffId: query.staffId,
  );
});

/// Streams money entries.
final moneyEntriesProvider =
    StreamProvider.family<List<MoneyEntry>, DateStaffQuery>((ref, query) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamMoneyEntries(
    query.orgId,
    date: query.date,
    month: query.month,
    staffId: query.staffId,
  );
});

final quotationsProvider = StreamProvider.family<List<Quotation>, String>((ref, orgId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamQuotations(orgId);
});

/// Report service provider.
final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService(ref.read(firestoreServiceProvider));
});

/// Monthly report provider.
final monthlyReportProvider =
    FutureProvider.family<MonthlyReportData, MonthQuery>((ref, query) async {
  final reportService = ref.read(reportServiceProvider);
  return reportService.getMonthlyReport(query.orgId, query.month);
});

/// Daily report provider.
final dailyReportProvider =
    FutureProvider.family<DailyReportData, DateStaffQuery>((ref, query) async {
  final reportService = ref.read(reportServiceProvider);
  return reportService.getDailyReport(query.orgId, query.date!,
      staffId: query.staffId);
});
