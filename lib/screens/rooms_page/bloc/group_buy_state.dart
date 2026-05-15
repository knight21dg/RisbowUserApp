import 'package:equatable/equatable.dart';
import 'package:hyper_local/screens/rooms_page/model/group_buy_models.dart';

abstract class GroupBuyState extends Equatable {
  const GroupBuyState();

  @override
  List<Object?> get props => [];
}

class GroupBuyInitial extends GroupBuyState {}

class GroupBuyLoading extends GroupBuyState {}

class MyRoomsLoaded extends GroupBuyState {
  final List<GroupBuyRoom> rooms;
  final String? query;

  const MyRoomsLoaded({required this.rooms, this.query});

  @override
  List<Object?> get props => [rooms, query];
}

class DiscoverRoomsLoaded extends GroupBuyState {
  final List<GroupBuyRoom> rooms;
  final String? query;

  const DiscoverRoomsLoaded({required this.rooms, this.query});

  @override
  List<Object?> get props => [rooms, query];
}

class RoomDetailsLoaded extends GroupBuyState {
  final GroupBuyRoom room;

  const RoomDetailsLoaded({required this.room});

  @override
  List<Object?> get props => [room];
}

class RoomCreated extends GroupBuyState {
  final GroupBuyRoom room;

  const RoomCreated({required this.room});

  @override
  List<Object?> get props => [room];
}

class RoomJoined extends GroupBuyState {
  final GroupBuyRoom room;

  const RoomJoined({required this.room});

  @override
  List<Object?> get props => [room];
}

class RoomLeft extends GroupBuyState {
  final int roomId;

  const RoomLeft({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class RoomEnded extends GroupBuyState {
  final GroupBuyRoom room;

  const RoomEnded({required this.room});

  @override
  List<Object?> get props => [room];
}

class GroupProductsLoaded extends GroupBuyState {
  final List<GroupBuyProduct> products;
  final GroupBuyRoom? room;

  const GroupProductsLoaded({required this.products, this.room});

  @override
  List<Object?> get props => [products, room];
}

class ProductAddedToRoom extends GroupBuyState {
  final GroupBuyRoom room;
  final GroupBuyProduct product;

  const ProductAddedToRoom({required this.room, required this.product});

  @override
  List<Object?> get props => [room, product];
}

class CartUpdated extends GroupBuyState {
  final GroupBuyRoom room;

  const CartUpdated({required this.room});

  @override
  List<Object?> get props => [room];
}

class CheckoutSuccess extends GroupBuyState {
  final String orderId;
  final double total;
  final String roomCode;

  const CheckoutSuccess({
    required this.orderId,
    required this.total,
    required this.roomCode,
  });

  @override
  List<Object?> get props => [orderId, total, roomCode];
}

class GroupBuyError extends GroupBuyState {
  final String message;

  const GroupBuyError({required this.message});

  @override
  List<Object?> get props => [message];
}