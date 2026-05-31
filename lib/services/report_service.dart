import '../models/production_entry_model.dart';
import '../models/money_entry_model.dart';
import '../models/enums.dart';
import '../utils/money_utils.dart';
import 'firestore_service.dart';

/// Report data models.
class DailyReportData {
  final String date;
  final List<ProductionEntry> productionEntries;
  final List<MoneyEntry> moneyEntries;
  final double totalProduction;
  final int totalItems;
  final double totalPayments;
  final double netPayable;

  DailyReportData({
    required this.date,
    required this.productionEntries,
    required this.moneyEntries,
    required this.totalProduction,
    required this.totalItems,
    required this.totalPayments,
    required this.netPayable,
  });
}

class MonthlyReportData {
  final String month;
  final List<StaffMonthlyData> staffData;
  final double totalGrossProduction;
  final double totalPayments;
  final double totalPayable;

  MonthlyReportData({
    required this.month,
    required this.staffData,
    required this.totalGrossProduction,
    required this.totalPayments,
    required this.totalPayable,
  });
}

class StaffMonthlyData {
  final String staffId;
  final String staffName;
  final Map<String, ItemBreakdown> itemBreakdown; // itemTypeName → breakdown
  final double grossProduction;
  final double totalAdvance;
  final double totalPartialPayment;
  final double totalFinalPayment;
  final double totalDeduction;
  final double totalBonus;
  final double finalPayable;
  final int totalItems;

  StaffMonthlyData({
    required this.staffId,
    required this.staffName,
    required this.itemBreakdown,
    required this.grossProduction,
    required this.totalAdvance,
    required this.totalPartialPayment,
    required this.totalFinalPayment,
    required this.totalDeduction,
    required this.totalBonus,
    required this.finalPayable,
    required this.totalItems,
  });
}

class ItemBreakdown {
  final String itemTypeName;
  final int totalQuantity;
  final double rate;
  final double totalAmount;

  ItemBreakdown({
    required this.itemTypeName,
    required this.totalQuantity,
    required this.rate,
    required this.totalAmount,
  });
}

class LedgerEntry {
  final String date;
  final String description;
  final double earned;
  final double paid;
  final double balance;

  LedgerEntry({
    required this.date,
    required this.description,
    required this.earned,
    required this.paid,
    required this.balance,
  });
}

/// Service for generating reports.
class ReportService {
  final FirestoreService _firestoreService;

  ReportService(this._firestoreService);

  /// Generate daily report.
  Future<DailyReportData> getDailyReport(
    String orgId,
    String date, {
    String? staffId,
  }) async {
    final productions = await _firestoreService.getProductionEntries(
      orgId,
      date: date,
      staffId: staffId,
    );
    final moneyEntries = await _firestoreService.getMoneyEntries(
      orgId,
      date: date,
      staffId: staffId,
    );

    double totalProduction = 0;
    int totalItems = 0;
    for (final entry in productions) {
      totalProduction += entry.totalAmount;
      totalItems += entry.totalQuantity;
    }

    double totalPayments = 0;
    for (final entry in moneyEntries) {
      if (entry.effect == MoneyEffect.decreasePayable) {
        totalPayments += entry.amount;
      }
    }

    return DailyReportData(
      date: date,
      productionEntries: productions,
      moneyEntries: moneyEntries,
      totalProduction: totalProduction,
      totalItems: totalItems,
      totalPayments: totalPayments,
      netPayable: totalProduction - totalPayments,
    );
  }

  /// Generate monthly report.
  Future<MonthlyReportData> getMonthlyReport(
    String orgId,
    String month, {
    String? staffId,
  }) async {
    final productions = await _firestoreService.getProductionEntries(
      orgId,
      month: month,
      staffId: staffId,
    );
    final moneyEntries = await _firestoreService.getMoneyEntries(
      orgId,
      month: month,
      staffId: staffId,
    );

    // Group by staff
    final staffProductions = <String, List<ProductionEntry>>{};
    final staffMoney = <String, List<MoneyEntry>>{};
    final staffNames = <String, String>{};

    for (final entry in productions) {
      staffProductions.putIfAbsent(entry.staffId, () => []).add(entry);
      staffNames[entry.staffId] = entry.staffName;
    }
    for (final entry in moneyEntries) {
      staffMoney.putIfAbsent(entry.staffId, () => []).add(entry);
      staffNames[entry.staffId] = entry.staffName;
    }

    final allStaffIds = {...staffProductions.keys, ...staffMoney.keys};
    final staffDataList = <StaffMonthlyData>[];

    double totalGross = 0;
    double totalPayments = 0;
    double totalPayable = 0;

    for (final sid in allStaffIds) {
      final data = _calculateStaffMonthly(
        sid,
        staffNames[sid] ?? 'Unknown',
        staffProductions[sid] ?? [],
        staffMoney[sid] ?? [],
      );
      staffDataList.add(data);
      totalGross += data.grossProduction;
      totalPayments += data.totalAdvance +
          data.totalPartialPayment +
          data.totalFinalPayment +
          data.totalDeduction;
      totalPayable += data.finalPayable;
    }

    return MonthlyReportData(
      month: month,
      staffData: staffDataList,
      totalGrossProduction: totalGross,
      totalPayments: totalPayments,
      totalPayable: totalPayable,
    );
  }

