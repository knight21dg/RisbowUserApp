import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/bloc/analytics_bloc/analytics_bloc.dart';
import 'package:hyper_local/bloc/analytics_bloc/analytics_event.dart';
import 'package:hyper_local/bloc/analytics_bloc/analytics_state.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/whole_page_progress.dart';

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  String _selectedPeriod = '30days';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<AnalyticsBloc>().add(FetchAnalyticsOverview(period: _selectedPeriod));
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showViewCart: false,
      body: Column(
        children: [
          _buildAppBar(),
          _buildPeriodSelector(),
          Expanded(
            child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
              builder: (context, state) {
                if (state is AnalyticsLoading) {
                  return WholePageProgress();
                }
                if (state is AnalyticsOverviewLoaded) {
                  return _buildDashboard(state.data);
                }
                if (state is AnalyticsError) {
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
            'Analytics Dashboard',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildPeriodChip('7days', '7 Days'),
            SizedBox(width: 8),
            _buildPeriodChip('30days', '30 Days'),
            SizedBox(width: 8),
            _buildPeriodChip('90days', '90 Days'),
            SizedBox(width: 8),
            _buildPeriodChip('1year', '1 Year'),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = value);
        context.read<AnalyticsBloc>().add(FetchAnalyticsOverview(period: value));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewSection(data),
          SizedBox(height: 24),
          _buildMetricsGrid(data),
          SizedBox(height: 24),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(Map<String, dynamic> data) {
    final revenue = data['total_revenue'] ?? 0;
    final orders = data['total_orders'] ?? 0;
    final customers = data['total_customers'] ?? 0;
    final avgOrderValue = data['avg_order_value'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'Total Revenue',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '₹${(revenue as num).toStringAsFixed(0)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildOverviewStat('Orders', orders.toString()),
                  _buildOverviewStat('Customers', customers.toString()),
                  _buildOverviewStat('Avg Order', '₹${(avgOrderValue as num).toStringAsFixed(0)}'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Conversion Rate',
                '${data['conversion_rate'] ?? 0}%',
                Icons.trending_up,
                Colors.green,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Repeat Rate',
                '${data['repeat_purchase_rate'] ?? 0}%',
                Icons.replay,
                Colors.blue,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Avg CLV',
                '₹${data['avg_clv'] ?? 0}',
                Icons.person,
                Colors.purple,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Active Vendors',
                '${data['active_vendors'] ?? 0}',
                Icons.store,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
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
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Reports',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        _buildActionTile('Cohort Analysis', Icons.group, Colors.blue, () {
          context.read<AnalyticsBloc>().add(const FetchCohortAnalysis());
        }),
        _buildActionTile('Customer Lifetime Value', Icons.person, Colors.purple, () {
          context.read<AnalyticsBloc>().add(const FetchClv());
        }),
        _buildActionTile('RFM Analysis', Icons.analytics, Colors.green, () {
          context.read<AnalyticsBloc>().add(const FetchRfmAnalysis());
        }),
        _buildActionTile('Vendor Scorecards', Icons.store, Colors.orange, () {
          context.read<AnalyticsBloc>().add(const FetchVendorScorecards());
        }),
        _buildActionTile('Category Performance', Icons.category, Colors.teal, () {
          context.read<AnalyticsBloc>().add(const FetchCategoryPerformance());
        }),
      ],
    );
  }

  Widget _buildActionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      trailing: Icon(Icons.chevron_right),
      onTap: onTap,
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
            onPressed: _loadData,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
}