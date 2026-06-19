import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/bloc/commission_bloc/commission_event.dart';
import 'package:hyper_local/bloc/commission_bloc/commission_state.dart';
import 'package:hyper_local/repositories/commission_repository.dart';

class CommissionBloc extends Bloc<CommissionEvent, CommissionState> {
  final CommissionRepository _repository;

  CommissionBloc({CommissionRepository? repository})
      : _repository = repository ?? CommissionRepository(),
        super(CommissionInitial()) {
    on<FetchCommissionRules>(_onFetchRules);
    on<FetchCommissionStats>(_onFetchStats);
    on<CreateCommissionRule>(_onCreateRule);
    on<UpdateCommissionRule>(_onUpdateRule);
  }

  Future<void> _onFetchRules(
    FetchCommissionRules event,
    Emitter<CommissionState> emit,
  ) async {
    emit(CommissionLoading());
    try {
      final rules = await _repository.fetchRules(
        page: event.page,
        scope: event.scope,
        isActive: event.isActive,
      );
      emit(CommissionRulesLoaded(
        rules: rules,
        currentPage: event.page,
        hasMore: rules.length >= 20,
      ));
    } catch (e) {
      emit(CommissionError(e.toString()));
    }
  }

  Future<void> _onFetchStats(
    FetchCommissionStats event,
    Emitter<CommissionState> emit,
  ) async {
    emit(CommissionLoading());
    try {
      final stats = await _repository.fetchStats(period: event.period);
      emit(CommissionStatsLoaded(stats));
    } catch (e) {
      emit(CommissionError(e.toString()));
    }
  }

  Future<void> _onCreateRule(
    CreateCommissionRule event,
    Emitter<CommissionState> emit,
  ) async {
    emit(CommissionLoading());
    try {
      final response = await _repository.createRule(event.ruleData);
      if (response['success'] == true) {
        emit(CommissionRuleCreated(response['message'] ?? 'Rule created successfully'));
      } else {
        emit(CommissionError(response['message'] ?? 'Failed to create rule'));
      }
    } catch (e) {
      emit(CommissionError(e.toString()));
    }
  }

  Future<void> _onUpdateRule(
    UpdateCommissionRule event,
    Emitter<CommissionState> emit,
  ) async {
    emit(CommissionLoading());
    try {
      final response = await _repository.updateRule(event.ruleId, event.ruleData);
      if (response['success'] == true) {
        emit(CommissionRuleUpdated(response['message'] ?? 'Rule updated successfully'));
      } else {
        emit(CommissionError(response['message'] ?? 'Failed to update rule'));
      }
    } catch (e) {
      emit(CommissionError(e.toString()));
    }
  }
}