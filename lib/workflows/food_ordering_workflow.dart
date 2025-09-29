import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/entities.dart';

import '../repositories/restaurant_repository.dart';
import '../state/cart/cart_bloc.dart';
import '../state/order/order_bloc.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/order_confirmation/order_confirmation_screen.dart';

/// Food Ordering Workflow - Orchestrates the complete ordering process
/// Following SOLID principles with single responsibility for workflow management
class FoodOrderingWorkflow {
  final RestaurantRepository _restaurantRepository;
  final BuildContext _context;

  FoodOrderingWorkflow({
    required RestaurantRepository restaurantRepository,
    required BuildContext context,
  })  : _restaurantRepository = restaurantRepository,
        _context = context;

  /// Initiates the complete food ordering workflow
  /// Returns true if order was successfully placed, false otherwise
  Future<bool> startOrderingWorkflow({
    required String restaurantId,
    required List<MenuItem> selectedItems,
  }) async {
    try {
      // Step 1: Add items to cart
      final cartBloc = _context.read<CartBloc>();
      for (final item in selectedItems) {
        cartBloc.add(AddItemToCartEvent(menuItem: item));
      }

      // Step 2: Navigate to cart screen
      final cartResult = await Navigator.push<bool>(
        _context,
        MaterialPageRoute(
          builder: (context) => const CartScreen(),
        ),
      );

      if (cartResult != true) {
        return false; // User cancelled from cart
      }

      // Step 3: Navigate to checkout screen
      final checkoutResult = await Navigator.push<bool>(
        _context,
        MaterialPageRoute(
          builder: (context) => const CheckoutScreen(),
        ),
      );

      if (checkoutResult != true) {
        return false; // User cancelled from checkout
      }

      // Step 4: Process order
      final orderBloc = _context.read<OrderBloc>();
      final cartState = cartBloc.state;
      
      orderBloc.add(PlaceOrderEvent(
        restaurantId: restaurantId,
        items: cartState.items,
        totalAmount: cartState.totalAmount,
      ));

      // Step 5: Navigate to order confirmation
      final confirmationResult = await Navigator.push<bool>(
        _context,
        MaterialPageRoute(
          builder: (context) => const OrderConfirmationScreen(),
        ),
      );

      // Step 6: Clear cart after successful order
      if (confirmationResult == true) {
        cartBloc.add(ClearCartEvent());
        return true;
      }

      return false;
    } catch (error) {
      debugPrint('Food ordering workflow error: $error');
      _showErrorDialog('Failed to complete order. Please try again.');
      return false;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: _context,
      builder: (context) => AlertDialog(
        title: const Text('Order Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}