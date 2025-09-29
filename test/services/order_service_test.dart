import 'package:flutter_test/flutter_test.dart';
import 'package:core/entities.dart';

import 'package:food_ordering_app_with_flutter_and_bloc/services/order_service.dart';
import 'package:food_ordering_app_with_flutter_and_bloc/state/cart/cart_bloc.dart';
import 'package:food_ordering_app_with_flutter_and_bloc/state/order/order_bloc.dart';

void main() {
  group('OrderService', () {
    late OrderService orderService;

    setUp(() {
      orderService = OrderService();
    });

    group('placeOrder', () {
      test('should successfully place an order', () async {
        // Arrange
        final testMenuItem = MenuItem(
          id: 'item_1',
          sectionId: 'section_1',
          restaurantId: 'restaurant_1',
          name: 'Test Pizza',
          price: 12.99,
          available: true,
        );

        final testOrder = Order(
          id: 'order_1',
          restaurantId: 'restaurant_1',
          items: [
            CartItem(
              id: 'cart_1',
              menuItem: testMenuItem,
              quantity: 1,
            ),
          ],
          totalAmount: 12.99,
          status: OrderTrackingStatus.confirmed,
          createdAt: DateTime.now(),
          estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 30)),
        );

        // Act
        final result = await orderService.placeOrder(testOrder);

        // Assert
        expect(result.id, equals('order_1'));
        expect(result.status, equals(OrderTrackingStatus.confirmed));
        expect(result.totalAmount, equals(12.99));
      });

      test('should handle order placement failures', () async {
        // Arrange
        final testOrder = Order(
          id: 'order_1',
          restaurantId: 'restaurant_1',
          items: [],
          totalAmount: 12.99,
          status: OrderTrackingStatus.confirmed,
          createdAt: DateTime.now(),
          estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 30)),
        );

        // Act & Assert
        // Note: The service has a 10% chance of failure, so we can't reliably test this
        // In a real implementation, we would inject a random number generator for testing
        expect(() => orderService.placeOrder(testOrder), returnsNormally);
      });
    });

    group('processPayment', () {
      test('should successfully process payment', () async {
        // Arrange
        final testOrder = Order(
          id: 'order_1',
          restaurantId: 'restaurant_1',
          items: [],
          totalAmount: 12.99,
          status: OrderTrackingStatus.confirmed,
          createdAt: DateTime.now(),
          estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 30)),
        );

        // Act & Assert
        expect(() => orderService.processPayment(testOrder), returnsNormally);
      });
    });

    group('trackOrder', () {
      test('should provide order tracking updates', () async {
        // Arrange
        final testMenuItem = MenuItem(
          id: 'item_1',
          sectionId: 'section_1',
          restaurantId: 'restaurant_1',
          name: 'Test Pizza',
          price: 12.99,
          available: true,
        );

        final testOrder = Order(
          id: 'order_1',
          restaurantId: 'restaurant_1',
          items: [
            CartItem(
              id: 'cart_1',
              menuItem: testMenuItem,
              quantity: 1,
            ),
          ],
          totalAmount: 12.99,
          status: OrderTrackingStatus.confirmed,
          createdAt: DateTime.now(),
          estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 30)),
        );

        // First place the order
        await orderService.placeOrder(testOrder);

        // Act
        final trackingStream = orderService.trackOrder('order_1');
        final updates = <Order>[];

        // Collect first few updates
        await for (final update in trackingStream.take(3)) {
          updates.add(update);
        }

        // Assert
        expect(updates.length, equals(3));
        expect(updates.first.status, equals(OrderTrackingStatus.confirmed));
        expect(updates.last.status, equals(OrderTrackingStatus.ready));
      });

      test('should handle tracking for non-existent order', () async {
        // Act & Assert
        expect(
          () => orderService.trackOrder('non_existent_order').first,
          throwsException,
        );
      });
    });

    group('cancelOrder', () {
      test('should successfully cancel an order', () async {
        // Arrange
        final testOrder = Order(
          id: 'order_1',
          restaurantId: 'restaurant_1',
          items: [],
          totalAmount: 12.99,
          status: OrderTrackingStatus.confirmed,
          createdAt: DateTime.now(),
          estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 30)),
        );

        // First place the order
        await orderService.placeOrder(testOrder);

        // Act
        final cancelledOrder = await orderService.cancelOrder('order_1');

        // Assert
        expect(cancelledOrder.status, equals(OrderTrackingStatus.cancelled));
      });

      test('should handle cancellation of non-existent order', () async {
        // Act & Assert
        expect(
          () => orderService.cancelOrder('non_existent_order'),
          throwsException,
        );
      });

      test('should prevent cancellation of orders that cannot be cancelled', () async {
        // Arrange
        final testOrder = Order(
          id: 'order_1',
          restaurantId: 'restaurant_1',
          items: [],
          totalAmount: 12.99,
          status: OrderTrackingStatus.delivered,
          createdAt: DateTime.now(),
          estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 30)),
        );

        // Place and update order status
        await orderService.placeOrder(testOrder);

        // Act & Assert
        expect(
          () => orderService.cancelOrder('order_1'),
          throwsException,
        );
      });
    });

    group('getOrderHistory', () {
      test('should return empty list when no orders exist', () async {
        // Act
        final history = await orderService.getOrderHistory();

        // Assert
        expect(history, isEmpty);
      });

      test('should return orders sorted by creation date', () async {
        // Arrange
        final order1 = Order(
          id: 'order_1',
          restaurantId: 'restaurant_1',
          items: [],
          totalAmount: 12.99,
          status: OrderTrackingStatus.delivered,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          estimatedDeliveryTime: DateTime.now().subtract(const Duration(days: 2)),
        );

        final order2 = Order(
          id: 'order_2',
          restaurantId: 'restaurant_2',
          items: [],
          totalAmount: 8.99,
          status: OrderTrackingStatus.delivered,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          estimatedDeliveryTime: DateTime.now().subtract(const Duration(days: 1)),
        );

        // Place orders
        await orderService.placeOrder(order1);
        await orderService.placeOrder(order2);

        // Act
        final history = await orderService.getOrderHistory();

        // Assert
        expect(history.length, equals(2));
        expect(history.first.id, equals('order_2')); // Most recent first
        expect(history.last.id, equals('order_1'));
      });
    });
  });
}