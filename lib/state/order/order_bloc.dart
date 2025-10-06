import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../state/cart/cart_bloc.dart';
import '../../services/order_service.dart';

part 'order_event.dart';
part 'order_state.dart';

/// Order BLoC - Manages order processing and tracking
/// Follows single responsibility principle for order management
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderService _orderService;
  final Uuid _uuid = const Uuid();

  OrderBloc({
    required OrderService orderService,
  })  : _orderService = orderService,
        super(const OrderState()) {
    on<PlaceOrderEvent>(_onPlaceOrder);
    on<TrackOrderEvent>(_onTrackOrder);
    on<CancelOrderEvent>(_onCancelOrder);
    on<LoadOrderHistoryEvent>(_onLoadOrderHistory);
  }

  void _onPlaceOrder(
    PlaceOrderEvent event,
    Emitter<OrderState> emit,
  ) async {
    try {
      debugPrint('Placing order for restaurant: ${event.restaurantId}');
      emit(state.copyWith(status: OrderStatus.placing));

      // Create order
      final order = Order(
        id: _uuid.v4(),
        restaurantId: event.restaurantId,
        items: event.items,
        totalAmount: event.totalAmount,
        status: OrderTrackingStatus.confirmed,
        createdAt: DateTime.now(),
        estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 30)),
      );

      // Process payment (simulated)
      await _orderService.processPayment(order);

      // Submit order to restaurant
      final placedOrder = await _orderService.placeOrder(order);

      emit(state.copyWith(
        status: OrderStatus.placed,
        currentOrder: placedOrder,
        orderHistory: [...state.orderHistory, placedOrder],
      ));

      // Start tracking
      add(TrackOrderEvent(orderId: placedOrder.id));
    } catch (error) {
      debugPrint('Error placing order: $error');
      emit(state.copyWith(
        status: OrderStatus.error,
        errorMessage: 'Failed to place order. Please try again.',
      ));
    }
  }

  void _onTrackOrder(
    TrackOrderEvent event,
    Emitter<OrderState> emit,
  ) async {
    try {
      debugPrint('Tracking order: ${event.orderId}');
      emit(state.copyWith(status: OrderStatus.tracking));

      await for (final orderUpdate in _orderService.trackOrder(event.orderId)) {
        emit(state.copyWith(
          currentOrder: orderUpdate,
          status: OrderStatus.tracking,
        ));

        if (orderUpdate.status == OrderTrackingStatus.delivered ||
            orderUpdate.status == OrderTrackingStatus.cancelled) {
          break;
        }
      }
    } catch (error) {
      debugPrint('Error tracking order: $error');
      emit(state.copyWith(
        status: OrderStatus.error,
        errorMessage: 'Failed to track order',
      ));
    }
  }

  void _onCancelOrder(
    CancelOrderEvent event,
    Emitter<OrderState> emit,
  ) async {
    try {
      debugPrint('Cancelling order: ${event.orderId}');
      emit(state.copyWith(status: OrderStatus.cancelling));

      final cancelledOrder = await _orderService.cancelOrder(event.orderId);

      emit(state.copyWith(
        status: OrderStatus.cancelled,
        currentOrder: cancelledOrder,
      ));
    } catch (error) {
      debugPrint('Error cancelling order: $error');
      emit(state.copyWith(
        status: OrderStatus.error,
        errorMessage: 'Failed to cancel order',
      ));
    }
  }

  void _onLoadOrderHistory(
    LoadOrderHistoryEvent event,
    Emitter<OrderState> emit,
  ) async {
    try {
      debugPrint('Loading order history');
      emit(state.copyWith(status: OrderStatus.loading));

      final orderHistory = await _orderService.getOrderHistory();

      emit(state.copyWith(
        status: OrderStatus.loaded,
        orderHistory: orderHistory,
      ));
    } catch (error) {
      debugPrint('Error loading order history: $error');
      emit(state.copyWith(
        status: OrderStatus.error,
        errorMessage: 'Failed to load order history',
      ));
    }
  }
}