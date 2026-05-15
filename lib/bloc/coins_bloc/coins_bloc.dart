import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/model/coins_model.dart';
import 'package:hyper_local/repositories/coins_repository.dart';

abstract class CoinsEvent extends Equatable {
  const CoinsEvent();
  @override
  List<Object?> get props => [];
}

class FetchCoinsBalance extends CoinsEvent {}

class FetchCoinsStats extends CoinsEvent {}

class FetchCoinsSettings extends CoinsEvent {}

class FetchCoinsTransactions extends CoinsEvent {
  final int perPage;
  const FetchCoinsTransactions({this.perPage = 20});
  @override
  List<Object?> get props => [perPage];
}

class ApplyReferralCode extends CoinsEvent {
  final String referralCode;
  final String? deviceId;
  final String? referralSource;
  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;
  final String? utmContent;
  final String? utmTerm;
  
  const ApplyReferralCode(
    this.referralCode, {
    this.deviceId,
    this.referralSource,
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.utmContent,
    this.utmTerm,
  });
  
  @override
  List<Object?> get props => [
    referralCode,
    deviceId,
    referralSource,
    utmSource,
    utmMedium,
    utmCampaign,
    utmContent,
    utmTerm,
  ];
}

class CalculateRedemption extends CoinsEvent {
  final int coins;
  const CalculateRedemption(this.coins);
  @override
  List<Object?> get props => [coins];
}

class RedeemCoins extends CoinsEvent {
  final int coins;
  final int orderId;
  const RedeemCoins(this.coins, this.orderId);
  @override
  List<Object?> get props => [coins, orderId];
}

class TrackInstallAttribution extends CoinsEvent {
  final String? referralCode;
  final String? googlePlayReferrer;
  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;
  final String? utmContent;
  final String? utmTerm;
  
  const TrackInstallAttribution({
    this.referralCode,
    this.googlePlayReferrer,
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.utmContent,
    this.utmTerm,
  });
  
  @override
  List<Object?> get props => [referralCode, googlePlayReferrer, utmSource, utmMedium, utmCampaign, utmContent, utmTerm];
}

abstract class CoinsState extends Equatable {
  const CoinsState();
  @override
  List<Object?> get props => [];
}

class CoinsInitial extends CoinsState {}

class CoinsLoading extends CoinsState {}

class CoinsBalanceLoaded extends CoinsState {
  final CoinsBalanceModel balance;
  const CoinsBalanceLoaded(this.balance);
  @override
  List<Object?> get props => [balance];
}

class CoinsStatsLoaded extends CoinsState {
  final CoinsStatsModel stats;
  const CoinsStatsLoaded(this.stats);
  @override
  List<Object?> get props => [stats];
}

class CoinsSettingsLoaded extends CoinsState {
  final CoinsSettingsModel settings;
  const CoinsSettingsLoaded(this.settings);
  @override
  List<Object?> get props => [settings];
}

class CoinsTransactionsLoaded extends CoinsState {
  final List<CoinsTransactionModel> transactions;
  const CoinsTransactionsLoaded(this.transactions);
  @override
  List<Object?> get props => [transactions];
}

class CoinsReferralApplied extends CoinsState {
  final String message;
  final int bonusCoins;
  const CoinsReferralApplied(this.message, this.bonusCoins);
  @override
  List<Object?> get props => [message, bonusCoins];
}

class CoinsRedemptionCalculated extends CoinsState {
  final int coinsToUse;
  final double rupeeValue;
  const CoinsRedemptionCalculated(this.coinsToUse, this.rupeeValue);
  @override
  List<Object?> get props => [coinsToUse, rupeeValue];
}

class CoinsRedeemed extends CoinsState {
  final int coinsDeducted;
  final double rupeeValue;
  const CoinsRedeemed(this.coinsDeducted, this.rupeeValue);
  @override
  List<Object?> get props => [coinsDeducted, rupeeValue];
}

class CoinsError extends CoinsState {
  final String message;
  const CoinsError(this.message);
  @override
  List<Object?> get props => [message];
}

class CoinsBloc extends Bloc<CoinsEvent, CoinsState> {
  final CoinsRepository _repository;

  CoinsBloc({CoinsRepository? repository})
      : _repository = repository ?? CoinsRepository(),
        super(CoinsInitial()) {
    on<FetchCoinsBalance>(_onFetchBalance);
    on<FetchCoinsStats>(_onFetchStats);
    on<FetchCoinsSettings>(_onFetchSettings);
    on<FetchCoinsTransactions>(_onFetchTransactions);
    on<ApplyReferralCode>(_onApplyReferral);
    on<CalculateRedemption>(_onCalculateRedemption);
    on<RedeemCoins>(_onRedeemCoins);
    on<TrackInstallAttribution>(_onTrackInstallAttribution);
  }

