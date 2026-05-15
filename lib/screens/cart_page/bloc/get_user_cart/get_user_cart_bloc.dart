import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:hyper_local/screens/cart_page/model/get_cart_model.dart';
import 'package:hyper_local/screens/cart_page/repo/cart_repository.dart';
import '../../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../../model/user_cart_model/user_cart.dart';
import '../../../../services/user_cart/user_cart_local.dart';
import '../../../../services/user_cart/user_cart_remote.dart';

part 'get_user_cart_state.dart';
part 'get_user_cart_event.dart';

class GetUserCartBloc extends Bloc<GetUserCartEvent, GetUserCartState> {
  GetUserCartBloc(this.cartBloc) : super(GetUserCartInitial()) {
    on<FetchUserCart>(_onFetchUserCart);
    on<RefreshUserCart>(_onRefreshUserCart);
    on<SyncCart>(_onSyncCart);
    on<SyncServerCartToLocal>(_onSyncServerCartToLocal);
  }

  final CartRepository repository = CartRepository();
  final localRepo = CartLocalRepository(Hive.box<UserCart>('cartBox'));
  final CartBloc cartBloc;
  final CartBloc localCartBloc = CartBloc(CartLocalRepository(Hive.box<UserCart>('cartBox')),
      CartRemoteRepository());
  List<GetCartModel> cartData = [];
  bool isUpdated = false;
  List<String> productSlug = [];
  int totalCartItems = 0;

  Future<void> _onFetchUserCart(FetchUserCart event, Emitter<GetUserCartState> emit) async {
    emit(GetUserCartLoading());
    try{
      final getCartData = await repository.getCartItems(
        addressId: event.addressId,
        promoCode: event.promoCode,
        rushDelivery: event.rushDelivery,
        useWallet: event.useWallet
      );

      cartData = getCartData;
      
      if (cartData.isEmpty) {
        emit(GetUserCartFailed(error: 'Failed to load cart'));
        return;
      }
      
      if (cartData.first.data == null) {
        // Server says cart is empty or failed
        final message = cartData.isNotEmpty ? cartData.first.message ?? '' : '';

        if (message.toLowerCase().contains('empty') ||
            (getCartData.isNotEmpty && getCartData.first.data?.items?.isEmpty == true)) {

          // Check if local cart has items (synced or pending sync) that shouldn't be cleared
          final localItems = localRepo.getAllItems();
          final hasLocalItems = localItems.isNotEmpty;
          
          // Don't clear local cart if:
          // 1. Local cart has items (either synced or pending sync)
          // This prevents clearing local cart after a sync operation when server hasn't reflected the changes yet
          if (hasLocalItems) {
            debugPrint('🛒 Server cart is EMPTY but local has $localItems.length item(s) - preserving local cart');
            
            // Still emit loaded state but keep local items
            emit(GetUserCartLoaded(
              cartData: cartData,
              message: 'Cart items preserved locally',
            ));
            return;
          }

          debugPrint('🛒 Server cart is EMPTY → Clearing local cart');

          // CLEAR LOCAL HIVE CART (only when truly empty, e.g., fresh app load)
          localRepo.clearLocalCart();

          // Reload CartBloc to reflect empty state
          cartBloc.add(LoadCart());
          debugPrint('🔄 CartBloc reloaded (empty cart)');
        }

        // Emit loaded state even if empty
        emit(GetUserCartLoaded(
          cartData: cartData,
          message: message,
        ));

        return;
      }

      if(getCartData.first.success == true) {

        if (cartData.isNotEmpty && cartData.first.data?.items != null) {
          productSlug = cartData.first.data!.items!
              .where((item) => item.product != null)
              .map((item) => item.product!.slug ?? '')
              .toList();
        }

        if(event.isRefresh == false){
          // 🔄 SYNC SERVER CART TO LOCAL STORAGE
          if (cartData.isNotEmpty && cartData.first.data?.items != null) {
            final serverItems = cartData.first.data!.items!;

            debugPrint('🔄 Starting sync: ${serverItems.length} server items');

            // Convert to sync format
            final serverItemsList = serverItems.map((item) {
              final product = item.product;
              final variant = item.variant;
              final mapped = {
                'id': item.id,
                'product_id': item.product?.id,
                'product_variant_id': item.productVariantId,
                'variant_name': item.variant?.title ?? '',
                'store_id': item.storeId,
                'name': product?.name ?? variant?.title ?? '',
                'image': product?.image ?? variant?.image ?? '',
                'price': variant?.price ?? 0,
                'special_price': variant?.specialPrice ?? 0,
                'quantity': item.quantity,
                'stock': variant?.stock ?? 0,
                'cart_item_id': item.id ?? 0
              };
              debugPrint('🔍 Mapping server item: ${item.product?.id}_${item.productVariantId} → id: ${item.id}, qty: ${item.quantity}');
              return mapped;
            }).toList();

            try {
              // Sync to local storage (no delay needed)
              localRepo.syncServerCartToLocal(serverItemsList);
              debugPrint('✅ Server cart synced to local storage');

              // Single CartBloc reload after sync
              cartBloc.add(LoadCart());
              debugPrint('🔄 CartBloc reloaded after sync');
            } catch (syncError, stackTrace) {
              debugPrint('❌ Sync failed: $syncError');
              debugPrint('Stack: $stackTrace');
            }

            // Update product slugs
            productSlug = serverItems
                .map((item) => item.product?.slug ?? '')
                .toList();
          }
          else {
            debugPrint('⚠️ No items to sync');
          }
        }

        totalCartItems = cartData.first.data?.itemsCount ?? 0;
        
        // Emit state FIRST, then notify bloc (no delay)
        emit(GetUserCartLoaded(
          cartData: cartData,
          message: cartData.first.message ?? ''
        ));
      } else {
        emit(GetUserCartLoaded(
          cartData: cartData,
          message: getCartData.first.message ?? ''
        ));
      }
    }catch (e) {
      emit(GetUserCartFailed(error: e.toString()));
    }
  }

  Future<void> _onRefreshUserCart(RefreshUserCart event, Emitter<GetUserCartState> emit) async {
    try{
      emit(GetUserCartInitial());
      Future.microtask((){
        add(FetchUserCart(
          addressId: event.addressId,
          promoCode: event.promoCode,
          rushDelivery: event.rushDelivery,
          useWallet: event.useWallet,
          isRefresh: true
        ));
      });
    }catch(e) {
      emit(GetUserCartFailed(error: e.toString()));
    }
  }

  Future<void> _onSyncCart (SyncCart event, Emitter<GetUserCartState> emit) async {
    emit(UserCartInitialLoading());
    try{
      final response = await repository.syncCart(items: localRepo.createSyncPayload());

      if(response['success'] == true){
        add(FetchUserCart());
      } else {
        emit(GetUserCartFailed(error: response['message'].toString()));
      }
    }catch(e) {
      emit(GetUserCartFailed(error: e.toString()));
    }
  }

  Future<void> _onSyncServerCartToLocal(
      SyncServerCartToLocal event,
      Emitter<GetUserCartState> emit,
      ) async {
    debugPrint('🔄 Manual sync triggered');

    if (event.serverItems.isEmpty) {
      debugPrint('⚠️ No server items to sync');
      return;
    }

    try {
      localRepo.syncServerCartToLocal(event.serverItems);

      // Reload CartBloc
      cartBloc.add(LoadCart());
      debugPrint('🔄 CartBloc reloaded after manual sync');
        } catch (e) {
      debugPrint('❌ Manual sync failed: $e');
    }
  }

}