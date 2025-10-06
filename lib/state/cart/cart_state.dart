part of 'cart_bloc.dart';

enum CartStatus { initial, loading, updated, error }

class CartState extends Equatable {
  final List<CartItem> items;
  final CartStatus status;
  final String? errorMessage;
  final double discountAmount;
  final String? discountCode;

  const CartState({
    this.items = const [],
    this.status = CartStatus.initial,
    this.errorMessage,
    this.discountAmount = 0.0,
    this.discountCode,
  });

  double get subtotal {
    return items.fold(0.0, (total, item) {
      final itemPrice = item.menuItem.price;
      final optionsPrice = item.selectedOptions.fold(0.0, 
        (optTotal, option) => optTotal + option.additionalCost);
      return total + ((itemPrice + optionsPrice) * item.quantity);
    });
  }

  double get deliveryFee => subtotal > 25.0 ? 0.0 : 2.99;
  
  double get tax => subtotal * 0.08; // 8% tax
  
  double get totalAmount => subtotal + deliveryFee + tax - discountAmount;

  int get itemCount => items.fold(0, (total, item) => total + item.quantity);

  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItem>? items,
    CartStatus? status,
    String? errorMessage,
    double? discountAmount,
    String? discountCode,
  }) {
    return CartState(
      items: items ?? this.items,
      status: status ?? this.status,
      errorMessage: errorMessage,
      discountAmount: discountAmount ?? this.discountAmount,
      discountCode: discountCode ?? this.discountCode,
    );
  }

  @override
  List<Object?> get props => [
        items,
        status,
        errorMessage,
        discountAmount,
        discountCode,
      ];
}

/// Cart Item entity following domain-driven design principles
class CartItem extends Equatable {
  final String id;
  final MenuItem menuItem;
  final int quantity;
  final List<MenuItemOption> selectedOptions;

  const CartItem({
    required this.id,
    required this.menuItem,
    required this.quantity,
    this.selectedOptions = const [],
  });

  double get totalPrice {
    final basePrice = menuItem.price;
    final optionsPrice = selectedOptions.fold(0.0, 
      (total, option) => total + option.additionalCost);
    return (basePrice + optionsPrice) * quantity;
  }

  CartItem copyWith({
    String? id,
    MenuItem? menuItem,
    int? quantity,
    List<MenuItemOption>? selectedOptions,
  }) {
    return CartItem(
      id: id ?? this.id,
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      selectedOptions: selectedOptions ?? this.selectedOptions,
    );
  }

  @override
  List<Object?> get props => [id, menuItem, quantity, selectedOptions];
}