  Future<void> _onFetchBalance(
    FetchCoinsBalance event,
    Emitter<CoinsState> emit,
  ) async {
    emit(CoinsLoading());
    try {
      final balance = await _repository.fetchCoinsBalance();
      emit(CoinsBalanceLoaded(balance));
    } catch (e) {
      emit(CoinsError(e.toString()));
    }
  }

  Future<void> _onFetchStats(
    FetchCoinsStats event,
    Emitter<CoinsState> emit,
  ) async {
    emit(CoinsLoading());
    try {
      final stats = await _repository.fetchCoinsStats();
      emit(CoinsStatsLoaded(stats));
    } catch (e) {
      emit(CoinsError(e.toString()));
    }
  }

  Future<void> _onFetchSettings(
    FetchCoinsSettings event,
    Emitter<CoinsState> emit,
  ) async {
    emit(CoinsLoading());
    try {
      final data = await _repository.fetchCoinsSettings();
      if (data.isNotEmpty) {
        final settings = CoinsSettingsModel.fromJson(data);
        emit(CoinsSettingsLoaded(settings));
      }
    } catch (e) {
      emit(CoinsError(e.toString()));
    }
  }

  Future<void> _onFetchTransactions(
    FetchCoinsTransactions event,
    Emitter<CoinsState> emit,
  ) async {
    emit(CoinsLoading());
    try {
      final response = await _repository.fetchCoinsTransactions(
        perPage: event.perPage,
      );
      if (response['success'] == true) {
        final List<CoinsTransactionModel> transactions = [];
        if (response['data'] != null && response['data']['data'] != null) {
          for (var item in response['data']['data']) {
            transactions.add(CoinsTransactionModel.fromJson(item));
          }
        }
        emit(CoinsTransactionsLoaded(transactions));
      } else {
        emit(CoinsTransactionsLoaded([]));
      }
    } catch (e) {
      emit(CoinsError(e.toString()));
    }
  }

  Future<void> _onApplyReferral(
    ApplyReferralCode event,
    Emitter<CoinsState> emit,
  ) async {
    emit(CoinsLoading());
    try {
      final response = await _repository.applyReferralCode(
        event.referralCode,
        deviceId: event.deviceId,
        referralSource: event.referralSource,
        utmSource: event.utmSource,
        utmMedium: event.utmMedium,
        utmCampaign: event.utmCampaign,
        utmContent: event.utmContent,
        utmTerm: event.utmTerm,
      );
      if (response['success'] == true) {
        emit(CoinsReferralApplied(
          response['message'] ?? 'Referral applied!',
          response['data']?['bonus_coins'] ?? 0,
        ));
      } else {
        emit(CoinsError(response['message'] ?? 'Failed to apply referral'));
      }
    } catch (e) {
      emit(CoinsError(e.toString()));
    }
  }

  Future<void> _onCalculateRedemption(
    CalculateRedemption event,
    Emitter<CoinsState> emit,
  ) async {
    try {
      final response = await _repository.calculateRedemption(event.coins);
      if (response['success'] == true) {
        emit(CoinsRedemptionCalculated(
          response['data']['coins_to_use'] ?? event.coins,
          (response['data']['rupee_value'] ?? 0).toDouble(),
        ));
      }
    } catch (e) {
      emit(CoinsError(e.toString()));
    }
  }

  Future<void> _onRedeemCoins(
    RedeemCoins event,
    Emitter<CoinsState> emit,
  ) async {
    emit(CoinsLoading());
    try {
      final response = await _repository.redeemCoinsForOrder(
        event.coins,
        event.orderId,
      );
      if (response['success'] == true) {
        emit(CoinsRedeemed(
          response['data']['coins_deducted'] ?? event.coins,
          (response['data']['rupee_value'] ?? 0).toDouble(),
        ));
      } else {
        emit(CoinsError(response['message'] ?? 'Failed to redeem coins'));
      }
    } catch (e) {
      emit(CoinsError(e.toString()));
    }
  }

  Future<void> _onTrackInstallAttribution(
    TrackInstallAttribution event,
    Emitter<CoinsState> emit,
  ) async {
    try {
      final response = await _repository.trackInstallAttribution(
        referralCode: event.referralCode,
        googlePlayReferrer: event.googlePlayReferrer,
        utmSource: event.utmSource,
        utmMedium: event.utmMedium,
        utmCampaign: event.utmCampaign,
        utmContent: event.utmContent,
        utmTerm: event.utmTerm,
      );
      
      if (response['success'] == true && response['data']['tracked'] == true) {
        debugPrint('Install attribution tracked: ${response['data']}');
      }
    } catch (e) {
      debugPrint('Failed to track install attribution: $e');
    }
  }
}
