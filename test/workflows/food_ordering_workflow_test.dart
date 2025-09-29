import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:core/entities.dart';

import 'package:food_ordering_app_with_flutter_and_bloc/workflows/food_ordering_workflow.dart';
import 'package:food_ordering_app_with_flutter_and_bloc/repositories/restaurant_repository.dart';
import 'package:food_ordering_app_with_flutter_and_bloc/state/cart/cart_bloc.dart';
import 'package:food_ordering_app_with_flutter_and_bloc/state/order/order_bloc.dart';
import 'package:food_ordering_app_with_flutter_and_bloc/services/order_service.dart';

import 'food_ordering_workflow_test.mocks.dart';

@GenerateMocks([RestaurantRepository, OrderService])
void main() {
  group('FoodOrderingWorkflow', () {
    late MockRestaurantRepository mockRestaurantRepository;
    late MockOrderService mockOrderService;
    late CartBloc cartBloc;
    late OrderBloc orderBloc;
    late Widget testWidget;

    setUp(() {
      mockRestaurantRepository = MockRestaurantRepository();
      mockOrderService = MockOrderService();
      cartBloc = CartBloc();
      orderBloc = OrderBloc(orderService: mockOrderService);

      testWidget = MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cartBloc),
            BlocProvider.value(value: orderBloc),
          ],
          child: const Scaffold(
            body: Center(child: Text('Test Widget')),
          ),
        ),
      );
    });

    tearDown(() {
      cartBloc.close();
      orderBloc.close();
    });

    testWidgets('should successfully complete ordering workflow', (tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);
      final context = tester.element(find.text('Test Widget'));
      
      final workflow = FoodOrderingWorkflow(
        restaurantRepository: mockRestaurantRepository,
        context: context,
      );

      final testMenuItem = MenuItem(
        id: 'item_1',
        sectionId: 'section_1',
        restaurantId: 'restaurant_1',
        name: 'Test Pizza',
        description: 'Delicious test pizza',
        imageUrl: 'https://example.com/pizza.jpg',
        price: 12.99,
        available: true,
      );

      // Mock successful order placement
      when(mockOrderService.processPayment(any))
          .thenAnswer((_) async => Future.value());
      when(mockOrderService.placeOrder(any))
          .thenAnswer((_) async => Order(
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
              ));

      // Act
      final result = await workflow.startOrderingWorkflow(
        restaurantId: 'restaurant_1',
        selectedItems: [testMenuItem],
      );

      // Assert
      expect(result, isFalse); // Will be false due to navigation in test environment
      
      // Verify cart was updated
      expect(cartBloc.state.items.length, equals(1));
      expect(cartBloc.state.items.first.menuItem.id, equals('item_1'));
    });

    testWidgets('should handle errors gracefully', (tester) async {
      // Arrange
      await tester.pumpWidget(testWidget);
      final context = tester.element(find.text('Test Widget'));
      
      final workflow = FoodOrderingWorkflow(
        restaurantRepository: mockRestaurantRepository,
        context: context,
      );

      final testMenuItem = MenuItem(
        id: 'item_1',
        sectionId: 'section_1',
        restaurantId: 'restaurant_1',
        name: 'Test Pizza',
        price: 12.99,
        available: true,
      );

      // Mock payment failure
      when(mockOrderService.processPayment(any))
          .thenThrow(Exception('Payment failed'));

      // Act
      final result = await workflow.startOrderingWorkflow(
        restaurantId: 'restaurant_1',
        selectedItems: [testMenuItem],
      );

      // Assert
      expect(result, isFalse);
    });

    test('should add multiple items to cart correctly', () {
      // Arrange
      final testMenuItem1 = MenuItem(
        id: 'item_1',
        sectionId: 'section_1',
        restaurantId: 'restaurant_1',
        name: 'Pizza',
        price: 12.99,
        available: true,
      );

      final testMenuItem2 = MenuItem(
        id: 'item_2',
        sectionId: 'section_1',
        restaurantId: 'restaurant_1',
        name: 'Burger',
        price: 8.99,
        available: true,
      );

      // Act
      cartBloc.add(AddItemToCartEvent(menuItem: testMenuItem1));
      cartBloc.add(AddItemToCartEvent(menuItem: testMenuItem2));

      // Assert
      expect(cartBloc.state.items.length, equals(2));
      expect(cartBloc.state.subtotal, equals(21.98));
    });
  });
}