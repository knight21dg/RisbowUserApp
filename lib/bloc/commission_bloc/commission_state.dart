import 'package:equatable/equatable.dart';
import 'package:hyper_local/model/commission_model.dart';

abstract class CommissionState extends Equatable {
  const CommissionState();
  @override
  List<Object?> get props => [];
}

class CommissionInitial extends CommissionState {}

class CommissionLoading extends CommissionState {}

class CommissionRulesLoaded extends CommissionState {
  final List<CommissionRuleModel> rules;
  final int currentPage;
  final bool hasMore;
  
  const CommissionRulesLoaded({
    required this.rules,
    this.currentPage = 1,
    this.hasMore = false,
  });
  
  @override
  List<Object?> get props => [rules, currentPage, hasMore];
}

class CommissionStatsLoaded extends CommissionState {
  final CommissionStatsModel stats;
  
  const CommissionStatsLoaded(this.stats);
  
  @override
  List<Object?> get props => [stats];
}

class CommissionRuleCreated extends CommissionState {
  final String message;
  
  const CommissionRuleCreated(this.message);
  
  @override
  List<Object?> get props => [message];
}

class CommissionRuleUpdated extends CommissionState {
  final String message;
  
  const CommissionRuleUpdated(this.message);
  
  @override
  List<Object?> get props => [message];
}

class CommissionError extends CommissionState {
  final String message;
  
  const CommissionError(this.message);
  
  @override
  List<Object?> get props => [message];
}