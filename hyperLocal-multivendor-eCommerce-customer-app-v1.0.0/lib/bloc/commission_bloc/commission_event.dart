import 'package:equatable/equatable.dart';

abstract class CommissionEvent extends Equatable {
  const CommissionEvent();
  @override
  List<Object?> get props => [];
}

class FetchCommissionRules extends CommissionEvent {
  final int page;
  final String? scope;
  final bool? isActive;
  
  const FetchCommissionRules({this.page = 1, this.scope, this.isActive});
  
  @override
  List<Object?> get props => [page, scope, isActive];
}

class FetchCommissionStats extends CommissionEvent {
  final String? period;
  
  const FetchCommissionStats({this.period});
  
  @override
  List<Object?> get props => [period];
}

class CreateCommissionRule extends CommissionEvent {
  final Map<String, dynamic> ruleData;
  
  const CreateCommissionRule(this.ruleData);
  
  @override
  List<Object?> get props => [ruleData];
}

class UpdateCommissionRule extends CommissionEvent {
  final int ruleId;
  final Map<String, dynamic> ruleData;
  
  const UpdateCommissionRule(this.ruleId, this.ruleData);
  
  @override
  List<Object?> get props => [ruleId, ruleData];
}