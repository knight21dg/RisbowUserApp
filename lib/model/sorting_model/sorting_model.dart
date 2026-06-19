enum SortType {
  relevance,
  priceLowToHigh,
  priceHighToLow,
  averageRated,
  bestSeller,
  featured,
  priceRange1,
  priceRange2,
  priceRange3,
  priceRange4,
}

class SortOption {
  final SortType type;
  final String displayName;
  final String apiValue;

  const SortOption({
    required this.type,
    required this.displayName,
    required this.apiValue,
  });

  static const List<SortOption> sortOptions = [
    SortOption(
      type: SortType.relevance,
      displayName: 'Relevance (default)',
      apiValue: 'relevance',
    ),
    SortOption(
      type: SortType.priceLowToHigh,
      displayName: 'Price (low to high)',
      apiValue: 'price_asc',
    ),
    SortOption(
      type: SortType.priceHighToLow,
      displayName: 'Price (high to low)',
      apiValue: 'price_desc',
    ),
    SortOption(
      type: SortType.averageRated,
      displayName: 'Top Rated',
      apiValue: 'avg_rated',
    ),
    SortOption(
      type: SortType.bestSeller,
      displayName: 'Best Seller',
      apiValue: 'best_seller',
    ),
    SortOption(
      type: SortType.featured,
      displayName: 'Featured',
      apiValue: 'featured',
    ),
    SortOption(
      type: SortType.priceRange1,
      displayName: 'Under ₹100',
      apiValue: 'price_range_1',
    ),
    SortOption(
      type: SortType.priceRange2,
      displayName: '₹100 - ₹500',
      apiValue: 'price_range_2',
    ),
    SortOption(
      type: SortType.priceRange3,
      displayName: '₹500 - ₹1000',
      apiValue: 'price_range_3',
    ),
    SortOption(
      type: SortType.priceRange4,
      displayName: 'Above ₹1000',
      apiValue: 'price_range_4',
    ),
  ];

  static SortOption getSortOptionByType(SortType type) {
    return sortOptions.firstWhere(
      (option) => option.type == type,
      orElse: () => sortOptions.first,
    );
  }

  static SortOption getSortOptionByApiValue(String apiValue) {
    return sortOptions.firstWhere(
          (option) => option.apiValue == apiValue,
      orElse: () => sortOptions.first,
    );
  }
}
