import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/home_page/model/homepage_section_model.dart';
import 'package:hyper_local/screens/home_page/repo/homepage_section_repo.dart';

abstract class HomepageSectionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchHomepageSections extends HomepageSectionEvent {
  final String? categorySlug;
  FetchHomepageSections({this.categorySlug});
  @override
  List<Object?> get props => [categorySlug];
}

abstract class HomepageSectionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomepageSectionInitial extends HomepageSectionState {}

class HomepageSectionLoading extends HomepageSectionState {}

class HomepageSectionLoaded extends HomepageSectionState {
  final List<HomepageSectionModel> sections;
  HomepageSectionLoaded({required this.sections});
  @override
  List<Object?> get props => [sections];
}

class HomepageSectionFailed extends HomepageSectionState {
  final String error;
  HomepageSectionFailed({required this.error});
  @override
  List<Object?> get props => [error];
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
    emit(HomepageSectionLoading());
    try {
      final sections = await repository.getHomepageSections(categorySlug: event.categorySlug);
      emit(HomepageSectionLoaded(sections: sections));
    } catch (e) {
      emit(HomepageSectionFailed(error: e.toString()));
    }
  }
}