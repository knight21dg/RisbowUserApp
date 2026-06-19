import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/bloc/inventory_bloc/inventory_bloc.dart';
import 'package:hyper_local/bloc/inventory_bloc/inventory_event.dart';
import 'package:hyper_local/bloc/inventory_bloc/inventory_state.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/model/inventory_model.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/whole_page_progress.dart';

class InventorySyncPage extends StatefulWidget {
  const InventorySyncPage({super.key});

  @override
  State<InventorySyncPage> createState() => _InventorySyncPageState();
}

class _InventorySyncPageState extends State<InventorySyncPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<InventoryBloc>().add(FetchInventoryDashboard());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showViewCart: false,
      body: Column(
        children: [
          _buildAppBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildLowStockTab(),
                _buildOutOfStockTab(),
              ],
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
            'Inventory Sync',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          IconButton(
            icon: Icon(Icons.upload_file),
            onPressed: _showBulkUploadDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode(context)
            ? Theme.of(context).colorScheme.onSecondary
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: 'Dashboard'),
          Tab(text: 'Low Stock'),
          Tab(text: 'Out of Stock'),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoading) {
          return WholePageProgress();
        }
        if (state is InventoryDashboardLoaded) {
          return _buildDashboard(state.dashboard);
        }
        if (state is InventoryError) {
          return _buildError(state.message);
        }
        return WholePageProgress();
      },
    );
  }

  Widget _buildDashboard(InventoryDashboardModel dashboard) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSyncStats(dashboard),
          SizedBox(height: 24),
          _buildSyncByType(dashboard.syncsByType),
          SizedBox(height: 24),
          _buildRecentLogs(dashboard.recentLogs),
        ],
      ),
    );
  }

  Widget _buildSyncStats(InventoryDashboardModel dashboard) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Today', dashboard.todaySyncs.toString(), Icons.today),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('This Week', dashboard.weekSyncs.toString(), Icons.date_range),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('This Month', dashboard.monthSyncs.toString(), Icons.calendar_month),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
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
      ),
    );
  }

  Widget _buildSyncByType(Map<String, int> syncsByType) {
    if (syncsByType.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sync by Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: syncsByType.entries.map((entry) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${entry.key}: ${entry.value}',
                style: TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentLogs(List<InventorySyncLogModel> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Sync Logs',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        if (logs.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No recent sync logs',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...logs.take(10).map((log) => _buildLogCard(log)),
      ],
    );
  }

  Widget _buildLogCard(InventorySyncLogModel log) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode(context)
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode(context) ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            log.isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            color: log.isPositive ? Colors.green : Colors.red,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.syncTypeDisplay,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Stock: ${log.oldStock} → ${log.newStock} (${log.change > 0 ? '+' : ''}${log.change})',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            log.source,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockTab() {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoading) {
          return WholePageProgress();
        }
        if (state is LowStockProductsLoaded) {
          return _buildProductList(state.products);
        }
        context.read<InventoryBloc>().add(const FetchLowStockProducts());
        return WholePageProgress();
      },
    );
  }

  Widget _buildOutOfStockTab() {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoading) {
          return WholePageProgress();
        }
        if (state is OutOfStockProductsLoaded) {
          return _buildProductList(state.products);
        }
        context.read<InventoryBloc>().add(FetchOutOfStockProducts());
        return WholePageProgress();
      },
    );
  }

  Widget _buildProductList(List<LowStockProductModel> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductCard(products[index]),
    );
  }

  Widget _buildProductCard(LowStockProductModel product) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Seller: ${product.seller}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          if (product.lowStockVariants.isNotEmpty) ...[
            SizedBox(height: 8),
            ...product.lowStockVariants.map((variant) => Padding(
              padding: EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: variant.stock == 0 ? Colors.red : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${variant.name}: ${variant.stock} left',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  void _showBulkUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bulk Upload'),
        content: Text('Bulk upload feature coming soon. Upload CSV to sync inventory.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
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
              context.read<InventoryBloc>().add(FetchInventoryDashboard());
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
}