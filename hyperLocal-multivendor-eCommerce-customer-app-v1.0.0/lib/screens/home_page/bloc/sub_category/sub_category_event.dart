import 'package:equatable/equatable.dart';

abstract class SubCategoryEvent extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class FetchSubCategory extends SubCategoryEvent {
  final String slug;
  final bool isForAllCategory;
  final bool isHome;
  FetchSubCategory({required this.slug, required this.isForAllCategory, this.isHome = false});
  @override
  // TODO: implement props
  List<Object?> get props => [slug, isForAllCategory, isHome];
}

class FetchMoreSubCategory extends SubCategoryEvent {}