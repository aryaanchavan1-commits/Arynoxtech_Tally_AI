import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        if (dashboard.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final summary = dashboard.summary;

        return RefreshIndicator(
          onRefresh: () => dashboard.loadDashboard(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                if (summary != null) ...[
                  _buildSummaryCards(summary),
                  const SizedBox(height: 16),
                  _buildChart(dashboard.chartData),
                  const SizedBox(height: 16),
                  _buildTopSections(dashboard),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _summaryCard('Revenue', '₹${_format(summary['total_revenue'])}', Icons.trending_up, AppTheme.successColor),
            _summaryCard('Expenses', '₹${_format(summary['total_expenses'])}', Icons.trending_down, AppTheme.errorColor),
            _summaryCard('Net Profit', '₹${_format(summary['net_profit'])}', Icons.account_balance_wallet, AppTheme.accentColor),
            _summaryCard('Cash', '₹${_format(summary['cash_position'])}', Icons.money, AppTheme.warningColor),
            _summaryCard('Receivables', '₹${_format(summary['total_receivables'])}', Icons.receipt, AppTheme.infoColor),
            _summaryCard('Payables', '₹${_format(summary['total_payables'])}', Icons.payment, Colors.orange),
            _summaryCard('Customers', '${summary['total_customers']}', Icons.people, AppTheme.primaryColor),
            _summaryCard('Low Stock', '${summary['low_stock_count']}', Icons.warning_amber, AppTheme.errorColor),
          ],
        );
      },
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(Map<String, dynamic>? chartData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Revenue vs Expenses', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: chartData != null && chartData['labels'] != null
                  ? BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxY(chartData),
                        barGroups: _buildBarGroups(chartData),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final labels = chartData['labels'] as List;
                                final idx = value.toInt();
                                if (idx >= 0 && idx < labels.length) {
                                  return Text(labels[idx].toString().substring(0, 3), style: const TextStyle(fontSize: 10));
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    )
                  : const Center(child: Text('No data available')),
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxY(Map<String, dynamic> chartData) {
    double max = 0;
    for (final v in chartData['revenue'] as List) {
      if ((v as num).toDouble() > max) max = v.toDouble();
    }
    for (final v in chartData['expenses'] as List) {
      if ((v as num).toDouble() > max) max = v.toDouble();
    }
    return max * 1.2;
  }

  List<BarChartGroupData> _buildBarGroups(Map<String, dynamic> chartData) {
    final revenue = (chartData['revenue'] as List).cast<num>();
    final expenses = (chartData['expenses'] as List).cast<num>();
    return List.generate(revenue.length, (i) {
      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: revenue[i].toDouble(), color: AppTheme.successColor, width: 12),
        BarChartRodData(toY: expenses[i].toDouble(), color: AppTheme.errorColor, width: 12),
      ]);
    });
  }

  Widget _buildTopSections(DashboardProvider dashboard) {
    return Row(
      children: [
        Expanded(child: _buildTopList('Top Customers', dashboard.topCustomers, Icons.person)),
        const SizedBox(width: 12),
        Expanded(child: _buildTopList('Top Products', dashboard.topProducts, Icons.inventory)),
      ],
    );
  }

  Widget _buildTopList(String title, List<dynamic> items, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...items.take(5).map((item) => ListTile(
              leading: CircleAvatar(child: Icon(icon, size: 16)),
              title: Text(item['name'] ?? '', style: const TextStyle(fontSize: 13)),
              trailing: Text('₹${_format(item['outstanding'] ?? item['stock'] ?? 0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              dense: true,
            )),
          ],
        ),
      ),
    );
  }

  String _format(dynamic value) {
    final num = (value ?? 0).toDouble();
    if (num >= 10000000) return '${(num / 10000000).toStringAsFixed(2)}Cr';
    if (num >= 100000) return '${(num / 100000).toStringAsFixed(2)}L';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toStringAsFixed(0);
  }
}
