import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/bloc/coins_bloc/coins_bloc.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import '../widgets/coins_transaction_card.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'dart:math' as math;

class CoinsPage extends StatefulWidget {
  const CoinsPage({super.key});

  @override
  State<CoinsPage> createState() => _CoinsPageState();
}

class _CoinsPageState extends State<CoinsPage> with TickerProviderStateMixin {
  late AnimationController _coinFlipController;
  late AnimationController _glowController;
  late Animation<double> _flipAnimation;
  late Animation<double> _glowAnimation;
  bool _isRefreshing = false;
  int _balance = 0;
  double _coinValue = 1.0;

  @override
  void initState() {
    super.initState();
    context.read<CoinsBloc>().add(FetchCoinsBalance());
    context.read<CoinsBloc>().add(FetchCoinsTransactions());

    _coinFlipController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _coinFlipController, curve: Curves.easeInOutBack),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _coinFlipController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _coinFlipController.reset();
        setState(() => _isRefreshing = false);
      }
    });
  }

  @override
  void dispose() {
    _coinFlipController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _refreshBalance() {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    _coinFlipController.forward();
    _glowController.repeat(reverse: true);

    context.read<CoinsBloc>().add(FetchCoinsBalance());
    context.read<CoinsBloc>().add(FetchCoinsTransactions());

    Future.delayed(Duration(milliseconds: 1200), () {
      if (mounted) {
        _glowController.stop();
        _glowController.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final backgroundHeight = screenHeight * 0.45;

    return BlocListener<CoinsBloc, CoinsState>(
      listener: (context, state) {
        if (state is CoinsBalanceLoaded) {
          setState(() {
            _balance = state.balance.coinsBalance;
            _coinValue = state.balance.coinValue;
          });
        }
      },
      child: CustomScaffold(
        backgroundColor: Colors.white,
        showViewCart: false,
        body: Stack(
          children: [
            Container(
              height: 400,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF59E0B),
                    Color(0xFFD97706),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            SafeArea(child: _buildAppBar(context)),
            Positioned(
              top: backgroundHeight,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: _buildTransactionsList(context),
              ),
            ),
            Positioned(
              top: backgroundHeight - 80,
              left: 20,
              right: 20,
              child: _buildCoinsBalanceCard(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.coins,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet(context) ? 24 : 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildCoinsBalanceCard(BuildContext context) {
    // Use local cached values updated via BlocListener so the balance stays visible
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFD700),
                Color(0xFFFFA500),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFFFD700).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Coins',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(
                            TablerIcons.coin,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(width: 8),
                          Text(
                            _balance.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${AppConstant.currency}${(_balance * _coinValue).toStringAsFixed(2)} value',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _refreshBalance,
                    child: AnimatedBuilder(
                      animation: _flipAnimation,
                      builder: (context, child) {
                        final angle = _flipAnimation.value;
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.002)
                            ..rotateY(angle),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: _isRefreshing ? [
                                BoxShadow(
                                  color: Colors.yellow.withValues(alpha: 0.5 * _glowAnimation.value),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ] : [],
                            ),
                            child: Icon(
                              TablerIcons.coin,
                              color: Color(0xFFD97706),
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Earned', '0'),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    _buildStatItem('Spent', '0'),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    _buildStatItem('Referrals', '0'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 100, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.push(AppRoutes.coinsTransactions);
                },
                child: Text('View All'),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<CoinsBloc, CoinsState>(
            buildWhen: (previous, current) => current is CoinsTransactionsLoaded || current is CoinsError || current is CoinsLoading,
            builder: (context, state) {
              if (state is CoinsTransactionsLoaded) {
                return state.transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(TablerIcons.coin, size: 64, color: Colors.grey.shade300),
                            SizedBox(height: 16),
                            Text(
                              'No coins transactions yet',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Earn coins by shopping and referring friends!',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: state.transactions.length > 5 ? 5 : state.transactions.length,
                        itemBuilder: (context, index) => CoinsTransactionCard(
                          transaction: state.transactions[index],
                        ),
                      );
              }

              if (state is CoinsLoading) {
                return Center(child: CustomCircularProgressIndicator());
              }

              return Center(child: CustomCircularProgressIndicator());
            },
          ),
        ),
      ],
    );
  }
}
