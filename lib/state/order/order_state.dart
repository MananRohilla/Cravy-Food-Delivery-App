part of 'order_bloc.dart';

enum OrderStatus {
  initial,
  loading,
  placing,
  placed,
  tracking,
  cancelling,
  cancelled,
  loaded,
  error,
}

enum OrderTrackingStatus {
  confirmed,
  preparing,
  ready,
  pickedUp,
  onTheWay,
  delivered,
  cancelled,
}

class OrderState extends Equatable {
  final OrderStatus status;
  final Order? currentOrder;
  final List<Order> orderHistory;
  final String? errorMessage;

  const OrderState({
    this.status = OrderStatus.initial,
    this.currentOrder,
    this.orderHistory = const [],
    this.errorMessage,
  });

  OrderState copyWith({
    OrderStatus? status,
    Order? currentOrder,
    List<Order>? orderHistory,
    String? errorMessage,
  }) {
    return OrderState(
      status: status ?? this.status,
      currentOrder: currentOrder ?? this.currentOrder,
      orderHistory: orderHistory ?? this.orderHistory,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, currentOrder, orderHistory, errorMessage];
}

/// Order entity following domain-driven design principles
class Order extends Equatable {
  final String id;
  final String restaurantId;
  final List<CartItem> items;
  final double totalAmount;
  final OrderTrackingStatus status;
  final DateTime createdAt;
  final DateTime estimatedDeliveryTime;
  final String? deliveryAddress;
  final String? specialInstructions;

  const Order({
    required this.id,
    required this.restaurantId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.estimatedDeliveryTime,
    this.deliveryAddress,
    this.specialInstructions,
  });

  Order copyWith({
    String? id,
    String? restaurantId,
    List<CartItem>? items,
    double? totalAmount,
    OrderTrackingStatus? status,
    DateTime? createdAt,
    DateTime? estimatedDeliveryTime,
    String? deliveryAddress,
    String? specialInstructions,
  }) {
    return Order(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  @override
  List<Object?> get props => [
        id,
        restaurantId,
        items,
        totalAmount,
        status,
        createdAt,
        estimatedDeliveryTime,
        deliveryAddress,
        specialInstructions,
      ];
}