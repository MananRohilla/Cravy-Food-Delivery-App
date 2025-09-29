import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/entities.dart';

import 'package:food_ordering_app_with_flutter_and_bloc/state/cart/cart_bloc.dart';

void main() {
  group('CartBloc', () {
    late CartBloc cartBloc;

    setUp(() {
      cartBloc = CartBloc();
    });

    tearDown(() {
      cartBloc.close();
    });

    test('initial state is correct', () {
      expect(cartBloc.state, equals(const CartState()));
      expect(cartBloc.state.isEmpty, isTrue);
      expect(cartBloc.state.itemCount, equals(0));
      expect(cartBloc.state.subtotal, equals(0.0));
    });

    group('AddItemToCartEvent', () {
      final testMenuItem = MenuItem(
        id: 'item_1',
        sectionId: 'section_1',
        restaurantId: 'restaurant_1',
        name: 'Test Pizza',
        description: 'Delicious test pizza',
        price: 12.99,
        available: true,
      );

      blocTest<CartBloc, CartState>(
        'emits updated state when item is added',
        build: () => cartBloc,
        act: (bloc) => bloc.add(AddItemToCartEvent(menuItem: testMenuItem)),
        expect: () => [
          predicate<CartState>((state) {
            return state.items.length == 1 &&
                state.items.first.menuItem.id == 'item_1' &&
                state.items.first.quantity == 1 &&
                state.status == CartStatus.updated;
          }),
        ],
      );

      blocTest<CartBloc, CartState>(
        'increases quantity when same item is added',
        build: () => cartBloc,
        act: (bloc) {
          bloc.add(AddItemToCartEvent(menuItem: testMenuItem));
          bloc.add(AddItemToCartEvent(menuItem: testMenuItem));
        },
        expect: () => [
          predicate<CartState>((state) => state.items.first.quantity == 1),
          predicate<CartState>((state) => state.items.first.quantity == 2),
        ],
      );

      blocTest<CartBloc, CartState>(
        'adds item with specified quantity',
        build: () => cartBloc,
        act: (bloc) => bloc.add(AddItemToCartEvent(
          menuItem: testMenuItem,
          quantity: 3,
        )),
        expect: () => [
          predicate<CartState>((state) => state.items.first.quantity == 3),
        ],
      );
    });

    group('RemoveItemFromCartEvent', () {
      final testMenuItem = MenuItem(
        id: 'item_1',
        sectionId: 'section_1',
        restaurantId: 'restaurant_1',
        name: 'Test Pizza',
        price: 12.99,
        available: true,
      );

      blocTest<CartBloc, CartState>(
        'removes item from cart',
        build: () => cartBloc,
        seed: () => CartState(
          items: [
            CartItem(
              id: 'cart_1',
              menuItem: testMenuItem,
              quantity: 1,
            ),
          ],
        ),
        act: (bloc) => bloc.add(const RemoveItemFromCartEvent(cartItemId: 'cart_1')),
        expect: () => [
          predicate<CartState>((state) => state.items.isEmpty),
        ],
      );
    });

    group('UpdateItemQuantityEvent', () {
      final testMenuItem = MenuItem(
        id: 'item_1',
        sectionId: 'section_1',
        restaurantId: 'restaurant_1',
        name: 'Test Pizza',
        price: 12.99,
        available: true,
      );

      blocTest<CartBloc, CartState>(
        'updates item quantity',
        build: () => cartBloc,
        seed: () => CartState(
          items: [
            CartItem(
              id: 'cart_1',
              menuItem: testMenuItem,
              quantity: 1,
            ),
          ],
        ),
        act: (bloc) => bloc.add(const UpdateItemQuantityEvent(
          cartItemId: 'cart_1',
          quantity: 3,
        )),
        expect: () => [
          predicate<CartState>((state) => state.items.first.quantity == 3),
        ],
      );

      blocTest<CartBloc, CartState>(
        'removes item when quantity is 0',
        build: () => cartBloc,
        seed: () => CartState(
          items: [
            CartItem(
              id: 'cart_1',
              menuItem: testMenuItem,
              quantity: 1,
            ),
          ],
        ),
        act: (bloc) => bloc.add(const UpdateItemQuantityEvent(
          cartItemId: 'cart_1',
          quantity: 0,
        )),
        expect: () => [
          predicate<CartState>((state) => state.items.isEmpty),
        ],
      );
    });

    group('ApplyDiscountEvent', () {
      final testMenuItem = MenuItem(
        id: 'item_1',
        sectionId: 'section_1',
        restaurantId: 'restaurant_1',
        name: 'Test Pizza',
        price: 10.00,
        available: true,
      );

      blocTest<CartBloc, CartState>(
        'applies valid discount code',
        build: () => cartBloc,
        seed: () => CartState(
          items: [
            CartItem(
              id: 'cart_1',
              menuItem: testMenuItem,
              quantity: 1,
            ),
          ],
        ),
        act: (bloc) => bloc.add(const ApplyDiscountEvent(discountCode: 'SAVE10')),
        wait: const Duration(milliseconds: 600),
        expect: () => [
          predicate<CartState>((state) {
            return state.discountAmount == 1.0 && // 10% of $10
                state.discountCode == 'SAVE10' &&
                state.status == CartStatus.updated;
          }),
        ],
      );

      blocTest<CartBloc, CartState>(
        'handles invalid discount code',
        build: () => cartBloc,
        seed: () => CartState(
          items: [
            CartItem(
              id: 'cart_1',
              menuItem: testMenuItem,
              quantity: 1,
            ),
          ],
        ),
        act: (bloc) => bloc.add(const ApplyDiscountEvent(discountCode: 'INVALID')),
        wait: const Duration(milliseconds: 600),
        expect: () => [
          predicate<CartState>((state) {
            return state.status == CartStatus.error &&
                state.errorMessage == 'Invalid discount code';
          }),
        ],
      );
    });

    group('ClearCartEvent', () {
      final testMenuItem = MenuItem(
        id: 'item_1',
        sectionId: 'section_1',
        restaurantId: 'restaurant_1',
        name: 'Test Pizza',
        price: 12.99,
        available: true,
      );

      blocTest<CartBloc, CartState>(
        'clears all items from cart',
        build: () => cartBloc,
        seed: () => CartState(
          items: [
            CartItem(
              id: 'cart_1',
              menuItem: testMenuItem,
              quantity: 2,
            ),
          ],
          discountAmount: 5.0,
          discountCode: 'SAVE10',
        ),
        act: (bloc) => bloc.add(ClearCartEvent()),
        expect: () => [
          const CartState(),
        ],
      );
    });

    group('Cart calculations', () {
      final testMenuItem1 = MenuItem(
        id: 'item_1',
        sectionId: 'section_1',
        restaurantId: 'restaurant_1',
        name: 'Pizza',
        price: 10.00,
        available: true,
      );

      final testMenuItem2 = MenuItem(
        id: 'item_2',
        sectionId: 'section_1',
        restaurantId: 'restaurant_1',
        name: 'Burger',
        price: 8.00,
        available: true,
      );

      test('calculates subtotal correctly', () {
        final state = CartState(
          items: [
            CartItem(id: 'cart_1', menuItem: testMenuItem1, quantity: 2),
            CartItem(id: 'cart_2', menuItem: testMenuItem2, quantity: 1),
          ],
        );

        expect(state.subtotal, equals(28.00)); // (10 * 2) + (8 * 1)
      });

      test('calculates delivery fee correctly', () {
        final stateWithFee = CartState(
          items: [
            CartItem(id: 'cart_1', menuItem: testMenuItem1, quantity: 1),
          ],
        );

        final stateWithoutFee = CartState(
          items: [
            CartItem(id: 'cart_1', menuItem: testMenuItem1, quantity: 3),
          ],
        );

        expect(stateWithFee.deliveryFee, equals(2.99)); // Under $25
        expect(stateWithoutFee.deliveryFee, equals(0.0)); // Over $25
      });

      test('calculates tax correctly', () {
        final state = CartState(
          items: [
            CartItem(id: 'cart_1', menuItem: testMenuItem1, quantity: 1),
          ],
        );

        expect(state.tax, equals(0.80)); // 8% of $10
      });

      test('calculates total amount correctly', () {
        final state = CartState(
          items: [
            CartItem(id: 'cart_1', menuItem: testMenuItem1, quantity: 1),
          ],
          discountAmount: 1.0,
        );

        // $10 (subtotal) + $2.99 (delivery) + $0.80 (tax) - $1.00 (discount) = $12.79
        expect(state.totalAmount, equals(12.79));
      });
    });
  });
}