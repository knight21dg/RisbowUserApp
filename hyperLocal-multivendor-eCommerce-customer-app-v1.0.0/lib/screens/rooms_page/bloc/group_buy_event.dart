import 'package:equatable/equatable.dart';

abstract class GroupBuyEvent extends Equatable {
  const GroupBuyEvent();

  @override
  List<Object?> get props => [];
}

class LoadMyRooms extends GroupBuyEvent {
  final String? query;
  const LoadMyRooms({this.query});

  @override
  List<Object?> get props => [query];
}

class LoadDiscoverRooms extends GroupBuyEvent {
  final String? query;
  const LoadDiscoverRooms({this.query});

  @override
  List<Object?> get props => [query];
}

class LoadRoomDetails extends GroupBuyEvent {
  final String code;
  const LoadRoomDetails({required this.code});

  @override
  List<Object?> get props => [code];
}

class CreateRoom extends GroupBuyEvent {
  final String name;
  final int maxMembers;
  final bool isPublic;
  final DateTime? expiresAt;

  const CreateRoom({
    required this.name,
    required this.maxMembers,
    required this.isPublic,
    this.expiresAt,
  });

  @override
  List<Object?> get props => [name, maxMembers, isPublic, expiresAt];
}

class JoinRoom extends GroupBuyEvent {
  final String code;
  const JoinRoom({required this.code});

  @override
  List<Object?> get props => [code];
}

class LeaveRoom extends GroupBuyEvent {
  final int roomId;
  const LeaveRoom({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class EndRoom extends GroupBuyEvent {
  final int roomId;
  const EndRoom({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class LoadGroupProducts extends GroupBuyEvent {
  final String? search;
  final String? category;
  final String? sort;

  const LoadGroupProducts({this.search, this.category, this.sort});

  @override
  List<Object?> get props => [search, category, sort];
}

class AddProductToRoom extends GroupBuyEvent {
  final int roomId;
  final int productId;
  final int quantity;

  const AddProductToRoom({
    required this.roomId,
    required this.productId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [roomId, productId, quantity];
}

class UpdateCartItem extends GroupBuyEvent {
  final int roomId;
  final int itemId;
  final int quantity;

  const UpdateCartItem({
    required this.roomId,
    required this.itemId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [roomId, itemId, quantity];
}

class RemoveFromCart extends GroupBuyEvent {
  final int roomId;
  final int itemId;

  const RemoveFromCart({required this.roomId, required this.itemId});

  @override
  List<Object?> get props => [roomId, itemId];
}

class Checkout extends GroupBuyEvent {
  final String roomCode;
  final Map<String, dynamic> address;
  final String paymentMethod;
  final List<Map<String, dynamic>> items;

  const Checkout({
    required this.roomCode,
    required this.address,
    required this.paymentMethod,
    required this.items,
  });

  @override
  List<Object?> get props => [roomCode, address, paymentMethod, items];
}