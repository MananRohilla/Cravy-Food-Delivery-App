import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:food_ordering_app_with_flutter_and_bloc/state/cart/cart_bloc.dart';
import '../state/order/order_bloc.dart';

class OrderServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  OrderServiceException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'OrderServiceException: $message';
}

class PaymentException extends OrderServiceException {
  PaymentException(super.message, {super.code, super.originalError});
}

class RestaurantUnavailableException extends OrderServiceException {
  RestaurantUnavailableException(super.message, {super.code, super.originalError});
}

class OrderNotFoundException extends OrderServiceException {
  OrderNotFoundException(super.message, {super.code, super.originalError});
}

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
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        debugPrint('Processing order: ${order.id} (attempt ${retryCount + 1}/$maxRetries)');

        if (order.items.isEmpty) {
          throw OrderServiceException('Cannot place order with no items');
        }

        if (order.totalAmount <= 0) {
          throw OrderServiceException('Order total must be greater than zero');
        }

        await Future.delayed(const Duration(seconds: 2));

        if (_random.nextDouble() < 0.1) {
          throw RestaurantUnavailableException(
            'Restaurant is currently unavailable',
            code: 'RESTAURANT_UNAVAILABLE',
          );
        }

        _orders[order.id] = order;

        debugPrint('Order placed successfully: ${order.id}');
        return order.copyWith(status: OrderTrackingStatus.confirmed);
      } on RestaurantUnavailableException {
        retryCount++;
        if (retryCount >= maxRetries) {
          debugPrint('Max retries reached for order: ${order.id}');
          rethrow;
        }
        debugPrint('Retrying order placement after delay...');
        await Future.delayed(retryDelay * retryCount);
      } catch (error) {
        debugPrint('Error placing order: $error');
        if (error is OrderServiceException) {
          rethrow;
        }
        throw OrderServiceException(
          'Failed to place order',
          originalError: error,
        );
      }
    }

    throw RestaurantUnavailableException(
      'Failed to place order after $maxRetries attempts',
    );
  }

  @override
  Future<void> processPayment(Order order) async {
    int retryCount = 0;
    const maxRetries = 2;

    while (retryCount < maxRetries) {
      try {
        debugPrint('Processing payment for order: ${order.id} (attempt ${retryCount + 1}/$maxRetries)');

        if (order.totalAmount <= 0) {
          throw PaymentException(
            'Invalid payment amount',
            code: 'INVALID_AMOUNT',
          );
        }

        await Future.delayed(const Duration(seconds: 1));

        if (_random.nextDouble() < 0.05) {
          throw PaymentException(
            'Payment declined. Please check your payment method.',
            code: 'PAYMENT_DECLINED',
          );
        }

        debugPrint('Payment processed successfully');
        return;
      } on PaymentException catch (e) {
        if (e.code == 'INVALID_AMOUNT') {
          rethrow;
        }
        retryCount++;
        if (retryCount >= maxRetries) {
          debugPrint('Max payment retries reached');
          rethrow;
        }
        debugPrint('Retrying payment processing...');
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      } catch (error) {
        debugPrint('Payment processing error: $error');
        throw PaymentException(
          'Payment processing failed',
          originalError: error,
        );
      }
    }
  }

  @override
  Stream<Order> trackOrder(String orderId) async* {
    try {
      debugPrint('Starting order tracking for: $orderId');

      final order = _orders[orderId];
      if (order == null) {
        throw OrderNotFoundException(
          'Order not found: $orderId',
          code: 'ORDER_NOT_FOUND',
        );
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
        throw OrderNotFoundException(
          'Order not found: $orderId',
          code: 'ORDER_NOT_FOUND',
        );
      }

      if (order.status == OrderTrackingStatus.pickedUp ||
          order.status == OrderTrackingStatus.onTheWay ||
          order.status == OrderTrackingStatus.delivered) {
        throw OrderServiceException(
          'Order cannot be cancelled at this stage: ${order.status.name}',
          code: 'CANCELLATION_NOT_ALLOWED',
        );
      }

      final cancelledOrder = order.copyWith(status: OrderTrackingStatus.cancelled);
      _orders[orderId] = cancelledOrder;
      
      return cancelledOrder;
    } catch (error) {
      debugPrint('Order cancellation error: $error');
      if (error is OrderServiceException) {
        rethrow;
      }
      throw OrderServiceException(
        'Failed to cancel order',
        originalError: error,
      );
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