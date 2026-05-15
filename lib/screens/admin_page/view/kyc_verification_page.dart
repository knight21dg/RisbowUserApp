import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/bloc/kyc_bloc/kyc_bloc.dart';
import 'package:hyper_local/bloc/kyc_bloc/kyc_event.dart';
import 'package:hyper_local/bloc/kyc_bloc/kyc_state.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/model/kyc_model.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/whole_page_progress.dart';

class KycVerificationPage extends StatefulWidget {
  const KycVerificationPage({super.key});

  @override
  State<KycVerificationPage> createState() => _KycVerificationPageState();
}

class _KycVerificationPageState extends State<KycVerificationPage> {
  @override
  void initState() {
    super.initState();
    context.read<KycBloc>().add(FetchKycDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showViewCart: false,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: BlocBuilder<KycBloc, KycState>(
              builder: (context, state) {
                if (state is KycLoading) {
                  return WholePageProgress();
                }
                if (state is KycDashboardLoaded) {
                  return _buildDashboard(state.dashboard);
                }
                if (state is KycError) {
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
            'KYC Verification',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(KycStatusModel dashboard) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCards(dashboard),
          SizedBox(height: 24),
          _buildPendingByType(dashboard.pendingByType),
          SizedBox(height: 24),
          _buildDocumentsList(),
        ],
      ),
    );
  }

  Widget _buildStatusCards(KycStatusModel dashboard) {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            'Pending',
            dashboard.totalPending.toString(),
            Colors.orange,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            'Approved',
            dashboard.totalApproved.toString(),
            Colors.green,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            'Rejected',
            dashboard.totalRejected.toString(),
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
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

  Widget _buildPendingByType(Map<String, int> pendingByType) {
    if (pendingByType.isEmpty) return SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending by Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: pendingByType.entries.map((entry) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
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

  Widget _buildDocumentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Types',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        _buildDocumentTypeTile('PAN Card', 'pan_card', Icons.badge),
        _buildDocumentTypeTile('Aadhaar Card', 'aadhaar_card', Icons.badge_outlined),
        _buildDocumentTypeTile('GST Certificate', 'gst_certificate', Icons.description),
        _buildDocumentTypeTile('Business License', 'business_license', Icons.business),
        _buildDocumentTypeTile('FSSAI License', 'fssai_license', Icons.restaurant),
        _buildDocumentTypeTile('Bank Statement', 'bank_statement', Icons.account_balance),
      ],
    );
  }

  Widget _buildDocumentTypeTile(String title, String type, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(title),
      trailing: Icon(Icons.chevron_right),
      onTap: () {
        // Navigate to document upload or detail page
      },
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
              context.read<KycBloc>().add(FetchKycDashboard());
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
}