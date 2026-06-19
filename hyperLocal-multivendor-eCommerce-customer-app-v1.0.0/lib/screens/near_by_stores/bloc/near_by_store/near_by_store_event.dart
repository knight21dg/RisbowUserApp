part of 'near_by_store_bloc.dart';

sealed class NearByStoreEvent extends Equatable {
  const NearByStoreEvent();
  @override
  List<Object?> get props => [];
}

final class FetchNearByStores extends NearByStoreEvent {
  final int page;
  final int perPage;
  final String searchQuery;
  final String? category;

  const FetchNearByStores({
    this.page = 1,
    this.perPage = 15,
    required this.searchQuery,
    this.category,
  });

  @override
  List<Object?> get props => [page, perPage, searchQuery, category];
}

final class LoadMoreNearByStores extends NearByStoreEvent {
  final int perPage;
  final String searchQuery;
  final String? category;

  const LoadMoreNearByStores({
    this.perPage = 15,
    required this.searchQuery,
    this.category,
  });

  @override
  List<Object?> get props => [perPage, searchQuery, category];
}