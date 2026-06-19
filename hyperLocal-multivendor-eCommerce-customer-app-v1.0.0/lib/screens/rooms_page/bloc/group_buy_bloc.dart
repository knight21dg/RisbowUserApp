import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/rooms_page/bloc/group_buy_event.dart';
import 'package:hyper_local/screens/rooms_page/bloc/group_buy_state.dart';
import 'package:hyper_local/screens/rooms_page/model/group_buy_models.dart';
import 'package:hyper_local/screens/rooms_page/repo/room_repository.dart';

class GroupBuyBloc extends Bloc<GroupBuyEvent, GroupBuyState> {
  final RoomRepository _repository = RoomRepository();
  GroupBuyRoom? _currentRoom;

  GroupBuyBloc() : super(GroupBuyInitial()) {
    on<LoadMyRooms>(_onLoadMyRooms);
    on<LoadDiscoverRooms>(_onLoadDiscoverRooms);
    on<LoadRoomDetails>(_onLoadRoomDetails);
    on<CreateRoom>(_onCreateRoom);
    on<JoinRoom>(_onJoinRoom);
    on<LeaveRoom>(_onLeaveRoom);
    on<EndRoom>(_onEndRoom);
    on<LoadGroupProducts>(_onLoadGroupProducts);
    on<AddProductToRoom>(_onAddProductToRoom);
    on<UpdateCartItem>(_onUpdateCartItem);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<Checkout>(_onCheckout);
  }

  Future<void> _onLoadMyRooms(
    LoadMyRooms event,
    Emitter<GroupBuyState> emit,
  ) async {
    emit(GroupBuyLoading());
    try {
      final rooms = await _repository.getMyRooms(query: event.query);
      emit(MyRoomsLoaded(rooms: rooms, query: event.query));
    } catch (e) {
      emit(GroupBuyError(message: 'Failed to load rooms: $e'));
    }
  }

  Future<void> _onLoadDiscoverRooms(
    LoadDiscoverRooms event,
    Emitter<GroupBuyState> emit,
  ) async {
    emit(GroupBuyLoading());
    try {
      final rooms = await _repository.discoverRooms(query: event.query);
      emit(DiscoverRoomsLoaded(rooms: rooms, query: event.query));
    } catch (e) {
      emit(GroupBuyError(message: 'Failed to load discover rooms: $e'));
    }
  }

  Future<void> _onLoadRoomDetails(
    LoadRoomDetails event,
    Emitter<GroupBuyState> emit,
  ) async {
    emit(GroupBuyLoading());
    try {
      final room = await _repository.getRoomDetails(event.code);
      if (room != null) {
        _currentRoom = room;
        emit(RoomDetailsLoaded(room: room));
      } else {
        emit(const GroupBuyError(message: 'Room not found'));
      }
    } catch (e) {
      emit(GroupBuyError(message: 'Failed to load room: $e'));
    }
  }

  Future<void> _onCreateRoom(
    CreateRoom event,
    Emitter<GroupBuyState> emit,
  ) async {
    emit(GroupBuyLoading());
    try {
      final room = await _repository.createRoom(
        name: event.name,
        maxMembers: event.maxMembers,
        isPublic: event.isPublic,
        expiresAt: event.expiresAt,
      );
      if (room != null) {
        _currentRoom = room;
        emit(RoomCreated(room: room));
      } else {
        emit(const GroupBuyError(message: 'Failed to create room'));
      }
    } catch (e) {
      emit(GroupBuyError(message: 'Failed to create room: $e'));
    }
  }

  Future<void> _onJoinRoom(
    JoinRoom event,
    Emitter<GroupBuyState> emit,
  ) async {
    emit(GroupBuyLoading());
    try {
      final room = await _repository.joinRoom(event.code);
      if (room != null) {
        _currentRoom = room;
        emit(RoomJoined(room: room));
      } else {
        emit(const GroupBuyError(message: 'Cannot join this room'));
      }
    } catch (e) {
      emit(GroupBuyError(message: 'Failed to join room: $e'));
    }
  }

  Future<void> _onLeaveRoom(
    LeaveRoom event,
    Emitter<GroupBuyState> emit,
  ) async {
    emit(GroupBuyLoading());
    try {
      if (_currentRoom != null && _currentRoom!.id == event.roomId) {
        final updated = await _repository.leaveRoom(_currentRoom!);
        if (updated != null) {
          emit(RoomLeft(roomId: event.roomId));
        }
      }
    } catch (e) {
      emit(GroupBuyError(message: 'Failed to leave room: $e'));
    }
  }

