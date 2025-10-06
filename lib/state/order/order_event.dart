part of 'order_bloc.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class PlaceOrderEvent extends OrderEvent {
  const PlaceOrderEvent({
    required this.restaurantId,
    required this.items,
    required this.totalAmount,
  });

  final String restaurantId;
  final List<CartItem> items;
  final double totalAmount;

  @override
  List<Object?> get props => [restaurantId, items, totalAmount];
}

class TrackOrderEvent extends OrderEvent {
  const TrackOrderEvent({required this.orderId});

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

class CancelOrderEvent extends OrderEvent {
  const CancelOrderEvent({required this.orderId});

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

class LoadOrderHistoryEvent extends OrderEvent {}