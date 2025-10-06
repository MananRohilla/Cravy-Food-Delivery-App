import 'package:bloc/bloc.dart';
import 'package:core/entities.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'cart_event.dart';
part 'cart_state.dart';

/// Cart BLoC - Manages shopping cart state following BLoC architecture
/// Implements single responsibility principle for cart management
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddItemToCartEvent>(_onAddItemToCart);
    on<RemoveItemFromCartEvent>(_onRemoveItemFromCart);
    on<UpdateItemQuantityEvent>(_onUpdateItemQuantity);
    on<ClearCartEvent>(_onClearCart);
    on<ApplyDiscountEvent>(_onApplyDiscount);
  }

  void _onAddItemToCart(
    AddItemToCartEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      debugPrint('Adding item to cart: ${event.menuItem.name}');
      
      final existingItemIndex = state.items.indexWhere(
        (item) => item.menuItem.id == event.menuItem.id,
      );

      List<CartItem> updatedItems;
      
      if (existingItemIndex >= 0) {
        // Update existing item quantity
        updatedItems = List.from(state.items);
        final existingItem = updatedItems[existingItemIndex];
        updatedItems[existingItemIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + (event.quantity ?? 1),
        );
      } else {
        // Add new item
        final newCartItem = CartItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          menuItem: event.menuItem,
          quantity: event.quantity ?? 1,
          selectedOptions: event.selectedOptions ?? [],
        );
        updatedItems = [...state.items, newCartItem];
      }

      final newState = state.copyWith(
        items: updatedItems,
        status: CartStatus.updated,
      );

      emit(newState);
    } catch (error) {
      debugPrint('Error adding item to cart: $error');
      emit(state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Failed to add item to cart',
      ));
    }
  }

  void _onRemoveItemFromCart(
    RemoveItemFromCartEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      debugPrint('Removing item from cart: ${event.cartItemId}');
      
      final updatedItems = state.items
          .where((item) => item.id != event.cartItemId)
          .toList();

      emit(state.copyWith(
        items: updatedItems,
        status: CartStatus.updated,
      ));
    } catch (error) {
      debugPrint('Error removing item from cart: $error');
      emit(state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Failed to remove item from cart',
      ));
    }
  }

  void _onUpdateItemQuantity(
    UpdateItemQuantityEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      debugPrint('Updating item quantity: ${event.cartItemId} to ${event.quantity}');
      
      if (event.quantity <= 0) {
        add(RemoveItemFromCartEvent(cartItemId: event.cartItemId));
        return;
      }

      final updatedItems = state.items.map((item) {
        if (item.id == event.cartItemId) {
          return item.copyWith(quantity: event.quantity);
        }
        return item;
      }).toList();

      emit(state.copyWith(
        items: updatedItems,
        status: CartStatus.updated,
      ));
    } catch (error) {
      debugPrint('Error updating item quantity: $error');
      emit(state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Failed to update item quantity',
      ));
    }
  }

  void _onClearCart(
    ClearCartEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      debugPrint('Clearing cart');
      emit(const CartState());
    } catch (error) {
      debugPrint('Error clearing cart: $error');
      emit(state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Failed to clear cart',
      ));
    }
  }

  void _onApplyDiscount(
    ApplyDiscountEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      debugPrint('Applying discount: ${event.discountCode}');
      
      // Simulate discount validation
      await Future.delayed(const Duration(milliseconds: 500));
      
      double discountAmount = 0.0;
      String? errorMessage;
      
      switch (event.discountCode.toUpperCase()) {
        case 'SAVE10':
          discountAmount = state.subtotal * 0.1;
          break;
        case 'SAVE20':
          discountAmount = state.subtotal * 0.2;
          break;
        case 'FIRSTORDER':
          discountAmount = state.subtotal * 0.15;
          break;
        default:
          errorMessage = 'Invalid discount code';
      }

      if (errorMessage != null) {
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: errorMessage,
        ));
        return;
      }

      emit(state.copyWith(
        discountAmount: discountAmount,
        discountCode: event.discountCode,
        status: CartStatus.updated,
      ));
    } catch (error) {
      debugPrint('Error applying discount: $error');
      emit(state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Failed to apply discount',
      ));
    }
  }
}