import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/bloc/commission_bloc/commission_bloc.dart';
import 'package:hyper_local/bloc/commission_bloc/commission_event.dart';
import 'package:hyper_local/bloc/commission_bloc/commission_state.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/model/commission_model.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/whole_page_progress.dart';

class CommissionConfigPage extends StatefulWidget {
  const CommissionConfigPage({super.key});

  @override
  State<CommissionConfigPage> createState() => _CommissionConfigPageState();
}

class _CommissionConfigPageState extends State<CommissionConfigPage> {
  @override
  void initState() {
    super.initState();
    context.read<CommissionBloc>().add(const FetchCommissionStats());
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showViewCart: false,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: BlocBuilder<CommissionBloc, CommissionState>(
              builder: (context, state) {
                if (state is CommissionLoading) {
                  return WholePageProgress();
                }
                if (state is CommissionStatsLoaded) {
                  return _buildDashboard(state.stats);
                }
                if (state is CommissionError) {
                  return _buildError(state.message);
                }
                return WholePageProgress();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode(context)
                    ? Theme.of(context).colorScheme.onSecondary
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_back, size: 20),
            ),
          ),
          SizedBox(width: 16),
          Text(
            'Commission Config',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(CommissionStatsModel stats) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCards(stats),
          SizedBox(height: 24),
          _buildRevenueSection(stats),
          SizedBox(height: 24),
          _buildCommissionBreakdown(stats),
          SizedBox(height: 24),
          _buildRulesSection(stats.rules),
        ],
      ),
    );
  }

  Widget _buildStatsCards(CommissionStatsModel stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Orders',
            stats.totalOrders.toString(),
            Icons.shopping_bag,
            Colors.blue,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Avg Order',
            '₹${stats.avgOrderValue.toStringAsFixed(0)}',
            Icons.attach_money,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSection(CommissionStatsModel stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue Overview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode(context)
                ? Theme.of(context).colorScheme.onSecondary
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRevenueItem('Total Revenue', '₹${stats.totalRevenue.toStringAsFixed(0)}'),
              _buildRevenueItem('Total Commission', '₹${stats.totalCommission.toStringAsFixed(0)}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCommissionBreakdown(CommissionStatsModel stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Commission Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildBreakdownCard('Pending', stats.pendingCommission, Colors.orange),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildBreakdownCard('Settled', stats.settledCommission, Colors.green),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBreakdownCard(String label, double amount, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesSection(List<CommissionRuleModel> rules) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Commission Rules',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${rules.length} rules',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        if (rules.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No commission rules found',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...rules.map((rule) => _buildRuleCard(rule)),
      ],
    );
  }

  Widget _buildRuleCard(CommissionRuleModel rule) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode(context)
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              rule.scope == 'global' ? Icons.public : Icons.store,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  rule.scopeDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: rule.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              rule.commissionDisplay,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: rule.isActive ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(message),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<CommissionBloc>().add(const FetchCommissionStats());
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
}