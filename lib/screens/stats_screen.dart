import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/finance_provider.dart';
import '../services/export_service.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final expenseTransactions = provider.transactions
        .where((t) => t.isExpense)
        .toList();

    // Group expenses by category
    final Map<int, double> categoryTotals = {};
    for (var t in expenseTransactions) {
      categoryTotals[t.categoryId] =
          (categoryTotals[t.categoryId] ?? 0) + t.amount;
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'overview'.tr(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      onPressed: () => ExportService.exportToPdf(provider),
                      tooltip: 'export_pdf'.tr(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.table_chart, color: Colors.green),
                      onPressed: () => ExportService.exportToExcel(provider),
                      tooltip: 'export_excel'.tr(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildBarChart(provider, context),
            const SizedBox(height: 32),
            if (categoryTotals.isNotEmpty) ...[
              Text(
                'expense_distribution'.tr(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: categoryTotals.entries.map((entry) {
                      final cat = provider.categories.firstWhere(
                        (c) => c.id == entry.key,
                      );
                      return PieChartSectionData(
                        color: _getColor(cat.color),
                        value: entry.value,
                        title: '${entry.value.toStringAsFixed(0)}DH',
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'details_by_category'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...categoryTotals.entries.map((entry) {
                final cat = provider.categories.firstWhere(
                  (c) => c.id == entry.key,
                );
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getColor(cat.color).withOpacity(0.2),
                      child: Icon(Icons.category, color: _getColor(cat.color), size: 20),
                    ),
                    title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text(
                      '${entry.value.toStringAsFixed(2)} DH',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                );
              }),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text('no_expense_stats'.tr(), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(FinanceProvider provider, BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'income_vs_expense'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      (provider.totalIncome > provider.totalExpense
                          ? provider.totalIncome
                          : provider.totalExpense) *
                      1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              value.toInt() == 0 ? 'income'.tr() : 'expense'.tr(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: provider.totalIncome,
                          color: Colors.green,
                          width: 40,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: provider.totalExpense,
                          color: Colors.red,
                          width: 40,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor(String hexColor) {
    if (hexColor.startsWith('#')) {
      return Color(int.parse(hexColor.substring(1, 7), radix: 16) + 0xFF000000);
    }
    return Colors.grey;
  }
}