  Future<void> _onEndRoom(
    EndRoom event,
    Emitter<GroupBuyState> emit,
  ) async {
    emit(GroupBuyLoading());
    try {
      if (_currentRoom != null && _currentRoom!.id == event.roomId) {
        final updated = await _repository.endRoom(_currentRoom!);
        if (updated != null) {
          _currentRoom = updated;
          emit(RoomEnded(room: updated));
        }
      }
    } catch (e) {
      emit(GroupBuyError(message: 'Failed to end room: $e'));
    }
  }

  Future<void> _onLoadGroupProducts(
    LoadGroupProducts event,
    Emitter<GroupBuyState> emit,
  ) async {
    emit(GroupBuyLoading());
    try {
      final products = await _repository.getGroupProducts(
        search: event.search,
        category: event.category,
        sort: event.sort,
      );
      emit(GroupProductsLoaded(products: products, room: _currentRoom));
    } catch (e) {
      emit(GroupBuyError(message: 'Failed to load products: $e'));
    }
  }

  Future<void> _onAddProductToRoom(
    AddProductToRoom event,
    Emitter<GroupBuyState> emit,
  ) async {
    try {
      if (_currentRoom == null || _currentRoom!.id != event.roomId) {
        emit(const GroupBuyError(message: 'Room not loaded'));
        return;
      }
      final product = GroupBuyProduct(
        id: event.productId,
        name: '',
        category: '',
        price: 0,
        groupPrice: 0,
        inStock: true,
        stock: 0,
      );
      final updated = await _repository.addItemToRoom(
        room: _currentRoom!,
        product: product,
        quantity: event.quantity,
      );
      if (updated != null) {
        _currentRoom = updated;
        emit(ProductAddedToRoom(room: updated, product: product));
      }
    } catch (e) {
      emit(GroupBuyError(message: 'Failed to add product: $e'));
    }
  }

  Future<void> _onUpdateCartItem(
    UpdateCartItem event,
    Emitter<GroupBuyState> emit,
  ) async {
    try {
      if (_currentRoom == null || _currentRoom!.id != event.roomId) {
        emit(const GroupBuyError(message: 'Room not loaded'));
        return;
      }
      final item = _currentRoom!.cartItems.firstWhere(
        (i) => i.id == event.itemId,
        orElse: () => throw Exception('Item not found'),
      );
      final updated = await _repository.updateItemQuantity(
        room: _currentRoom!,
        item: item,
        quantity: event.quantity,
      );
      if (updated != null) {
        _currentRoom = updated;
        emit(CartUpdated(room: updated));
      }
    } catch (e) {
      emit(GroupBuyError(message: 'Failed to update cart: $e'));
    }
  }

  Future<void> _onRemoveFromCart(
    RemoveFromCart event,
    Emitter<GroupBuyState> emit,
  ) async {
    try {
      if (_currentRoom == null || _currentRoom!.id != event.roomId) {
        emit(const GroupBuyError(message: 'Room not loaded'));
        return;
      }
      final updated = await _repository.removeFromRoomCart(
        room: _currentRoom!,
        itemId: event.itemId,
      );
      if (updated != null) {
        _currentRoom = updated;
        emit(CartUpdated(room: updated));
      }
    } catch (e) {
      emit(GroupBuyError(message: 'Failed to remove from cart: $e'));
    }
  }

  Future<void> _onCheckout(
    Checkout event,
    Emitter<GroupBuyState> emit,
  ) async {
    emit(GroupBuyLoading());
    try {
      final payload = GroupBuyCheckoutPayload(
        roomCode: event.roomCode,
        address: event.address,
        paymentToken: event.paymentMethod,
        items: event.items
            .map<GroupBuyCheckoutItem>((item) => GroupBuyCheckoutItem(
                  productId: item['product_id'] as int,
                  quantity: item['quantity'] as int,
                ))
            .toList(),
      );
      final result = await _repository.confirmGroupBuyPurchase(payload);
      if (result != null && result['success'] == true) {
        final totalVal = result['total'];
        double total = 0.0;
        if (totalVal is double) {
          total = totalVal;
        } else if (totalVal is int) {
          total = totalVal.toDouble();
        } else if (totalVal is String) {
          total = double.tryParse(totalVal) ?? 0.0;
        }
        emit(CheckoutSuccess(
          orderId: result['order_id'] ?? 'ORD-UNKNOWN',
          total: total,
          roomCode: _currentRoom?.code ?? '',
        ));
      } else {
        emit(GroupBuyError(
          message: result?['message'] ?? 'Checkout failed',
        ));
      }
    } catch (e) {
      emit(GroupBuyError(message: 'Failed to checkout: $e'));
    }
  }
}