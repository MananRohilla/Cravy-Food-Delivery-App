import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../state/cart/cart_bloc.dart';
import '../state/order/order_bloc.dart';

/// Order Service - Handles order processing and external integrations
/// Implements dependency inversion principle with abstract interface
abstract class OrderServiceInterface {
  Future<Order> placeOrder(Order order);
  Future<void> processPayment(Order order);
  Stream<Order> trackOrder(String orderId);
  Future<Order> cancelOrder(String orderId);
  Future<List<Order>> getOrderHistory();
}

/// Concrete implementation of OrderService
/// Follows single responsibility principle for order operations
class OrderService implements OrderServiceInterface {
  final Map<String, Order> _orders = {};
  final Random _random = Random();

  @override
  Future<Order> placeOrder(Order order) async {
    try {
      debugPrint('Processing order: ${order.id}');
      
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate occasional failures for error handling testing
      if (_random.nextDouble() < 0.1) {
        throw Exception('Restaurant is currently unavailable');
      }

      // Store order
      _orders[order.id] = order;
      
      return order.copyWith(status: OrderTrackingStatus.confirmed);
    } catch (error) {
      debugPrint('Error placing order: $error');
      rethrow;
    }
  }

  @override
  Future<void> processPayment(Order order) async {
    try {
      debugPrint('Processing payment for order: ${order.id}');
      
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulate payment failures
      if (_random.nextDouble() < 0.05) {
        throw Exception('Payment failed. Please check your payment method.');
      }
      
      debugPrint('Payment processed successfully');
    } catch (error) {
      debugPrint('Payment processing error: $error');
      rethrow;
    }
  }

  @override
  Stream<Order> trackOrder(String orderId) async* {
    try {
      debugPrint('Starting order tracking for: $orderId');
      
      final order = _orders[orderId];
      if (order == null) {
        throw Exception('Order not found');
      }

      final statuses = [
        OrderTrackingStatus.confirmed,
        OrderTrackingStatus.preparing,
        OrderTrackingStatus.ready,
        OrderTrackingStatus.pickedUp,
        OrderTrackingStatus.onTheWay,
        OrderTrackingStatus.delivered,
      ];

      for (int i = 0; i < statuses.length; i++) {
        await Future.delayed(Duration(seconds: 5 + _random.nextInt(10)));
        
        final updatedOrder = order.copyWith(status: statuses[i]);
        _orders[orderId] = updatedOrder;
        
        yield updatedOrder;
        
        if (statuses[i] == OrderTrackingStatus.delivered) {
          break;
        }
      }
    } catch (error) {
      debugPrint('Order tracking error: $error');
      rethrow;
    }
  }

  @override
  Future<Order> cancelOrder(String orderId) async {
    try {
      debugPrint('Cancelling order: $orderId');
      
      await Future.delayed(const Duration(seconds: 1));
      
      final order = _orders[orderId];
      if (order == null) {
        throw Exception('Order not found');
      }

      // Check if order can be cancelled
      if (order.status == OrderTrackingStatus.pickedUp ||
          order.status == OrderTrackingStatus.onTheWay ||
          order.status == OrderTrackingStatus.delivered) {
        throw Exception('Order cannot be cancelled at this stage');
      }

      final cancelledOrder = order.copyWith(status: OrderTrackingStatus.cancelled);
      _orders[orderId] = cancelledOrder;
      
      return cancelledOrder;
    } catch (error) {
      debugPrint('Order cancellation error: $error');
      rethrow;
    }
  }

  @override
  Future<List<Order>> getOrderHistory() async {
    try {
      debugPrint('Loading order history');
      
      await Future.delayed(const Duration(seconds: 1));
      
      return _orders.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (error) {
      debugPrint('Error loading order history: $error');
      rethrow;
    }
  }
}