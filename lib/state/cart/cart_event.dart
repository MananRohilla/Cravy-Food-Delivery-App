part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddItemToCartEvent extends CartEvent {
  const AddItemToCartEvent({
    required this.menuItem,
    this.quantity,
    this.selectedOptions,
  });

  final MenuItem menuItem;
  final int? quantity;
  final List<MenuItemOption>? selectedOptions;

  @override
  List<Object?> get props => [menuItem, quantity, selectedOptions];
}

class RemoveItemFromCartEvent extends CartEvent {
  const RemoveItemFromCartEvent({required this.cartItemId});

  final String cartItemId;

  @override
  List<Object?> get props => [cartItemId];
}

class UpdateItemQuantityEvent extends CartEvent {
  const UpdateItemQuantityEvent({
    required this.cartItemId,
    required this.quantity,
  });

  final String cartItemId;
  final int quantity;

  @override
  List<Object?> get props => [cartItemId, quantity];
}

class ClearCartEvent extends CartEvent {}

class ApplyDiscountEvent extends CartEvent {
  const ApplyDiscountEvent({required this.discountCode});

  final String discountCode;

  @override
  List<Object?> get props => [discountCode];
}