  /// Generate staff ledger entries.
  Future<List<LedgerEntry>> getStaffLedger(
    String orgId,
    String staffId, {
    String? month,
  }) async {
    final productions = await _firestoreService.getProductionEntries(
      orgId,
      month: month,
      staffId: staffId,
    );
    final moneyEntries = await _firestoreService.getMoneyEntries(
      orgId,
      month: month,
      staffId: staffId,
    );

    // Combine and sort by date
    final entries = <LedgerEntry>[];
    double runningBalance = 0;

    // Create combined list with date for sorting
    final combined = <MapEntry<String, dynamic>>[];
    for (final p in productions) {
      combined.add(MapEntry(p.date, p));
    }
    for (final m in moneyEntries) {
      combined.add(MapEntry(m.date, m));
    }
    combined.sort((a, b) => a.key.compareTo(b.key));

    for (final item in combined) {
      if (item.value is ProductionEntry) {
        final p = item.value as ProductionEntry;
        final desc = p.items
            .where((i) => i.quantity > 0)
            .map((i) => '${i.itemTypeName} ×${i.quantity}')
            .join(', ');
        runningBalance += p.totalAmount;
        entries.add(LedgerEntry(
          date: p.date,
          description: desc.isEmpty ? 'Production' : desc,
          earned: p.totalAmount,
          paid: 0,
          balance: runningBalance,
        ));
      } else if (item.value is MoneyEntry) {
        final m = item.value as MoneyEntry;
        final paid =
            m.effect == MoneyEffect.decreasePayable ? m.amount : 0.0;
        final earned =
            m.effect == MoneyEffect.increasePayable ? m.amount : 0.0;
        if (m.effect == MoneyEffect.decreasePayable) {
          runningBalance -= m.amount;
        } else {
          runningBalance += m.amount;
        }
        entries.add(LedgerEntry(
          date: m.date,
          description: '${m.type.displayName}${m.notes != null ? " - ${m.notes}" : ""}',
          earned: earned,
          paid: paid,
          balance: runningBalance,
        ));
      }
    }

    return entries;
  }

  StaffMonthlyData _calculateStaffMonthly(
    String staffId,
    String staffName,
    List<ProductionEntry> productions,
    List<MoneyEntry> moneyEntries,
  ) {
    // Item breakdown
    final itemMap = <String, ItemBreakdown>{};
    double grossProduction = 0;
    int totalItems = 0;

    for (final entry in productions) {
      for (final item in entry.items) {
        if (item.quantity > 0) {
          final existing = itemMap[item.itemTypeName];
          if (existing != null) {
            itemMap[item.itemTypeName] = ItemBreakdown(
              itemTypeName: item.itemTypeName,
              totalQuantity: existing.totalQuantity + item.quantity,
              rate: item.rateSnapshot,
              totalAmount: existing.totalAmount + item.lineTotal,
            );
          } else {
            itemMap[item.itemTypeName] = ItemBreakdown(
              itemTypeName: item.itemTypeName,
              totalQuantity: item.quantity,
              rate: item.rateSnapshot,
              totalAmount: item.lineTotal,
            );
          }
          totalItems += item.quantity;
        }
      }
      grossProduction += entry.totalAmount;
    }

    // Money breakdown
    double totalAdvance = 0;
    double totalPartialPayment = 0;
    double totalFinalPayment = 0;
    double totalDeduction = 0;
    double totalBonus = 0;

    for (final entry in moneyEntries) {
      switch (entry.type) {
        case MoneyEntryType.advance:
          totalAdvance += entry.amount;
          break;
        case MoneyEntryType.partialPayment:
          totalPartialPayment += entry.amount;
          break;
        case MoneyEntryType.finalPayment:
          totalFinalPayment += entry.amount;
          break;
        case MoneyEntryType.deduction:
          totalDeduction += entry.amount;
          break;
        case MoneyEntryType.bonus:
          totalBonus += entry.amount;
          break;
        case MoneyEntryType.other:
          if (entry.effect == MoneyEffect.decreasePayable) {
            totalDeduction += entry.amount;
          } else {
            totalBonus += entry.amount;
          }
          break;
      }
    }

    final finalPayable = MoneyUtils.calculateFinalPayable(
      grossProduction: grossProduction,
      totalBonus: totalBonus,
      totalAdvance: totalAdvance,
      totalPartialPayment: totalPartialPayment,
      totalFinalPayment: totalFinalPayment,
      totalDeduction: totalDeduction,
    );

    return StaffMonthlyData(
      staffId: staffId,
      staffName: staffName,
      itemBreakdown: itemMap,
      grossProduction: grossProduction,
      totalAdvance: totalAdvance,
      totalPartialPayment: totalPartialPayment,
      totalFinalPayment: totalFinalPayment,
      totalDeduction: totalDeduction,
      totalBonus: totalBonus,
      finalPayable: finalPayable,
      totalItems: totalItems,
    );
  }
}
