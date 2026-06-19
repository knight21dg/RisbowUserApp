import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/wallet_page/model/prepare_wallet_recharge_model.dart';
import 'package:hyper_local/screens/wallet_page/repo/wallet_repository.dart';

part 'wallet_transactions_event.dart';
part 'wallet_transactions_state.dart';

class WalletTransactionsBloc extends Bloc<WalletTransactionsEvent, WalletTransactionsState> {
  WalletTransactionsBloc() : super(WalletTransactionsInitial()) {
    on<FetchWalletTransactions>(_onFetchWalletTransactions);
    on<FetchMoreWalletTransactions>(_onFetchMoreWalletTransactions);
  }

  final repository = WalletRepository();

  int currentPage = 1;
  int perPage = 10;
  bool hasReachedMax = false;
  bool isLoadingMore = false;

  Future<void> _onFetchWalletTransactions(FetchWalletTransactions event, Emitter<WalletTransactionsState> emit) async {
    emit(WalletTransactionsLoading());

    try {
      currentPage = 1;
      hasReachedMax = false;
      isLoadingMore = false;

      final response = await repository.fetchWalletTransactions(
        page: currentPage,
        perPage: perPage,
      );

      if (response['success'] != true) {
        emit(WalletTransactionsFailure(error: response['message']?.toString() ?? 'Failed to load transactions'));
        return;
      }

      final data = response['data'];
      if (data == null || data['data'] == null) {
        emit(WalletTransactionsFailure(error: 'Invalid response format'));
        return;
      }

      final transactions = List<Transaction>.from(
          (data['data'] as List).map((item) => Transaction.fromJson(item))
      );

      final currentTotal = int.tryParse(data['current_page']?.toString() ?? '') ?? 1;
      final lastPageNum = int.tryParse(data['last_page']?.toString() ?? '') ?? 1;
      hasReachedMax = currentTotal >= lastPageNum || transactions.length < perPage;

      emit(WalletTransactionsLoaded(
        transactions: transactions,
        hasReachedMax: hasReachedMax,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(WalletTransactionsFailure(error: e.toString()));
    }
  }

  Future<void> _onFetchMoreWalletTransactions(FetchMoreWalletTransactions event, Emitter<WalletTransactionsState> emit) async {
    if (hasReachedMax || isLoadingMore) return;

    final currentState = state;
    if (currentState is WalletTransactionsLoaded) {
      isLoadingMore = true;

      try {
        currentPage += 1;

        final response = await repository.fetchWalletTransactions(
          page: currentPage,
          perPage: perPage,
        );

        if (response['success'] != true) {
          currentPage -= 1;
          return;
        }

        final data = response['data'];
        if (data == null || data['data'] == null) {
          currentPage -= 1;
          return;
        }

        final newTransactions = List<Transaction>.from(
            (data['data'] as List).map((item) => Transaction.fromJson(item))
        );

        final currentTotal = int.tryParse(data['current_page']?.toString() ?? '') ?? 1;
        final lastPageNum = int.tryParse(data['last_page']?.toString() ?? '') ?? 1;
        hasReachedMax = currentTotal >= lastPageNum || newTransactions.length < perPage;

        final updatedTransactions = List<Transaction>.from(currentState.transactions);

        for (final newTransaction in newTransactions) {
          if (!updatedTransactions.any((existing) => existing.id == newTransaction.id)) {
            updatedTransactions.add(newTransaction);
          }
        }

        emit(WalletTransactionsLoaded(
          transactions: updatedTransactions,
          hasReachedMax: hasReachedMax,
          isLoadingMore: false,
        ));

      } catch (e) {
        currentPage -= 1;
        emit(WalletTransactionsFailure(error: e.toString()));
      } finally {
        isLoadingMore = false;
      }
    }
  }
}