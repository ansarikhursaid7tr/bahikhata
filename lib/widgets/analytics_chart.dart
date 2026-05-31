import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/production_entry_model.dart';
import '../models/money_entry_model.dart';
import '../theme/app_theme.dart';
import '../utils/money_utils.dart';

class AnalyticsChart extends StatelessWidget {
  final List<ProductionEntry> productionEntries;
  final List<MoneyEntry> moneyEntries;
  final String currency;

  const AnalyticsChart({
    super.key,
    required this.productionEntries,
    required this.moneyEntries,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    // Get last 7 days
    final now = DateTime.now();
    final List<DateTime> last7Days = List.generate(7, (index) {
      return now.subtract(Duration(days: 6 - index));
    });

    final dateFormat = DateFormat('yyyy-MM-dd');
    final displayFormat = DateFormat('E'); // Mon, Tue, etc.

    // Calculate totals per day
    final List<double> prodTotals = [];
    final List<double> moneyTotals = [];
    double maxVal = 0;

    for (var date in last7Days) {
      final dateStr = dateFormat.format(date);
      
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
                          if (index < 0 || index >= last7Days.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              displayFormat.format(last7Days[index]),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                        reservedSize: 28,
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
