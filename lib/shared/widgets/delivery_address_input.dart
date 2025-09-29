import 'package:flutter/material.dart';

class DeliveryAddressInput extends StatelessWidget {
  const DeliveryAddressInput({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Address',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your delivery address',
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a delivery address';
            }
            return null;
          },
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                // Simulate getting current location
                controller.text = '123 Main St, New York, NY 10001';
              },
              icon: const Icon(Icons.my_location, size: 16),
              label: const Text('Use Current Location'),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: () {
                // Show saved addresses dialog
                _showSavedAddresses(context);
              },
              icon: const Icon(Icons.bookmark, size: 16),
              label: const Text('Saved Addresses'),
            ),
          ],
        ),
      ],
    );
  }

  void _showSavedAddresses(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saved Addresses'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              subtitle: const Text('123 Main St, New York, NY 10001'),
              onTap: () {
                controller.text = '123 Main St, New York, NY 10001';
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text('Work'),
              subtitle: const Text('456 Business Ave, New York, NY 10002'),
              onTap: () {
                controller.text = '456 Business Ave, New York, NY 10002';
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}