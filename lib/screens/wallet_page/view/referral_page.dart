import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/bloc/coins_bloc/coins_bloc.dart';
import 'package:hyper_local/bloc/user_details_bloc/user_details_bloc.dart';
import 'package:hyper_local/bloc/user_details_bloc/user_details_state.dart';
import 'package:hyper_local/config/env_config.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_textfield.dart';
import 'package:share_plus/share_plus.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  final TextEditingController _referralCodeController = TextEditingController();
  bool _isApplying = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    context.read<CoinsBloc>().add(FetchCoinsStats());
  }

  @override
  void dispose() {
    _referralCodeController.dispose();
    super.dispose();
  }

  void _copyReferralCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareReferralCode(String code, String? name) {
    final shareText = 'Join me on Risbow!\n\n'
        'Use my referral code: $code\n\n'
        'You\'ll get bonus coins on signup, and so will I!\n\n'
        'Download app: ${EnvConfig.domainBaseUrl}/app';
    
    Share.share(shareText, subject: 'Join Risbow with my referral code');
  }

  void _applyReferralCode() {
    final code = _referralCodeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a referral code';
      });
      return;
    }

    setState(() {
      _isApplying = true;
      _errorMessage = null;
      _successMessage = null;
    });

    context.read<CoinsBloc>().add(ApplyReferralCode(code));
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.read<UserDataBloc>().state;
    String? userReferralCode;
    String? userName;
    
    if (userState is UserDataStored) {
      userReferralCode = userState.userData.referralCode;
      userName = userState.userData.name;
    } else if (userState is UserDataRetrieved && userState.userData != null) {
      userReferralCode = userState.userData!.referralCode;
      userName = userState.userData!.name;
    }

    return BlocListener<CoinsBloc, CoinsState>(
      listener: (context, state) {
        if (state is CoinsReferralApplied) {
          setState(() {
            _isApplying = false;
            _successMessage = state.message;
            _referralCodeController.clear();
          });
        } else if (state is CoinsError) {
          setState(() {
            _isApplying = false;
            _errorMessage = state.message;
          });
        }
      },
      child: CustomScaffold(
        showViewCart: true,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(TablerIcons.arrow_left, color: Colors.black),
            onPressed: () => context.pop(),
          ),
          title: Text(
            AppLocalizations.of(context)!.referralCode,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // My Referral Code Section
              _buildReferralCodeCard(userReferralCode, userName),
              SizedBox(height: 24.h),

              // How it works Section
              _buildHowItWorksSection(),
              SizedBox(height: 24.h),

              // Stats Section
              BlocBuilder<CoinsBloc, CoinsState>(
                builder: (context, state) {
                  if (state is CoinsStatsLoaded) {
                    return _buildStatsSection(state);
                  }
                  return const SizedBox.shrink();
                },
              ),
              SizedBox(height: 24.h),

              // Enter Referral Code Section
              _buildEnterReferralSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferralCodeCard(String? code, String? name) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(TablerIcons.users, color: Colors.white, size: 24.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Referral Code',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      code ?? 'Loading...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: code != null ? () => _copyReferralCode(code!) : null,
                icon: Icon(TablerIcons.copy, color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              onPressed: code != null ? () => _shareReferralCode(code!, name) : null,
              backgroundColor: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(TablerIcons.share, color: AppTheme.primaryColor, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Share with Friends',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How it works',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            _buildStepItem(
              icon: TablerIcons.share,
              title: 'Share',
              subtitle: 'Share your code',
              color: Colors.blue,
            ),
            SizedBox(width: 12.w),
            _buildStepItem(
              icon: TablerIcons.user_plus,
              title: 'Invite',
              subtitle: 'Friend signs up',
              color: Colors.green,
            ),
            SizedBox(width: 12.w),
            _buildStepItem(
              icon: TablerIcons.coins,
              title: 'Earn',
              subtitle: 'Get bonus coins',
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28.r),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(CoinsStatsLoaded state) {
    final stats = state.stats;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Referral Stats',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: TablerIcons.user_plus,
                  value: stats.referralCount.toString(),
                  label: 'Friends Joined',
                  color: Colors.blue,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.grey[200],
              ),
              Expanded(
                child: _buildStatItem(
                  icon: TablerIcons.coins,
                  value: stats.totalEarned.toString(),
                  label: 'Coins Earned',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24.r),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildEnterReferralSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Have a referral code?',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Enter your friend\'s code to earn bonus coins!',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _referralCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Enter referral code',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            ),
          ),
          if (_errorMessage != null) ...[
            SizedBox(height: 8.h),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red, fontSize: 12.sp),
            ),
          ],
          if (_successMessage != null) ...[
            SizedBox(height: 8.h),
            Text(
              _successMessage!,
              style: TextStyle(color: Colors.green, fontSize: 12.sp),
            ),
          ],
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              onPressed: _isApplying ? null : _applyReferralCode,
              isLoading: _isApplying,
              child: Text(_isApplying ? 'Applying...' : 'Apply Code'),
            ),
          ),
        ],
      ),
    );
  }
}