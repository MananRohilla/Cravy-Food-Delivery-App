import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/entities.dart';

import '../repositories/restaurant_repository.dart';
import '../state/cart/cart_bloc.dart';
import '../state/order/order_bloc.dart';
import '../services/order_service.dart';
import '../services/loading_indicator_service.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/order_confirmation/order_confirmation_screen.dart';

enum WorkflowStep {
  addingToCart,
  reviewingCart,
  enteringCheckout,
  processingPayment,
  placingOrder,
  confirmingOrder,
}

class WorkflowException implements Exception {
  final String message;
  final WorkflowStep? failedStep;
  final dynamic originalError;

  WorkflowException(this.message, {this.failedStep, this.originalError});

  @override
  String toString() => 'WorkflowException: $message at step: $failedStep';
}

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
  /// Throws WorkflowException if validation fails
  Future<bool> startOrderingWorkflow({
    required String restaurantId,
    required List<MenuItem> selectedItems,
    String? deliveryAddress,
    String? specialInstructions,
  }) async {
    WorkflowStep currentStep = WorkflowStep.addingToCart;

    try {
      if (restaurantId.isEmpty) {
        throw WorkflowException(
          'Restaurant ID cannot be empty',
          failedStep: WorkflowStep.addingToCart,
        );
      }

      if (selectedItems.isEmpty) {
        _showErrorDialog('Please select at least one item to order.');
        return false;
      }

      final unavailableItems = selectedItems.where((item) => !item.available).toList();
      if (unavailableItems.isNotEmpty) {
        _showErrorDialog(
          'Some items are currently unavailable: ${unavailableItems.map((e) => e.name).join(", ")}',
        );
        return false;
      }

      final cartBloc = _context.read<CartBloc>();

      if (cartBloc.state.items.isNotEmpty) {
        final shouldClearCart = await _showConfirmationDialog(
          'You have items in your cart',
          'Would you like to clear your current cart before adding new items?',
        );
        if (shouldClearCart == true) {
          cartBloc.add(ClearCartEvent());
        }
      }

      LoadingIndicatorService.show(_context, message: 'Adding items to cart...');

      for (final item in selectedItems) {
        if (item.price < 0) {
          LoadingIndicatorService.hide();
          throw WorkflowException(
            'Invalid item price: ${item.name}',
            failedStep: WorkflowStep.addingToCart,
          );
        }
        cartBloc.add(AddItemToCartEvent(menuItem: item));
      }

      await Future.delayed(const Duration(milliseconds: 300));
      LoadingIndicatorService.hide();

      currentStep = WorkflowStep.reviewingCart;

      if (cartBloc.state.isEmpty) {
        throw WorkflowException(
          'Cart is empty after adding items',
          failedStep: WorkflowStep.reviewingCart,
        );
      }

      final cartResult = await Navigator.push<bool>(
        _context,
        MaterialPageRoute(
          builder: (context) => const CartScreen(),
        ),
      );

      if (cartResult != true) {
        debugPrint('User cancelled workflow at cart screen');
        return false;
      }

      currentStep = WorkflowStep.enteringCheckout;

      if (cartBloc.state.totalAmount <= 0) {
        throw WorkflowException(
          'Invalid cart total amount',
          failedStep: WorkflowStep.enteringCheckout,
        );
      }

      final checkoutResult = await Navigator.push<bool>(
        _context,
        MaterialPageRoute(
          builder: (context) => const CheckoutScreen(),
        ),
      );

      if (checkoutResult != true) {
        debugPrint('User cancelled workflow at checkout screen');
        return false;
      }

      currentStep = WorkflowStep.processingPayment;

      final orderBloc = _context.read<OrderBloc>();
      final cartState = cartBloc.state;

      if (cartState.items.isEmpty) {
        throw WorkflowException(
          'Cart became empty before order placement',
          failedStep: WorkflowStep.processingPayment,
        );
      }

      currentStep = WorkflowStep.placingOrder;
      debugPrint('Placing order for restaurant: $restaurantId');

      LoadingIndicatorService.show(_context, message: 'Placing your order...');

      orderBloc.add(PlaceOrderEvent(
        restaurantId: restaurantId,
        items: cartState.items,
        totalAmount: cartState.totalAmount,
      ));

      await Future.delayed(const Duration(milliseconds: 500));
      LoadingIndicatorService.hide();

      if (orderBloc.state.status == OrderStatus.error) {
        throw WorkflowException(
          orderBloc.state.errorMessage ?? 'Failed to place order',
          failedStep: WorkflowStep.placingOrder,
        );
      }

      currentStep = WorkflowStep.confirmingOrder;

      final confirmationResult = await Navigator.push<bool>(
        _context,
        MaterialPageRoute(
          builder: (context) => const OrderConfirmationScreen(),
        ),
      );

      if (confirmationResult == true) {
        cartBloc.add(ClearCartEvent());
        debugPrint('Order workflow completed successfully');
        return true;
      }

      debugPrint('Order confirmation not received');
      return false;
    } on WorkflowException catch (e) {
      LoadingIndicatorService.hide();
      debugPrint('Workflow exception: $e');
      _showErrorDialog(e.message);
      return false;
    } on PaymentException catch (e) {
      LoadingIndicatorService.hide();
      debugPrint('Payment exception: $e');
      _showErrorDialog('Payment failed: ${e.message}');
      return false;
    } on OrderServiceException catch (e) {
      LoadingIndicatorService.hide();
      debugPrint('Order service exception: $e');
      _showErrorDialog('Order processing failed: ${e.message}');
      return false;
    } catch (error) {
      LoadingIndicatorService.hide();
      debugPrint('Unexpected error in workflow at step $currentStep: $error');
      _showErrorDialog(
        'An unexpected error occurred. Please try again.\nStep: ${currentStep.name}',
      );
      return false;
    }
  }

  Future<bool?> _showConfirmationDialog(String title, String message) async {
    return showDialog<bool>(
      context: _context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
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