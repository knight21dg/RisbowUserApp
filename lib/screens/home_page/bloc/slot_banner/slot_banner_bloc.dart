import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/home_page/model/slot_banner_model.dart';
import 'package:hyper_local/screens/home_page/repo/slot_banner_repo.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class SlotBannerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchSlotBanners extends SlotBannerEvent {
  final String position;
  final String? storeSlug;

  FetchSlotBanners({required this.position, this.storeSlug});

  @override
  List<Object?> get props => [position, storeSlug];
}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class SlotBannerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SlotBannerInitial extends SlotBannerState {}

class SlotBannerLoading extends SlotBannerState {}

class SlotBannerLoaded extends SlotBannerState {
  final List<SlotBannerModel> banners;
  SlotBannerLoaded({required this.banners});

  @override
  List<Object?> get props => [banners];
}

class SlotBannerEmpty extends SlotBannerState {}

class SlotBannerFailed extends SlotBannerState {
  final String error;
  SlotBannerFailed({required this.error});

  @override
  List<Object?> get props => [error];
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class SlotBannerBloc extends Bloc<SlotBannerEvent, SlotBannerState> {
  final SlotBannerRepository _repo = SlotBannerRepository();

  SlotBannerBloc() : super(SlotBannerInitial()) {
    on<FetchSlotBanners>(_onFetch);
  }

  Future<void> _onFetch(
    FetchSlotBanners event,
    Emitter<SlotBannerState> emit,
  ) async {
    emit(SlotBannerLoading());
    try {
      final json = await _repo.fetchSlotBanners(
        position: event.position,
        storeSlug: event.storeSlug,
      );

      final response = SlotBannerResponse.fromJson(json);

      if (response.banners.isEmpty) {
        emit(SlotBannerEmpty());
      } else {
        emit(SlotBannerLoaded(banners: response.banners));
      }
    } catch (e) {
      emit(SlotBannerFailed(error: e.toString()));
    }
  }
}
