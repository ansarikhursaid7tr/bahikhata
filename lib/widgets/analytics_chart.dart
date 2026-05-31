import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/production_entry_model.dart';
import '../models/money_entry_model.dart';
import '../theme/app_theme.dart';
import '../utils/money_utils.dart';
import '../utils/date_utils.dart';

class AnalyticsChart extends StatelessWidget {
  final List<ProductionEntry> productionEntries;
  final List<MoneyEntry> moneyEntries;
  final String currency;
  final String calendarType;

  const AnalyticsChart({
    super.key,
    required this.productionEntries,
    required this.moneyEntries,
    required this.currency,
    this.calendarType = 'AD',
  });

  /// Gets the last 7 date strings based on the calendar type.
  List<String> _getLast7Days() {
    final todayStr = AppDateUtils.today(calendarType: calendarType);
    final parts = todayStr.split('-');
    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    int day = int.parse(parts[2]);

    final dates = <String>[];

    for (int i = 6; i >= 0; i--) {
      // Calculate the date i days ago
      int d = day - i;
      int m = month;
      int y = year;

      // Handle day underflow — go to previous month
      while (d < 1) {
        m -= 1;
        if (m < 1) {
          m = 12;
          y -= 1;
        }
        // Get days in the previous month
        d += _daysInMonth(y, m);
      }

      dates.add('$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}');
    }

    return dates;
  }

  int _daysInMonth(int year, int month) {
    if (year > 2050) {
      // BS calendar — approximate days per month
      // Nepali months typically have 29-32 days
      const bsDaysInMonth = [0, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31];
      if (month >= 1 && month <= 12) return bsDaysInMonth[month];
      return 30;
    } else {
      // AD calendar
      return DateUtils.getDaysInMonth(year, month);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last7Days = _getLast7Days();

    // Calculate totals per day
    final List<double> prodTotals = [];
    final List<double> moneyTotals = [];
    double maxVal = 0;

    for (var dateStr in last7Days) {
      final double prod = productionEntries
          .where((e) => e.date == dateStr)
          .fold(0.0, (sum, e) => sum + e.totalAmount);

      final double money = moneyEntries
          .where((e) => e.date == dateStr)
          .fold(0.0, (sum, e) => sum + e.amount);

      prodTotals.add(prod);
      moneyTotals.add(money);

      if (prod > maxVal) maxVal = prod;
      if (money > maxVal) maxVal = money;
    }

    // Add some padding to max Y
    final maxY = maxVal > 0 ? (maxVal * 1.2) : 1000.0;

    // Build short display labels from actual date strings
    final displayLabels = last7Days.map((d) => AppDateUtils.shortDate(d)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '7-Day Trend',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildLegendItem('Production', AppTheme.primary),
                const SizedBox(width: 16),
                _buildLegendItem('Payments', AppTheme.warning),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.blueGrey.shade800,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final isProd = rodIndex == 0;
                        return BarTooltipItem(
                          '${isProd ? "Prod: " : "Pay: "}${MoneyUtils.formatCurrencyCompact(rod.toY, currency)}',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= displayLabels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              displayLabels[index],
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 9,
                              ),
                            ),
                          );
                        },
                        reservedSize: 32,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == maxY) return const SizedBox.shrink();
                          return Text(
                            MoneyUtils.formatCurrencyCompact(value, currency),
                            style: const TextStyle(
                              color: AppTheme.textLight,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.dividerColor,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: prodTotals[index],
                          color: AppTheme.primary,
                          width: 12,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: moneyTotals[index],
                          color: AppTheme.warning,
                          width: 12,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
