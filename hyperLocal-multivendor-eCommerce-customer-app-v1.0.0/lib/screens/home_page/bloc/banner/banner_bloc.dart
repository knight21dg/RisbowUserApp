
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/banner/banner_event.dart';
import 'package:hyper_local/screens/home_page/bloc/banner/banner_state.dart';
import 'package:hyper_local/screens/home_page/repo/banner_repo.dart';

import '../../model/banner_model.dart';

class BannerBloc extends Bloc<BannerEvent, BannerState> {
  BannerBloc() : super(BannerInitial()){
    on<FetchBanner>(_onFetchBanner);
  }

  int currentPage = 0;
  int perPage = 0;
  int? lastPage;
  bool _hasReachedMax = false;
  bool loadMore = false;
  final BannerRepository repository = BannerRepository();

  Future<void> _onFetchBanner(FetchBanner event, Emitter<BannerState> emit) async {
    emit(BannerLoading());
    try {
      List<Top> bannerData = [];
      List<Top> middleBanners = [];
      String? middleTitle;
      perPage = 18;
      currentPage = 1;
      _hasReachedMax = false;
      loadMore = false;
      
      final response = await repository.fetchBanners(categorySlug: event.categorySlug);

      print('BannerBloc: API Response for slug "${event.categorySlug}": $response');

      final dynamic rawData = (response.containsKey('data')) ? response['data'] : response;
      List<dynamic> combinedBanners = [];
      Map<String, dynamic>? targetMap;
      
      if (rawData is List) {
        combinedBanners = rawData;
      } else if (rawData is Map<String, dynamic>) {
        targetMap = rawData;
        
        // Try BannersData.fromJson first if data contains grouped keys
        if (rawData.containsKey('top') || rawData.containsKey('carousel') || rawData.containsKey('middle')) {
          final parsedData = BannersData.fromJson(rawData);
          middleBanners = parsedData.middle ?? [];
          middleTitle = parsedData.middleTitle;
        }

        // Handle pagination wrapper: { data: { top: [], carousel: [], middle: [], ... } }
        if (rawData.containsKey('data')) {
          final nestedData = rawData['data'];
          if (nestedData is Map<String, dynamic>) {
            targetMap = nestedData;
            if (nestedData.containsKey('top') || nestedData.containsKey('carousel') || nestedData.containsKey('middle')) {
              final parsedData = BannersData.fromJson(nestedData);
              if (middleBanners.isEmpty) {
                middleBanners = parsedData.middle ?? [];
              }
              middleTitle ??= parsedData.middleTitle;
            }
          } else if (nestedData is List) {
            combinedBanners.addAll(nestedData);
            targetMap = rawData;
          }
        } else {
          targetMap = rawData;
        }
      }

      // Collect banners from all known positional keys for the general bannerData list
      if (targetMap != null) {
        final List<String> keysToCollect = ['top', 'carousel', 'sidebar', 'full', 'middle', 'bottom', 'general', 'banners', 'home_top', 'all_tab', 'all_homepage', 'home_carousel', 'home_sidebar'];
        for (final key in keysToCollect) {
          if (targetMap.containsKey(key) && targetMap[key] is List) {
            combinedBanners.addAll(targetMap[key] as List);
          }
        }
      }

      print('BannerBloc: Collected ${combinedBanners.length} banners before deduplication');

      if (combinedBanners.isNotEmpty) {
        final Map<String, dynamic> uniqueBanners = {};
        for (var b in combinedBanners) {
          if (b is Map<String, dynamic>) {
            final id = b['id']?.toString() ?? b.hashCode.toString();
            uniqueBanners[id] = b;
          }
        }
        
        bannerData = uniqueBanners.values.map((data) {
          try {
            return Top.fromJson(data);
          } catch (e) {
            print('BannerBloc: Error parsing banner item: $e\nData: $data');
            return null;
          }
        }).whereType<Top>().toList();
      }

      print('BannerBloc: Middle banners: ${middleBanners.length} | Total: ${bannerData.length}');

      _hasReachedMax = combinedBanners.length < perPage;

      emit(BannerLoaded(
          message: 'Banners loaded',
          bannerData: bannerData,
          middleBanners: middleBanners,
          middleTitle: middleTitle,
          hasReachedMax: _hasReachedMax
      ));
    } catch (e, stacktrace) {
      print('BannerBloc Error: $e\n$stacktrace');
      emit(BannerFailed(error: e.toString()));
    }
  }
}
