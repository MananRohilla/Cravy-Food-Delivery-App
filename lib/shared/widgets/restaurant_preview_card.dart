import 'package:core/entities.dart';
import 'package:flutter/material.dart';

import '../../screens/restaurant_details/restaurant_details_screen.dart';

class RestaurantPreviewCard extends StatelessWidget {
  const RestaurantPreviewCard({
    super.key,
    required this.restaurant,
  });

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return RestaurantDetailsScreen(
                restaurantId: restaurant.id,
              );
            },
          ),
        );
      },
      child: Container(
        width: size.width,
        margin: const EdgeInsets.only(bottom: 16.0, right: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox( // Wrap Stack in SizedBox with fixed height
              height: 125.0,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      restaurant.imageUrl!,
                      width: size.width,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    left: 8.0,
                    top: 8.0,
                    child: Chip(
                      visualDensity: VisualDensity.compact, // Add this
                      side: BorderSide.none,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4.0), // Reduce padding
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      label: Text(
                        '2 offers available',
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 10.0, // Reduce font size
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Reduce vertical padding
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          restaurant.name,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 0.9, // Reduce line height further
                            fontSize: 13.0, // Slightly smaller font
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '\Rs 49 Delivery Fee • 25-35 min',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            height: 0.9, // Reduce line height
                            fontSize: 10.0, // Smaller font size
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  CircleAvatar(
                    radius: 13.0, // Reduce radius slightly
                    backgroundColor: colorScheme.surfaceVariant,
                    foregroundColor: colorScheme.primary,
                    child: Text(
                      restaurant.rating.toString(),
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 9.0, // Smaller font size
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
