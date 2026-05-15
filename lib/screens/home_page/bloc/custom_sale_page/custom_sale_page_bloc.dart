import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/home_page/model/custom_sale_page_model.dart';
import 'package:hyper_local/screens/home_page/repo/custom_sale_page_repo.dart';
import 'package:hyper_local/utils/widgets/cache_manager.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

abstract class CustomSalePageEvent {}

class FetchCustomSalePages extends CustomSalePageEvent {}

class FetchCustomSalePageBySlug extends CustomSalePageEvent {
  final String slug;
  FetchCustomSalePageBySlug({required this.slug});
}

abstract class CustomSalePageState {}

class CustomSalePageInitial extends CustomSalePageState {}

class CustomSalePageListLoading extends CustomSalePageState {}

class CustomSalePageListLoaded extends CustomSalePageState {
  final List<CustomSalePageListItem> pages;
  CustomSalePageListLoaded({required this.pages});
}

class CustomSalePageDetailLoading extends CustomSalePageState {}

class CustomSalePageDetailLoaded extends CustomSalePageState {
  final CustomSalePageModel page;
  CustomSalePageDetailLoaded({required this.page});
}

class CustomSalePageFailed extends CustomSalePageState {
  final String error;
  CustomSalePageFailed({required this.error});
}

class CustomSalePageBloc extends Bloc<CustomSalePageEvent, CustomSalePageState> {
  final CustomSalePageRepo repository = CustomSalePageRepo();

  CustomSalePageBloc() : super(CustomSalePageInitial()) {
    on<FetchCustomSalePages>(_onFetchCustomSalePages);
    on<FetchCustomSalePageBySlug>(_onFetchCustomSalePageBySlug);
  }

  void _precacheImages(List<String> urls) {
    for (final url in urls) {
      final resolvedUrl = resolveImageUrl(url);
      if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
        PermanentCacheManager().downloadFile(resolvedUrl);
      }
    }
  }

  Future<void> _onFetchCustomSalePages(
    FetchCustomSalePages event,
    Emitter<CustomSalePageState> emit,
  ) async {
    emit(CustomSalePageListLoading());
    try {
      final pages = await repository.getCustomSalePages();
      
      // Pre-cache list banner images
      final imageUrls = pages.map((p) => p.bannerImage).whereType<String>().toList();
      _precacheImages(imageUrls);

      emit(CustomSalePageListLoaded(pages: pages));
    } catch (e) {
      emit(CustomSalePageFailed(error: e.toString()));
    }
  }

  Future<void> _onFetchCustomSalePageBySlug(
    FetchCustomSalePageBySlug event,
    Emitter<CustomSalePageState> emit,
  ) async {
    emit(CustomSalePageDetailLoading());
    try {
      final page = await repository.getCustomSalePageBySlug(event.slug);

      final hydratedSections = <CustomSalePageSectionModel>[];
      for (final section in page.sections) {
        if (section.products.isNotEmpty ||
            (section.sectionType != 'categories' && section.sectionType != 'category_based')) {
          hydratedSections.add(section);
          continue;
        }

        final fetchedProducts = await repository.getProductsForSection(
          categorySlug: section.categorySlug,
          categoryId: section.categoryId,
          perPage: section.limit,
          page: 1,
        );

        hydratedSections.add(section.copyWith(products: fetchedProducts));
      }

      final hydratedPage = CustomSalePageModel(
        id: page.id,
        title: page.title,
        slug: page.slug,
        description: page.description,
        metaTitle: page.metaTitle,
        metaDescription: page.metaDescription,
        bannerImage: page.bannerImage,
        backgroundColor: page.backgroundColor,
        textColor: page.textColor,
        buttonColor: page.buttonColor,
        buttonTextColor: page.buttonTextColor,
        buttonText: page.buttonText,
        buttonLink: page.buttonLink,
        sections: hydratedSections,
        banners: page.banners,
      );

      emit(CustomSalePageDetailLoaded(page: hydratedPage));

      // Pre-cache detail images in background
      final detailUrls = <String>[];
      if (hydratedPage.bannerImage != null) detailUrls.add(hydratedPage.bannerImage!);
      for (final b in hydratedPage.banners) { if (b.image.isNotEmpty) detailUrls.add(b.image); }
      for (final s in hydratedPage.sections) {
        detailUrls.addAll(s.products.map((p) => p.mainImage));
        detailUrls.addAll(s.categories.map((c) => c.image));
        detailUrls.addAll(s.stores.map((st) => st.banner.isNotEmpty ? st.banner : st.image));
      }
      _precacheImages(detailUrls);
    } catch (e) {
      emit(CustomSalePageFailed(error: e.toString()));
    }
  }
}
