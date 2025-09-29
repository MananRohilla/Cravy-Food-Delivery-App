import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../state/order/order_bloc.dart';

class OrderTrackingTimeline extends StatelessWidget {
  const OrderTrackingTimeline({
    super.key,
    required this.order,
  });

  final Order order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        final currentOrder = state.currentOrder ?? order;
        
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Status',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _TimelineStep(
                icon: Icons.check_circle,
                title: 'Order Confirmed',
                subtitle: 'Your order has been received',
                isCompleted: _isStatusCompleted(
                  currentOrder.status,
                  OrderTrackingStatus.confirmed,
                ),
                isActive: currentOrder.status == OrderTrackingStatus.confirmed,
              ),
              _TimelineStep(
                icon: Icons.restaurant,
                title: 'Preparing',
                subtitle: 'Restaurant is preparing your food',
                isCompleted: _isStatusCompleted(
                  currentOrder.status,
                  OrderTrackingStatus.preparing,
                ),
                isActive: currentOrder.status == OrderTrackingStatus.preparing,
              ),
              _TimelineStep(
                icon: Icons.done_all,
                title: 'Ready for Pickup',
                subtitle: 'Your order is ready',
                isCompleted: _isStatusCompleted(
                  currentOrder.status,
                  OrderTrackingStatus.ready,
                ),
                isActive: currentOrder.status == OrderTrackingStatus.ready,
              ),
              _TimelineStep(
                icon: Icons.delivery_dining,
                title: 'Out for Delivery',
                subtitle: 'Driver is on the way',
                isCompleted: _isStatusCompleted(
                  currentOrder.status,
                  OrderTrackingStatus.onTheWay,
                ),
                isActive: currentOrder.status == OrderTrackingStatus.onTheWay,
              ),
              _TimelineStep(
                icon: Icons.home,
                title: 'Delivered',
                subtitle: 'Enjoy your meal!',
                isCompleted: _isStatusCompleted(
                  currentOrder.status,
                  OrderTrackingStatus.delivered,
                ),
                isActive: currentOrder.status == OrderTrackingStatus.delivered,
                isLast: true,
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isStatusCompleted(
    OrderTrackingStatus currentStatus,
    OrderTrackingStatus checkStatus,
  ) {
    final statusOrder = [
      OrderTrackingStatus.confirmed,
      OrderTrackingStatus.preparing,
      OrderTrackingStatus.ready,
      OrderTrackingStatus.pickedUp,
      OrderTrackingStatus.onTheWay,
      OrderTrackingStatus.delivered,
    ];

    final currentIndex = statusOrder.indexOf(currentStatus);
    final checkIndex = statusOrder.indexOf(checkStatus);

    return currentIndex > checkIndex;
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isActive,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;
    
    Color getColor() {
      if (isCompleted) return Colors.green;
      if (isActive) return primaryColor;
      return Colors.grey;
    }

    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: getColor().withOpacity(0.1),
                border: Border.all(
                  color: getColor(),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                color: getColor(),
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: getColor(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}