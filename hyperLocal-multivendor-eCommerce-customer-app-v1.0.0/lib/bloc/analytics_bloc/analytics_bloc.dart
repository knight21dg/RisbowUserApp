import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/bloc/analytics_bloc/analytics_event.dart';
import 'package:hyper_local/bloc/analytics_bloc/analytics_state.dart';
import 'package:hyper_local/repositories/analytics_repository.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository _repository;

  AnalyticsBloc({AnalyticsRepository? repository})
      : _repository = repository ?? AnalyticsRepository(),
        super(AnalyticsInitial()) {
    on<FetchAnalyticsOverview>(_onFetchOverview);
    on<FetchCohortAnalysis>(_onFetchCohort);
    on<FetchClv>(_onFetchClv);
    on<FetchRfmAnalysis>(_onFetchRfm);
    on<FetchVendorScorecards>(_onFetchVendorScorecards);
    on<FetchCategoryPerformance>(_onFetchCategoryPerformance);
    on<FetchOrderMetrics>(_onFetchOrderMetrics);
    on<FetchRevenueMetrics>(_onFetchRevenueMetrics);
  }

  Future<void> _onFetchOverview(
    FetchAnalyticsOverview event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _repository.fetchOverview(period: event.period);
      emit(AnalyticsOverviewLoaded(data));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }

  Future<void> _onFetchCohort(
    FetchCohortAnalysis event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _repository.fetchCohort(period: event.period, months: event.months);
      emit(CohortAnalysisLoaded(data));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }

  Future<void> _onFetchClv(
    FetchClv event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _repository.fetchClv(period: event.period, limit: event.limit);
      emit(ClvLoaded(data));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }

  Future<void> _onFetchRfm(
    FetchRfmAnalysis event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _repository.fetchRfm(period: event.period);
      emit(RfmAnalysisLoaded(data));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }

  Future<void> _onFetchVendorScorecards(
    FetchVendorScorecards event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _repository.fetchVendorScorecards(period: event.period, vendorId: event.vendorId);
      emit(VendorScorecardsLoaded(data));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }

  Future<void> _onFetchCategoryPerformance(
    FetchCategoryPerformance event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _repository.fetchCategoryPerformance(period: event.period, categoryId: event.categoryId);
      emit(CategoryPerformanceLoaded(data));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }

  Future<void> _onFetchOrderMetrics(
    FetchOrderMetrics event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _repository.fetchOrderMetrics(period: event.period);
      emit(OrderMetricsLoaded(data));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }

  Future<void> _onFetchRevenueMetrics(
    FetchRevenueMetrics event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _repository.fetchRevenueMetrics(period: event.period);
      emit(RevenueMetricsLoaded(data));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }
}