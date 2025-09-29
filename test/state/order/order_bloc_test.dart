import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:core/entities.dart';

import 'package:food_ordering_app_with_flutter_and_bloc/state/order/order_bloc.dart';
import 'package:food_ordering_app_with_flutter_and_bloc/state/cart/cart_bloc.dart';
import 'package:food_ordering_app_with_flutter_and_bloc/services/order_service.dart';

import 'order_bloc_test.mocks.dart';

@GenerateMocks([OrderService])
void main() {
  group('OrderBloc', () {
    late MockOrderService mockOrderService;
    late OrderBloc orderBloc;

    setUp(() {
      mockOrderService = MockOrderService();
      orderBloc = OrderBloc(orderService: mockOrderService);
    });

    tearDown(() {
      orderBloc.close();
    });

    test('initial state is correct', () {
      expect(orderBloc.state, equals(const OrderState()));
      expect(orderBloc.state.status, equals(OrderStatus.initial));
      expect(orderBloc.state.currentOrder, isNull);
      expect(orderBloc.state.orderHistory, isEmpty);
    });

    group('PlaceOrderEvent', () {
      final testMenuItem = MenuItem(
        id: 'item_1',
        sectionId: 'section_1',
        restaurantId: 'restaurant_1',
        name: 'Test Pizza',
        price: 12.99,
        available: true,
      );

      final testCartItem = CartItem(
        id: 'cart_1',
        menuItem: testMenuItem,
        quantity: 1,
      );

      final testOrder = Order(
        id: 'order_1',
        restaurantId: 'restaurant_1',
        items: [testCartItem],
        totalAmount: 12.99,
        status: OrderTrackingStatus.confirmed,
        createdAt: DateTime.now(),
        estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 30)),
      );

      blocTest<OrderBloc, OrderState>(
        'emits placing and placed states when order is successful',
        build: () => orderBloc,
        setUp: () {
          when(mockOrderService.processPayment(any))
              .thenAnswer((_) async => Future.value());
          when(mockOrderService.placeOrder(any))
              .thenAnswer((_) async => testOrder);
          when(mockOrderService.trackOrder(any))
              .thenAnswer((_) => Stream.value(testOrder));
        },
        act: (bloc) => bloc.add(PlaceOrderEvent(
          restaurantId: 'restaurant_1',
          items: [testCartItem],
          totalAmount: 12.99,
        )),
        expect: () => [
          predicate<OrderState>((state) => state.status == OrderStatus.placing),
          predicate<OrderState>((state) {
            return state.status == OrderStatus.placed &&
                state.currentOrder?.id == 'order_1' &&
                state.orderHistory.length == 1;
          }),
          predicate<OrderState>((state) => state.status == OrderStatus.tracking),
        ],
        verify: (_) {
          verify(mockOrderService.processPayment(any)).called(1);
          verify(mockOrderService.placeOrder(any)).called(1);
          verify(mockOrderService.trackOrder(any)).called(1);
        },
      );

      blocTest<OrderBloc, OrderState>(
        'emits error state when payment fails',
        build: () => orderBloc,
        setUp: () {
          when(mockOrderService.processPayment(any))
              .thenThrow(Exception('Payment failed'));
        },
        act: (bloc) => bloc.add(PlaceOrderEvent(
          restaurantId: 'restaurant_1',
          items: [testCartItem],
          totalAmount: 12.99,
        )),
        expect: () => [
          predicate<OrderState>((state) => state.status == OrderStatus.placing),
          predicate<OrderState>((state) {
            return state.status == OrderStatus.error &&
                state.errorMessage == 'Failed to place order. Please try again.';
          }),
        ],
      );
    });

    group('TrackOrderEvent', () {
      final testOrder = Order(
        id: 'order_1',
        restaurantId: 'restaurant_1',
        items: [],
        totalAmount: 12.99,
        status: OrderTrackingStatus.confirmed,
        createdAt: DateTime.now(),
        estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 30)),
      );

      blocTest<OrderBloc, OrderState>(
        'emits tracking states as order progresses',
        build: () => orderBloc,
        setUp: () {
          when(mockOrderService.trackOrder('order_1')).thenAnswer((_) {
            return Stream.fromIterable([
              testOrder.copyWith(status: OrderTrackingStatus.confirmed),
              testOrder.copyWith(status: OrderTrackingStatus.preparing),
              testOrder.copyWith(status: OrderTrackingStatus.ready),
              testOrder.copyWith(status: OrderTrackingStatus.delivered),
            ]);
          });
        },
        act: (bloc) => bloc.add(const TrackOrderEvent(orderId: 'order_1')),
        expect: () => [
          predicate<OrderState>((state) => state.status == OrderStatus.tracking),
          predicate<OrderState>((state) {
            return state.status == OrderStatus.tracking &&
                state.currentOrder?.status == OrderTrackingStatus.confirmed;
          }),
          predicate<OrderState>((state) {
            return state.currentOrder?.status == OrderTrackingStatus.preparing;
          }),
          predicate<OrderState>((state) {
            return state.currentOrder?.status == OrderTrackingStatus.ready;
          }),
          predicate<OrderState>((state) {
            return state.currentOrder?.status == OrderTrackingStatus.delivered;
          }),
        ],
      );

      blocTest<OrderBloc, OrderState>(
        'emits error state when tracking fails',
        build: () => orderBloc,
        setUp: () {
          when(mockOrderService.trackOrder('order_1'))
              .thenThrow(Exception('Tracking failed'));
        },
        act: (bloc) => bloc.add(const TrackOrderEvent(orderId: 'order_1')),
        expect: () => [
          predicate<OrderState>((state) => state.status == OrderStatus.tracking),
          predicate<OrderState>((state) {
            return state.status == OrderStatus.error &&
                state.errorMessage == 'Failed to track order';
          }),
        ],
      );
    });

    group('CancelOrderEvent', () {
      final testOrder = Order(
        id: 'order_1',
        restaurantId: 'restaurant_1',
        items: [],
        totalAmount: 12.99,
        status: OrderTrackingStatus.cancelled,
        createdAt: DateTime.now(),
        estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 30)),
      );

      blocTest<OrderBloc, OrderState>(
        'emits cancelling and cancelled states when successful',
        build: () => orderBloc,
        setUp: () {
          when(mockOrderService.cancelOrder('order_1'))
              .thenAnswer((_) async => testOrder);
        },
        act: (bloc) => bloc.add(const CancelOrderEvent(orderId: 'order_1')),
        expect: () => [
          predicate<OrderState>((state) => state.status == OrderStatus.cancelling),
          predicate<OrderState>((state) {
            return state.status == OrderStatus.cancelled &&
                state.currentOrder?.status == OrderTrackingStatus.cancelled;
          }),
        ],
      );

      blocTest<OrderBloc, OrderState>(
        'emits error state when cancellation fails',
        build: () => orderBloc,
        setUp: () {
          when(mockOrderService.cancelOrder('order_1'))
              .thenThrow(Exception('Cannot cancel order'));
        },
        act: (bloc) => bloc.add(const CancelOrderEvent(orderId: 'order_1')),
        expect: () => [
          predicate<OrderState>((state) => state.status == OrderStatus.cancelling),
          predicate<OrderState>((state) {
            return state.status == OrderStatus.error &&
                state.errorMessage == 'Failed to cancel order';
          }),
        ],
      );
    });

    group('LoadOrderHistoryEvent', () {
      final testOrders = [
        Order(
          id: 'order_1',
          restaurantId: 'restaurant_1',
          items: [],
          totalAmount: 12.99,
          status: OrderTrackingStatus.delivered,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          estimatedDeliveryTime: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Order(
          id: 'order_2',
          restaurantId: 'restaurant_2',
          items: [],
          totalAmount: 8.99,
          status: OrderTrackingStatus.delivered,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          estimatedDeliveryTime: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

      blocTest<OrderBloc, OrderState>(
        'emits loading and loaded states with order history',
        build: () => orderBloc,
        setUp: () {
          when(mockOrderService.getOrderHistory())
              .thenAnswer((_) async => testOrders);
        },
        act: (bloc) => bloc.add(LoadOrderHistoryEvent()),
        expect: () => [
          predicate<OrderState>((state) => state.status == OrderStatus.loading),
          predicate<OrderState>((state) {
            return state.status == OrderStatus.loaded &&
                state.orderHistory.length == 2;
          }),
        ],
      );

      blocTest<OrderBloc, OrderState>(
        'emits error state when loading fails',
        build: () => orderBloc,
        setUp: () {
          when(mockOrderService.getOrderHistory())
              .thenThrow(Exception('Failed to load'));
        },
        act: (bloc) => bloc.add(LoadOrderHistoryEvent()),
        expect: () => [
          predicate<OrderState>((state) => state.status == OrderStatus.loading),
          predicate<OrderState>((state) {
            return state.status == OrderStatus.error &&
                state.errorMessage == 'Failed to load order history';
          }),
        ],
      );
    });
  });
}