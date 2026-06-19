import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/bloc/coins_bloc/coins_bloc.dart';
import 'package:hyper_local/screens/wallet_page/widgets/coins_transaction_card.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';

class CoinsTransactionsPage extends StatefulWidget {
  const CoinsTransactionsPage({super.key});

  @override
  State<CoinsTransactionsPage> createState() => _CoinsTransactionsPageState();
}

class _CoinsTransactionsPageState extends State<CoinsTransactionsPage> {
  @override
  void initState() {
    super.initState();
    context.read<CoinsBloc>().add(FetchCoinsTransactions());
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showViewCart: false,
      title: 'Coins Transactions',
      showAppBar: true,
      body: BlocBuilder<CoinsBloc, CoinsState>(
        builder: (BuildContext context, CoinsState state) {
          if (state is CoinsTransactionsLoaded) {
            if (state.transactions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No transactions yet',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return CustomRefreshIndicator(
              onRefresh: () async {
                context.read<CoinsBloc>().add(FetchCoinsTransactions());
              },
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: state.transactions.length,
                itemBuilder: (context, index) {
                  return CoinsTransactionCard(
                    transaction: state.transactions[index],
                  );
                },
              ),
            );
          }
          return Center(child: CustomCircularProgressIndicator());
        },
      ),
    );
  }
}
