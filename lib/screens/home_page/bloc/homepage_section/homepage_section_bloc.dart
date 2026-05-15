import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:hyper_local/screens/home_page/model/homepage_section_model.dart';
import 'package:hyper_local/screens/home_page/repo/homepage_section_repo.dart';

abstract class HomepageSectionEvent {}

class FetchHomepageSections extends HomepageSectionEvent {}

abstract class HomepageSectionState {}

class HomepageSectionInitial extends HomepageSectionState {}

class HomepageSectionLoading extends HomepageSectionState {}

class HomepageSectionLoaded extends HomepageSectionState {
  final List<HomepageSectionModel> sections;
  HomepageSectionLoaded({required this.sections});
}

class HomepageSectionFailed extends HomepageSectionState {
  final String error;
  HomepageSectionFailed({required this.error});
}

class HomepageSectionBloc extends Bloc<HomepageSectionEvent, HomepageSectionState> {
  final HomepageSectionRepo repository = HomepageSectionRepo();

  HomepageSectionBloc() : super(HomepageSectionInitial()) {
    on<FetchHomepageSections>(_onFetchHomepageSections);
  }

  Future<void> _onFetchHomepageSections(
    FetchHomepageSections event,
    Emitter<HomepageSectionState> emit,
  ) async {
    debugPrint('=== BLOC: FetchHomepageSections called ===');
    emit(HomepageSectionLoading());
    debugPrint('=== BLOC: Emitted Loading state ===');
    try {
      final sections = await repository.getHomepageSections();
      debugPrint('=== BLOC: Got ${sections.length} sections ===');
      emit(HomepageSectionLoaded(sections: sections));
      debugPrint('=== BLOC: Emitted Loaded state ===');
    } catch (e) {
      debugPrint('=== BLOC: Error: $e ===');
      emit(HomepageSectionFailed(error: e.toString()));
    }
  }
}