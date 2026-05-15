import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_event.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_state.dart';

import '../../model/user_cart_model/cart_sync_action.dart';
import '../../screens/cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import '../../services/user_cart/user_cart_local.dart';
import '../../services/user_cart/user_cart_remote.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartLocalRepository localRepo;
  final CartRemoteRepository remoteRepo;

  Timer? _debounce;

  CartBloc(this.localRepo, this.remoteRepo)
      : super(CartInitial()) {
    on<LoadCart>(_onLoadCart);
    on<AddToCart>(_onAddToCart);
    on<UpdateCartQty>(_onUpdateQty);
    on<RemoveFromCart>(_onRemoveItem);
    on<RemoveLocally>(_onRemoveLocally);
    on<ClearCart>(_onClearCart);
    on<SyncLocalCart>(_onSyncLocalCart);
  }

  void _onLoadCart(LoadCart event, Emitter<CartState> emit) {
    emit(CartLoading());
    emit(CartLoaded(localRepo.getAllItems()));
  }

  Future<void> _onAddToCart(AddToCart event, Emitter<CartState> emit) async {
    emit(CartLoading());
    debugPrint('🌐 ADD TO SERVER → ${event.item.productId} ${event.item.variantId}');
    
    final blocContext = event.context;
    final getUserCartBloc = blocContext.read<GetUserCartBloc>();
    final shouldSync = blocContext.mounted;
    
    try {
      final res = await remoteRepo.addItemToCart(
        productVariantId: int.parse(event.item.variantId),
        storeId: int.parse(event.item.vendorId),
        quantity: event.item.quantity,
      );
      
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        
        // Handle both direct 'items' and nested 'cart.items' (backward compatibility)
        List<dynamic>? itemsList;
        if (data['items'] != null) {
          itemsList = data['items'] as List<dynamic>?;
        } else if (data['cart'] != null && data['cart']['items'] != null) {
          itemsList = data['cart']['items'] as List<dynamic>?;
        }
        
        if (itemsList != null) {
          final addedServerItem = itemsList.firstWhere(
            (serverItem) =>
                serverItem['product_variant_id'].toString() == event.item.variantId &&
                serverItem['store_id'].toString() == event.item.vendorId,
            orElse: () => null,
          );
          
          if (addedServerItem != null) {
            final serverCartItemId = addedServerItem['id'] as int;
            
            localRepo.addItemWithServerId(event.item, serverCartItemId);
            debugPrint('✅ ADDED TO SERVER → Server ID: $serverCartItemId');
            
            emit(CartLoaded(localRepo.getAllItems()));
            if (blocContext.mounted) {
              getUserCartBloc.add(FetchUserCart());
            }
            return;
          }
        }
        
        debugPrint('⚠️ Server response missing item - adding locally');
        localRepo.addItem(event.item);
        emit(CartLoaded(localRepo.getAllItems()));
        if (shouldSync) {
          _debouncedSync(blocContext);
        }
      } else {
        final errorMessage = res['message'] as String? ?? 'Failed to add to cart';
        debugPrint('❌ ADD FAILED → $errorMessage');
        emit(CartLoaded(localRepo.getAllItems(), errorMessage: errorMessage));
      }
    } catch (e) {
      debugPrint('❌ ADD ERROR → $e');
      localRepo.addItem(event.item);
      emit(CartLoaded(localRepo.getAllItems()));
      if (shouldSync) {
        _debouncedSync(blocContext);
      }
    }
  }

  void _onUpdateQty(UpdateCartQty event, Emitter<CartState> emit) {
    emit(CartLoading());

    // Just update quantity - it will automatically set the correct syncAction
    localRepo.updateQuantity(event.cartKey, event.quantity);

    emit(CartLoaded(localRepo.getAllItems()));
    _debouncedSync(event.context);
  }

  void _onRemoveItem(RemoveFromCart event, Emitter<CartState> emit) {
    emit(CartLoading());
    debugPrint('🗑 REMOVE → ${event.cartKey}');
    localRepo.markForDelete(event.cartKey);
    emit(CartLoaded(localRepo.getAllItems()));
    _debouncedSync(event.context);
  }

  void _onRemoveLocally(RemoveLocally event, Emitter<CartState> emit) {
    emit(CartLoading());
    debugPrint('🗑 REMOVE → ${event.cartKey}');
    localRepo.deleteLocally(event.cartKey);
    emit(CartLoaded(localRepo.getAllItems()));
    _debouncedSync(event.context);
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(CartLoading());
    debugPrint('🧹 CLEAR CART');
    localRepo.clearLocalCart();
    emit(CartLoaded([]));
    _debouncedSync(event.context);
  }

  void _debouncedSync(BuildContext context) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      add(SyncLocalCart(context: context));
    });
  }

  Future<void> _onSyncLocalCart(
      SyncLocalCart event,
      Emitter<CartState> emit,
      ) async {
    final pendingItems = localRepo.getPendingSyncItems();

    if (pendingItems.isEmpty) {
      debugPrint('✅ SYNC → Nothing to sync');
      return;
    }

    debugPrint('🌐 SYNC START → ${pendingItems.length} items');

    for (final item in pendingItems) {
      try {
        debugPrint('🔄 Processing sync for ${item.cartKey} | Action: ${item.syncAction} | ServerID: ${item.serverCartItemId}');

        switch (item.syncAction) {
          case CartSyncAction.add:
            debugPrint('🌐 ADD API → ${item.cartKey}');
            final res = await remoteRepo.addItemToCart(
              productVariantId: int.parse(item.variantId),
              storeId: int.parse(item.vendorId),
              quantity: item.quantity,
            );
            if (res['success'] == true && res['data'] != null) {
              final data = res['data'];
              
              // Handle both direct 'items' and nested 'cart.items'
              List<dynamic>? itemsList;
              if (data['items'] != null) {
                itemsList = data['items'] as List<dynamic>?;
              } else if (data['cart'] != null && data['cart']['items'] != null) {
                itemsList = data['cart']['items'] as List<dynamic>?;
              }

              if (itemsList != null) {
                final addedServerItem = itemsList.firstWhere(
                      (serverItem) =>
                  serverItem['product_variant_id'].toString() == item.variantId &&
                      serverItem['store_id'].toString() == item.vendorId,
                  orElse: () => null,
                );

                if (addedServerItem != null) {
                  final serverCartItemId = addedServerItem['id'] as int;

                  localRepo.markSynced(
                    item.cartKey,
                    serverCartItemId: serverCartItemId,
                  );

                  debugPrint('✅ ADD synced locally with serverCartItemId: $serverCartItemId');
                } else {
                  debugPrint('⚠️ Could not find specific matching item in server response, but ADD was successful');
                  // Mark as synced anyway with Action.none if it was successful, to prevent loops
                  // We'll get the real serverCartItemId on the next full getCart fetch
                  localRepo.markSynced(item.cartKey);
                }
              }
            } else {
              String errorMessage = res['message'] as String? ?? 'Failed to add item to cart';
              if(errorMessage.toLowerCase().contains('store')){
                errorMessage = 'Store was not available';
              }
              
              localRepo.deleteLocally(item.cartKey);
              // ← THIS LINE MUST BE EXACTLY LIKE THIS
              emit(CartLoaded(localRepo.getAllItems(), errorMessage: errorMessage));
              return;
            }

            break;

          case CartSyncAction.update:
          // ALWAYS get the absolute latest item from Hive
            final freshItem = localRepo.getItemByKey(item.cartKey);

            if (freshItem == null) {
              debugPrint('❌ Item disappeared from local storage: ${item.cartKey}');
              break;
            }

            if (freshItem.serverCartItemId == null) {
              debugPrint('❌ No serverCartItemId yet for ${item.cartKey}');
              debugPrint('   Current syncAction: ${freshItem.syncAction}');
              debugPrint('   Quantity: ${freshItem.quantity}');
              debugPrint('   Will retry on next sync');
              break;
            }

            try {
              await remoteRepo.updateItemQuantity(
                cartItemId: freshItem.serverCartItemId!,
                quantity: freshItem.quantity,
              );

              localRepo.markSynced(item.cartKey);
              debugPrint('✅ UPDATE successful → qty: ${freshItem.quantity}, serverId: ${freshItem.serverCartItemId}');
            } catch (e) {
              debugPrint('❌ UPDATE API failed → $e');
              String errorMessage = e.toString();
              if(errorMessage.toLowerCase().contains('store')){
                errorMessage = 'Store was not available';
              }
              emit(CartLoaded(localRepo.getAllItems(), errorMessage: errorMessage));
            }
            break;

          case CartSyncAction.delete:
            if (item.serverCartItemId != null) {
              try {
                await remoteRepo.removeItemFromCart(
                  cartItemId: item.serverCartItemId!,
                );
                debugPrint('✅ DELETE API successful → ${item.cartKey}');
              } catch (e) {
                debugPrint('❌ DELETE API failed → $e');
                String errorMessage = e.toString();
                if(errorMessage.toLowerCase().contains('store')){
                  errorMessage = 'Store was not available';
                  emit(CartLoaded(localRepo.getAllItems(), errorMessage: errorMessage));
                }
              }
            }

            // Remove from local storage after server sync
            localRepo.removeLocal(item.cartKey);
            debugPrint('✅ Removed locally → ${item.cartKey}');
            break;

          case CartSyncAction.none:
            break;
        }
      } catch (e, stackTrace) {
        debugPrint('❌ SYNC FAILED → ${item.cartKey} → $e');
        debugPrint('Stack trace: ${stackTrace.toString()}');
        // Continue with other items instead of returning
        continue;
      }
    }

    debugPrint('✅ SYNC COMPLETE');
    emit(CartLoaded(localRepo.getAllItems()));

    if(event.context.mounted){
      event.context.read<GetUserCartBloc>().add(FetchUserCart());
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}





/*
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_event.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_state.dart';

import '../../model/user_cart_model/cart_sync_action.dart';
import '../../services/user_cart/user_cart_local.dart';
import '../../services/user_cart/user_cart_remote.dart';



class CartBloc extends Bloc<CartEvent, CartState> {
  final CartLocalRepository localRepo;
  final CartRemoteRepository remoteRepo;

  Timer? _debounce;

  CartBloc(this.localRepo, this.remoteRepo)
      : super(CartInitial()) {
    on<LoadCart>(_onLoadCart);
    on<AddToCart>(_onAddToCart);
    on<UpdateCartQty>(_onUpdateQty);
    on<RemoveFromCart>(_onRemoveItem);
    on<ClearCart>(_onClearCart);
    on<SyncCart>(_onSyncCart);
  }

  void _onLoadCart(LoadCart event, Emitter<CartState> emit) {
    emit(CartLoaded(localRepo.getAllItems()));
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    emit(CartLoading());
    debugPrint('ADD → ${event.item.productId} ${event.item.variantId}');
    localRepo.addItem(event.item);
    emit(CartLoaded(localRepo.getAllItems()));
    _debouncedSync();
  }

  void _onUpdateQty(UpdateCartQty event, Emitter<CartState> emit) {
    emit(CartLoading());
    localRepo.markForUpdate(event.cartKey);

    localRepo.updateQuantity(event.cartKey, event.quantity);

    emit(CartLoaded(localRepo.getAllItems()));
    _debouncedSync();
  }

  void _onRemoveItem(RemoveFromCart event, Emitter<CartState> emit) {
    emit(CartLoading());
    debugPrint('🗑 REMOVE → ${event.cartKey}');
    localRepo.markForDelete(event.cartKey);
    // add(LoadCart());
    emit(CartLoaded(localRepo.getAllItems()));
    _debouncedSync(); // Disabled auto-sync
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(CartLoading());
    debugPrint('🧹 CLEAR CART');
    localRepo.markAllForDelete();
    // add(LoadCart());
    emit(CartLoaded([]));
    _debouncedSync(); // Disabled auto-sync
  }

  void _debouncedSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      add(SyncCart());
    });
  }

  Future<void> _onSyncCart(
      SyncCart event,
      Emitter<CartState> emit,
      ) async {
    final pendingItems = localRepo.getPendingSyncItems();

    if (pendingItems.isEmpty) {
      debugPrint('✅ SYNC → Nothing to sync');
      return;
    }

    debugPrint('🌐 SYNC START → ${pendingItems.length} items');

    for (final item in pendingItems) {
      try {

          print('OFIUBEFb ${item.syncAction}');
        switch (item.syncAction) {
          case CartSyncAction.add:
            debugPrint('🌐 ADD API → ${item.cartKey}');
            final res = await remoteRepo.addItemToCart(
              productVariantId: int.parse(item.variantId),
              storeId: int.parse(item.vendorId),
              quantity: item.quantity,
            );
            if (res['success'] == true && res['data'] != null) {
              final itemsList = res['data']['items'] as List<dynamic>?;

              if (itemsList != null) {
                // Find the item that matches the one we just added
                final addedServerItem = itemsList.firstWhere(
                      (serverItem) =>
                  serverItem['product_variant_id'].toString() == item.variantId &&
                      serverItem['store_id'].toString() == item.vendorId,
                  orElse: () => null,
                );

                if (addedServerItem != null) {
                  final serverCartItemId = addedServerItem['id'] as int;

                  localRepo.markSynced(
                    item.cartKey,
                    serverCartItemId: serverCartItemId,
                  );

                  debugPrint('✅ Synced locally with serverCartItemId: $serverCartItemId');
                  debugPrint('Sync Action: ${item.syncAction}');
                } else {
                  debugPrint('⚠️ Could not find matching item in server response');
                  // Optionally retry or handle gracefully
                }
              }
            }
            break;

          case CartSyncAction.update:
            debugPrint('🌐 UPDATE API → ${item.cartKey} (qty: ${item.serverCartItemId})');

            // ALWAYS get the absolute latest item from Hive
            final freshItem = localRepo.getItemByKey(item.cartKey);

            if (freshItem == null) {
              debugPrint('❌ Item disappeared from local storage: ${item.cartKey}');
              break;
            }

            if (item.serverCartItemId == null) {
              debugPrint('❌ No serverCartItemId yet — likely ADD sync still pending for ${item.serverCartItemId}');
              debugPrint('   Current syncAction: ${freshItem.syncAction}');
              debugPrint('   Will retry on next sync');
              // Do NOT mark synced — keep it pending
              break;
            }

            try {
              await remoteRepo.updateItemQuantity(
                cartItemId: freshItem.serverCartItemId!,
                quantity: freshItem.quantity,
              );

              // Only mark synced after successful update
              localRepo.markSynced(item.cartKey);
              debugPrint('✅ UPDATE successful → qty: ${freshItem.quantity}, serverId: ${freshItem.serverCartItemId}');
            } catch (e) {
              debugPrint('❌ UPDATE API failed → $e');
              // Don't mark synced on error — will retry later
              // Optionally break or continue
            }
            break;

          case CartSyncAction.delete:
            debugPrint('🌐 DELETE API → ${item.cartKey}');
            if (item.serverCartItemId != null) {
              await remoteRepo.removeItemFromCart(
                cartItemId: item.serverCartItemId!,
              );
            }
            localRepo.removeLocal(item.cartKey);
            break;

          case CartSyncAction.none:
            break;
        }
      } catch (e, stackTrace) {
        debugPrint('❌ SYNC FAILED → ${item.cartKey} → $e');
        debugPrint('❌ SYNC FAILED → ${item.cartKey} → ${stackTrace.toString()}');
        return; // retry later
      }
    }

    debugPrint('✅ SYNC COMPLETE');
    emit(CartLoaded(localRepo.getAllItems()));
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

}
*/
