import 'package:flutter/material.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/seller_membership_page/model/membership_model.dart';
import 'package:hyper_local/screens/seller_membership_page/repo/membership_repository.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/l10n/app_localizations.dart';

class MembershipPage extends StatefulWidget {
  const MembershipPage({super.key});

  @override
  State<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends State<MembershipPage> {
  final MembershipRepository _repository = MembershipRepository();
  List<MembershipTierModel> _tiers = [];
  CurrentSubscriptionModel? _currentSubscription;
  bool _isLoading = true;
  String _selectedBillingCycle = 'monthly';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final tiers = await _repository.getTiers();
      final subscription = await _repository.getCurrentSubscription();
      setState(() {
        _tiers = tiers;
        _currentSubscription = subscription;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _subscribe(int tierId) async {
    final result = await _repository.subscribe(
      tierId: tierId,
      billingCycle: _selectedBillingCycle,
    );
    
    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Success')),
        );
        _loadData();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Error')),
        );
      }
    }
  }

  Future<void> _cancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmCancel),
        content: Text(AppLocalizations.of(context)!.cancelSubscriptionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.yes),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _repository.cancelSubscription();
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Cancelled')),
          );
          _loadData();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: AppLocalizations.of(context)!.membership,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentSubscription != null) _buildCurrentPlan(),
                    const SizedBox(height: 24),
                    _buildBillingCycleSelector(),
                    const SizedBox(height: 16),
                    _buildTiersList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentPlan() {
    final tier = _currentSubscription!.tier;
    final subscription = _currentSubscription!.subscription;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.currentPlan,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (subscription != null && subscription.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.active,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tier?.name ?? 'Free',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subscription != null) ...[
              const SizedBox(height: 8),
              Text(
                '${AppLocalizations.of(context)!.expires}: ${subscription.expiresAt?.toString().split(' ')[0] ?? 'N/A'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                '${AppLocalizations.of(context)!.commission}: ${subscription.commissionRate}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (subscription != null && subscription.isActive) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _cancelSubscription,
                  child: Text(AppLocalizations.of(context)!.cancelPlan),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBillingCycleSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildBillingOption('monthly', AppLocalizations.of(context)!.monthly),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBillingOption('yearly', AppLocalizations.of(context)!.yearly),
        ),
      ],
    );
  }

  Widget _buildBillingOption(String value, String label) {
    final isSelected = _selectedBillingCycle == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedBillingCycle = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          border: Border.all(color: AppTheme.primaryColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTiersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.availablePlans,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...(_tiers.map((tier) => _buildTierCard(tier)).toList()),
      ],
    );
  }

  Widget _buildTierCard(MembershipTierModel tier) {
    final isCurrentPlan = _currentSubscription?.tier?.id == tier.id;
    final price = tier.getPrice(_selectedBillingCycle);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tier.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (tier.featured)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.popular,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  '/${_selectedBillingCycle == 'yearly' ? 'year' : 'month'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFeatureItem('${tier.commissionPercent}% ${AppLocalizations.of(context)!.commission}'),
            _buildFeatureItem('${tier.productsLimit} ${AppLocalizations.of(context)!.products}'),
            _buildFeatureItem('${tier.storesLimit} ${AppLocalizations.of(context)!.stores}'),
            if (tier.analytics) _buildFeatureItem(AppLocalizations.of(context)!.analytics),
            if (tier.prioritySupport) _buildFeatureItem(AppLocalizations.of(context)!.prioritySupport),
            if (tier.customDomain) _buildFeatureItem(AppLocalizations.of(context)!.customDomain),
            if (tier.apiAccess) _buildFeatureItem(AppLocalizations.of(context)!.apiAccess),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: isCurrentPlan
                  ? OutlinedButton(
                      onPressed: null,
                      child: Text(AppLocalizations.of(context)!.currentPlan),
                    )
                  : ElevatedButton(
                      onPressed: _currentSubscription?.subscription?.isActive == true
                          ? null
                          : () => _subscribe(tier.id),
                      child: Text(AppLocalizations.of(context)!.subscribe),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
