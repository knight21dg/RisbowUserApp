import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/wallet_page/repo/wallet_repository.dart';

part 'prepare_recharge_event.dart';
part 'prepare_recharge_state.dart';

class PrepareRechargeBloc extends Bloc<PrepareRechargeEvent, PrepareRechargeState> {
  PrepareRechargeBloc() : super(PrepareRechargeInitial()) {
    on<PrepareRecharge>(_onPrepareRecharge);
  }

  final WalletRepository repository = WalletRepository();

  Future<void> _onPrepareRecharge(PrepareRecharge event, Emitter<PrepareRechargeState> emit) async {
    emit(PrepareRechargeLoading());
    try{
      final response = await repository.prepareRecharge(
        amount: event.amount,
        paymentMethod: event.paymentMethod,
        description: event.description
      );

      if (response.isEmpty) {
        emit(PrepareRechargeFailure(error: 'Empty response from server'));
        return;
      }

      final firstItem = response.first;
      if (firstItem.success == true && firstItem.data != null) {
        final paymentResponse = firstItem.data!.paymentResponse;
        emit(PrepareRechargeSuccess(
          orderId: paymentResponse?.id?.toString() ?? '',
          amount: paymentResponse?.amountDue?.toString() ?? '0',
          currency: paymentResponse?.currency ?? ''
        ));
      } else {
        emit(PrepareRechargeFailure(error: firstItem.message ?? 'Failed to prepare recharge'));
      }
    }catch(e) {
      emit(PrepareRechargeFailure(error: e.toString()));
    }
  }
}
