import 'package:flutter_bloc/flutter_bloc.dart';
import '../repo/weekly_rooms_repo.dart';

abstract class WeeklyRoomsEvent {}
class FetchActiveRooms extends WeeklyRoomsEvent {}
class FetchRoomDetails extends WeeklyRoomsEvent { final int roomId; FetchRoomDetails(this.roomId); }
class FetchInstanceDetails extends WeeklyRoomsEvent { final int instanceId; FetchInstanceDetails(this.instanceId); }
class StartNewPrivateGroup extends WeeklyRoomsEvent { final int roomId; StartNewPrivateGroup(this.roomId); }
class JoinPrivateGroup extends WeeklyRoomsEvent { final String code; JoinPrivateGroup(this.code); }

abstract class WeeklyRoomsState {}
class WeeklyRoomsInitial extends WeeklyRoomsState {}
class WeeklyRoomsLoading extends WeeklyRoomsState {}
class ActiveRoomsLoaded extends WeeklyRoomsState { final List<dynamic> rooms; ActiveRoomsLoaded(this.rooms); }
class RoomDetailsLoaded extends WeeklyRoomsState { final Map<String, dynamic> data; RoomDetailsLoaded(this.data); }
class InstanceDetailsLoaded extends WeeklyRoomsState { final Map<String, dynamic> data; InstanceDetailsLoaded(this.data); }
class GroupJoinSuccess extends WeeklyRoomsState { final Map<String, dynamic> data; GroupJoinSuccess(this.data); }
class WeeklyRoomsError extends WeeklyRoomsState { final String message; WeeklyRoomsError(this.message); }

class WeeklyRoomsBloc extends Bloc<WeeklyRoomsEvent, WeeklyRoomsState> {
  final WeeklyRoomsRepo repo;

  WeeklyRoomsBloc(this.repo) : super(WeeklyRoomsInitial()) {
    on<FetchActiveRooms>((event, emit) async {
      emit(WeeklyRoomsLoading());
      try {
        final res = await repo.getActiveWeeklyRooms();
        if (res['success']) {
          emit(ActiveRoomsLoaded(res['data']));
        } else {
          emit(WeeklyRoomsError(res['message'] ?? 'Failed to load rooms'));
        }
      } catch (e) {
        emit(WeeklyRoomsError(e.toString()));
      }
    });

    on<FetchRoomDetails>((event, emit) async {
      emit(WeeklyRoomsLoading());
      try {
        final res = await repo.getRoomDetails(event.roomId);
        if (res['success']) {
          emit(RoomDetailsLoaded(res['data']));
        } else {
          emit(WeeklyRoomsError(res['message'] ?? 'Failed to load room details'));
        }
      } catch (e) {
        emit(WeeklyRoomsError(e.toString()));
      }
    });

    on<FetchInstanceDetails>((event, emit) async {
      // Don't emit loading here to allow silent background polling
      try {
        final res = await repo.getInstanceDetails(event.instanceId);
        if (res['success']) {
          emit(InstanceDetailsLoaded(res['data']));
        } else {
          emit(WeeklyRoomsError(res['message'] ?? 'Failed to load instance details'));
        }
      } catch (e) {
        emit(WeeklyRoomsError(e.toString()));
      }
    });

    on<StartNewPrivateGroup>((event, emit) async {
      emit(WeeklyRoomsLoading());
      try {
        final res = await repo.joinWeeklyRoom(event.roomId);
        if (res['success']) {
          emit(GroupJoinSuccess(res));
        } else {
          emit(WeeklyRoomsError(res['message'] ?? 'Failed to start group'));
        }
      } catch (e) {
        emit(WeeklyRoomsError(e.toString()));
      }
    });

    on<JoinPrivateGroup>((event, emit) async {
      emit(WeeklyRoomsLoading());
      try {
        final res = await repo.joinInstance(event.code);
        if (res['success']) {
          emit(GroupJoinSuccess(res));
        } else {
          emit(WeeklyRoomsError(res['message'] ?? 'Failed to join group'));
        }
      } catch (e) {
        emit(WeeklyRoomsError(e.toString()));
      }
    });
  }
}
