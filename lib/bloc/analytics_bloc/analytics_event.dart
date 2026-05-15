import 'package:equatable/equatable.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();
  @override
  List<Object?> get props => [];
}

class FetchAnalyticsOverview extends AnalyticsEvent {
  final String? period;
  
  const FetchAnalyticsOverview({this.period});
  
  @override
  List<Object?> get props => [period];
}

class FetchCohortAnalysis extends AnalyticsEvent {
  final String? period;
  final int? months;
  
  const FetchCohortAnalysis({this.period, this.months});
  
  @override
  List<Object?> get props => [period, months];
}

class FetchClv extends AnalyticsEvent {
  final String? period;
  final int? limit;
  
  const FetchClv({this.period, this.limit});
  
  @override
  List<Object?> get props => [period, limit];
}

class FetchRfmAnalysis extends AnalyticsEvent {
  final String? period;
  
  const FetchRfmAnalysis({this.period});
  
  @override
  List<Object?> get props => [period];
}

class FetchVendorScorecards extends AnalyticsEvent {
  final String? period;
  final int? vendorId;
  
  const FetchVendorScorecards({this.period, this.vendorId});
  
  @override
  List<Object?> get props => [period, vendorId];
}

class FetchCategoryPerformance extends AnalyticsEvent {
  final String? period;
  final int? categoryId;
  
  const FetchCategoryPerformance({this.period, this.categoryId});
  
  @override
  List<Object?> get props => [period, categoryId];
}

class FetchOrderMetrics extends AnalyticsEvent {
  final String? period;
  
  const FetchOrderMetrics({this.period});
  
  @override
  List<Object?> get props => [period];
}

class FetchRevenueMetrics extends AnalyticsEvent {
  final String? period;
  
  const FetchRevenueMetrics({this.period});
  
  @override
  List<Object?> get props => [period];
}