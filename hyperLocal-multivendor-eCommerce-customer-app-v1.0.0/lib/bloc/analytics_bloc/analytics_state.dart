import 'package:equatable/equatable.dart';

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();
  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsOverviewLoaded extends AnalyticsState {
  final Map<String, dynamic> data;
  
  const AnalyticsOverviewLoaded(this.data);
  
  @override
  List<Object?> get props => [data];
}

class CohortAnalysisLoaded extends AnalyticsState {
  final Map<String, dynamic> data;
  
  const CohortAnalysisLoaded(this.data);
  
  @override
  List<Object?> get props => [data];
}

class ClvLoaded extends AnalyticsState {
  final Map<String, dynamic> data;
  
  const ClvLoaded(this.data);
  
  @override
  List<Object?> get props => [data];
}

class RfmAnalysisLoaded extends AnalyticsState {
  final Map<String, dynamic> data;
  
  const RfmAnalysisLoaded(this.data);
  
  @override
  List<Object?> get props => [data];
}

class VendorScorecardsLoaded extends AnalyticsState {
  final Map<String, dynamic> data;
  
  const VendorScorecardsLoaded(this.data);
  
  @override
  List<Object?> get props => [data];
}

class CategoryPerformanceLoaded extends AnalyticsState {
  final Map<String, dynamic> data;
  
  const CategoryPerformanceLoaded(this.data);
  
  @override
  List<Object?> get props => [data];
}

class OrderMetricsLoaded extends AnalyticsState {
  final Map<String, dynamic> data;
  
  const OrderMetricsLoaded(this.data);
  
  @override
  List<Object?> get props => [data];
}

class RevenueMetricsLoaded extends AnalyticsState {
  final Map<String, dynamic> data;
  
  const RevenueMetricsLoaded(this.data);
  
  @override
  List<Object?> get props => [data];
}

class AnalyticsError extends AnalyticsState {
  final String message;
  
  const AnalyticsError(this.message);
  
  @override
  List<Object?> get props => [message];
}